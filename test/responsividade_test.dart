import 'package:entre_patas/view/core/responsive_content.dart';
import 'package:entre_patas/view/autenticacao/bem_vindo.dart';
import 'package:entre_patas/view/autenticacao/login.dart';
import 'package:entre_patas/view/autenticacao/cadastro/cadastro_usuario.dart';
import 'package:entre_patas/view/autenticacao/esqueci_senha.dart';
import 'package:entre_patas/view/animal/cadastro_animal.dart';
import 'package:entre_patas/view/questionario/teste_comp_a.dart';
import 'package:entre_patas/view/questionario/teste_comp_b.dart';
import 'package:entre_patas/view/questionario/teste_comp_c.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  for (final size in [
    const Size(390, 844),
    const Size(1366, 768),
    const Size(1920, 1080),
    const Size(1024, 500),
  ]) {
    testWidgets('entrada e cadastro legíveis em $size', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final screen in const [
        BemVindoScreen(),
        LoginScreen(),
        CadastroUsuarioScreen(),
        EsqueciSenhaScreen(),
      ]) {
        await tester.pumpWidget(MaterialApp(home: screen));
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: screen.runtimeType.toString(),
        );
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -2000),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: screen.runtimeType.toString(),
        );
      }
    });
  }
  for (final size in [
    const Size(390, 844),
    const Size(1366, 768),
    const Size(1920, 1080),
  ]) {
    testWidgets('formulários sem overflow em $size', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final screen in const [
        TesteCompAScreen(),
        TesteCompBScreen(),
        TesteCompCScreen(),
        CadastroAnimalScreen(),
      ]) {
        await tester.pumpWidget(MaterialApp(home: screen));
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: screen.runtimeType.toString(),
        );
        final body = find.byType(ResponsiveContent).first;
        final child = tester.widget<ResponsiveContent>(body).child;
        final rect = tester.getRect(find.byWidget(child));
        expect(rect.width, lessThanOrEqualTo(840));
        expect(rect.center.dx, closeTo(size.width / 2, 1));
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -5000),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Avançar').evaluate().isNotEmpty ||
              find.text('Publicar Animal').evaluate().isNotEmpty ||
              find.text('Finalizar').evaluate().isNotEmpty,
          isTrue,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: screen.runtimeType.toString(),
        );
      }
    });
  }

  testWidgets('resultados passam de uma a duas colunas ao ampliar a janela', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final width in [390.0, 1200.0]) {
      await tester.binding.setSurfaceSize(Size(width, 800));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveCards(
              children: [
                SizedBox(key: ValueKey('a'), height: 100),
                SizedBox(key: ValueKey('b'), height: 100),
              ],
            ),
          ),
        ),
      );
      final a = tester.getRect(find.byKey(const ValueKey('a')));
      final b = tester.getRect(find.byKey(const ValueKey('b')));
      if (width < 900) {
        expect(b.top, greaterThan(a.bottom));
      } else {
        expect(b.top, a.top);
        expect(b.left, greaterThan(a.right));
      }
      expect(tester.takeException(), isNull, reason: 'Resultados');
    }
  });
}
