import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:entre_patas/controller/cliente_controller.dart';
import 'package:entre_patas/controller/clientes_scope.dart';
import 'package:entre_patas/model/animais.dart';
import 'package:entre_patas/view/animal/animaisCadastrados.dart';
import 'package:entre_patas/view/animal/cadastroAnimal.dart';

class DadosAnimais extends ClienteController {
  final filtros = <Map<String, String>>[];
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
    idCliente: 1,
    cidade: 'Mogi',
    estado: 'SP',
  );
  @override
  Future<List<Animal>> listarAnimais({
    Map<String, String> filtros = const {},
  }) async {
    this.filtros.add(filtros);
    return [animal];
  }

  @override
  Future<Animal> buscarAnimalRemoto(int id) async => animal;
}

void main() {
  testWidgets('lista consulta dados e permite abrir filtros em tela pequena', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 420);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dados = DadosAnimais();
    await tester.pumpWidget(
      ClientesScope(
        controller: dados,
        child: const MaterialApp(home: Scaffold(body: ListaAnimais())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lua'), findsOneWidget);
    expect(dados.filtros, hasLength(1));
    await tester.tap(find.text('Região e preferências'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    dados.dispose();
  });

  testWidgets('edição carrega os campos do animal pelo ID', (tester) async {
    final dados = DadosAnimais();
    await tester.pumpWidget(
      ClientesScope(
        controller: dados,
        child: const MaterialApp(home: CadastroAnimalScreen(animalId: 8)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Editar Animal'), findsOneWidget);
    final campos = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(campos.first.controller!.text, 'Lua');
    expect(campos[1].controller!.text, '2');
    expect(find.byType(Slider), findsNWidgets(2));
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    dados.dispose();
  });
  testWidgets(
    'gerenciamento mantém cartões e botão flutuante do layout original',
    (tester) async {
      final dados = DadosAnimais();
      await tester.pumpWidget(
        ClientesScope(
          controller: dados,
          child: const MaterialApp(home: AnimaisCadastradosScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Lua'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.edit_note_rounded), findsOneWidget);
      expect(find.text('Região e preferências'), findsNothing);
      await tester.tap(find.byIcon(Icons.edit_note_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Editar Animal'), findsOneWidget);
      expect(find.byType(Slider), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      dados.dispose();
    },
  );
}
