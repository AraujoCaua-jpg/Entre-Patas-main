import 'package:material_ui/material_ui.dart';

import 'support/radio_test_helpers.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:entre_patas/controller/cliente_controller.dart';
import 'package:entre_patas/controller/clientes_scope.dart';
import 'package:entre_patas/model/animais.dart';
import 'package:entre_patas/model/cliente.dart';
import 'package:entre_patas/view/animal/ficha_animal.dart';
import 'package:entre_patas/view/animal/compatibilidade_animal.dart';
import 'package:entre_patas/view/core/usuario_resumo.dart';
import 'package:entre_patas/view/animal/animais_cadastrados.dart';
import 'package:entre_patas/view/animal/cadastro_animal.dart';

class DadosAnimais extends ClienteController {
  Animal? salvo;
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
    vacinado: 'Sim',
    castrado: 'Não',
  );
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
    filtros.add({'id_cliente': '$clienteId'});
    return [animal];
  }

  @override
  Future<List<Animal>> listarAnimaisSupabase({
    String? tipo,
    Map<String, String> filtros = const {},
    int? pagina,
    bool somenteMeus = false,
  }) async {
    this.filtros.add(filtros);
    return [animal];
  }

  @override
  Future<Animal> buscarAnimalPorIdSupabase(int id) async => animal;

  @override
  Future<Animal> buscarMeuAnimalParaEditarSupabase(int id) async => animal;

  @override
  Future<Map<String, dynamic>?> buscarMeuQuestionarioSupabase() async => {
    'id_cliente': 2,
    'tipo': 'Gato',
    'sexo': 'Fêmea',
    'idadeMin': 0,
    'idadeMax': 10,
    'porte': 0,
    'energia': 1,
    'ambiente': 'Apartamento',
    'sozinho': 5,
    'dedicacao': 4,
    'animais': 'Não',
    'imovel': 1,
    'apoio': 1,
    'compromisso': 1,
    'moradores': 1,
    'financeiro': 3,
    'rotina': 1,
  };

  @override
  Future<Animal> salvarAnimal(Animal animal, {bool editar = false}) async {
    salvo = animal;
    return animal;
  }

  @override
  Future<void> editarAnimalSupabase(Animal animal) async {
    salvo = animal;
  }
}

class DadosFicha extends DadosAnimais {
  DadosFicha(this.proprio);
  final bool proprio;
  @override
  Cliente get clienteLogado => Cliente(
    id: proprio ? 1 : 2,
    nome: 'Ana',
    sobrenome: 'Silva',
    email: '',
    telefone: '',
    cidadeDeResidencia: 'Mogi',
    usuario: 'ana',
  );
  @override
  Future<Map<String, dynamic>> buscarResumoResponsavelSupabase(
    int clienteId,
  ) async => {'id': clienteId, 'nome': 'Ana', 'usuario': 'ana', 'imagem': null};
}

void main() {
  for (final proprio in [true, false]) {
    testWidgets(
      proprio
          ? 'responsável vê publicado por você sem adoção ou compatibilidade'
          : 'visitante vê adoção e compatibilidade',
      (tester) async {
        final dados = DadosFicha(proprio);
        dados.animal.compatibilidade = {
          'total': 95,
          'rotina': 90,
          'ambiente': 100,
          'preferencias': 100,
        };
        await tester.pumpWidget(
          ClientesScope(
            controller: dados,
            child: const MaterialApp(home: FichaAnimalScreen(animalId: 8)),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Publicado por você'),
          proprio ? findsOneWidget : findsNothing,
        );
        expect(
          find.text('Quero Adotar'),
          proprio ? findsNothing : findsOneWidget,
        );
        expect(
          find.byType(CompatibilidadeAnimal),
          proprio ? findsNothing : findsOneWidget,
        );
        expect(
          find.byType(UsuarioResumo),
          proprio ? findsNothing : findsOneWidget,
        );
        expect(
          find.text('Ver animais deste responsável'),
          proprio ? findsNothing : findsOneWidget,
        );
        if (proprio) {
          expect(find.text('Publicado por: '), findsNothing);
          expect(
            find.ancestor(
              of: find.text('Publicado por você'),
              matching: find.byType(InkWell),
            ),
            findsNothing,
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        dados.dispose();
      },
    );
  }
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
    final saude = tester
        .widgetList<Radio<String>>(find.byType(Radio<String>))
        .toList()
        .sublist(6);
    expect(saude.map((r) => valorGrupoRadio(tester, r)).toList(), [
      'Não',
      'Não',
      'Sim',
      'Sim',
    ]);
    for (final indice in [6, 7, 8, 9]) {
      await clicarRadio(tester, indice);
      final radio = tester.widget<Radio<String>>(
        find.byType(Radio<String>).at(indice),
      );
      expect(valorGrupoRadio(tester, radio), radio.value);
    }
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    dados.dispose();
  });
  testWidgets(
    'edição salva respostas de vacinação e castração nos controles originais',
    (tester) async {
      final dados = DadosAnimais();
      await tester.pumpWidget(
        ClientesScope(
          controller: dados,
          child: const MaterialApp(home: AnimaisCadastradosScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_note_rounded));
      await tester.pumpAndSettle();
      final radios = find.byType(Radio<String>);
      await tester.ensureVisible(radios.at(6));
      await tester.tap(radios.at(6));
      await tester.pumpAndSettle();
      await tester.ensureVisible(radios.at(9));
      await tester.tap(radios.at(9));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Salvar Alterações'));
      await tester.tap(find.text('Salvar Alterações'));
      await tester.pumpAndSettle();
      expect(dados.salvo?.castrado, 'Sim');
      expect(dados.salvo?.vacinado, 'Não');
      expect(find.text('Animais Publicados'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      dados.dispose();
    },
  );
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
