import 'dart:async';

import 'package:entre_patas/controller/cliente_controller.dart';
import 'package:entre_patas/model/adocao.dart';
import 'package:entre_patas/model/cliente.dart';
import 'package:entre_patas/services/login_exception.dart';
import 'package:flutter_test/flutter_test.dart';

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
}

void main() {
  late _Dados controller;
  late int avisos;
  setUp(() {
    controller = _Dados();
    avisos = 0;
    controller.addListener(() => avisos++);
  });
  tearDown(() => controller.dispose());

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
