import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:entre_patas/controller/cliente_controller.dart';
import 'package:entre_patas/controller/clientes_scope.dart';
import 'package:entre_patas/model/animais.dart';
import 'package:entre_patas/view/principal/home.dart';

class DadosEspecie extends ClienteController {
  DadosEspecie(this.tipo);
  String? tipo;
  final filtros = <Map<String, String>>[];
  final especiesSolicitadas = <String?>[];

  @override
  Future<Map<String, dynamic>?> buscarMeuQuestionarioSupabase() async =>
      tipo == null ? null : {'id_cliente': 1, 'tipo': tipo};

  @override
  Future<List<Animal>> listarAnimaisSupabase({
    String? tipo,
    Map<String, String> filtros = const {},
    int? pagina,
    bool somenteMeus = false,
  }) async {
    this.filtros.add(filtros);
    especiesSolicitadas.add(tipo);
    return [];
  }

  void responder(String resposta) {
    tipo = resposta;
    notifyListeners();
  }
}

void main() {
  testWidgets(
    'Carrossel avança a cada 3 segundos e permite voltar pelas laterais',
    (tester) async {
      final dados = DadosEspecie('Gato');
      await tester.pumpWidget(
        ClientesScope(
          controller: dados,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      final carrossel = find.byKey(const ValueKey('carrossel-home'));
      PageController controller() =>
          tester.widget<PageView>(carrossel).controller!;
      expect(controller().page, 0);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(controller().page, 1);
      await tester.tap(find.bySemanticsLabel('Próxima imagem'));
      await tester.pumpAndSettle();
      expect(controller().page, 2);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(controller().page, 0);
      await tester.tap(find.bySemanticsLabel('Imagem anterior'));
      await tester.pumpAndSettle();
      expect(controller().page, 2);
      await tester.pumpWidget(const SizedBox());
      dados.dispose();
    },
  );

  for (final especie in ['Cachorro', 'Gato', null]) {
    testWidgets('Home usa o teste e atualiza os matches: $especie', (
      tester,
    ) async {
      final dados = DadosEspecie(especie);
      await tester.pumpWidget(
        ClientesScope(
          controller: dados,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(dados.filtros, hasLength(1));
      expect(dados.especiesSolicitadas, [especie]);
      expect(find.text('Amiguinhos disponíveis'), findsOneWidget);
      expect(
        find.text('Faça o teste para descobrir seus matches'),
        especie == null ? findsOneWidget : findsNothing,
      );
      final novaEspecie = especie == 'Gato' ? 'Cachorro' : 'Gato';
      dados.responder(novaEspecie);
      await tester.pumpAndSettle();
      expect(dados.filtros, hasLength(2));
      expect(dados.especiesSolicitadas, [especie, novaEspecie]);
      expect(
        find.text('Faça o teste para descobrir seus matches'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      dados.dispose();
    });
  }
}
