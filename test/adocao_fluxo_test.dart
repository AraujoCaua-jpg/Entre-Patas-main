import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:entre_patas/controller/cliente_controller.dart';
import 'package:entre_patas/controller/clientes_scope.dart';
import 'package:entre_patas/model/cliente.dart';
import 'package:entre_patas/model/animais.dart';
import 'package:entre_patas/model/adocao.dart';
import 'package:entre_patas/view/animal/adocao.dart';
import 'package:entre_patas/view/questionario/testeCompA.dart';
import 'package:entre_patas/view/questionario/testeComp.dart';
import 'package:entre_patas/view/usuario/configuracoes.dart';

class FluxoDados extends ClienteController {
  FluxoDados({this.dono = false});
  final bool dono;
  Map<String, dynamic>? salvo;
  String? acao;
  int envios = 0;
  final respostas = <String, dynamic>{
    'tipo': 'Gato',
    'sexo': 'Fêmea',
    'idadeMin': 0,
    'idadeMax': 10,
    'porte': 0,
    'energia': 1,
    'ambiente': 'Apartamento',
    'sozinho': 5,
    'dedicacao': 4,
    'animais': 'Não',
    'imovel': 1,
    'apoio': 1,
    'compromisso': 1,
    'moradores': 1,
    'financeiro': 3,
    'rotina': 1,
  };
  @override
  Cliente get clienteLogado => Cliente(
    id: dono ? 1 : 2,
    nome: dono ? 'Dono' : 'Ana',
    sobrenome: 'Silva',
    email: 'ana@example.com',
    telefone: '11999999999',
    cidadeDeResidencia: 'Mogi',
    usuario: 'ana',
  );
  @override
  Future<Map<String, dynamic>?> carregarQuestionario() async => respostas;
  @override
  Future<void> salvarQuestionario(Map<String, dynamic> dados) async {
    salvo = dados;
  }

  @override
  Future<Animal> buscarAnimalRemoto(int id) async => Animal(
    id: id,
    nome: 'Lua',
    idade: 2,
    tipo: 'Gato',
    energia: 'Médio',
    porte: 'Pequeno',
    convivencia: 'Sim',
    carencia: 'Não',
    descricao: 'Carinhosa',
    sexo: 'Fêmea',
    status: 'Disponível',
    idCliente: 1,
    cidade: 'Mogi',
    estado: 'SP',
    compatibilidade: {'total': 100},
  );
  Adocao pedido(String status) => Adocao.fromJson({
    'id': 44,
    'data': '2026-11-12 12:30:00',
    'status': status,
    'id_animal': 8,
    'id_cliente': 2,
    'id_dono': 1,
    'animal_nome': 'Lua',
    'animal_imagem': null,
    'animal_idade': 2,
    'animal_sexo': 'Fêmea',
    'estado': 'SP',
    'cidadeDeResidencia': 'Mogi',
    'solicitante_nome': 'Ana',
    'solicitante_sobrenome': 'Silva',
    'solicitante_email': 'ana@example.com',
    'solicitante_telefone': '11999999999',
  });
  @override
  Future<Adocao> solicitarAdocao(int id) async {
    envios++;
    return pedido('Aguardando');
  }

  @override
  Future<Adocao> buscarAdocao(int id) async => pedido('Aguardando');
  @override
  Future<Adocao> responderAdocao(int id, String acao) async {
    this.acao = acao;
    return pedido(acao == 'aceitar' ? 'Aceito' : 'Cancelado');
  }

  @override
  Future<Cliente> buscarClienteRemoto(int id, {bool basico = false}) async =>
      clienteLogado;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'NunitoSans',
    )..addFont(rootBundle.load('assets/fonts/NunitoSans.ttf'))).load();
  });
  Future<void> abrir(WidgetTester tester, FluxoDados dados, Widget tela) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ClientesScope(
        controller: dados,
        child: MaterialApp(
          theme: ThemeData(fontFamily: 'NunitoSans'),
          home: tela,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> clicar(WidgetTester tester, String texto) async {
    final alvo = find.text(texto);
    if (alvo.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        alvo,
        250,
        scrollable: find.byType(Scrollable).last,
      );
    }
    await tester.ensureVisible(alvo);
    await tester.pumpAndSettle();
    await tester.tap(alvo);
    await tester.pumpAndSettle();
  }

  testWidgets('refazer inicia vazio e só substitui as respostas após salvar', (
    tester,
  ) async {
    final dados = FluxoDados();
    await abrir(tester, dados, const ConfiguracoesScreen());
    await clicar(tester, 'Refazer teste');
    expect(find.byType(TesteCompScreen), findsOneWidget);
    await clicar(tester, 'Começar');
    expect(find.byType(TesteCompAScreen), findsOneWidget);
    expect(
      tester
          .widgetList<TextField>(find.byType(TextField))
          .first
          .controller!
          .text,
      '',
    );
    expect(
      tester
          .widgetList<Radio<String>>(find.byType(Radio<String>))
          .every((radio) => radio.groupValue == null),
      isTrue,
    );
    expect(dados.salvo, isNull);
    await clicar(tester, 'Gato');
    await tester.enterText(find.byType(TextField).at(0), '0');
    await tester.enterText(find.byType(TextField).at(1), '10');
    tester.widget<Radio<String>>(find.byType(Radio<String>).at(1)).onChanged!(
      'Fêmea',
    );
    final sliders = tester.widgetList<Slider>(find.byType(Slider)).toList();
    sliders[0].onChanged!(0);
    sliders[1].onChanged!(1);
    await tester.pumpAndSettle();
    await clicar(tester, 'Avançar');
    var radios = tester
        .widgetList<Radio<String>>(find.byType(Radio<String>))
        .toList();
    expect(radios.every((radio) => radio.groupValue == null), isTrue);
    for (final index in [2, 4, 12, 14]) {
      radios[index].onChanged!(radios[index].value);
    }
    await tester.pumpAndSettle();
    await clicar(tester, 'Avançar');
    radios = tester
        .widgetList<Radio<String>>(find.byType(Radio<String>))
        .toList();
    expect(radios.every((radio) => radio.groupValue == null), isTrue);
    expect(dados.salvo, isNull);
    for (final index in [0, 2, 4, 6, 8, 11]) {
      radios[index].onChanged!(radios[index].value);
    }
    await tester.pumpAndSettle();
    await clicar(tester, 'Avançar');
    expect(dados.salvo, dados.respostas);
    expect(find.text('Teste concluído'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    dados.dispose();
  });
  testWidgets('solicitação exige confirmação e mostra o pedido salvo', (
    tester,
  ) async {
    final dados = FluxoDados();
    await abrir(tester, dados, const AdocaoScreen(animalId: 8));
    expect(find.text('Lua'), findsOneWidget);
    await clicar(tester, 'Enviar solicitação');
    expect(dados.envios, 0);
    await clicar(tester, 'Confirmar');
    expect(dados.envios, 1);
    expect(find.text('Adoção ID#44'), findsOneWidget);
    expect(find.text('Cancelar solicitação'), findsOneWidget);
    expect(find.text('Aprovar adoção'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    dados.dispose();
  });
  testWidgets('responsável pode aprovar o pedido e vê o novo status', (
    tester,
  ) async {
    final dados = FluxoDados(dono: true);
    await abrir(tester, dados, const AdocaoScreen(adocaoId: 44));
    await clicar(tester, 'Aprovar adoção');
    await clicar(tester, 'Confirmar');
    expect(dados.acao, 'aceitar');
    expect(find.text('Status: Aceito'), findsOneWidget);
    expect(find.text('Aprovar adoção'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    dados.dispose();
  });
}
