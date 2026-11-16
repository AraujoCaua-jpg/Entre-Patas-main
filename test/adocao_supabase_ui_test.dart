import 'dart:async';

import 'package:entre_patas/controller/cliente_controller.dart';
import 'package:entre_patas/controller/clientes_scope.dart';
import 'package:entre_patas/model/adocao.dart';
import 'package:entre_patas/model/animais.dart';
import 'package:entre_patas/model/cliente.dart';
import 'package:entre_patas/service/auth_api.dart';
import 'package:entre_patas/view/animal/adocao.dart';
import 'package:entre_patas/view/principal/notificacoes.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DadosAdocao extends ClienteController {
  _DadosAdocao({this.dono = false});
  final bool dono;
  int leiturasLista = 0;
  int envios = 0;
  String status = 'Aguardando';
  String statusAnimal = 'Disponível';
  String? acao;
  String? erroEnvio;
  Completer<List<Adocao>>? listaPendente;

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

  Adocao pedido() => Adocao.fromJson({
    'id': 44,
    'data': '2026-11-12T12:30:00Z',
    'status': status,
    'id_animal': 8,
    'id_cliente': 2,
    'id_dono': 1,
    'animal_nome': 'Lua',
    'animal_imagem': null,
    'animal_idade': 2,
    'animal_sexo': 'Fêmea',
    'cidadeDeResidencia': 'Mogi',
    'estado': 'SP',
    'solicitante_nome': 'Ana',
    'solicitante_sobrenome': 'Silva',
    'solicitante_email': 'ana@example.com',
    'solicitante_telefone': '11999999999',
  });

  @override
  Future<Animal> buscarAnimalRemoto(int id) async =>
      throw StateError('A tela não pode consultar PHP');

  @override
  Future<Animal> buscarAnimalPorIdSupabase(int id) async => Animal(
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
    status: statusAnimal,
    idCliente: 1,
  );

  @override
  Future<Map<String, dynamic>> buscarPerfilPublicoSupabase(int id) async => {
    'id': id,
    'nome': 'Dono',
    'usuario': 'dono',
    'cidade': 'Mogi',
    'estado': 'SP',
  };

  @override
  Future<Map<String, dynamic>> buscarResumoResponsavelSupabase(int id) async =>
      {'id': id, 'nome': 'Dono', 'usuario': 'dono'};

  @override
  Future<Map<String, dynamic>?> buscarMeuQuestionarioSupabase() async => {
    'id_cliente': 2,
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
  Future<Adocao> buscarAdocao(int id) async => pedido();

  @override
  Future<List<Adocao>> listarAdocoes() async {
    leiturasLista++;
    return listaPendente == null ? [pedido()] : listaPendente!.future;
  }

  @override
  Future<Adocao> solicitarAdocao(int id) async {
    envios++;
    if (erroEnvio != null) throw LoginException(erroEnvio!);
    return pedido();
  }

  @override
  Future<Adocao> responderAdocao(int id, String acao) async {
    this.acao = acao;
    status = {
      'aceitar': 'Aceito',
      'recusar': 'Recusado',
      'cancelar': 'Cancelado',
    }[acao]!;
    notifyListeners();
    return pedido();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (call) async => call.method == 'getAll' ? <String, Object>{} : true,
        );
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-key',
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        autoRefreshToken: false,
      ),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());

  Future<void> abrir(
    WidgetTester tester,
    _DadosAdocao dados,
    Widget tela,
  ) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ClientesScope(
        controller: dados,
        child: MaterialApp(home: tela),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> clicar(WidgetTester tester, String texto) async {
    await tester.ensureVisible(find.text(texto));
    await tester.tap(find.text(texto));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Criação usa animal e questionário Supabase e exige confirmação',
    (tester) async {
      final dados = _DadosAdocao();
      await abrir(tester, dados, const AdocaoScreen(animalId: 8));
      expect(find.text('100% de compatibilidade'), findsOneWidget);
      expect(find.text('Mogi - SP'), findsOneWidget);
      await clicar(tester, 'Enviar solicitação');
      expect(dados.envios, 0);
      await clicar(tester, 'Confirmar');
      expect(dados.envios, 1);
      expect(find.text('Status: Aguardando'), findsOneWidget);
      expect(find.text('Cancelar solicitação'), findsOneWidget);
      expect(find.text('Aprovar adoção'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      dados.dispose();
    },
  );

  for (final status in ['Reservado', 'Adotado']) {
    testWidgets('Animal $status não oferece nova solicitação', (tester) async {
      final dados = _DadosAdocao()..statusAnimal = status;
      await abrir(tester, dados, const AdocaoScreen(animalId: 8));
      expect(find.text('Enviar solicitação'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      dados.dispose();
    });
  }

  testWidgets('Animal próprio não oferece solicitação nem percentual', (
    tester,
  ) async {
    final dados = _DadosAdocao(dono: true);
    await abrir(tester, dados, const AdocaoScreen(animalId: 8));
    expect(find.text('Enviar solicitação'), findsNothing);
    expect(find.text('100% de compatibilidade'), findsNothing);
    expect(find.text('Este animal foi publicado por você.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    dados.dispose();
  });

  for (final acao in ['aceitar', 'recusar', 'cancelar']) {
    testWidgets('Decisão $acao atualiza o detalhe e remove ações pendentes', (
      tester,
    ) async {
      final dados = _DadosAdocao(dono: acao != 'cancelar');
      await abrir(tester, dados, const AdocaoScreen(adocaoId: 44));
      final botao = {
        'aceitar': 'Aprovar adoção',
        'recusar': 'Recusar solicitação',
        'cancelar': 'Cancelar solicitação',
      }[acao]!;
      await clicar(tester, botao);
      await clicar(tester, 'Confirmar');
      expect(dados.acao, acao);
      expect(find.text('Status: ${dados.status}'), findsOneWidget);
      expect(find.text(botao), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      dados.dispose();
    });
  }

  testWidgets('Erro de duplicidade não anuncia solicitação salva', (
    tester,
  ) async {
    final dados = _DadosAdocao()
      ..erroEnvio =
          'Você já possui uma solicitação em andamento para este animal.';
    await abrir(tester, dados, const AdocaoScreen(animalId: 8));
    await clicar(tester, 'Enviar solicitação');
    await clicar(tester, 'Confirmar');
    expect(find.text(dados.erroEnvio!), findsOneWidget);
    expect(find.text('Solicitação atualizada.'), findsNothing);
    expect(find.text('Adoção ID#44'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    dados.dispose();
  });

  testWidgets('Notificações atualiza status ao retornar da decisão', (
    tester,
  ) async {
    final dados = _DadosAdocao(dono: true);
    await abrir(tester, dados, const NotificacoesScreen());
    await clicar(tester, 'Ana quer adotar Lua');
    await clicar(tester, 'Aprovar adoção');
    await clicar(tester, 'Confirmar');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Aceito • 12/11/2026'), findsOneWidget);
    expect(dados.leiturasLista, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    dados.dispose();
  });

  testWidgets('Notificação visualizada some da lista', (tester) async {
    final dados = _DadosAdocao();
    await abrir(tester, dados, const NotificacoesScreen());
    expect(find.text('Sua solicitação para Lua'), findsOneWidget);
    await clicar(tester, 'Sua solicitação para Lua');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Sua solicitação para Lua'), findsNothing);
    expect(find.text('Nenhuma solicitação de adoção.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    dados.dispose();
  });

  testWidgets(
    'Atualizar notificações não mantém lista antiga enquanto aguarda',
    (tester) async {
      final dados = _DadosAdocao();
      await abrir(tester, dados, const NotificacoesScreen());
      expect(find.text('Sua solicitação para Lua'), findsOneWidget);
      dados.listaPendente = Completer<List<Adocao>>();
      await tester.tap(find.byTooltip('Atualizar'));
      await tester.pump();
      expect(find.text('Sua solicitação para Lua'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      dados.listaPendente!.complete([]);
      await tester.pumpAndSettle();
      expect(find.text('Nenhuma solicitação de adoção.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      dados.dispose();
    },
  );
}
