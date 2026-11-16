import 'dart:async';
import 'dart:convert';

import 'package:entre_patas/controller/cliente_controller.dart';
import 'package:entre_patas/controller/clientes_scope.dart';
import 'package:entre_patas/services/login_exception.dart';
import 'package:entre_patas/services/supabase_service.dart';
import 'package:entre_patas/view/core/usuario_resumo.dart';
import 'package:entre_patas/view/usuario/ficha_perfil.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/logout_supabase_backend.dart';

// As três verificações de widget usam o SDK real com transporte simulado.
// Expõe a conclusão da leitura para executá-la no runAsync, sem deixar
// pumpAndSettle aguardando trabalho criado fora do relógio FakeAsync.
class _ControllerLeituraReal extends ClienteController {
  Future<void>? leitura;

  Future<Map<String, dynamic>> _acompanhar(
    Future<Map<String, dynamic>> consulta,
  ) {
    leitura = consulta.then<void>((_) {}, onError: (Object _) {});
    return consulta;
  }

  @override
  Future<Map<String, dynamic>> buscarPerfilPublicoSupabase(int clienteId) =>
      _acompanhar(super.buscarPerfilPublicoSupabase(clienteId));

  @override
  Future<Map<String, dynamic>> buscarResumoResponsavelSupabase(int clienteId) =>
      _acompanhar(super.buscarResumoResponsavelSupabase(clienteId));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseService service;
  late ServidorAuthSimulado auth;
  late List<http.Request> requests;
  dynamic resposta;
  Map<String, dynamic>? erroRpc;
  bool falharRede = false;
  int renovacoes = 0;
  Completer<void>? rpcIniciada;
  Completer<void>? liberarRpc;

