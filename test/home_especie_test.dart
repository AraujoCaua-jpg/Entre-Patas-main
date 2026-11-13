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

  @override
  Future<Map<String, dynamic>?> carregarQuestionario() async =>
      tipo == null ? null : {'tipo': tipo};

  @override
  Future<List<Animal>> listarAnimais({
    Map<String, String> filtros = const {},
  }) async {
    this.filtros.add(filtros);
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
      expect(dados.filtros.single, {'acao': 'melhores', 'tipo': ?especie});
      expect(find.text('Seus melhores Matches'), findsOneWidget);
      expect(
        find.text('Faça o teste para descobrir seus matches'),
        especie == null ? findsOneWidget : findsNothing,
      );
      dados.responder(especie == 'Gato' ? 'Cachorro' : 'Gato');
      await tester.pumpAndSettle();
      expect(dados.filtros.last, {'acao': 'melhores', 'tipo': dados.tipo!});
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
