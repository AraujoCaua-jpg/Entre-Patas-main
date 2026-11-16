import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:entre_patas/view/questionario/teste_comp_b.dart';
import 'package:entre_patas/view/questionario/teste_comp_c.dart';

import 'support/radio_test_helpers.dart';

void main() {
  testWidgets('setas mudam apenas a pergunta em foco', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TesteCompBScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(RadioGroup<String>), findsNWidgets(4));
    await clicarRadio(tester, 0);
    await clicarRadio(tester, 4);
    // Cliques em modo touch não dão foco de teclado automaticamente.
    final detector = tester.widget<FocusableActionDetector>(
      find.descendant(
        of: find.byType(Radio<String>).at(4),
        matching: find.byType(FocusableActionDetector),
      ),
    );
    detector.focusNode!.requestFocus();
    await tester.pump();
    expect(detector.focusNode!.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    final radios = tester
        .widgetList<Radio<String>>(find.byType(Radio<String>))
        .toList();
    expect(valorGrupoRadio(tester, radios[4]), '4');
    expect(valorGrupoRadio(tester, radios[0]), 'Casa c/ Quintal');
    expect(valorGrupoRadio(tester, radios[9]), isNull);
    expect(valorGrupoRadio(tester, radios[13]), isNull);
    expect(tester.takeException(), isNull);
  });

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
          grupo
              .sublist(4, 9)
              .every((r) => valorGrupoRadio(tester, r) == '${5 - i}'),
          isTrue,
        );
      }
      for (var i = 0; i < 4; i++) {
        await escolher(9 + i);
        final grupo = tester.widgetList<Radio<String>>(radios).toList();
        expect(
          grupo
              .sublist(9, 13)
              .every((r) => valorGrupoRadio(tester, r) == '${i + 1}'),
          isTrue,
        );
        expect(valorGrupoRadio(tester, grupo[4]), '1');
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
        grupo
            .sublist(8, 11)
            .every((r) => valorGrupoRadio(tester, r) == '${3 - i}'),
        isTrue,
      );
    }
    expect(tester.takeException(), isNull);
  });
}
