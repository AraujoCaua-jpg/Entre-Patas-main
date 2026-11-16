import 'package:entre_patas/view/questionario/teste_comp.dart';
import 'package:entre_patas/view/questionario/teste_comp_fim.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  for (final tela in [const TesteCompScreen(), const TesteCompFimScreen()]) {
    testWidgets('${tela.runtimeType} permite continuar em janela baixa', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: tela));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final botao = find.byType(ElevatedButton);
      await tester.ensureVisible(botao);
      expect(botao.hitTestable(), findsOneWidget);
    });
  }
}
