import 'dart:convert';

import 'package:entre_patas/model/cliente.dart';
import 'package:entre_patas/service/clientes_api.dart';
import 'package:entre_patas/service/auth_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('pesquisa preserva o termo e envia a sessão no cabeçalho', () async {
    final api = ClientesApi(
      client: MockClient((r) async {
        expect(r.method, 'GET');
        expect(r.url.queryParameters['q'], '@ana & bia');
        expect(r.headers['Authorization'], 'Bearer teste');
        return http.Response(
          jsonEncode({
            'clientes': [
              {'id': 4, 'nome': 'Ana', 'usuario': 'ana', 'imagem': null},
            ],
          }),
          200,
        );
      }),
    );
    addTearDown(api.close);
    final resultado = await api.pesquisar('teste', '@ana & bia');
    expect(resultado.single.id, 4);
    expect(resultado.single.email, '');
  });
  test('edição não envia ID, senha ou ativo no corpo', () async {
    final api = ClientesApi(
      client: MockClient((r) async {
        expect(r.url.queryParameters['acao'], 'editar');
        final body = jsonDecode(r.body) as Map;
        expect(body.containsKey('id'), false);
        expect(body.containsKey('senha'), false);
        expect(body.containsKey('ativo'), false);
        return http.Response(
          jsonEncode({
            'cliente': {'id': 4, ...body},
          }),
          200,
        );
      }),
    );
    addTearDown(api.close);
    final c = Cliente(
      id: 4,
      nome: 'Ana',
      sobrenome: 'Teste',
      email: 'ana@example.com',
      telefone: '11999999999',
      cidadeDeResidencia: 'Teste',
      usuario: 'ana',
    );
    expect((await api.editar('teste', c)).nome, 'Ana');
  });
  test('exclusão chama a rota de desativação autenticada', () async {
    final api = ClientesApi(
      client: MockClient((r) async {
        expect(r.method, 'POST');
        expect(r.url.queryParameters['acao'], 'apagar');
        expect(r.headers['Authorization'], 'Bearer teste');
        return http.Response('{}', 200);
      }),
    );
    addTearDown(api.close);
    await api.apagar('teste');
  });
  test('recuperação sem envio configurado informa o erro', () async {
    final api = ClientesApi(
      client: MockClient((r) async {
        expect(r.headers.containsKey('Authorization'), false);
        return http.Response('{"erro":"Configure o envio de email"}', 503);
      }),
    );
    addTearDown(api.close);
    await expectLater(
      api.solicitarRecuperacao('ana@example.com'),
      throwsA(isA<LoginException>()),
    );
  });
}
