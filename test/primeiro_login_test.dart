import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:entre_patas/controller/cliente_controller.dart';
import 'package:entre_patas/controller/clientes_scope.dart';
import 'package:entre_patas/model/cliente.dart';
import 'package:entre_patas/model/animais.dart';
import 'package:entre_patas/view/autenticacao/login.dart';
import 'package:entre_patas/view/questionario/testeComp.dart';
import 'package:entre_patas/view/navagacao.dart';
import 'package:entre_patas/service/auth_api.dart';

class DadosPrimeiroLogin extends ClienteController {
  DadosPrimeiroLogin({
    required this.concluido,
    this.falhar = false,
    this.novo = true,
  });
  final bool concluido, falhar, novo;
  bool autenticado = false;
  @override
  Future<void> entrar(String email, String senha) async {
    autenticado = true;
  }

  @override
  Future<Map<String, dynamic>?> carregarQuestionario() async {
    if (falhar)
      throw const LoginException('Não foi possível conferir o teste.');
    return concluido ? {'id': 1} : null;
  }

  @override
  Cliente get clienteLogado => Cliente(
    id: 1,
    nome: 'Ana',
    sobrenome: 'Silva',
    email: 'ana@example.com',
    telefone: '11999999999',
    cidadeDeResidencia: 'Mogi',
    usuario: 'ana',
    questionarioPendente: novo,
  );
  @override
  Future<List<Animal>> listarAnimais({
    Map<String, String> filtros = const {},
  }) async => [];
}

void main() {
  testWidgets('conta antiga sem questionário vai direto ao início', (
    tester,
  ) async {
    final dados = DadosPrimeiroLogin(
      concluido: false,
      novo: false,
      falhar: true,
    );
    await tester.pumpWidget(
      ClientesScope(
        controller: dados,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.enterText(find.byType(TextField).at(0), 'ana@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'Senha!123');
    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.byType(NavegacaoScreen), findsOneWidget);
    expect(find.byType(TesteCompScreen), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    dados.dispose();
  });
  for (final concluido in [false, true]) {
    testWidgets(
      concluido
          ? 'login com teste concluído abre início sem botão de teste'
          : 'primeiro login abre teste automaticamente',
      (tester) async {
        final dados = DadosPrimeiroLogin(concluido: concluido);
        await tester.pumpWidget(
          ClientesScope(
            controller: dados,
            child: const MaterialApp(home: LoginScreen()),
          ),
        );
        await tester.enterText(find.byType(TextField).at(0), 'ana@example.com');
        await tester.enterText(find.byType(TextField).at(1), 'Senha!123');
        await tester.ensureVisible(find.text('Entrar'));
        await tester.tap(find.text('Entrar'));
        await tester.pumpAndSettle();
        expect(dados.autenticado, isTrue);
        expect(
          find.byType(TesteCompScreen),
          concluido ? findsNothing : findsOneWidget,
        );
        expect(
          find.byType(NavegacaoScreen),
          concluido ? findsOneWidget : findsNothing,
        );
        if (concluido)
          expect(find.text('Teste de compatibilidade'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        dados.dispose();
      },
    );
  }
  testWidgets('falha ao consultar questionário não ignora primeiro acesso', (
    tester,
  ) async {
    final dados = DadosPrimeiroLogin(concluido: false, falhar: true);
    await tester.pumpWidget(
      ClientesScope(
        controller: dados,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.enterText(find.byType(TextField).at(0), 'ana@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'Senha!123');
    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Não foi possível conferir o teste.'), findsOneWidget);
    expect(find.byType(NavegacaoScreen), findsNothing);
    await tester.pumpWidget(const SizedBox());
    dados.dispose();
  });
}
