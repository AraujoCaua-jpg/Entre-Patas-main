import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../model/cliente.dart';
import 'cliente_api.dart';
import 'auth_api.dart';

class ClientesApi {
  ClientesApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<Map<String, dynamic>> requisicao(
    String rota, {
    String? token,
    Map<String, dynamic>? dados,
  }) async {
    try {
      final uri = Uri.parse('${ClienteApi.baseUrl}/$rota');
      final headers = {
        'Content-Type': 'application/json; charset=utf-8',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final response =
          await (dados == null
                  ? _client.get(uri, headers: headers)
                  : _client.post(
                      uri,
                      headers: headers,
                      body: jsonEncode(dados),
                    ))
              .timeout(const Duration(seconds: 15));
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is! Map<String, dynamic>) throw const FormatException();
      if (response.statusCode != 200)
        throw LoginException(
          json['erro'] as String? ?? 'Não foi possível concluir.',
        );
      return json;
    } on TimeoutException {
      throw const LoginException('O servidor demorou para responder.');
    } on http.ClientException {
      throw const LoginException('Confira a conexão com o Apache e o MySQL.');
    } on FormatException {
      throw const LoginException('Resposta inválida do servidor.');
    }
  }

  Future<Cliente> perfil(String token) async => Cliente.fromJson(
    (await requisicao('clientes.php', token: token))['cliente']
        as Map<String, dynamic>,
  );
  Future<Cliente> buscarId(String token, int id, {bool basico = false}) async =>
      Cliente.fromJson(
        (await requisicao(
              'clientes.php?acao=${basico ? 'basico' : 'id'}&id=$id',
              token: token,
            ))['cliente']
            as Map<String, dynamic>,
      );
  Future<List<Cliente>> pesquisar(String token, String termo) async {
    final json = await requisicao(
      'clientes.php?acao=buscar&q=${Uri.encodeQueryComponent(termo)}',
      token: token,
    );
    return (json['clientes'] as List)
        .map((c) => Cliente.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<Cliente> editar(String token, Cliente c) async => Cliente.fromJson(
    (await requisicao(
          'clientes.php?acao=editar',
          token: token,
          dados: c.toJson(),
        ))['cliente']
        as Map<String, dynamic>,
  );
  Future<void> apagar(String token) async {
    await requisicao('clientes.php?acao=apagar', token: token, dados: {});
  }

  Future<void> alterarSenha(String token, String atual, String nova) async {
    await requisicao(
      'senha.php',
      token: token,
      dados: {'senhaAtual': atual, 'novaSenha': nova},
    );
  }

  Future<String> solicitarRecuperacao(String email) async =>
      (await requisicao(
            'senha.php?acao=solicitar',
            dados: {'email': email.trim()},
          ))['mensagem']
          as String;
  Future<void> recuperar(String codigo, String nova) async {
    await requisicao(
      'senha.php?acao=recuperar',
      dados: {'codigo': codigo.trim(), 'novaSenha': nova},
    );
  }

  void close() => _client.close();
}
