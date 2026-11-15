import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:entre_patas/controller/cliente_controller.dart';
import 'package:entre_patas/controller/clientes_scope.dart';
import 'package:entre_patas/model/cliente.dart';
import 'package:entre_patas/services/supabase_auth_service.dart';
import 'package:entre_patas/view/usuario/configuracoes.dart';
import 'package:entre_patas/view/autenticacao/bemVindo.dart';

Cliente perfil(int id) => Cliente(
  id: id,
  nome: 'Conta $id',
  sobrenome: '',
  email: '$id@example.com',
  telefone: '',
  cidadeDeResidencia: '',
  usuario: 'conta$id',
);

class ControllerLogoutSimulado extends ClienteController {
  ControllerLogoutSimulado({required super.supabaseAuthService});

  int? _id;

  @override
  Cliente? get clienteLogado => _id == null ? null : buscarCliente(_id!);

  @override
  Future<void> entrar(String email, String senha) async {
    _id = 1;
    cadastrarCliente(perfil(1));
  }

  @override
  void limparSessao() {
    _id = null;
    super.limparSessao();
  }
}

class AuthSupabaseSimulado extends SupabaseAuthService {
  Completer<void> resposta = Completer<void>();
  int chamadas = 0;
  @override
  Future<void> sair() {
    chamadas++;
    return resposta.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (call) async => call.method == 'getAll' ? <String, Object>{} : true,
        );
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-key',
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        autoRefreshToken: false,
      ),
    );
  });
  tearDownAll(() async => Supabase.instance.dispose());

  test('Logout aguarda sucesso, limpa estado e não chama PHP', () async {
    final auth = AuthSupabaseSimulado();
    final controller = ControllerLogoutSimulado(supabaseAuthService: auth);
    await controller.entrar('', '');
    controller.cadastrarCliente(perfil(3));
    var notificacoes = 0;
    controller.addListener(() => notificacoes++);
    final saida = controller.sair();
    final repetida = controller.sair();
    expect(auth.chamadas, 1);
    expect(controller.clienteLogado?.id, 1);
    expect(controller.clientes, hasLength(2));
    expect(notificacoes, 0);
    auth.resposta.complete();
    await Future.wait([saida, repetida]);
    expect(controller.clienteLogado, isNull);
    expect(controller.clientes, isEmpty);
    expect(notificacoes, 1);
    await controller.entrar('', '');
    expect(controller.clienteLogado?.id, 1);
    expect(controller.clientes.map((c) => c.id), [1]);
    controller.dispose();
  });

  test('Falha mantém perfil e permite tentar novamente', () async {
    final auth = AuthSupabaseSimulado();
    final controller = ControllerLogoutSimulado(supabaseAuthService: auth);
    await controller.entrar('', '');
    final saida = controller.sair();
    final verificacao = expectLater(saida, throwsException);
    auth.resposta.completeError(Exception('Sem conexão'));
    await verificacao;
    expect(controller.clienteLogado?.id, 1);
    expect(controller.clientes, hasLength(1));
    auth.resposta = Completer<void>();
    final tentativa = controller.sair();
    auth.resposta.complete();
    await tentativa;
    expect(auth.chamadas, 2);
    expect(controller.clientes, isEmpty);
    controller.dispose();
  });

  testWidgets('Configurações navega somente após sucesso e remove rotas', (
    tester,
  ) async {
    final auth = AuthSupabaseSimulado();
    final controller = ControllerLogoutSimulado(supabaseAuthService: auth);
    await controller.entrar('', '');
    await tester.pumpWidget(
      ClientesScope(
        controller: controller,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ConfiguracoesScreen(),
                  ),
                ),
                child: const Text('Abrir configurações'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir configurações'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sair do Aplicativo'));
    await tester.tap(find.text('Sair do Aplicativo'));
    await tester.pump();
    expect(find.byType(BemVindoScreen), findsNothing);
    expect(controller.clienteLogado?.id, 1);
    auth.resposta.completeError(Exception('Sem conexão'));
    await tester.pumpAndSettle();
    expect(find.byType(ConfiguracoesScreen), findsOneWidget);
    expect(
      find.text('Não foi possível sair. Confira a conexão e tente novamente.'),
      findsOneWidget,
    );
    auth.resposta = Completer<void>();
    await tester.tap(find.text('Sair do Aplicativo'));
    auth.resposta.complete();
    await tester.pumpAndSettle();
    expect(find.byType(BemVindoScreen), findsOneWidget);
    final context = tester.element(find.byType(BemVindoScreen));
    expect(Navigator.of(context).canPop(), isFalse);
    // Exercita o evento Voltar, além de inspecionar a pilha.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(BemVindoScreen), findsOneWidget);
    expect(find.byType(ConfiguracoesScreen), findsNothing);
    expect(controller.clientes, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
