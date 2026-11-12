import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:entre_patas/controller/cliente_controller.dart';
import 'package:entre_patas/controller/clientes_scope.dart';
import 'package:entre_patas/model/animais.dart';
import 'package:entre_patas/view/principal/home.dart';

class DadosEspecie extends ClienteController {
  DadosEspecie(this.tipo);
  final String? tipo;
  final filtros = <Map<String, String>>[];
  int questionarios = 0;
  @override
  Future<Map<String, dynamic>?> carregarQuestionario() async {
    questionarios++;
    return tipo == null ? null : {'tipo': tipo};
  }

  @override
  Future<List<Animal>> listarAnimais({
    Map<String, String> filtros = const {},
  }) async {
    this.filtros.add(filtros);
    return [];
  }
}

void main() {
  for (final especie in ['Cachorro', 'Gato', null]) {
    testWidgets(
      'início respeita preferência $especie e permite alternar espécie',
      (tester) async {
        final dados = DadosEspecie(especie);
        await tester.pumpWidget(
          ClientesScope(
            controller: dados,
            child: const MaterialApp(home: HomeScreen()),
          ),
        );
        await tester.pumpAndSettle();
        expect(dados.filtros.single, {
          'acao': 'melhores',
          if (especie != null) 'tipo': especie,
        });
        final proxima = especie == 'Gato' ? 'Cachorro' : 'Gato';
        await tester.tap(find.text(proxima == 'Gato' ? 'Gatos' : 'Cachorros'));
        await tester.pumpAndSettle();
        expect(dados.filtros.last, {'acao': 'melhores', 'tipo': proxima});
        expect(dados.questionarios, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        dados.dispose();
      },
    );
  }
}
