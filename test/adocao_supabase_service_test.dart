import 'dart:async';
import 'dart:convert';

import 'package:entre_patas/controller/cliente_controller.dart';
import 'package:entre_patas/model/adocao.dart';
import 'package:entre_patas/service/auth_api.dart';
import 'package:entre_patas/services/supabase_auth_service.dart';
import 'package:entre_patas/services/supabase_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _uidAdotante = '11111111-1111-4111-8111-111111111111';
const _uidDono = '22222222-2222-4222-8222-222222222222';

Map<String, dynamic> _pedido({String status = 'Aguardando'}) => {
  'id': 7,
  'data': '2026-11-14T12:00:00Z',
  'status': status,
  'id_animal': 9,
  'id_cliente': 1,
  'id_dono': 2,
  'animal_nome': 'Lua',
  'animal_imagem': 'https://example.com/lua.png',
  'animal_idade': 3,
  'animal_sexo': 'Fêmea',
  'estado': 'SP',
  'cidadeDeResidencia': 'São Paulo',
  'solicitante_nome': 'Ana',
  'solicitante_sobrenome': 'Silva',
  'solicitante_email': 'ana@example.com',
  'solicitante_telefone': '11999998888',
};

// Respostas de transporte, sem reproduzir autorização, RLS ou transações SQL.
// O teste comprova o contrato do aplicativo; segurança e concorrência precisam
// ser verificadas contra as RPCs no PostgreSQL de teste.
class _ServidorAdocao {
  final requisicoes = <http.Request>[];
  Map<String, dynamic>? erro;
  int statusErro = 400;
  bool falhaRede = false;
  String usuarioId = _uidAdotante;
  dynamic respostaRpc;
  String? token;
  int emissao = 0;
  Completer<void>? rpcIniciada;
  Completer<void>? liberarRpc;

  Map<String, dynamic> _sessao() {
    String segmento(Object dados) =>
        base64Url.encode(utf8.encode(jsonEncode(dados))).replaceAll('=', '');
    token =
        '${segmento({'alg': 'HS256', 'typ': 'JWT'})}.'
        '${segmento({'sub': usuarioId, 'aud': 'authenticated', 'role': 'authenticated', 'jti': ++emissao, 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600})}.simulado';
    return {
      'access_token': token,
      'token_type': 'bearer',
      'expires_in': 3600,
      'refresh_token': 'refresh-simulado-$usuarioId',
      'user': {
        'id': usuarioId,
        'aud': 'authenticated',
        'email': usuarioId == _uidDono ? 'dono@example.com' : 'ana@example.com',
        'created_at': '2026-01-01T00:00:00Z',
        'app_metadata': {'provider': 'email'},
        'user_metadata': <String, Object>{},
      },
    };
  }

  Future<http.Response> responder(http.Request request) async {
    requisicoes.add(request);
    http.Response json(Object? dados, [int status = 200]) => http.Response(
      jsonEncode(dados),
      status,
      request: request,
      headers: {'content-type': 'application/json'},
    );
    final rota = request.url.path;
    if (rota == '/auth/v1/token') {
      final dados = jsonDecode(request.body) as Map;
      if (request.url.queryParameters['grant_type'] != 'refresh_token') {
        usuarioId = dados['email'] == 'dono@example.com'
            ? _uidDono
            : _uidAdotante;
      }
      return json(_sessao());
    }
    if (rota == '/auth/v1/logout') return json({});
    if (rota == '/rest/v1/cliente') {
      expect(request.url.queryParameters['auth_user_id'], 'eq.$usuarioId');
      return json([
        {
          'id': usuarioId == _uidDono ? 2 : 1,
          'ativo': true,
          'nome': usuarioId == _uidDono ? 'Responsável' : 'Ana',
          'usuario': usuarioId == _uidDono ? 'responsavel' : 'ana',
        },
      ]);
    }
    if (rota.startsWith('/rest/v1/rpc/')) {
      expect(request.method, 'POST');
      expect(request.headers['Authorization'], 'Bearer $token');
      rpcIniciada?.complete();
      await liberarRpc?.future;
      if (falhaRede) {
        throw http.ClientException('Conexão simulada indisponível');
      }
      if (erro != null) return json(erro, statusErro);
      if (respostaRpc != null) return json(respostaRpc);
      switch (rota.split('/').last) {
        case 'listar_minhas_adocoes':
          return json([_pedido()]);
        case 'buscar_minha_adocao':
        case 'solicitar_adocao':
          return json(_pedido());
        case 'responder_adocao':
          final dados = jsonDecode(request.body) as Map;
          return json(
            _pedido(
              status: {
                'aceitar': 'Aceito',
                'recusar': 'Recusado',
                'cancelar': 'Cancelado',
              }[dados['p_acao']]!,
            ),
          );
      }
    }
    fail('Requisição inesperada no teste: ${request.method} $rota');
  }

