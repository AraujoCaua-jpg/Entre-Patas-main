import 'dart:convert';

import 'package:entre_patas/controller/cliente_controller.dart';
import 'package:entre_patas/controller/clientes_scope.dart';
import 'package:entre_patas/view/autenticacao/bemVindo.dart';
import 'package:entre_patas/view/autenticacao/esqueciSenha.dart';
import 'package:entre_patas/view/core/recuperacao_senha_navigation.dart';
import 'package:entre_patas/view/usuario/alterarSenha.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _idA = '11111111-1111-4111-8111-111111111111';
const _idB = '22222222-2222-4222-8222-222222222222';

String _token(String id) {
  String encode(Object data) =>
      base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');
  return '${encode({'alg': 'HS256'})}.'
      '${encode({'sub': id, 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600})}.test';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ClienteController controller;
  late List<http.Request> requisicoes;
  RecuperacaoSenhaNavigation? navigation;
  var usuarioAtual = _idA;

  Map<String, dynamic> usuario() => {
    'id': usuarioAtual,
    'email': usuarioAtual == _idA ? 'a@example.com' : 'b@example.com',
    'aud': 'authenticated',
    'app_metadata': {},
    'user_metadata': {},
    'created_at': '2026-01-01T00:00:00Z',
  };
  Map<String, dynamic> sessao() => {
    'access_token': _token(usuarioAtual),
    'refresh_token': 'refresh-test',
    'token_type': 'bearer',
    'expires_in': 3600,
    'user': usuario(),
  };

  setUp(() async {
    usuarioAtual = _idA;
    navigation = null;
    requisicoes = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (call) async => call.method == 'getAll' ? <String, Object>{} : true,
        );
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-key',
      httpClient: MockClient((request) async {
        requisicoes.add(request);
        Object resposta;
        switch (request.url.path) {
          case '/auth/v1/recover':
            resposta = {};
          case '/auth/v1/token':
            resposta = sessao();
          case '/auth/v1/verify':
            expect(jsonDecode(request.body)['type'], 'recovery');
            usuarioAtual = _idB;
            resposta = sessao();
          case '/auth/v1/user':
            resposta = usuario();
          case '/rest/v1/cliente':
            resposta = [
              {'id': 1, 'ativo': true, 'nome': 'Conta A', 'usuario': 'contaA'},
            ];
          default:
            fail('Rota inesperada: ${request.url.path}');
        }
        return http.Response(
          jsonEncode(resposta),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
    );
    controller = ClienteController();
  });
  tearDown(() async {
    navigation?.dispose();
    controller.dispose();
    await Supabase.instance.dispose();
  });

  Future<void> abrirLink() async {
    usuarioAtual = _idB;
    await Supabase.instance.client.auth.getSessionFromUrl(
      Uri.parse(
        'entrepatas://auth-callback#access_token=${_token(_idB)}'
        '&refresh_token=refresh-test&expires_in=3600&token_type=bearer&type=recovery',
      ),
    );
  }

  Widget app(Widget home) => ClientesScope(
    controller: controller,
    child: MaterialApp(
      navigatorKey: navigation?.navigatorKey,
      navigatorObservers: navigation == null ? [] : [navigation!],
      builder: (context, child) {
        navigation?.navigatorConstruido();
        return child!;
      },
      home: home,
    ),
  );

  testWidgets(
    'Solicitação neutra envia recovery Supabase e conserva formulário',
    (tester) async {
      await tester.pumpWidget(app(const EsqueciSenhaScreen()));
      await tester.enterText(find.byType(TextField), 'b@example.com');
      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
        // O SDK grava o verifier PKCE por meio do plugin assíncrono.
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pumpAndSettle();
      expect(find.byType(AlterarSenhaScreen), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(3));
      expect(
        find.textContaining('Se o e-mail estiver cadastrado'),
        findsOneWidget,
      );
      final recovery = requisicoes.single;
      expect(recovery.url.path, '/auth/v1/recover');
      expect(
        recovery.url.queryParameters['redirect_to'],
        'entrepatas://auth-callback',
      );
      expect(requisicoes.any((r) => r.url.path.endsWith('.php')), isFalse);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Evento recovery anterior ao listener abre tela com link confirmado',
    (tester) async {
      await tester.runAsync(abrirLink);
      navigation = RecuperacaoSenhaNavigation();
      await tester.pumpWidget(app(const BemVindoScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(AlterarSenhaScreen), findsOneWidget);
      final campo = tester.widget<TextField>(find.byType(TextField).first);
      expect(campo.readOnly, isTrue);
      expect(campo.controller!.text, 'Confirmado pelo link');
      expect(controller.clientes, isEmpty);
      expect(
        Navigator.of(tester.element(find.byType(AlterarSenhaScreen))).canPop(),
        isFalse,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Link expirado no coldstart informa erro sem abrir redefinição', (
    tester,
  ) async {
    await tester.runAsync(() async {
      try {
        await Supabase.instance.client.auth.getSessionFromUrl(
          Uri.parse(
            'entrepatas://auth-callback#error=access_denied'
            '&error_code=otp_expired&error_description=Link%20expirado',
          ),
        );
        fail('O SDK deve rejeitar o link expirado.');
      } on AuthException catch (erro) {
        // Reproduz a publicação feita por SupabaseAuth._handleDeeplink.
        // ignore: invalid_use_of_internal_member
        Supabase.instance.client.auth.notifyException(erro);
      }
    });
    navigation = RecuperacaoSenhaNavigation();
    await tester.pumpWidget(app(const BemVindoScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(BemVindoScreen), findsOneWidget);
    expect(find.byType(AlterarSenhaScreen), findsNothing);
    expect(
      find.textContaining('Solicite um novo link e tente novamente.'),
      findsOneWidget,
    );
    expect(Supabase.instance.client.auth.currentSession, isNull);
    expect(controller.clienteLogado, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Link na tela de código limpa conta anterior sem duplicar tela', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await Supabase.instance.client.auth.signInWithPassword(
        email: 'a@example.com',
        password: 'senha-test',
      );
      await controller.carregarMeuPerfilSupabase();
    });
    navigation = RecuperacaoSenhaNavigation();
    await tester.pumpWidget(app(const BemVindoScreen()));
    await tester.pumpAndSettle();
    navigation!.navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/recuperar-senha'),
        builder: (_) => const AlterarSenhaScreen(
          recuperacao: true,
          emailRecuperacao: 'b@example.com',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.clienteLogado?.id, 1);
    await tester.runAsync(abrirLink);
    await tester.pumpAndSettle();
    expect(controller.clienteLogado, isNull);
    expect(controller.clientes, isEmpty);
    expect(find.byType(AlterarSenhaScreen), findsOneWidget);
    final campo = tester.widget<TextField>(find.byType(TextField).first);
    expect(campo.readOnly, isTrue);
    expect(campo.controller!.text, 'Confirmado pelo link');
    expect(Supabase.instance.client.auth.currentUser?.id, _idB);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
