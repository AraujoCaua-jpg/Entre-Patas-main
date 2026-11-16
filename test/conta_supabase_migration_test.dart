import 'dart:convert';

import 'package:entre_patas/controller/cliente_controller.dart';
import 'package:entre_patas/model/cliente.dart';
import 'package:entre_patas/service/auth_api.dart';
import 'package:entre_patas/services/supabase_auth_service.dart';
import 'package:entre_patas/services/supabase_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _uid = '11111111-1111-4111-8111-111111111111';
const _senha = 'Atual123!';
const _novaSenha = 'NovaSenha123!';

class _ServidorConta {
  static int _proximaInstancia = 0;
  final instancia = ++_proximaInstancia;
  final requisicoes = <http.Request>[];
  String? conflito;
  bool codigoExpirado = false;
  bool exigirReautenticacao = false;
  bool emailEmUso = false;
  String? emailPendente;
  Map<String, dynamic> metadadosUsuario = {};
  String senha = _senha;
  int emissao = 0;
  final perfil = <String, dynamic>{
    'id': 1,
    'auth_user_id': _uid,
    'ativo': true,
    'nome': 'Ana',
    'sobrenome': 'Silva',
    'email': 'ana@example.com',
    'telefone': '11999998888',
    'usuario': 'ana_silva',
    'estado': 'SP',
    'cidadeDeResidencia': 'São Paulo',
    'cidade': 'São Paulo',
    'larDeAdocao': false,
    'lar_de_adocao': false,
    'imagem': 'https://example.com/foto.png',
  };

  Map<String, dynamic> get usuario => {
    'id': _uid,
    'aud': 'authenticated',
    'email': 'ana@example.com',
    'email_confirmed_at': '2026-01-01T00:00:00Z',
    'created_at': '2026-01-01T00:00:00Z',
    'app_metadata': {'provider': 'email'},
    'user_metadata': metadadosUsuario,
    if (emailPendente != null) 'new_email': emailPendente,
  };

  Map<String, dynamic> sessao() {
    emissao++;
    String segmento(Object valor) =>
        base64Url.encode(utf8.encode(jsonEncode(valor))).replaceAll('=', '');
    return {
      'access_token':
          '${segmento({'alg': 'HS256', 'typ': 'JWT'})}.'
          '${segmento({'sub': _uid, 'aud': 'authenticated', 'role': 'authenticated', 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600, 'jti': emissao, 'teste': instancia})}.simulado',
      'token_type': 'bearer',
      'expires_in': 3600,
      'refresh_token': 'refresh-simulado-$emissao',
      'user': usuario,
    };
  }

  Future<http.Response> responder(http.Request request) async {
    requisicoes.add(request);
    http.Response json(Object dados, [int status = 200]) => http.Response(
      jsonEncode(dados),
      status,
      request: request,
      headers: {'content-type': 'application/json'},
    );
    final rota = request.url.path;
    if (rota == '/auth/v1/token') {
      final dados = jsonDecode(request.body) as Map;
      if (dados['password'] != senha) {
        return json({
          'error_code': 'invalid_credentials',
          'msg': 'Invalid login credentials',
        }, 400);
      }
      return json(sessao());
    }
    if (rota == '/auth/v1/user') {
      if (request.method == 'PUT') {
        final dados = jsonDecode(request.body) as Map;
        if (dados['email'] != null) {
          if (emailEmUso) {
            return json({
              'error_code': 'email_exists',
              'msg':
                  'A user with this email address has already been registered',
            }, 422);
          }
          // Simula confirmação pendente no Auth: o e-mail confirmado não muda.
          emailPendente = dados['email'] as String;
        }
        if (exigirReautenticacao && dados['nonce'] != '654321') {
          return json({
            'error_code': 'reauthentication_needed',
            'msg': 'Reauthentication required',
          }, 401);
        }
        if (dados['password'] != null) senha = dados['password'] as String;
      }
      return json(usuario);
    }
    if (rota == '/auth/v1/recover') return json(<String, Object>{});
    if (rota == '/auth/v1/verify') {
      if (codigoExpirado) {
        return json({
          'error_code': 'otp_expired',
          'msg': 'Token has expired or is invalid',
        }, 403);
      }
      return json(sessao());
    }
    if (rota == '/auth/v1/reauthenticate') return json(<String, Object>{});
    if (rota == '/auth/v1/logout') return json(<String, Object>{});
    if (rota == '/rest/v1/cliente') {
      final filtros = request.url.queryParameters;
      if (filtros['auth_user_id'] != 'eq.$_uid' ||
          (filtros['id'] != null && filtros['id'] != 'eq.1')) {
        return json({
          'code': 'PGRST116',
          'message': 'Cannot coerce the result to a single JSON object',
          'details': 'The result contains 0 rows',
        }, 406);
      }
      if (request.method == 'PATCH') {
        if (conflito != null) {
          return json({
            'code': '23505',
            'message':
                'duplicate key value violates unique constraint cliente_${conflito}_key',
            'details': 'Key ($conflito) already exists.',
          }, 409);
        }
        perfil.addAll(
          Map<String, dynamic>.from(jsonDecode(request.body) as Map),
        );
      }
      return json(
        request.headers['Accept']?.contains('vnd.pgrst.object') == true
            ? perfil
            : [perfil],
      );
    }
    fail('Rota inesperada no teste: ${request.method} $rota');
  }
}

