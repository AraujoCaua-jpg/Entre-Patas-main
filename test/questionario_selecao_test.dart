import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:entre_patas/view/questionario/testeCompB.dart';
import 'package:entre_patas/view/questionario/testeCompC.dart';

void main() {
  for (final respostas in [
    <String, dynamic>{},
    <String, dynamic>{
      'ambiente': 'Apartamento',
      'sozinho': 5,
      'dedicacao': 1,
      'animais': 'Não',
    },
  ]) {
    testWidgets('horas e dedicação mudam por clique com respostas $respostas', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: TesteCompBScreen(respostas: respostas)),
      );
      await tester.pumpAndSettle();
      final radios = find.byType(Radio<String>);
      Future<void> escolher(int indice) async {
        await tester.ensureVisible(radios.at(indice));
        await tester.tap(radios.at(indice));
        await tester.pumpAndSettle();
      }

      await escolher(0);
      for (var i = 0; i < 5; i++) {
        await escolher(4 + i);
        final grupo = tester.widgetList<Radio<String>>(radios).toList();
        expect(
          grupo.sublist(4, 9).every((r) => r.groupValue == '${5 - i}'),
          isTrue,
        );
      }
      for (var i = 0; i < 4; i++) {
        await escolher(9 + i);
        final grupo = tester.widgetList<Radio<String>>(radios).toList();
        expect(
          grupo.sublist(9, 13).every((r) => r.groupValue == '${i + 1}'),
          isTrue,
        );
        expect(grupo[4].groupValue, '1');
      }
      await escolher(13);
      await tester.ensureVisible(find.text('Avançar'));
      await tester.tap(find.text('Avançar'));
      await tester.pumpAndSettle();
      final proxima = tester.widget<TesteCompCScreen>(
        find.byType(TesteCompCScreen),
      );
      expect(proxima.respostas['sozinho'], 1);
      expect(proxima.respostas['dedicacao'], 4);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('opções financeiras também aceitam a nova seleção', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: TesteCompCScreen(respostas: {'financeiro': 3})),
    );
    await tester.pumpAndSettle();
    final radios = find.byType(Radio<String>);
    for (var i = 0; i < 3; i++) {
      await tester.ensureVisible(radios.at(8 + i));
      await tester.tap(radios.at(8 + i));
      await tester.pumpAndSettle();
      final grupo = tester.widgetList<Radio<String>>(radios).toList();
      expect(
        grupo.sublist(8, 11).every((r) => r.groupValue == '${3 - i}'),
        isTrue,
      );
    }
    expect(tester.takeException(), isNull);
  });
}
