import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:entre_patas/controller/cliente_controller.dart';
import 'package:entre_patas/controller/clientes_scope.dart';
import 'package:entre_patas/model/cliente.dart';
import 'package:entre_patas/model/animais.dart';
import 'package:entre_patas/model/adocao.dart';
import 'package:entre_patas/service/auth_api.dart';
import 'package:entre_patas/view/principal/perfil.dart';
import 'package:entre_patas/view/principal/home.dart';
import 'package:entre_patas/view/principal/notificacoes.dart';

class DadosPerfil extends ClienteController {
  @override
  Future<Map<String, dynamic>?> carregarQuestionario() async => null;
  int consultas = 0, consultasNotificacoes = 0;
  bool falhar = false;

  void simularAlteracaoDeAnimal() => notifyListeners();
  @override
  Cliente get clienteLogado => Cliente(
    id: 1,
    nome: 'Ana',
    sobrenome: 'Silva',
    email: 'ana@example.com',
    telefone: '11999999999',
    cidadeDeResidencia: 'Mogi',
    usuario: 'ana',
  );
  @override
  Future<List<Animal>> listarAnimaisDoClienteSupabase(int clienteId) async {
    consultas++;
    if (falhar) throw const LoginException('Falha temporária');
    return [];
  }

  @override
  Future<Map<String, dynamic>?> buscarMeuQuestionarioSupabase() async =>
      {'id_cliente': 1};

  @override
  Future<List<Animal>> listarAnimaisSupabase({
    String? tipo,
    Map<String, String> filtros = const {},
    int? pagina,
    bool somenteMeus = false,
  }) async {
    consultas++;
    if (falhar) throw const LoginException('Falha temporária');
    return [];
  }

  @override
  Future<List<Adocao>> atualizarNotificacoes() async {
    consultasNotificacoes++;
    return [];
  }
}

void main() {
  testWidgets('perfil recarrega após alteração de animal em outra tela', (
    tester,
  ) async {
    final dados = DadosPerfil();
    await tester.pumpWidget(
      ClientesScope(
        controller: dados,
        child: const MaterialApp(home: PerfilScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(dados.consultas, 1);

    dados.falhar = true;
    dados.simularAlteracaoDeAnimal();
    await tester.pumpAndSettle();
    expect(dados.consultas, 2);
    expect(find.text('Falha temporária'), findsOneWidget);

    dados.falhar = false;
    dados.simularAlteracaoDeAnimal();
    await tester.pumpAndSettle();
    expect(dados.consultas, 3);
    expect(find.text('Nenhum Animal Cadastrado'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    dados.dispose();
  });

  testWidgets('perfil abre e recarrega após voltar de animais publicados', (
    tester,
  ) async {
    final dados = DadosPerfil();
    await tester.pumpWidget(
      ClientesScope(
        controller: dados,
        child: const MaterialApp(home: PerfilScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ana Silva'), findsOneWidget);
    expect(dados.consultas, 1);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Ver Todos'));
    await tester.tap(find.text('Ver Todos'));
    await tester.pumpAndSettle();
    expect(find.text('Animais Publicados'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(dados.consultas, 3);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    dados.dispose();
  });
  testWidgets(
    'início permite tentar carregar novamente sem Future em setState',
    (tester) async {
      final dados = DadosPerfil()..falhar = true;
      await tester.pumpWidget(
        ClientesScope(
          controller: dados,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      dados.falhar = false;
      await tester.ensureVisible(find.text('Tentar novamente'));
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(dados.consultas, 2);
      expect(find.text('Nenhum amiguinho disponível no momento.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      dados.dispose();
    },
  );
  testWidgets('notificações atualizam sem retornar Future de setState', (
    tester,
  ) async {
    final dados = DadosPerfil();
    await tester.pumpWidget(
      ClientesScope(
        controller: dados,
        child: const MaterialApp(home: NotificacoesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Atualizar'));
    await tester.pumpAndSettle();
    expect(dados.consultasNotificacoes, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    dados.dispose();
  });
}
