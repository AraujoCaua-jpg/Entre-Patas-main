import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:entre_patas/controller/cliente_controller.dart';
import 'package:entre_patas/controller/clientes_scope.dart';
import 'package:entre_patas/model/animais.dart';
import 'package:entre_patas/model/cliente.dart';
import 'package:entre_patas/view/principal/pesquisa.dart';

class PesquisaDados extends ClienteController {
  final filtros = <Map<String, String>>[];
  String? termo;
  @override
  Future<List<Animal>> listarAnimais({
    Map<String, String> filtros = const {},
  }) async {
    this.filtros.add(filtros);
    return [];
  }

  @override
  Future<List<Cliente>> pesquisarClientes(String termo) async {
    this.termo = termo;
    return [];
  }
}

void main() {
  testWidgets(
    'Pesquisa filtra pets, aplica filtros e busca usuários em tela pequena',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final dados = PesquisaDados();
      await tester.pumpWidget(
        ClientesScope(
          controller: dados,
          child: const MaterialApp(home: PesquisaScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Explorar novos amigos:'), findsOneWidget);
      await tester.tap(find.text('Cachorros'));
      await tester.pumpAndSettle();
      expect(dados.filtros.last['tipo'], 'Cachorro');
      await tester.tap(find.byTooltip('Filtros'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fêmea'));
      await tester.tap(find.text('Pequeno'));
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();
      expect(dados.filtros.last['sexo'], 'Fêmea');
      expect(dados.filtros.last['porte'], 'Pequeno');
      await tester.tap(find.text('Usuários'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Ana');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(dados.termo, 'Ana');
      expect(find.byTooltip('Filtros'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      dados.dispose();
    },
  );
}
