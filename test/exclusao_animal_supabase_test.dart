import 'dart:async';
import 'dart:convert';

import 'package:entre_patas/controller/cliente_controller.dart';
import 'package:entre_patas/services/login_exception.dart';
import 'package:entre_patas/services/supabase_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/logout_supabase_backend.dart';

// O mock confere transporte e contrato; propriedade/permissões da RPC são
// verificadas separadamente pelos testes SQL em PostgreSQL de teste.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseService service;
  late ClienteController controller;
  late ServidorAuthSimulado auth;
  late List<http.Request> requests;
  dynamic respostaRpc;
  Map<String, dynamic>? erroRpc;
  int statusErro = 400;
  bool falharRede = false;
  int renovacoes = 0;
  Completer<void>? rpcIniciada;
  Completer<void>? liberarRpc;

  setUp(() async {
    requests = [];
    auth = ServidorAuthSimulado();
    respostaRpc = {'id': 9, 'ativo': false};
    erroRpc = null;
    statusErro = 400;
    falharRede = false;
    renovacoes = 0;
    rpcIniciada = null;
    liberarRpc = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (call) async => call.method == 'getAll' ? <String, Object>{} : true,
        );
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-key',
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        autoRefreshToken: false,
      ),
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.url.path == '/auth/v1/token' &&
            request.url.queryParameters['grant_type'] == 'refresh_token') {
          final sessao = Supabase.instance.client.auth.currentSession!;
          final partes = sessao.accessToken.split('.');
          final claims = jsonDecode(
            utf8.decode(base64Url.decode(base64Url.normalize(partes[1]))),
          ) as Map<String, dynamic>;
          claims['jti'] = ++renovacoes;
          final payload = base64Url
              .encode(utf8.encode(jsonEncode(claims)))
              .replaceAll('=', '');
          return http.Response(
            jsonEncode({
              ...sessao.toJson(),
              'access_token': '${partes[0]}.$payload.assinatura-simulada',
              'expires_in': 3600,
            }),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        if (request.url.path != '/rest/v1/rpc/excluir_meu_animal') {
          return auth.responder(request);
        }
        expect(request.method, 'POST');
        expect(request.headers['Authorization'], startsWith('Bearer '));
        rpcIniciada?.complete();
        await liberarRpc?.future;
        if (falharRede) throw http.ClientException('Erro interno simulado');
        return http.Response(
          jsonEncode(erroRpc ?? respostaRpc),
          erroRpc == null ? 200 : statusErro,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    service = SupabaseService();
    controller = ClienteController();
  });

  tearDown(() async {
    controller.dispose();
    await Supabase.instance.dispose();
  });

  Future<void> entrar([String email = 'a@example.com']) async {
    await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: 'senha-simulada',
    );
    requests.clear();
  }

  Matcher mensagem(String texto) =>
      isA<LoginException>().having((erro) => erro.mensagem, 'mensagem', texto);

  test('Sem sessão não envia operação de exclusão', () async {
    await expectLater(
      service.excluirMeuAnimalSupabase(9),
      throwsA(mensagem('Entre novamente para continuar.')),
    );
    expect(requests, isEmpty);
  });

  for (final id in [0, -1]) {
    test('ID $id é rejeitado sem requisição', () async {
      await expectLater(
        service.excluirMeuAnimalSupabase(id),
        throwsA(mensagem('ID inválido.')),
      );
      expect(requests, isEmpty);
    });
  }

  test('Exclusão usa somente RPC e ID; notifica após confirmação', () async {
    await entrar();
    var avisos = 0;
    controller.addListener(() => avisos++);
    await controller.apagarAnimalSupabase(9);
    expect(requests, hasLength(1));
    expect(requests.single.url.path, '/rest/v1/rpc/excluir_meu_animal');
    expect(jsonDecode(requests.single.body), {'p_animal_id': 9});
    expect(avisos, 1);
    expect(
      requests.any(
        (request) =>
            request.method == 'PATCH' ||
            request.method == 'DELETE' ||
            request.url.path.endsWith('.php') ||
            request.url.path == '/rest/v1/cliente',
      ),
      isFalse,
    );
  });

  test(
    'Listagem própria solicita apenas animais ativos após soft delete',
    () async {
      await entrar();
      await service.buscarAnimaisDoCliente(1);
      final consulta = requests.singleWhere(
        (request) => request.url.path == '/rest/v1/animal',
      );
      expect(consulta.url.queryParameters['id_cliente'], 'eq.1');
      expect(consulta.url.queryParameters['ativo'], 'eq.true');
      expect(consulta.url.queryParameters.containsKey('status'), isFalse);
    },
  );

  test(
    'Próprio animal já inativo aceita confirmação idempotente da RPC',
    () async {
      await entrar();
      await service.excluirMeuAnimalSupabase(9);
      await service.excluirMeuAnimalSupabase(9);
      expect(requests, hasLength(2));
      for (final request in requests) {
        expect(jsonDecode(request.body), {'p_animal_id': 9});
      }
    },
  );

  for (final regra in <String, String>{
    'Entre novamente para continuar.': 'PT401',
    'Perfil não encontrado ou inativo.': 'PT403',
    'Animal não encontrado ou sem permissão para excluir.': 'PT404',
  }.entries) {
    test(
      'Erro autorizado pelo contrato não anuncia sucesso: ${regra.key}',
      () async {
        await entrar();
        erroRpc = {'code': regra.value, 'message': regra.key};
        var avisos = 0;
        controller.addListener(() => avisos++);
        await expectLater(
          controller.apagarAnimalSupabase(9),
          throwsA(mensagem(regra.key)),
        );
        expect(avisos, 0);
        expect(requests, hasLength(1));
      },
    );
  }

  for (final codigo in ['PGRST202', '42883', 'PGRST205', '42P01']) {
    test('RPC ausente $codigo tem mensagem própria sem fallback', () async {
      await entrar();
      erroRpc = {'code': codigo, 'message': 'Internal SQL private_schema'};
      statusErro = 404;
      await expectLater(
        service.excluirMeuAnimalSupabase(9),
        throwsA(
          mensagem(
            'A exclusão de animais ainda precisa ser configurada no Supabase.',
          ),
        ),
      );
      expect(requests, hasLength(1));
    });
  }

  for (final codigo in ['42501', 'PT403']) {
    test('Permissão negada $codigo não expõe detalhes internos', () async {
      await entrar();
      erroRpc = {'code': codigo, 'message': 'Internal SQL private_schema'};
      statusErro = 403;
      await expectLater(
        service.excluirMeuAnimalSupabase(9),
        throwsA(
          mensagem('Animal não encontrado ou sem permissão para excluir.'),
        ),
      );
      expect(requests, hasLength(1));
    });
  }

  for (final caso in <String, Object?>{
    'nula': null,
    'lista vazia': [],
    'mapa vazio': <String, dynamic>{},
    'ID diferente': {'id': 10, 'ativo': false},
    'ID em string': {'id': '9', 'ativo': false},
    'ainda ativo': {'id': 9, 'ativo': true},
    'booleano em string': {'id': 9, 'ativo': 'false'},
  }.entries) {
    test('Resposta ${caso.key} não confirma exclusão nem notifica', () async {
      await entrar();
      respostaRpc = caso.value;
      var avisos = 0;
      controller.addListener(() => avisos++);
      await expectLater(
        controller.apagarAnimalSupabase(9),
        throwsA(mensagem('Não foi possível confirmar a exclusão do animal.')),
      );
      expect(avisos, 0);
    });
  }

  test(
    'Renovação de token preserva confirmação e notificação da exclusão',
    () async {
      await entrar();
      var avisos = 0;
      controller.addListener(() => avisos++);
      final tokenAnterior =
          Supabase.instance.client.auth.currentSession!.accessToken;
      rpcIniciada = Completer<void>();
      liberarRpc = Completer<void>();
      final operacao = controller.apagarAnimalSupabase(9);
      final resultado = expectLater(operacao, completes);
      await rpcIniciada!.future;
      await Supabase.instance.client.auth.refreshSession();
      expect(
        Supabase.instance.client.auth.currentSession!.accessToken,
        isNot(tokenAnterior),
      );
      liberarRpc!.complete();
      await resultado;
      expect(avisos, 1);
    },
  );

  for (final mudanca in [
    'logout',
    'troca de conta',
    'novo login da mesma conta',
  ]) {
    test('Resposta antiga é rejeitada após $mudanca', () async {
      await entrar();
      var avisos = 0;
      controller.addListener(() => avisos++);
      rpcIniciada = Completer<void>();
      liberarRpc = Completer<void>();
      final operacao = controller.apagarAnimalSupabase(9);
      final resultado = expectLater(
        operacao,
        throwsA(mensagem('Entre novamente para continuar.')),
      );
      await rpcIniciada!.future;
      if (mudanca == 'logout') {
        await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
      } else {
        await entrar(
          mudanca == 'troca de conta' ? 'b@example.com' : 'a@example.com',
        );
      }
      liberarRpc!.complete();
      await resultado;
      expect(avisos, 0);
    });
  }

  test('Falha de rede é tratada sem notificar ou usar PHP', () async {
    await entrar();
    falharRede = true;
    var avisos = 0;
    controller.addListener(() => avisos++);
    await expectLater(
      controller.apagarAnimalSupabase(9),
      throwsA(mensagem('Não foi possível excluir o animal. Tente novamente.')),
    );
    expect(avisos, 0);
    expect(requests, hasLength(1));
  });
}