  List<http.Request> get rpcs =>
      requisicoes.where((r) => r.url.path.startsWith('/rest/v1/rpc/')).toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _ServidorAdocao servidor;
  late SupabaseAuthService auth;
  late SupabaseService service;
  late ClienteController controller;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (call) async => call.method == 'getAll' ? <String, Object>{} : true,
        );
    servidor = _ServidorAdocao();
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

  Future<void> entrar({bool dono = false}) async {
    await auth.entrar(
      dono ? 'dono@example.com' : 'ana@example.com',
      'Teste123!',
    );
  }

  void conferirDetalhes(Adocao pedido) {
    expect(pedido.id, 7);
    expect(pedido.idAnimal, 9);
    expect(pedido.idCliente, 1);
    expect(pedido.idDono, 2);
    expect(pedido.data.toUtc(), DateTime.utc(2026, 11, 14, 12));
    expect(pedido.detalhes['animal_nome'], 'Lua');
    expect(pedido.detalhes['animal_imagem'], 'https://example.com/lua.png');
    expect(pedido.detalhes['animal_idade'], 3);
    expect(pedido.detalhes['animal_sexo'], 'Fêmea');
    expect(pedido.detalhes['cidadeDeResidencia'], 'São Paulo');
    expect(pedido.detalhes['solicitante_email'], 'ana@example.com');
    expect(pedido.detalhes['solicitante_telefone'], '11999998888');
  }

  test('Sem sessão não envia consultas nem operações de adoção', () async {
    for (final operacao in <Future<dynamic> Function()>[
      service.listarAdocoesSupabase,
      () => service.buscarAdocaoSupabase(7),
      () => service.solicitarAdocaoSupabase(9),
      () => service.responderAdocaoSupabase(7, 'aceitar'),
    ]) {
      await expectLater(operacao(), throwsA(isA<LoginException>()));
    }
    expect(servidor.requisicoes, isEmpty);
  });

  test(
    'Lista notificações por RPC com sessão Auth e conserva detalhes',
    () async {
      await entrar();
      final lista = await service.listarAdocoesSupabase();
      expect(lista, hasLength(1));
      conferirDetalhes(lista.single);
      expect(lista.single.status, 'Aguardando');
      final request = servidor.rpcs.single;
      expect(request.url.path, '/rest/v1/rpc/listar_minhas_adocoes');
      expect(request.body.isEmpty ? {} : jsonDecode(request.body), isEmpty);
    },
  );

  test('Lista vazia não inventa notificações', () async {
    await entrar();
    servidor.respostaRpc = <Object>[];
    expect(await service.listarAdocoesSupabase(), isEmpty);
  });

  for (final status in ['Aguardando', 'Aceito', 'Recusado', 'Cancelado']) {
    test('Consulta solicitação conserva estado $status e detalhes', () async {
      await entrar();
      servidor.respostaRpc = _pedido(status: status);
      final pedido = await service.buscarAdocaoSupabase(7);
      conferirDetalhes(pedido);
      expect(pedido.status, status);
      final request = servidor.rpcs.single;
      expect(request.url.path, '/rest/v1/rpc/buscar_minha_adocao');
      expect(jsonDecode(request.body), {'p_adocao_id': 7});
    });
  }

  test(
    'Solicitar envia somente ID animal; adotante e status vêm da RPC',
    () async {
      await entrar();
      final pedido = await service.solicitarAdocaoSupabase(9);
      conferirDetalhes(pedido);
      expect(pedido.status, 'Aguardando');
      expect(servidor.rpcs.single.url.path, '/rest/v1/rpc/solicitar_adocao');
      expect(jsonDecode(servidor.rpcs.single.body), {'p_animal_id': 9});
      expect(
        servidor.requisicoes.any((r) => r.url.path.endsWith('.php')),
        isFalse,
      );
      expect(
        servidor.requisicoes.any(
          (r) =>
              r.url.path == '/rest/v1/adocao' ||
              r.url.path == '/rest/v1/animal',
        ),
        isFalse,
      );
    },
  );

  for (final acao in ['aceitar', 'recusar', 'cancelar']) {
    test('Decisão $acao usa RPC e não atualiza status diretamente', () async {
      await entrar(dono: acao != 'cancelar');
      final pedido = await service.responderAdocaoSupabase(7, acao);
      expect(
        pedido.status,
        {
          'aceitar': 'Aceito',
          'recusar': 'Recusado',
          'cancelar': 'Cancelado',
        }[acao],
      );
      expect(servidor.rpcs.single.url.path, '/rest/v1/rpc/responder_adocao');
      expect(jsonDecode(servidor.rpcs.single.body), {
        'p_adocao_id': 7,
        'p_acao': acao,
      });
      expect(servidor.requisicoes.where((r) => r.method == 'PATCH'), isEmpty);
    });
  }

  test(
    'Controller notifica após solicitação e decisão, não nas leituras',
    () async {
      await entrar();
      var avisos = 0;
      controller.addListener(() => avisos++);
      await controller.listarAdocoes();
      await controller.buscarAdocao(7);
      expect(avisos, 0);
      final enviado = await controller.solicitarAdocao(9);
      expect(enviado.status, 'Aguardando');
      expect(avisos, 1);
      final cancelado = await controller.responderAdocao(7, 'cancelar');
      expect(cancelado.status, 'Cancelado');
      expect(avisos, 2);
    },
  );

  for (final regra in <String, String>{
    'Você não pode solicitar a adoção do próprio animal.': 'PT400',
    'Este animal não está disponível para adoção.': 'PT409',
    'Você já possui uma solicitação em andamento para este animal.': 'PT409',
    'Você não pode realizar esta ação.': 'PT403',
    'Esta solicitação já foi finalizada.': 'PT409',
    'Não é possível aprovar esta adoção.': 'PT409',
    'Solicitação não encontrada.': 'PT404',
  }.entries) {
    final mensagem = regra.key;
    test('Erro de regra da RPC é legível: $mensagem', () async {
      await entrar();
      servidor.erro = {'code': regra.value, 'message': mensagem};
      await expectLater(
        service.solicitarAdocaoSupabase(9),
        throwsA(
          isA<LoginException>().having(
            (erro) => erro.mensagem,
            'mensagem',
            mensagem,
          ),
        ),
      );
    });
  }

  for (final codigo in ['23505', '42501', 'PGRST202']) {
    test('Erro técnico $codigo não expõe SQL ou detalhes internos', () async {
      await entrar();
      servidor.statusErro = codigo == 'PGRST202' ? 404 : 409;
      servidor.erro = {
        'code': codigo,
        'message': 'Internal SQL private_table_name secret_constraint',
        'details': 'Internal schema data not meant for UI',
      };
      await expectLater(
        service.solicitarAdocaoSupabase(9),
        throwsA(
          isA<LoginException>().having(
            (erro) => erro.mensagem,
            'mensagem amigável',
            allOf(
              isNot(contains('private_table_name')),
              isNot(contains('SQL')),
            ),
          ),
        ),
      );
    });
  }

  test(
    'Erro desconhecido P0001 não vaza mensagem interna arbitrária',
    () async {
      await entrar();
      servidor.erro = {
        'code': 'P0001',
        'message': 'Internal SQL private_table_name secret_constraint',
      };
      await expectLater(
        service.responderAdocaoSupabase(7, 'aceitar'),
        throwsA(
          isA<LoginException>().having(
            (erro) => erro.mensagem,
            'mensagem amigável',
            isNot(contains('private_table_name')),
          ),
        ),
      );
    },
  );

  test('Erro não notifica nem apresenta uma operação como concluída', () async {
    await entrar();
    var avisos = 0;
    controller.addListener(() => avisos++);
    servidor.erro = {'code': '23505', 'message': 'Duplicate key'};
    await expectLater(
      controller.solicitarAdocao(9),
      throwsA(isA<LoginException>()),
    );
    expect(avisos, 0);
  });

  for (final operacao in ['listar', 'solicitar', 'aceitar']) {
    test('Renovação de token preserva o resultado de $operacao', () async {
      await entrar(dono: operacao == 'aceitar');
      final usuario = Supabase.instance.client.auth.currentUser!.id;
      final tokenAnterior =
          Supabase.instance.client.auth.currentSession!.accessToken;
      servidor.rpcIniciada = Completer<void>();
      servidor.liberarRpc = Completer<void>();
      final Future<dynamic> consulta = switch (operacao) {
        'listar' => service.listarAdocoesSupabase(),
        'solicitar' => service.solicitarAdocaoSupabase(9),
        _ => service.responderAdocaoSupabase(7, 'aceitar'),
      };
      final conclusao = expectLater(consulta, completes);
      await servidor.rpcIniciada!.future;
      await Supabase.instance.client.auth.refreshSession();
      expect(Supabase.instance.client.auth.currentUser!.id, usuario);
      expect(
        Supabase.instance.client.auth.currentSession!.accessToken,
        isNot(tokenAnterior),
      );
      servidor.liberarRpc!.complete();
      await conclusao;
      final dados = await consulta;
      if (operacao == 'listar') {
        expect((dados as List<Adocao>).single.id, 7);
      } else {
        expect(
          (dados as Adocao).status,
          operacao == 'aceitar' ? 'Aceito' : 'Aguardando',
        );
      }
    });
  }

  for (final mudanca in [
    'troca de conta',
    'logout',
    'novo login da mesma conta',
  ]) {
    test('Resposta antiga não é entregue após $mudanca', () async {
      await entrar();
      servidor.rpcIniciada = Completer<void>();
      servidor.liberarRpc = Completer<void>();
      final consulta = service.listarAdocoesSupabase();
      final resultado = expectLater(consulta, throwsA(isA<LoginException>()));
      await servidor.rpcIniciada!.future;
      if (mudanca == 'logout') {
        await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
      } else {
        await entrar(dono: mudanca == 'troca de conta');
      }
      servidor.liberarRpc!.complete();
      await resultado;
      expect(
        Supabase.instance.client.auth.currentUser?.id,
        mudanca == 'logout'
            ? null
            : mudanca == 'troca de conta'
            ? _uidDono
            : _uidAdotante,
      );
    });
  }

  test(
    'Nova operação ignora histórico de renovação e de login anterior',
    () async {
      await entrar();
      await Supabase.instance.client.auth.refreshSession();
      expect(await service.listarAdocoesSupabase(), hasLength(1));
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
      await entrar();
      expect(await service.listarAdocoesSupabase(), hasLength(1));
    },
  );

  test(
    'Falha de conexão recebe mensagem tratável, sem HTTP/PHP fallback',
    () async {
      await entrar();
      servidor.falhaRede = true;
      await expectLater(
        service.listarAdocoesSupabase(),
        throwsA(isA<LoginException>()),
      );
      expect(servidor.rpcs, hasLength(1));
      expect(
        servidor.requisicoes.any((r) => r.url.path.endsWith('.php')),
        isFalse,
      );
    },
  );
}
