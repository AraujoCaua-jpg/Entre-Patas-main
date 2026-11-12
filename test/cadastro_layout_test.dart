import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:entre_patas/controller/clientes_scope.dart';
import 'package:entre_patas/view/autenticacao/cadastro/cadastroUsuario.dart';

void main() {
  for (final size in [const Size(1280, 576), const Size(390, 844), const Size(390, 420)]) {
    testWidgets('cadastro permite rolar sem overflow em $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const ClientesScope(
        child: MaterialApp(home: CadastroUsuarioScreen()),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(TextField).first).width, lessThanOrEqualTo(560));
      await tester.ensureVisible(find.text('Continuar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Preencha todos os campos para continuar.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}