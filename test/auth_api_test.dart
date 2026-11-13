import 'dart:convert';
import 'dart:async';

import 'package:entre_patas/controller/cliente_controller.dart';
import 'package:entre_patas/service/auth_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final perfil = {
    'id': 7,
    'nome': 'Teste',
    'sobrenome': 'Login',
    'email': 'login@example.com',
    'telefone': '11999999999',
    'usuario': 'teste_login',
    'cidadeDeResidencia': null,
    'estado': 'SP',
    'larDeAdocao': true,
  };

  test('entra sem cadastro em memória e encerra a sessão com token', () async {
    final api = AuthApi(
      client: MockClient((request) async {
        if (request.url.path.endsWith('login.php')) {
          expect(jsonDecode(request.body), {
            'email': 'login@example.com',
            'senha': ' Senha!123 ',
          });
          return http.Response(
            jsonEncode({'cliente': perfil, 'token': 'token-teste'}),
            200,
          );
        }
        expect(request.url.path, endsWith('logout.php'));
        expect(request.headers['Authorization'], 'Bearer token-teste');
        return http.Response('{"mensagem":"Sessao encerrada"}', 200);
      }),
    );
    final controller = ClienteController(authApi: api);
    addTearDown(controller.dispose);
    expect(controller.clienteLogado, isNull);
    await controller.entrar(' login@example.com ', ' Senha!123 ');
    expect(controller.clienteLogado?.id, 7);
    expect(controller.clienteLogado?.larDeAdocao, true);
    await controller.sair();
    expect(controller.clienteLogado, isNull);
  });

  test('senha incorreta não autentica e mostra o erro da API', () async {
    final controller = ClienteController(
      authApi: AuthApi(
        client: MockClient((_) async {
          return http.Response(
            '{"erro":"Credenciais inválidas"}',
            401,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      ),
    );
    addTearDown(controller.dispose);
    await expectLater(
      controller.entrar('login@example.com', 'errada'),
      throwsA(isA<LoginException>()),
    );
    expect(controller.clienteLogado, isNull);
    expect(controller.clientes, isEmpty);
  });

  test(
    'logout limpa sessão imediatamente mesmo com servidor lento ou offline',
    () async {
      final remoto = Completer<http.Response>();
      final controller = ClienteController(
        authApi: AuthApi(
          client: MockClient((request) async {
            if (request.url.path.endsWith('login.php')) {
              return http.Response(
                jsonEncode({'cliente': perfil, 'token': 'token-teste'}),
                200,
              );
            }
            return remoto.future;
          }),
        ),
      );
      addTearDown(controller.dispose);
      await controller.entrar('login@example.com', 'Senha!123');
      await controller.sair().timeout(const Duration(seconds: 1));
      expect(controller.clienteLogado, isNull);
      expect(controller.clientes, isEmpty);
      remoto.complete(http.Response('{"erro":"Indisponível"}', 503));
      await Future<void>.delayed(Duration.zero);
    },
  );

  test('rejeita resposta incompleta e falha de conexão', () async {
    for (final body in ['<html>Erro PHP</html>', '{"cliente":{}}']) {
      final api = AuthApi(
        client: MockClient((_) async => http.Response(body, 200)),
      );
      addTearDown(api.close);
      await expectLater(
        api.entrar('login@example.com', 'senha'),
        throwsA(isA<LoginException>()),
      );
    }
    final api = AuthApi(
      client: MockClient((_) async {
        throw http.ClientException('offline');
      }),
    );
    addTearDown(api.close);
    await expectLater(
      api.entrar('login@example.com', 'senha'),
      throwsA(isA<LoginException>()),
    );
  });
}
