import 'dart:convert';

import 'package:entre_patas/service/auth_api.dart';
import 'package:entre_patas/services/supabase_auth_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _usuarioId = '11111111-1111-4111-8111-111111111111';

class _ServidorExclusao {
  final requisicoes = <http.Request>[];
  bool senhaCorreta = true;
  bool falhaFuncao = false;
  String email = 'ana@example.com';
  String? tokenAtual;
  String? authorizationFuncao;
  Map? corpoFuncao;

  String _segmento(Map<String, dynamic> dados) =>
      base64Url.encode(utf8.encode(jsonEncode(dados))).replaceAll('=', '');

  String get _token {
    final agora = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return '${_segmento({'alg': 'HS256', 'typ': 'JWT'})}.'
        '${_segmento({'sub': _usuarioId, 'aud': 'authenticated', 'role': 'authenticated', 'auth_time': agora, 'exp': agora + 3600})}.simulado';
  }

  http.Response _json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  Future<http.Response> responder(http.Request request) async {
    requisicoes.add(request);
    if (request.url.path == '/auth/v1/token') {
      final dados = jsonDecode(request.body) as Map<String, dynamic>;
      if (!senhaCorreta || dados['password'] != 'SenhaAtual123!') {
        return _json({
          'error_code': 'invalid_credentials',
          'msg': 'Invalid login credentials',
        }, 400);
      }
      email = dados['email'] as String;
      tokenAtual = _token;
      return _json({
        'access_token': tokenAtual,
        'token_type': 'bearer',
        'expires_in': 3600,
        'refresh_token': 'refresh-simulado',
        'user': {
          'id': _usuarioId,
          'aud': 'authenticated',
          'email': email,
          'app_metadata': {'provider': 'email'},
          'user_metadata': <String, Object>{},
          'created_at': '2026-01-01T00:00:00Z',
        },
      });
    }
    if (request.url.path == '/functions/v1/excluir-conta') {
      if (falhaFuncao) return _json({'error': 'server_not_configured'}, 503);
      authorizationFuncao = request.headers['authorization'];
      if (request.body.isNotEmpty) {
        final body = jsonDecode(request.body);
        if (body is Map) {
          corpoFuncao = body;
        }
      }
      return _json({'deleted': true, 'storageCleanupPending': false});
    }
    fail('Requisição inesperada: ${request.method} ${request.url}');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _ServidorExclusao servidor;
  late SupabaseAuthService auth;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (call) async => call.method == 'getAll' ? <String, Object>{} : true,
        );
    servidor = _ServidorExclusao();
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
  });

  tearDown(() async {
    await Supabase.instance.dispose();
  });

  test('reautentica e solicita exclusão sem enviar ID de usuário', () async {
    await auth.entrar('ana@example.com', 'SenhaAtual123!');
    final limpezaPendente = await auth.apagarConta('SenhaAtual123!');

    expect(limpezaPendente, isFalse);
    expect(Supabase.instance.client.auth.currentUser, isNull);
    expect(
      servidor.requisicoes.where(
        (r) => r.url.path == '/functions/v1/excluir-conta',
      ),
      hasLength(1),
    );
    expect(servidor.authorizationFuncao, 'Bearer ${servidor.tokenAtual}');
    expect(servidor.corpoFuncao?['userId'], isNull);
    expect(servidor.corpoFuncao?['auth_user_id'], isNull);
  });

  test(
    'senha incorreta não chama a Edge Function nem encerra a sessão',
    () async {
      await auth.entrar('ana@example.com', 'SenhaAtual123!');
      servidor.senhaCorreta = false;

      await expectLater(
        auth.apagarConta('incorreta'),
        throwsA(isA<LoginException>()),
      );

      expect(
        servidor.requisicoes.any(
          (r) => r.url.path == '/functions/v1/excluir-conta',
        ),
        isFalse,
      );
      expect(Supabase.instance.client.auth.currentUser?.id, _usuarioId);
    },
  );

  test('falha no servidor mantém a sessão local ativa', () async {
    await auth.entrar('ana@example.com', 'SenhaAtual123!');
    servidor.falhaFuncao = true;

    await expectLater(
      auth.apagarConta('SenhaAtual123!'),
      throwsA(isA<LoginException>()),
    );

    expect(Supabase.instance.client.auth.currentUser?.id, _usuarioId);
    expect(Supabase.instance.client.auth.currentSession, isNotNull);
  });
}