Cliente _edicao({
  int id = 1,
  String email = 'ana@example.com',
  String? imagem = 'https://example.com/foto.png',
}) => Cliente(
  id: id,
  nome: 'Ana Maria',
  sobrenome: 'Silva',
  email: email,
  telefone: '(11) 99999-8888',
  usuario: 'ana_maria',
  cidadeDeResidencia: 'São Paulo',
  estado: 'SP',
  imageUrl: imagem,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _ServidorConta servidor;
  late SupabaseAuthService auth;
  late SupabaseService service;
  late ClienteController controller;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (call) async => call.method == 'getAll' ? <String, Object>{} : true,
        );
    servidor = _ServidorConta();
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-key',
      httpClient: MockClient(servidor.responder),
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        autoRefreshToken: false,
      ),
    );
    auth = SupabaseAuthService();
    service = SupabaseService();
    controller = ClienteController();
  });
  tearDown(() async {
    controller.dispose();
    await Supabase.instance.dispose();
  });

  Future<void> entrar() async => auth.entrar('ana@example.com', _senha);

  test('Sem sessão não consulta nem atualiza perfil', () async {
    await expectLater(
      service.buscarMeuPerfilSupabase(),
      throwsA(isA<LoginException>()),
    );
    await expectLater(
      service.editarMeuPerfilSupabase(_edicao()),
      throwsA(isA<LoginException>()),
    );
    expect(servidor.requisicoes, isEmpty);
  });

  test(
    'Autenticação recente permite código após validar a senha atual',
    () async {
      await entrar();
      servidor.exigirReautenticacao = true;
      await expectLater(
        auth.alterarSenha(_senha, _novaSenha),
        throwsA(isA<ReautenticacaoNecessariaException>()),
      );
      expect(servidor.senha, _senha);
      await auth.solicitarCodigoReautenticacao();
      await auth.alterarSenha(
        _senha,
        _novaSenha,
        codigoReautenticacao: '654321',
      );
      expect(servidor.senha, _novaSenha);
      expect(
        servidor.requisicoes.where((r) => r.url.path == '/auth/v1/token'),
        hasLength(2),
      );
    },
  );

  test('Link exige evento de recuperação para a sessão atual', () async {
    await entrar();
    final sessao = Supabase.instance.client.auth.currentSession;
    auth.registrarRecuperacao(AuthState(AuthChangeEvent.signedIn, sessao));
    expect(auth.recuperacaoConfirmada, isFalse);
    auth.registrarRecuperacao(
      AuthState(AuthChangeEvent.passwordRecovery, sessao),
    );
    expect(auth.recuperacaoConfirmada, isTrue);
    await auth.redefinirSenha(_novaSenha);
    expect(servidor.senha, _novaSenha);
    expect(auth.recuperacaoConfirmada, isFalse);
  });

  test('Login e recarga preservam a foto por URL do banco', () async {
    servidor.perfil['imagem'] = 'https://example.com/foto-banco.png';
    await controller.entrar('ana@example.com', _senha);
    expect(
      controller.clienteLogado!.imageUrl,
      'https://example.com/foto-banco.png',
    );
    final perfil = await controller.atualizarPerfil();
    expect(perfil.imageUrl, 'https://example.com/foto-banco.png');
    expect(servidor.requisicoes.where((r) => r.method == 'PATCH'), isEmpty);
  });

  test('Login usa foto Auth quando o perfil não tem imagem', () async {
    servidor.perfil['imagem'] = null;
    servidor.metadadosUsuario = {'imagem': 'https://example.com/foto-auth.png'};
    await controller.entrar('ana@example.com', _senha);
    expect(
      controller.clienteLogado!.imageUrl,
      'https://example.com/foto-auth.png',
    );
    expect(servidor.perfil['imagem'], isNull);
  });

  test('Perfil só é carregado por auth_user_id autenticado', () async {
    await entrar();
    final cliente = await service.buscarMeuPerfilSupabase();
    expect(cliente.id, 1);
    expect(cliente.imageUrl, servidor.perfil['imagem']);
    final consulta = servidor.requisicoes.lastWhere(
      (r) => r.url.path == '/rest/v1/cliente',
    );
    expect(consulta.url.queryParameters['auth_user_id'], 'eq.$_uid');
    expect(consulta.url.queryParameters['ativo'], 'eq.true');
  });

  test(
    'Perfil usa URL dos metadados Auth se a coluna imagem estiver vazia',
    () async {
      servidor.perfil['imagem'] = null;
      servidor.metadadosUsuario = {
        'imagem': 'https://example.com/foto-auth.png',
      };
      await entrar();

      final cliente = await service.buscarMeuPerfilSupabase();
      expect(cliente.imageUrl, 'https://example.com/foto-auth.png');
      expect(servidor.perfil['imagem'], isNull);
    },
  );

  test(
    'Edição usa whitelist, filtra proprietário e normaliza telefone',
    () async {
      await entrar();
      await service.editarMeuPerfilSupabase(_edicao());
      final patch = servidor.requisicoes.singleWhere(
        (r) => r.method == 'PATCH',
      );
      expect(patch.url.queryParameters['auth_user_id'], 'eq.$_uid');
      expect(patch.url.queryParameters['id'], 'eq.1');
      final corpo = jsonDecode(patch.body) as Map;
      expect(corpo['telefone'], '11999998888');
      for (final campo in [
        'id',
        'auth_user_id',
        'ativo',
        'senha',
        'email',
        'questionario_pendente',
      ]) {
        expect(
          corpo.containsKey(campo),
          isFalse,
          reason: '$campo não é editável',
        );
      }
      expect(corpo['imagem'], 'https://example.com/foto.png');
    },
  );

  test('Edição persiste a remoção da foto como imagem nula', () async {
    await entrar();
    await service.editarMeuPerfilSupabase(_edicao(imagem: null));

    final patch = servidor.requisicoes.singleWhere(
      (request) => request.method == 'PATCH',
    );
    final corpo = jsonDecode(patch.body) as Map;
    expect(corpo['imagem'], isNull);
    expect(servidor.perfil['imagem'], isNull);
  });

  test(
    'URL editada continua disponível após sair e entrar novamente',
    () async {
      const url = 'https://example.com/nova-foto.png';
      await entrar();
      await service.editarMeuPerfilSupabase(_edicao(imagem: url));
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
      await entrar();

      final cliente = await service.buscarMeuPerfilSupabase();
      expect(cliente.imageUrl, url);
    },
  );

  test('Edição de outro ID não altera o perfil autenticado', () async {
    await entrar();
    await expectLater(
      service.editarMeuPerfilSupabase(_edicao(id: 2)),
      throwsA(isA<LoginException>()),
    );
    expect(servidor.perfil['nome'], 'Ana');
    final patch = servidor.requisicoes.singleWhere((r) => r.method == 'PATCH');
    expect(patch.url.queryParameters['id'], 'eq.2');
    expect(patch.url.queryParameters['auth_user_id'], 'eq.$_uid');
  });

  test('Controller atualiza perfil e notifica após salvar', () async {
    await entrar();
    await controller.atualizarPerfil();
    var notificacoes = 0;
    controller.addListener(() => notificacoes++);
    expect(await controller.editarClienteRemoto(_edicao()), isTrue);
    expect(controller.clienteLogado?.nome, 'Ana Maria');
    expect(controller.clienteLogado?.telefone, '11999998888');
    expect(notificacoes, greaterThan(0));
    expect(
      servidor.requisicoes.any((r) => r.url.path.endsWith('.php')),
      isFalse,
    );
  });

  for (final campo in ['email', 'telefone', 'usuario']) {
    test('Conflito de $campo usa mensagem compreensível', () async {
      await entrar();
      servidor.conflito = campo;
      await expectLater(
        service.editarMeuPerfilSupabase(_edicao()),
        throwsA(
          isA<LoginException>().having(
            (e) => e.mensagem,
            'mensagem',
            allOf(
              isNot(contains('23505')),
              isNot(contains('duplicate key')),
              isNot(contains('constraint')),
            ),
          ),
        ),
      );
    });
  }

  test(
    'Troca de email não escreve perfil sem configuração de sincronização',
    () async {
      await entrar();
      await expectLater(
        service.editarMeuPerfilSupabase(_edicao(email: 'nova@example.com')),
        throwsA(isA<LoginException>()),
      );
      expect(servidor.requisicoes.where((r) => r.method == 'PATCH'), isEmpty);
      expect(servidor.requisicoes.where((r) => r.method == 'PUT'), isEmpty);
    },
    skip: SupabaseService.alteracaoEmailHabilitada,
  );

  test(
    'Alteração de email usa apenas Auth e mantém confirmado até verificação',
    () async {
      await entrar();
      await auth.solicitarAlteracaoEmail(' Nova@Example.com ');
      final alteracao = servidor.requisicoes.singleWhere(
        (r) => r.method == 'PUT',
      );
      expect(alteracao.url.path, '/auth/v1/user');
      expect((jsonDecode(alteracao.body) as Map)['email'], 'nova@example.com');
      expect(servidor.emailPendente, 'nova@example.com');
      expect(
        Supabase.instance.client.auth.currentUser?.email,
        'ana@example.com',
      );
      expect(servidor.perfil['email'], 'ana@example.com');
      expect(
        servidor.requisicoes.where((r) => r.url.path == '/rest/v1/cliente'),
        isEmpty,
      );
    },
  );

  test('Auth email_exists vira mensagem legível sem erro técnico', () async {
    await entrar();
    servidor.emailEmUso = true;
    await expectLater(
      auth.solicitarAlteracaoEmail('existente@example.com'),
      throwsA(
        isA<LoginException>().having(
          (e) => e.mensagem,
          'mensagem',
          allOf(
            contains('e-mail'),
            isNot(contains('email_exists')),
            isNot(contains('registered')),
          ),
        ),
      ),
    );
    expect(Supabase.instance.client.auth.currentUser?.email, 'ana@example.com');
    expect(servidor.requisicoes.where((r) => r.method == 'PATCH'), isEmpty);
  });

  test('Email habilitado: controller pede confirmação após PATCH sem antecipar email', () async {
    await entrar();
    await controller.atualizarPerfil();
    expect(
      await controller.editarClienteRemoto(_edicao(email: 'nova@example.com')),
      isTrue,
    );
    final indicePatch = servidor.requisicoes.indexWhere(
      (r) => r.method == 'PATCH',
    );
    final indiceAuth = servidor.requisicoes.indexWhere(
      (r) => r.method == 'PUT',
    );
    expect(indicePatch, greaterThan(-1));
    expect(indiceAuth, greaterThan(indicePatch));
    expect(
      (jsonDecode(servidor.requisicoes[indicePatch].body) as Map).containsKey(
        'email',
      ),
      isFalse,
    );
    expect(servidor.emailPendente, 'nova@example.com');
    expect(controller.clienteLogado?.nome, 'Ana Maria');
    expect(controller.clienteLogado?.email, 'ana@example.com');
    expect(Supabase.instance.client.auth.currentUser?.email, 'ana@example.com');
    expect(servidor.perfil['email'], 'ana@example.com');
  }, skip: !SupabaseService.alteracaoEmailHabilitada);

  test(
    'Email habilitado: conflito Auth informa que os outros dados foram salvos',
    () async {
      await entrar();
      await controller.atualizarPerfil();
      servidor.emailEmUso = true;
      await expectLater(
        controller.editarClienteRemoto(_edicao(email: 'existente@example.com')),
        throwsA(
          isA<LoginException>().having(
            (e) => e.mensagem,
            'mensagem',
            allOf(
              contains('outros dados'),
              contains('salvos'),
              isNot(contains('email_exists')),
            ),
          ),
        ),
      );
      expect(controller.clienteLogado?.nome, 'Ana Maria');
      expect(controller.clienteLogado?.email, 'ana@example.com');
      expect(servidor.perfil['email'], 'ana@example.com');
    },
    skip: !SupabaseService.alteracaoEmailHabilitada,
  );

  test('Senha atual incorreta impede updateUser', () async {
    await entrar();
    await expectLater(
      auth.alterarSenha('Incorreta123!', _novaSenha),
      throwsA(isA<LoginException>()),
    );
    expect(servidor.requisicoes.where((r) => r.method == 'PUT'), isEmpty);
    expect(Supabase.instance.client.auth.currentUser?.id, _uid);
  });

  test('Senha fraca é recusada antes de chamadas para alterar senha', () async {
    await entrar();
    final antes = servidor.requisicoes.length;
    await expectLater(
      auth.alterarSenha(_senha, 'fraca'),
      throwsA(isA<LoginException>()),
    );
    expect(servidor.requisicoes.length, antes);
  });

  test(
    'Alterar senha reautentica e atualiza Auth sem tocar tabela cliente',
    () async {
      await entrar();
      await auth.alterarSenha(_senha, _novaSenha);
      expect(servidor.senha, _novaSenha);
      expect(
        servidor.requisicoes.where((r) => r.url.path == '/auth/v1/token'),
        hasLength(2),
      );
      expect(
        servidor.requisicoes.where((r) => r.url.path == '/rest/v1/cliente'),
        isEmpty,
      );
      expect(Supabase.instance.client.auth.currentUser?.id, _uid);
    },
  );

  test(
    'Solicitação recuperação usa recover e redirectTo sem consultar perfis',
    () async {
      await auth.solicitarRecuperacao(
        'nao-existe@example.com',
        redirectTo: 'entrepatas://auth-callback',
      );
      final request = servidor.requisicoes.single;
      expect(request.url.path, '/auth/v1/recover');
      expect(
        request.url.queryParameters['redirect_to'],
        'entrepatas://auth-callback',
      );
      expect(
        (jsonDecode(request.body) as Map)['email'],
        'nao-existe@example.com',
      );
    },
  );

  test(
    'Sessão comum não autoriza redefinição sem confirmação de recuperação',
    () async {
      await entrar();
      await expectLater(
        auth.redefinirSenha(_novaSenha),
        throwsA(isA<LoginException>()),
      );
      expect(servidor.requisicoes.where((r) => r.method == 'PUT'), isEmpty);
    },
  );

  test(
    'Código válido confirma recuperação e permite atualizar senha uma vez',
    () async {
      await auth.verificarCodigoRecuperacao('ana@example.com', '123456');
      await auth.redefinirSenha(_novaSenha);
      expect(servidor.senha, _novaSenha);
      final verify = servidor.requisicoes.firstWhere(
        (r) => r.url.path == '/auth/v1/verify',
      );
      expect((jsonDecode(verify.body) as Map)['type'], 'recovery');
      await expectLater(
        auth.redefinirSenha('OutraSenha123!'),
        throwsA(isA<LoginException>()),
      );
    },
  );

  test('Código expirado não permite definir nova senha', () async {
    servidor.codigoExpirado = true;
    await expectLater(
      auth.verificarCodigoRecuperacao('ana@example.com', '000000'),
      throwsA(isA<LoginException>()),
    );
    await expectLater(
      auth.redefinirSenha(_novaSenha),
      throwsA(isA<LoginException>()),
    );
    expect(servidor.requisicoes.where((r) => r.method == 'PUT'), isEmpty);
  });
}
