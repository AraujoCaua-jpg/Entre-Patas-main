import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

String? valorGrupoRadio(WidgetTester tester, Radio<String> radio) {
  final contexto = tester.element(find.byWidget(radio));
  final grupo = RadioGroup.maybeOf<String>(contexto);
  expect(grupo, isNotNull, reason: 'Cada opção deve pertencer à sua pergunta.');
  return grupo!.groupValue;
}

Future<void> clicarRadio(WidgetTester tester, int indice) async {
  final opcao = find.byType(Radio<String>).at(indice);
  await tester.ensureVisible(opcao);
  await tester.tap(opcao);
  await tester.pumpAndSettle();
}
