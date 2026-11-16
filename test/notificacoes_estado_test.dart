import 'dart:async';

import 'package:entre_patas/controller/cliente_controller.dart';
import 'package:entre_patas/model/adocao.dart';
import 'package:entre_patas/model/cliente.dart';
import 'package:entre_patas/services/login_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:entre_patas/services/notificacoes_lidas_service.dart';
import 'package:entre_patas/controller/clientes_scope.dart';
import 'package:entre_patas/view/principal/notificacoes.dart';
import 'package:entre_patas/view/animal/adocao.dart';
import 'package:material_ui/material_ui.dart';

Adocao pedido({String status = 'Aguardando', String nome = 'Lua'}) => Adocao(
  id: 1,
  data: DateTime(2026, 11, 16),
  status: status,
  idAnimal: 4,
  idCliente: 2,
  idDono: 1,
  detalhes: {'animal_nome': nome},
);

class _Dados extends ClienteController {
  _Dados({super.notificacoesLidasService});
  bool logado = true;
  List<Adocao> dados = [];
  Completer<List<Adocao>>? pendente;
  @override
  Cliente? get clienteLogado => logado
      ? Cliente(
          id: 1,
          nome: 'Ana',
          sobrenome: '',
          email: '',
          telefone: '',
          cidadeDeResidencia: '',
          usuario: 'ana',
        )
      : null;
  @override
  Future<List<Adocao>> listarAdocoes() async => pendente?.future ?? dados;

  @override
  Future<Adocao> buscarAdocao(int id) async =>
      dados.firstWhere((a) => a.id == id);

  @override
  Future<Map<String, dynamic>> buscarResumoResponsavelSupabase(int id) async =>
      {'id': id, 'nome': 'Responsável', 'usuario': 'responsavel'};
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Dados controller;
  late int avisos;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    controller = _Dados();
    avisos = 0;
    controller.addListener(() => avisos++);
  });
  tearDown(() => controller.dispose());

  testWidgets(
    'abrir item marca leitura e ela continua oculta ao reabrir a tela',
    (tester) async {
      controller.dados = [pedido()];
      await tester.pumpWidget(
        ClientesScope(
          controller: controller,
          child: const MaterialApp(home: NotificacoesScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsOneWidget);
      expect(controller.notificacaoFoiLida(pedido()), isFalse);
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();
      expect(find.byType(AdocaoScreen), findsOneWidget);
      expect(controller.notificacaoFoiLida(pedido()), isTrue);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Nenhuma solicitação de adoção.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      final reaberto = _Dados()..dados = [pedido()];
      try {
        await tester.pumpWidget(
          ClientesScope(
            controller: reaberto,
            child: const MaterialApp(home: NotificacoesScreen()),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ListTile), findsNothing);
        expect(find.text('Nenhuma solicitação de adoção.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        reaberto.dispose();
      }
    },
  );

  test('leitura persiste ao sair, entrar e recriar o controller', () async {
    controller.dados = [pedido()];
    await controller.atualizarNotificacoes();
    await controller.lerNotificacao(pedido());
    controller.limparSessao();
    await controller.atualizarNotificacoes();
    expect(controller.totalNotificacoes, 0);
    expect(controller.notificacaoFoiLida(pedido()), isTrue);
    final reaberto = _Dados()..dados = [pedido()];
    try {
      await reaberto.atualizarNotificacoes();
      expect(reaberto.totalNotificacoes, 0);
      expect(reaberto.notificacaoFoiLida(pedido()), isTrue);
    } finally {
      reaberto.dispose();
    }
  });

  test(
    'novo status da mesma adoção continua sendo uma notificação nova',
    () async {
      controller.dados = [pedido()];
      await controller.atualizarNotificacoes();
      await controller.lerNotificacao(pedido());
      controller.limparSessao();
      controller.dados = [pedido(status: 'Cancelado')];
      await controller.atualizarNotificacoes();
      expect(controller.totalNotificacoes, 1);
      expect(
        controller.notificacaoFoiLida(pedido(status: 'Cancelado')),
        isFalse,
      );
    },
  );

  test('falha ao salvar não oculta a notificação', () async {
    final dados = _Dados(notificacoesLidasService: _GravacaoFalha())
      ..dados = [pedido()];
    try {
      await dados.atualizarNotificacoes();
      await expectLater(
        dados.lerNotificacao(pedido()),
        throwsA(isA<LoginException>()),
      );
      expect(dados.totalNotificacoes, 1);
      expect(dados.notificacaoFoiLida(pedido()), isFalse);
    } finally {
      dados.dispose();
    }
  });

  test('polling vazio e dados equivalentes não disparam rebuild', () async {
    await controller.atualizarNotificacoes();
    expect(avisos, 0);
    controller.dados = [pedido()];
    await controller.atualizarNotificacoes();
    expect(avisos, 1);
    controller.dados = [pedido()];
    await controller.atualizarNotificacoes();
    expect(avisos, 1);
    expect(controller.totalNotificacoes, 1);
  });

  test(
    'mudanças de status, conteúdo e exclusão continuam notificando',
    () async {
      controller.dados = [pedido()];
      await controller.atualizarNotificacoes();
      controller.dados = [pedido(nome: 'Sol')];
      await controller.atualizarNotificacoes();
      controller.dados = [pedido(status: 'Aceito', nome: 'Sol')];
      await controller.atualizarNotificacoes();
      expect(avisos, 3);
      expect(controller.totalNotificacoes, 0);
      controller.dados = [];
      await controller.atualizarNotificacoes();
      expect(avisos, 4);
    },
  );

  test(
    'leitura repetida é idempotente e polling não restaura o badge',
    () async {
      controller.dados = [pedido()];
      await controller.atualizarNotificacoes();
      await controller.lerNotificacao(pedido());
      expect(avisos, 2);
      await controller.lerNotificacao(pedido());
      controller.dados = [pedido()];
      await controller.atualizarNotificacoes();
      expect(avisos, 2);
      expect(controller.totalNotificacoes, 0);
      expect(controller.notificacaoFoiLida(pedido()), isTrue);
    },
  );

  test('resposta anterior ao logout não restaura as notificações', () async {
    final resposta = Completer<List<Adocao>>();
    controller.pendente = resposta;
    final consulta = controller.atualizarNotificacoes();
    final expectativa = expectLater(consulta, throwsA(isA<LoginException>()));
    controller.logado = false;
    controller.limparSessao();
    resposta.complete([pedido()]);
    await expectativa;
    expect(controller.notificacoes, isEmpty);
  });
}

class _GravacaoFalha extends NotificacoesLidasService {
  @override
  Future<void> marcarComoLida(
    int clienteId,
    int adocaoId,
    String status,
  ) async {
    throw const LoginException('Falha simulada ao salvar.');
  }
}
