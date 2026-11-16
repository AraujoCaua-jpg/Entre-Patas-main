import 'dart:async';

import 'package:entre_patas/controller/cliente_controller.dart';
import 'package:entre_patas/controller/clientes_scope.dart';
import 'package:entre_patas/model/animais.dart';
import 'package:entre_patas/services/login_exception.dart';
import 'package:entre_patas/view/principal/pesquisa.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Dados extends ClienteController {
  final paginas = <int?>[];
  final especies = <String?>[];
  bool falhar = false;
  Completer<List<Animal>>? pendente;
  @override
  Future<List<Animal>> listarAnimaisSupabase({
    String? tipo,
    Map<String, String> filtros = const {},
    int? pagina,
    bool somenteMeus = false,
  }) async {
    paginas.add(pagina);
    especies.add(tipo);
    if (falhar) throw const LoginException('Falha de rede simulada.');
    if (pagina == 2 && pendente != null) return pendente!.future;
    return List.generate(
      pagina == 1 ? 50 : 1,
      (i) => pet((pagina! - 1) * 50 + i),
    );
  }
}

Animal pet(int id) => Animal(
  id: id,
  idCliente: 2,
  nome: 'Pet $id',
  idade: 2,
  tipo: 'Gato',
  energia: 'Médio',
  porte: 'Pequeno',
  convivencia: 'Sim',
  carencia: 'Sim',
  descricao: '',
  sexo: 'Fêmea',
  status: 'Disponível',
);

void main() {
  Future<void> abrir(WidgetTester tester, _Dados dados) async {
    await tester.pumpWidget(
      ClientesScope(
        controller: dados,
        child: const MaterialApp(home: PesquisaScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> carregarMais(WidgetTester tester) async {
    final botao = find.text('Carregar mais');
    await tester.ensureVisible(botao);
    await tester.tap(botao);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'próxima página acrescenta resultados e esconde botão ao terminar',
    (tester) async {
      final dados = _Dados();
      await abrir(tester, dados);
      expect(find.text('Pet 0'), findsOneWidget);
      await carregarMais(tester);
      expect(dados.paginas, [1, 2]);
      expect(find.text('Pet 0'), findsOneWidget);
      expect(find.text('Pet 50'), findsOneWidget);
      expect(find.text('Carregar mais'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      dados.dispose();
    },
  );

  testWidgets('falha na próxima página preserva lista e permite repetir', (
    tester,
  ) async {
    final dados = _Dados();
    await abrir(tester, dados);
    dados.falhar = true;
    await carregarMais(tester);
    expect(find.text('Pet 0'), findsOneWidget);
    expect(find.text('Falha de rede simulada.'), findsOneWidget);
    // Aguarda o feedback sair da frente do botão na parte inferior da tela.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    dados.falhar = false;
    await carregarMais(tester);
    expect(dados.paginas, [1, 2, 2]);
    expect(find.text('Pet 50'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    dados.dispose();
  });

  testWidgets('trocar espécie invalida próxima página em andamento', (
    tester,
  ) async {
    final dados = _Dados();
    await abrir(tester, dados);
    final resposta = Completer<List<Animal>>();
    dados.pendente = resposta;
    await carregarMais(tester);
    await tester.ensureVisible(find.text('Gatos'));
    await tester.tap(find.text('Gatos'));
    await tester.pumpAndSettle();
    resposta.complete([pet(999)]);
    await tester.pumpAndSettle();
    expect(dados.paginas, [1, 2, 1]);
    expect(dados.especies.last, 'Gato');
    expect(find.text('Pet 999'), findsNothing);
    expect(find.text('Pet 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    dados.dispose();
  });
}