  setUp(() async {
    auth = ServidorAuthSimulado();
    requests = [];
    resposta = [
      {
        'id': 9,
        'nome': 'Pessoa legada',
        'sobrenome': 'QA',
        'usuario': 'legado_qa',
        'imagem': null,
        'cidade': 'Cidade fictícia',
        'estado': 'SP',
        'lar_de_adocao': false,
      },
    ];
    erroRpc = null;
    falharRede = false;
    renovacoes = 0;
    rpcIniciada = null;
    liberarRpc = null;
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
        detectSessionInUri: false,
      ),
      httpClient: MockClient((request) async {
        requests.add(request);
        final rota = request.url.path;
        if (rota == '/auth/v1/token' &&
            request.url.queryParameters['grant_type'] == 'refresh_token') {
          final sessao = Supabase.instance.client.auth.currentSession!;
          final partes = sessao.accessToken.split('.');
          final claims = jsonDecode(
            utf8.decode(base64Url.decode(base64Url.normalize(partes[1]))),
          ) as Map<String, dynamic>;
          claims['jti'] = ++renovacoes;
          final payload = base64Url
              .encode(utf8.encode(jsonEncode(claims)))
              .replaceAll('=', '');
          return http.Response(
            jsonEncode({
              ...sessao.toJson(),
              'access_token': '${partes[0]}.$payload.assinatura-simulada',
              'expires_in': 3600,
            }),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        if (rota == '/rest/v1/rpc/buscar_perfil_publico' ||
            rota == '/rest/v1/rpc/buscar_resumo_responsavel') {
          expect(request.method, 'POST');
          expect(jsonDecode(request.body), {'p_cliente_id': 9});
          rpcIniciada?.complete();
          await liberarRpc?.future;
          if (falharRede) throw http.ClientException('Erro interno simulado');
          return http.Response(
            jsonEncode(erroRpc ?? resposta),
            erroRpc == null ? 200 : 403,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        if (rota == '/rest/v1/animal') {
          return http.Response(
            '[]',
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        return auth.responder(request);
      }),
    );
    service = SupabaseService();
  });

  tearDown(() async => Supabase.instance.dispose());

  Future<void> entrar([String email = 'a@example.com']) async {
    await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: 'senha-simulada',
    );
    requests.clear();
  }

  Future<Map<String, dynamic>> consultar(bool resumo, [int id = 9]) => resumo
      ? service.buscarResumoResponsavel(id)
      : service.buscarPerfilPublicoSupabase(id);

  Matcher mensagem(String texto) =>
      isA<LoginException>().having((erro) => erro.mensagem, 'mensagem', texto);

  Future<void> abrirWidgetComSdk(
    WidgetTester tester,
    _ControllerLeituraReal controller,
    Widget tela,
  ) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ClientesScope(
          controller: controller,
          child: MaterialApp(home: tela),
        ),
      );
      expect(controller.leitura, isNotNull);
      await controller.leitura;
    });
    await tester.pumpAndSettle();
  }

  for (final resumo in [false, true]) {
    final nome = resumo ? 'Resumo' : 'Perfil';
    final invalido = resumo
        ? 'Dados do responsável inválidos.'
        : 'Dados do perfil público inválidos.';
    final indisponivel = resumo
        ? 'Responsável não encontrado.'
        : 'Perfil público indisponível.';

    test(
      '$nome aceita legado sem vínculo Auth/animais/contatos no DTO',
      () async {
        await entrar();
        final result = await consultar(resumo);
        expect(result, resposta.single);
        expect(result.containsKey('auth_user_id'), isFalse);
        expect(result.containsKey('email'), isFalse);
        expect(result.containsKey('telefone'), isFalse);
        expect(result.containsKey('endereco'), isFalse);
        expect(requests, hasLength(1));
        expect(
          requests.single.url.path,
          resumo
              ? '/rest/v1/rpc/buscar_resumo_responsavel'
              : '/rest/v1/rpc/buscar_perfil_publico',
        );
      },
    );

    test('$nome aceita ID numérico de ponto flutuante integral', () async {
      await entrar();
      resposta.single['id'] = 9.0;
      final result = await consultar(resumo);
      expect(result['id'], isA<double>());
      expect(result['id'], 9);
    });

    test(
      '$nome preserva campos opcionais omitidos sem inventar dados',
      () async {
        await entrar();
        resposta = [
          {'id': 9},
        ];
        expect(await consultar(resumo), {'id': 9});
      },
    );

    test('$nome preserva campos públicos nulos', () async {
      await entrar();
      resposta = [
        {
          'id': 9,
          'nome': null,
          'sobrenome': null,
          'usuario': null,
          'imagem': null,
          'cidade': null,
          'estado': null,
          'lar_de_adocao': null,
        },
      ];
      expect(await consultar(resumo), resposta.single);
    });

    test('$nome não propaga campos privados inesperados', () async {
      await entrar();
      resposta.single.addAll({
        'email': 'privado@example.com',
        'telefone': '11999998888',
        'endereco': 'Endereço fictício',
        'auth_user_id': null,
        'ativo': true,
      });
      final result = await consultar(resumo);
      for (final campo in [
        'email',
        'telefone',
        'endereco',
        'auth_user_id',
        'ativo',
      ]) {
        expect(result.containsKey(campo), isFalse);
      }
      expect(result['id'], 9);
    });

    test('$nome sem sessão não consulta a RPC', () async {
      await expectLater(
        consultar(resumo),
        throwsA(mensagem('Entre novamente para continuar.')),
      );
      expect(requests, isEmpty);
    });

    for (final id in [0, -1]) {
      test('$nome rejeita parâmetro $id sem consultar a RPC', () async {
        await expectLater(
          consultar(resumo, id),
          throwsA(mensagem('ID inválido.')),
        );
        expect(requests, isEmpty);
      });
    }

    test('$nome vazio informa ausência com LoginException legível', () async {
      await entrar();
      resposta = [];
      await expectLater(consultar(resumo), throwsA(mensagem(indisponivel)));
    });

    for (final caso in <String, Object?>{
      'nulo': null,
      'mapa fora da lista': {'id': 9},
      'string': 'não é uma lista',
      'item nulo': [null],
      'item não mapa': ['não é um mapa'],
      'mais de um item': [
        {'id': 9},
        {'id': 9},
      ],
      'ID ausente': [<String, dynamic>{}],
      'ID string': [
        {'id': '9'},
      ],
      'ID booleano': [
        {'id': true},
      ],
      'ID zero': [
        {'id': 0},
      ],
      'ID negativo': [
        {'id': -9},
      ],
      'ID fracionário': [
        {'id': 9.5},
      ],
      'outro ID': [
        {'id': 10},
      ],
      'nome numérico': [
        {'id': 9, 'nome': 12},
      ],
      'sobrenome booleano': [
        {'id': 9, 'sobrenome': true},
      ],
      'usuário numérico': [
        {'id': 9, 'usuario': 12},
      ],
      'imagem booleana': [
        {'id': 9, 'imagem': false},
      ],
      'cidade em lista': [
        {'id': 9, 'cidade': []},
      ],
      'estado em mapa': [
        {'id': 9, 'estado': <String, dynamic>{}},
      ],
      'lar string': [
        {'id': 9, 'lar_de_adocao': 'true'},
      ],
      'lar numérico': [
        {'id': 9, 'lar_de_adocao': 1},
      ],
    }.entries) {
      test('$nome rejeita DTO ${caso.key} sem TypeError', () async {
        await entrar();
        resposta = caso.value;
        await expectLater(consultar(resumo), throwsA(mensagem(invalido)));
      });
    }

    for (final codigo in ['42501', 'PT403']) {
      test(
        '$nome trata erro $codigo sem detalhes privados e sem fallback',
        () async {
          await entrar();
          erroRpc = {'code': codigo, 'message': 'Internal SQL private_profile'};
          await expectLater(
            consultar(resumo),
            throwsA(
              mensagem('Você não tem permissão para consultar este perfil.'),
            ),
          );
          expect(requests, hasLength(1));
        },
      );
    }

    test('$nome trata RPC ausente sem contornar autorização', () async {
      await entrar();
      erroRpc = {'code': 'PGRST202', 'message': 'Internal SQL private_profile'};
      await expectLater(
        consultar(resumo),
        throwsA(
          mensagem(
            'A consulta de perfis públicos ainda precisa ser configurada no Supabase.',
          ),
        ),
      );
      expect(requests, hasLength(1));
    });

    test('$nome trata erro SQL inesperado sem divulgar sua mensagem', () async {
      await entrar();
      erroRpc = {'code': 'XX000', 'message': 'Internal SQL private_profile'};
      await expectLater(
        consultar(resumo),
        throwsA(
          mensagem('Não foi possível consultar os dados públicos no Supabase.'),
        ),
      );
    });

    test('$nome trata erro de conexão sem TypeError', () async {
      await entrar();
      falharRede = true;
      await expectLater(
        consultar(resumo),
        throwsA(
          mensagem('Não foi possível consultar os dados públicos no Supabase.'),
        ),
      );
    });

    test('$nome aceita renovação de token durante a consulta', () async {
      await entrar();
      final tokenAnterior =
          Supabase.instance.client.auth.currentSession!.accessToken;
      rpcIniciada = Completer<void>();
      liberarRpc = Completer<void>();
      final operacao = consultar(resumo);
      final conclusao = expectLater(operacao, completes);
      await rpcIniciada!.future;
      await Supabase.instance.client.auth.refreshSession();
      expect(
        Supabase.instance.client.auth.currentSession!.accessToken,
        isNot(tokenAnterior),
      );
      liberarRpc!.complete();
      await conclusao;
      expect((await operacao)['id'], 9);
    });

    for (final mudanca in [
      'logout',
      'troca de conta',
      'novo login da mesma conta',
    ]) {
      test('$nome descarta resposta após $mudanca', () async {
        await entrar();
        rpcIniciada = Completer<void>();
        liberarRpc = Completer<void>();
        final operacao = consultar(resumo);
        final resultado = expectLater(
          operacao,
          throwsA(mensagem('Entre novamente para continuar.')),
        );
        await rpcIniciada!.future;
        if (mudanca == 'logout') {
          await Supabase.instance.client.auth.signOut(
            scope: SignOutScope.local,
          );
        } else {
          await entrar(
            mudanca == 'troca de conta' ? 'b@example.com' : 'a@example.com',
          );
        }
        liberarRpc!.complete();
        await resultado;
      });
    }
  }

  testWidgets('Ficha mostra erro de contrato sem lançar no fromMap', (
    tester,
  ) async {
    await entrar();
    resposta = [
      {'id': '9'},
    ];
    final controller = _ControllerLeituraReal();
    await abrirWidgetComSdk(
      tester,
      controller,
      const FichaPerfilScreen(clienteId: 9),
    );
    expect(find.text('Dados do perfil público inválidos.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets(
    'Resumo mostra tentativa novamente para dados inválidos sem TypeError',
    (tester) async {
      await entrar();
      resposta.single['imagem'] = false;
      final controller = _ControllerLeituraReal();
      await abrirWidgetComSdk(
        tester,
        controller,
        const Scaffold(body: UsuarioResumo(clienteId: 9)),
      );
      expect(
        find.text('Não foi possível carregar. Tentar novamente'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );

  testWidgets(
    'Ficha exibe perfil legado com animais vazios e sem contatos privados',
    (tester) async {
      await entrar();
      final controller = _ControllerLeituraReal();
      await abrirWidgetComSdk(
        tester,
        controller,
        const FichaPerfilScreen(clienteId: 9),
      );
      expect(find.text('Pessoa legada QA'), findsOneWidget);
      expect(find.text('Perfil público indisponível.'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );
}
