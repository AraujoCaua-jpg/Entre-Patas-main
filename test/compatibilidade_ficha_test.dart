import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:entre_patas/controller/cliente_controller.dart';
import 'package:entre_patas/controller/clientes_scope.dart';
import 'package:entre_patas/model/animais.dart';
import 'package:entre_patas/model/cliente.dart';
import 'package:entre_patas/services/compatibilidade_service.dart';
import 'package:entre_patas/view/animal/ficha_animal.dart';
import 'package:entre_patas/view/animal/compatibilidade_animal.dart';

Map<String, dynamic> respostas() => {
  'id_cliente': 2,
  'dedicacao': 4,
  'sozinho': 5,
  'imovel': 1,
  'apoio': 1,
  'compromisso': 1,
  'moradores': 1,
  'rotina': 1,
  'financeiro': 3,
  'idadeMin': 0,
  'idadeMax': 10,
  'porte': 0,
  'energia': 1,
  'ambiente': 'Apartamento',
  'animais': 'Não',
  'tipo': 'Gato',
  'sexo': 'Fêmea',
};

Animal animal() => Animal(
  id: 8,
  idCliente: 1,
  nome: 'Lua',
  idade: 2,
  tipo: 'Gato',
  energia: 'Médio',
  porte: 'Pequeno',
  convivencia: 'Sim',
  carencia: 'Sim',
  descricao: 'Carinhosa',
  sexo: 'Fêmea',
  status: 'Disponível',
);

class DadosFichaSupabase extends ClienteController {
  bool proprio = false;
  bool falhar = false;
  int consultas = 0;
  Map<String, dynamic>? questionario = respostas();

  @override
  Cliente get clienteLogado => Cliente(
    id: proprio ? 1 : 2,
    nome: 'Ana',
    sobrenome: '',
    email: '',
    telefone: '',
    cidadeDeResidencia: '',
    usuario: 'ana',
  );

  @override
  Future<Animal> buscarAnimalPorIdSupabase(int id) async => animal();

  @override
  Future<Map<String, dynamic>?> buscarMeuQuestionarioSupabase() async {
    consultas++;
    if (falhar) throw Exception('Falha de conexão simulada');
    return questionario;
  }

  @override
  Future<Map<String, dynamic>> buscarResumoResponsavelSupabase(int id) async =>
      {'id': 1, 'nome': 'Responsável', 'usuario': 'responsavel'};

  void atualizar() => notifyListeners();
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

  test('Categorias e pesos preservam resultados conhecidos', () {
    expect(CompatibilidadeService.calcular(animal(), respostas()), {
      'rotina': 100,
      'ambiente': 100,
      'preferencias': 100,
      'total': 100,
      'versao': 1,
    });
    final q = respostas()..['sozinho'] = 1;
    expect(CompatibilidadeService.calcular(animal(), q), {
      'rotina': 67,
      'ambiente': 100,
      'preferencias': 100,
      'total': 83,
      'versao': 1,
    });
    expect(CompatibilidadeService.calcular(animal(), null), isNull);
    expect(CompatibilidadeService.calcular(animal(), {}), isNull);
  });

  for (final caso in ['normal', 'proprio', 'sem questionario', 'erro']) {
    testWidgets('Ficha: $caso', (tester) async {
      final dados = DadosFichaSupabase()
        ..proprio = caso == 'proprio'
        ..falhar = caso == 'erro';
      if (caso == 'sem questionario') dados.questionario = null;
      await tester.pumpWidget(
        ClientesScope(
          controller: dados,
          child: const MaterialApp(home: FichaAnimalScreen(animalId: 8)),
        ),
      );
      await tester.pumpAndSettle();
      if (caso == 'proprio') {
        expect(find.byType(CompatibilidadeAnimal), findsNothing);
        expect(dados.consultas, 0);
      } else if (caso == 'erro') {
        expect(
          find.text('Não foi possível carregar o animal.'),
          findsOneWidget,
        );
        expect(find.byType(CompatibilidadeAnimal), findsNothing);
        dados.falhar = false;
        await tester.tap(find.text('Não foi possível carregar o animal.'));
        await tester.pumpAndSettle();
        expect(find.byType(CompatibilidadeAnimal), findsOneWidget);
      } else {
        final componente = tester.widget<CompatibilidadeAnimal>(
          find.byType(CompatibilidadeAnimal),
        );
        expect(
          componente.dados,
          CompatibilidadeService.calcular(animal(), dados.questionario),
        );
        if (caso == 'normal') {
          dados.questionario = respostas()..['sozinho'] = 1;
          dados.atualizar();
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<CompatibilidadeAnimal>(
                  find.byType(CompatibilidadeAnimal),
                )
                .dados?['total'],
            83,
          );
          dados.falhar = true;
          dados.atualizar();
          await tester.pumpAndSettle();
          expect(find.byType(CompatibilidadeAnimal), findsNothing);
        }
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      dados.dispose();
    });
  }
}
