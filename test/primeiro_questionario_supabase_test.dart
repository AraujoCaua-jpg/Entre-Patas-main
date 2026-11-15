import 'dart:convert';

import 'package:entre_patas/controller/cliente_controller.dart';
import 'package:entre_patas/controller/clientes_scope.dart';
import 'package:entre_patas/view/autenticacao/login.dart';
import 'package:entre_patas/view/navagacao.dart';
import 'package:entre_patas/view/questionario/testeComp.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _ServidorPrimeiroAcesso {
  bool cadastroDoApp = true;
  int pendenteNoBanco = 0;
  bool falharConsulta = false;
  Map<String, dynamic>? questionario;
  final chamadas = <http.Request>[];

  Future<http.Response> responder(http.Request request) async {
    chamadas.add(request);
    http.Response json(Object dados, [int status = 200]) => http.Response(
      jsonEncode(dados),
      status,
      headers: {'content-type': 'application/json'},
      request: request,
    );
    switch (request.url.path) {
      case '/auth/v1/token':
        String parte(Object valor) => base64Url
            .encode(utf8.encode(jsonEncode(valor)))
            .replaceAll('=', '');
        return json({
          'access_token':
              '${parte({'alg': 'HS256'})}.'
              '${parte({'sub': '11111111-1111-4111-8111-111111111111', 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600})}.teste',
          'refresh_token': 'refresh-ficticio',
          'token_type': 'bearer',
          'expires_in': 3600,
          'user': {
            'id': '11111111-1111-4111-8111-111111111111',
            'email': 'qa@example.com',
            'aud': 'authenticated',
            'app_metadata': {},
            'user_metadata': cadastroDoApp
                ? {'origem_cadastro': 'entre_patas'}
                : {},
            'created_at': '2026-11-14T00:00:00Z',
          },
        });
      case '/rest/v1/cliente':
        return json([
          {
            'id': 1,
            'ativo': true,
            'nome': 'Conta QA',
            'usuario': 'qa',
            'email': 'qa@example.com',
            'questionario_pendente': pendenteNoBanco,
          },
        ]);
      case '/rest/v1/questionario':
        if (request.method == 'POST') {
          questionario = {
            'id': questionario?['id'] ?? 9,
            ...Map<String, dynamic>.from(jsonDecode(request.body) as Map),
          };
          return json({});
        }
        if (falharConsulta) {
          return json({
            'code': '42501',
            'message': 'Sem permissão simulada',
          }, 403);
        }
        return json(questionario == null ? [] : [questionario]);
      case '/rest/v1/animal':
        return json([]);
      default:
        fail('Rota inesperada no teste de primeiro acesso');
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _ServidorPrimeiroAcesso servidor;
  late ClienteController controller;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (call) async => call.method == 'getAll' ? <String, Object>{} : true,
        );
    servidor = _ServidorPrimeiroAcesso();
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-key',
      httpClient: MockClient(servidor.responder),
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
    );
    controller = ClienteController();
  });
  tearDown(() async {
    controller.dispose();
    await Supabase.instance.dispose();
  });

  Future<void> loginNaTela(WidgetTester tester) async {
    await tester.pumpWidget(
      ClientesScope(
        controller: controller,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.enterText(find.byType(TextField).at(0), 'qa@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'SenhaTeste!123');
    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
  }

  testWidgets('Cadastro do app com default 0 exige primeiro questionário', (
    tester,
  ) async {
    await loginNaTela(tester);
    expect(controller.clienteLogado!.questionarioPendente, isTrue);
    expect(find.byType(TesteCompScreen), findsOneWidget);
    expect(find.byType(NavegacaoScreen), findsNothing);
    expect(servidor.pendenteNoBanco, 0);
    expect(servidor.chamadas.where((r) => r.method == 'PATCH'), isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Respostas existentes têm precedência sem reiniciar progresso', (
    tester,
  ) async {
    servidor.questionario = {'id': 9, 'id_cliente': 1, 'dedicacao': 2};
    final original = Map<String, dynamic>.from(servidor.questionario!);
    await loginNaTela(tester);
    expect(find.byType(NavegacaoScreen), findsOneWidget);
    expect(find.byType(TesteCompScreen), findsNothing);
    expect(controller.clienteLogado!.questionarioPendente, isFalse);
    expect(servidor.questionario, original);
    expect(
      servidor.chamadas.where(
        (r) => r.url.path == '/rest/v1/questionario' && r.method != 'GET',
      ),
      isEmpty,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Conta legada sem marcador e sem pendência mantém navegação', (
    tester,
  ) async {
    servidor.cadastroDoApp = false;
    await loginNaTela(tester);
    expect(controller.clienteLogado!.questionarioPendente, isFalse);
    expect(find.byType(NavegacaoScreen), findsOneWidget);
    expect(find.byType(TesteCompScreen), findsNothing);
    expect(servidor.chamadas.where((r) => r.method == 'PATCH'), isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Pendência explícita de conta legada continua respeitada', (
    tester,
  ) async {
    servidor.cadastroDoApp = false;
    servidor.pendenteNoBanco = 1;
    await loginNaTela(tester);
    expect(find.byType(TesteCompScreen), findsOneWidget);
    expect(find.byType(NavegacaoScreen), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Erro de consulta não libera o primeiro acesso', (tester) async {
    servidor.falharConsulta = true;
    await loginNaTela(tester);
    expect(controller.clienteLogado!.questionarioPendente, isTrue);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(NavegacaoScreen), findsNothing);
    expect(find.byType(TesteCompScreen), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  test(
    'Salvar conclui pendência apenas na memória, preservando questionário',
    () async {
      await controller.entrar('qa@example.com', 'SenhaTeste!123');
      expect(controller.clienteLogado!.questionarioPendente, isTrue);
      await controller.salvarQuestionario({'dedicacao': 2});
      expect(controller.clienteLogado!.questionarioPendente, isFalse);
      final id = servidor.questionario!['id'];
      await controller.salvarQuestionario({'dedicacao': 3});
      expect(servidor.questionario!['id'], id);
      expect(servidor.questionario!['dedicacao'], 3);
      expect(servidor.pendenteNoBanco, 0);
      expect(servidor.chamadas.where((r) => r.method == 'PATCH'), isEmpty);
      await controller.carregarMeuPerfilSupabase();
      expect(controller.clienteLogado!.questionarioPendente, isTrue);
      final respostas = await controller.carregarQuestionario();
      expect(respostas!['id'], id);
      expect(controller.clienteLogado!.questionarioPendente, isFalse);
    },
  );
}
