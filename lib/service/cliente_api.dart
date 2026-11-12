import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../model/cliente.dart';

class CadastroException implements Exception {
  const CadastroException(this.mensagem);
  final String mensagem;
}

class ClienteApi {
  ClienteApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost/entrepatas-api',
  );

  Future<int> cadastrar(Cliente cliente, String senha) async {
    try {
      final resposta = await _client
          .post(
            Uri.parse('$baseUrl/cadastrar_cliente.php'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({
              'nome': cliente.nome,
              'sobrenome': cliente.sobrenome,
              'email': cliente.email,
              'telefone': cliente.telefone.replaceAll(RegExp(r'\D'), ''),
              'senha': senha,
              'usuario': cliente.usuario,
              'estado': cliente.estado,
              'cidadeDeResidencia': cliente.cidadeDeResidencia,
              'endereco': cliente.endereco,
              'larDeAdocao': cliente.larDeAdocao,
              'imagem': cliente.imageUrl,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (dados is! Map<String, dynamic>) {
        throw const FormatException();
      }
      if (resposta.statusCode != 201) {
        throw CadastroException(
          dados['erro'] is String
              ? dados['erro'] as String
              : 'Não foi possível cadastrar. Tente novamente.',
        );
      }
      final id = dados['id'];
      if (id is! int || id <= 0) throw const FormatException();
      return id;
    } on TimeoutException {
      throw const CadastroException(
        'O servidor demorou para responder. Confira no banco se o cadastro foi salvo antes de tentar novamente.',
      );
    } on http.ClientException {
      throw const CadastroException(
        'Não foi possível acessar a API. Confira se Apache e MySQL estão ligados.',
      );
    } on FormatException {
      throw const CadastroException(
        'Resposta inválida da API. Confira o arquivo cadastrar_cliente.php.',
      );
    }
  }

  void close() => _client.close();
}
