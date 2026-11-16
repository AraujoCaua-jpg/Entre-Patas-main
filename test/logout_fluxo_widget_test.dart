import 'package:entre_patas/controller/cliente_controller.dart';
import 'package:entre_patas/controller/clientes_scope.dart';
import 'package:entre_patas/view/autenticacao/bem_vindo.dart';
import 'package:entre_patas/view/autenticacao/login.dart';
import 'package:entre_patas/view/navagacao.dart';
import 'package:entre_patas/view/principal/home.dart';
import 'package:entre_patas/view/principal/perfil.dart';
import 'package:entre_patas/view/usuario/configuracoes.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/logout_supabase_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ClienteController controller;
  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (call) async => call.method == 'getAll' ? <String, Object>{} : true,
        );
    final servidor = ServidorAuthSimulado();
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-key',
      httpClient: MockClient(servidor.responder),
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        autoRefreshToken: false,
      ),
    );
    controller = ClienteController();
  });
  tearDown(() async {
    controller.dispose();
    await Supabase.instance.dispose();
  });

  testWidgets('Telas reais: login A, logout, Voltar e login B sem dados de A', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ClientesScope(
        controller: controller,
        child: const MaterialApp(home: BemVindoScreen()),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> login(String email) async {
      await tester.tap(find.text('Fazer Login'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(0), email);
      await tester.enterText(find.byType(TextField).at(1), 'senha-simulada');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
      await tester.pumpAndSettle();
      expect(find.byType(NavegacaoScreen), findsOneWidget);
    }

    Finder petNaHome(String nome) =>
        find.descendant(of: find.byType(HomeScreen), matching: find.text(nome));
    Finder petNoPerfil(String nome) => find.descendant(
      of: find.byType(PerfilScreen),
      matching: find.text(nome),
    );

    await login('a@example.com');
    expect(controller.clienteLogado?.id, 1);
    expect(Supabase.instance.client.auth.currentUser?.id, idContaA);
    expect(petNaHome('Animal 2'), findsOneWidget);
    expect(petNaHome('Animal 1'), findsNothing);
    await tester.tap(find.text('Perfil').last);
    await tester.pumpAndSettle();
    expect(find.text('@conta1'), findsOneWidget);
    expect(petNoPerfil('Animal 1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sair do Aplicativo'));
    // A remoção do armazenamento do SDK usa operações assíncronas de plugin.
    await tester.runAsync(() async {
      await tester.tap(find.text('Sair do Aplicativo'));
      await controller.sair();
    });
    await tester.pumpAndSettle();
    expect(find.byType(BemVindoScreen), findsOneWidget);
    expect(controller.clienteLogado, isNull);
    expect(controller.clientes, isEmpty);
    expect(Supabase.instance.client.auth.currentSession, isNull);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(BemVindoScreen), findsOneWidget);
    expect(find.byType(ConfiguracoesScreen), findsNothing);
    expect(find.byType(NavegacaoScreen), findsNothing);

    await login('b@example.com');
    expect(controller.clienteLogado?.id, 2);
    expect(Supabase.instance.client.auth.currentUser?.id, idContaB);
    expect(controller.clientes.map((c) => c.id), [2]);
    expect(petNaHome('Animal 1'), findsOneWidget);
    expect(petNaHome('Animal 2'), findsNothing);
    await tester.tap(find.text('Perfil').last);
    await tester.pumpAndSettle();
    expect(find.text('@conta2'), findsOneWidget);
    expect(find.text('@conta1'), findsNothing);
    expect(petNoPerfil('Animal 2'), findsOneWidget);
    expect(petNoPerfil('Animal 1'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
