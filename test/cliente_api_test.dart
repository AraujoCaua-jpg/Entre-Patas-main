import 'dart:convert';

import 'package:entre_patas/model/cliente.dart';
import 'package:entre_patas/service/cliente_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final cliente = Cliente(
    id: 0,
    nome: 'Teste',
    sobrenome: 'Cadastro',
    email: 'teste@example.com',
    telefone: '(11) 99999-9999',
    cidadeDeResidencia: 'São Paulo',
    usuario: 'teste',
    estado: 'SP',
    larDeAdocao: true,
    endereco: 'Rua de teste',
  );

  test('envia os dados por POST e usa o ID gerado pelo banco', () async {
    final api = ClienteApi(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/entrepatas-api/cadastrar_cliente.php');
        final dados = jsonDecode(request.body) as Map<String, dynamic>;
        expect(dados['senha'], 'SenhaTeste!1');
        expect(dados['telefone'], '11999999999');
        expect(dados['cidadeDeResidencia'], 'São Paulo');
        expect(dados['larDeAdocao'], true);
        expect(dados.containsKey('id'), false);
        return http.Response('{"id":42}', 201);
      }),
    );
    addTearDown(api.close);
    expect(await api.cadastrar(cliente, 'SenhaTeste!1'), 42);
  });

  test('exibe o erro de duplicidade retornado pelo PHP', () async {
    final api = ClienteApi(
      client: MockClient((_) async {
        return http.Response('{"erro":"Cadastro duplicado"}', 409);
      }),
    );
    addTearDown(api.close);
    await expectLater(
      api.cadastrar(cliente, 'SenhaTeste!1'),
      throwsA(
        isA<CadastroException>().having(
          (erro) => erro.mensagem,
          'mensagem',
          'Cadastro duplicado',
        ),
      ),
    );
  });

  test('não aceita HTML ou sucesso sem ID válido', () async {
    for (final body in ['<html>Erro PHP</html>', '{"id":0}']) {
      final api = ClienteApi(
        client: MockClient((_) async {
          return http.Response(body, 201);
        }),
      );
      addTearDown(api.close);
      await expectLater(
        api.cadastrar(cliente, 'SenhaTeste!1'),
        throwsA(isA<CadastroException>()),
      );
    }
  });
}
