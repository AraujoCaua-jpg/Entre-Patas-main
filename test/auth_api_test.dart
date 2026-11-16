import 'dart:convert';

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

  test('endpoint PHP legado valida perfil e usa o token ao sair', () async {
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
    addTearDown(api.close);
    final sessao = await api.entrar(' login@example.com ', ' Senha!123 ');
    expect(sessao.cliente.id, 7);
    expect(sessao.cliente.larDeAdocao, true);
    await api.sair(sessao.token);
  });

  test('endpoint PHP legado recusa credenciais inválidas', () async {
    final api = AuthApi(
      client: MockClient((_) async {
        return http.Response(
          '{"erro":"Credenciais inválidas"}',
          401,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    addTearDown(api.close);
    await expectLater(
      api.entrar('login@example.com', 'errada'),
      throwsA(isA<LoginException>()),
    );
  });

  test('endpoint PHP legado aguarda resposta ao encerrar sessão', () async {
    var autorizado = false;
    final api = AuthApi(
      client: MockClient((request) async {
        expect(request.url.path, endsWith('logout.php'));
        autorizado = request.headers['Authorization'] == 'Bearer token';
        return http.Response('{"mensagem":"Sessao encerrada"}', 200);
      }),
    );
    addTearDown(api.close);
    await api.sair('token');
    expect(autorizado, isTrue);
  });

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
