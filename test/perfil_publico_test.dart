import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:entre_patas/controller/cliente_controller.dart';
import 'package:entre_patas/controller/clientes_scope.dart';
import 'package:entre_patas/model/animais.dart';
import 'package:entre_patas/view/usuario/ficha_perfil.dart';
import 'package:entre_patas/view/animal/ficha_animal.dart';

class PerfilPublicoDados extends ClienteController {
  PerfilPublicoDados({this.lar = true, this.vazio = false});
  final bool lar, vazio;
  int? clienteConsultado;
  int? paginaConsultada;
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
  Future<Map<String, dynamic>> buscarPerfilPublicoSupabase(int id) async => {
    'id': id,
    'nome': 'Juliana',
    'sobrenome': 'Dias',
    'usuario': 'juli_dias',
    'cidade': 'Mogi das Cruzes',
    'estado': 'SP',
    'lar_de_adocao': lar,
  };

  @override
  Future<List<Animal>> listarAnimaisDisponiveisDoClienteSupabase(
    int clienteId, {
    int pagina = 1,
  }) async {
    clienteConsultado = clienteId;
    paginaConsultada = pagina;
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
      expect(dados.clienteConsultado, 7);
      expect(dados.paginaConsultada, 1);
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
