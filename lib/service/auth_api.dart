import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../model/cliente.dart';
import 'cliente_api.dart';

class LoginException implements Exception {
  const LoginException(this.mensagem);
  final String mensagem;
}

class SessaoAutenticada {
  const SessaoAutenticada(this.cliente, this.token);
  final Cliente cliente;
  final String token;
}

class AuthApi {
  AuthApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<SessaoAutenticada> entrar(String email, String senha) async {
    final dados = await _post('login.php', {
      'email': email.trim(),
      'senha': senha,
    });
    try {
      final token = dados['token'];
      final c = dados['cliente'];
      if (token is! String ||
          token.isEmpty ||
          c is! Map<String, dynamic> ||
          c['id'] is! int ||
          (c['id'] as int) <= 0) {
        throw const FormatException();
      }
      return SessaoAutenticada(
        Cliente(
          id: c['id'] as int,
          nome: c['nome'] as String,
          sobrenome: c['sobrenome'] as String,
          email: c['email'] as String,
          telefone: c['telefone'] as String,
          usuario: c['usuario'] as String,
          cidadeDeResidencia: c['cidadeDeResidencia'] as String? ?? '',
          estado: c['estado'] as String?,
          endereco: c['endereco'] as String?,
          imageUrl: c['imagem'] as String?,
          larDeAdocao: c['larDeAdocao'] == true || c['larDeAdocao'] == 1,
          questionarioPendente:
              c['questionario_pendente'] == true ||
              c['questionario_pendente'] == 1,
        ),
        token,
      );
    } catch (_) {
      throw const LoginException(
        'Resposta de login inválida. Confira a API PHP.',
      );
    }
  }

  Future<void> sair(String token) async {
    await _post('logout.php', {}, token: token);
  }

  Future<Map<String, dynamic>> _post(
    String rota,
    Map<String, dynamic> corpo, {
    String? token,
  }) async {
    try {
      final resposta = await _client
          .post(
            Uri.parse('${ClienteApi.baseUrl}/$rota'),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(corpo),
          )
          .timeout(const Duration(seconds: 15));
      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (dados is! Map<String, dynamic>) throw const FormatException();
      if (resposta.statusCode != 200) {
        throw LoginException(
          dados['erro'] is String
              ? dados['erro'] as String
              : 'Não foi possível concluir. Tente novamente.',
        );
      }
      return dados;
    } on TimeoutException {
      throw const LoginException(
        'O servidor demorou para responder. Tente novamente.',
      );
    } on http.ClientException {
      throw const LoginException(
        'Não foi possível acessar a API. Confira o Apache e o MySQL.',
      );
    } on FormatException {
      throw const LoginException(
        'Resposta inválida da API. Confira os arquivos PHP.',
      );
    }
  }

  void close() => _client.close();
}
