import 'package:entre_patas/controller/cliente_controller.dart';
import 'package:entre_patas/controller/clientes_scope.dart';
import 'package:entre_patas/model/animais.dart';
import 'package:entre_patas/services/compatibilidade_service.dart';
import 'package:entre_patas/view/principal/home.dart';
import 'package:entre_patas/view/animal/cadastroAnimal.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, dynamic> _respostas() => {
  'id_cliente': 1,
  'tipo': 'Gato',
  'sexo': 'Fêmea',
  'idadeMin': 0,
  'idadeMax': 10,
  'porte': 0,
  'energia': 1,
  'ambiente': 'Apartamento',
  'animais': 'Não',
  'dedicacao': 4,
  'sozinho': 5,
  'imovel': 1,
  'apoio': 1,
  'compromisso': 1,
  'moradores': 1,
  'rotina': 1,
  'financeiro': 3,
};

Map<String, dynamic> _jsonAnimal(int id, String nome, int? idade) => {
  'id': id,
  'id_cliente': 2,
  'nome': nome,
  'idade': idade,
  'tipo': 'Gato',
  'sexo': 'Fêmea',
  'energia': 'Médio',
  'porte': 'Pequeno',
  'carencia': 'Sim',
  'convivencia': 'Sim',
  'status': 'Disponível',
};

class _DadosHome extends ClienteController {
  final animais = [
    Animal.fromJson(_jsonAnimal(3, 'Idade desconhecida', null)),
    Animal.fromJson(_jsonAnimal(2, 'Menor nota', 20)),
    Animal.fromJson(_jsonAnimal(1, 'Completo', 2)),
    Animal.fromJson({..._jsonAnimal(4, 'Meu animal', null), 'id_cliente': 1}),
  ];

  @override
  Future<Map<String, dynamic>?> buscarMeuQuestionarioSupabase() async =>
      _respostas();

  @override
  Future<List<Animal>> listarAnimaisSupabase({
    String? tipo,
    Map<String, String> filtros = const {},
    int? pagina,
    bool somenteMeus = false,
  }) async => animais;

  @override
  Future<Animal> buscarMeuAnimalParaEditarSupabase(int id) async =>
      animais.first;
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

  test('JSON mantém idade desconhecida nula, sem converter para zero', () {
    final animal = Animal.fromJson(_jsonAnimal(1, 'Sem idade', null));
    expect(animal.idade, isNull);
    expect(animal.toJson()['idade'], isNull);
    expect(CompatibilidadeService.calcular(animal, _respostas()), isNull);
  });

  test('Idade zero continua conhecida e cálculo válido permanece igual', () {
    final animal = Animal.fromJson(_jsonAnimal(1, 'Filhote', 0));
    expect(animal.idade, 0);
    expect(CompatibilidadeService.calcular(animal, _respostas()), {
      'rotina': 100,
      'ambiente': 100,
      'preferencias': 100,
      'total': 100,
      'versao': 1,
    });
  });

  test('Campos opcionais nulos não interrompem a conversão do animal', () {
    final animal = Animal.fromJson({
      'id': 1,
      'id_cliente': 2,
      'idade': null,
      'nome': null,
      'imagem': null,
      'tipo': null,
      'descricao': null,
      'sexo': null,
      'energia': null,
      'porte': null,
      'carencia': null,
      'convivencia': null,
    });
    expect(animal.idade, isNull);
    expect(animal.nome, '');
    expect(CompatibilidadeService.calcular(animal, _respostas()), isNull);
  });

  testWidgets(
    'Home mantém feed misto e ordena desconhecidos após notas válidas',
    (tester) async {
      final dados = _DadosHome();
      await tester.pumpWidget(
        ClientesScope(
          controller: dados,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      final cards = find
          .byWidgetPredicate(
            (widget) => widget.runtimeType.toString() == '_PetCard',
          )
          .evaluate()
          .map((e) => (e.widget as dynamic).animal as Animal)
          .toList();
      expect(cards.map((a) => a.nome), [
        'Completo',
        'Menor nota',
        'Idade desconhecida',
      ]);
      expect(cards.map((a) => a.compatibilidade?['total']), [100, 96, null]);
      expect(find.text('Idade não informada'), findsOneWidget);
      expect(find.text('null anos'), findsNothing);
      expect(find.text('Meu animal'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      dados.dispose();
    },
  );

  testWidgets('Edição não preenche idade desconhecida como zero ou null', (
    tester,
  ) async {
    final dados = _DadosHome();
    await tester.pumpWidget(
      ClientesScope(
        controller: dados,
        child: const MaterialApp(home: CadastroAnimalScreen(animalId: 3)),
      ),
    );
    await tester.pumpAndSettle();
    final campo = tester.widget<TextField>(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Idade (anos)',
      ),
    );
    expect(campo.controller!.text, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    dados.dispose();
  });
}
