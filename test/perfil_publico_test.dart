import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:entre_patas/controller/cliente_controller.dart';
import 'package:entre_patas/controller/clientes_scope.dart';
import 'package:entre_patas/model/cliente.dart';
import 'package:entre_patas/model/animais.dart';
import 'package:entre_patas/view/usuario/fichaPerfil.dart';
import 'package:entre_patas/view/animal/fichaAnimal.dart';

class PerfilPublicoDados extends ClienteController {
  PerfilPublicoDados({this.lar = true, this.vazio = false});
  final bool lar, vazio;
  Map<String, String>? filtrosRecebidos;
  final animal = Animal(
    id: 8,
    nome: 'Lua',
    idade: 2,
    tipo: 'Gato',
    energia: 'Médio',
    porte: 'Pequeno',
    convivencia: 'Sim',
    carencia: 'Não',
    descricao: 'Carinhosa',
    sexo: 'Fêmea',
    status: 'Disponível',
    idCliente: 7,
  );
  @override
  Future<Cliente> buscarClienteRemoto(int id, {bool basico = false}) async =>
      Cliente(
        id: id,
        nome: 'Juliana',
        sobrenome: 'Dias',
        email: lar ? 'juliana@example.com' : '',
        telefone: lar ? '11912345678' : '',
        cidadeDeResidencia: 'Mogi das Cruzes',
        usuario: 'juli_dias',
        larDeAdocao: lar,
        endereco: lar ? 'Rua Coronel, 67 - Jardim Solaris' : null,
      );
  @override
  Future<List<Animal>> listarAnimais({
    Map<String, String> filtros = const {},
  }) async {
    filtrosRecebidos = filtros;
    return vazio ? [] : [animal];
  }

  @override
  Future<Animal> buscarAnimalRemoto(int id) async => animal;
}

void main() {
  for (final tamanho in [
    const Size(250, 550),
    const Size(390, 844),
    const Size(730, 700),
  ]) {
    testWidgets('perfil público segue layout e filtra animais em $tamanho', (
      tester,
    ) async {
      tester.view.physicalSize = tamanho;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final dados = PerfilPublicoDados();
      await tester.pumpWidget(
        ClientesScope(
          controller: dados,
          child: const MaterialApp(home: FichaPerfilScreen(clienteId: 7)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Perfil ‘@juli_dias’'), findsOneWidget);
      expect(find.text('Juliana Dias'), findsOneWidget);
      expect(find.text('Lar de Adoção'), findsOneWidget);
      expect(dados.filtrosRecebidos, {
        'id_cliente': '7',
        'status': 'Disponível',
        'pagina': '1',
      });
      await tester.scrollUntilVisible(
        find.text('Lua'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Lua'));
      await tester.pumpAndSettle();
      expect(find.byType(FichaAnimalScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      dados.dispose();
    });
  }
  testWidgets('perfil comum sem animais não mostra contatos de lar', (
    tester,
  ) async {
    final dados = PerfilPublicoDados(lar: false, vazio: true);
    await tester.pumpWidget(
      ClientesScope(
        controller: dados,
        child: const MaterialApp(home: FichaPerfilScreen(clienteId: 7)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lar de Adoção'), findsNothing);
    expect(find.text('Nenhum animal disponível no momento.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    dados.dispose();
  });
}
