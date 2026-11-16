import 'dart:convert';

import 'package:entre_patas/main.dart';
import 'package:entre_patas/services/navegacao_persistida_service.dart';
import 'package:entre_patas/view/autenticacao/bem_vindo.dart';
import 'package:entre_patas/view/navagacao.dart';
import 'package:entre_patas/view/animal/ficha_animal.dart';
import 'package:entre_patas/view/questionario/teste_comp.dart';
import 'package:entre_patas/view/usuario/configuracoes.dart';
import 'package:entre_patas/view/usuario/alterar_senha.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/logout_supabase_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ServidorAuthSimulado servidor;
  late NavegacaoPersistidaService persistencia;
  var semQuestionario = false;
  var falharPerfil = false;
  setUp(() async {
    persistencia = NavegacaoPersistidaService();
    SharedPreferences.setMockInitialValues({});
    semQuestionario = false;
    falharPerfil = false;
    servidor = ServidorAuthSimulado();
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-key',
      httpClient: MockClient((request) async {
        if (request.url.path == '/auth/v1/user') {
          return http.Response(
            jsonEncode(Supabase.instance.client.auth.currentUser!.toJson()),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/rest/v1/questionario' && semQuestionario) {
          return http.Response(
            '[]',
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/rest/v1/cliente' && falharPerfil) {
          return http.Response(
            '{"code":"42501","message":"Sem acesso"}',
            403,
            headers: {'content-type': 'application/json'},
          );
        }
        return servidor.responder(request);
      }),
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
    );
  });
  tearDown(() async => Supabase.instance.dispose());
  Future<void> entrar([String email = 'a@example.com']) async {
    await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: 'senha-simulada',
    );
  }

  Future<void> abrir(WidgetTester tester) async {
    await tester.pumpWidget(const MeuApp());
    // A ficha tem barras animadas de compatibilidade que não ficam inativas.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> fechar(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
  }

  testWidgets('sem sessão abre boas-vindas e não restaura páginas privadas', (
    tester,
  ) async {
    await persistencia.salvar(idContaA, {'pagina': 'configuracoes', 'aba': 2});
    await abrir(tester);
    expect(find.byType(BemVindoScreen), findsOneWidget);
    expect(find.byType(ConfiguracoesScreen), findsNothing);
    await fechar(tester);
  });

  testWidgets('recarregar mantém a aba Perfil sem exigir login', (
    tester,
  ) async {
    await entrar();
    await abrir(tester);
    await tester.tap(find.text('Perfil').last);
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    expect((await persistencia.carregar(idContaA))?['aba'], 2);
    await fechar(tester);
    await abrir(tester);
    expect(find.byType(BemVindoScreen), findsNothing);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );
    expect(find.text('@conta1'), findsOneWidget);
    await fechar(tester);
  });

  testWidgets('reabre animal pelo ID e Voltar retorna à aba anterior', (
    tester,
  ) async {
    await entrar();
    await persistencia.salvar(idContaA, {
      'pagina': 'animal',
      'id': 20,
      'aba': 1,
    });
    await abrir(tester);
    expect(find.byType(FichaAnimalScreen), findsOneWidget);
    expect(
      tester.widget<FichaAnimalScreen>(find.byType(FichaAnimalScreen)).animalId,
      20,
    );
    await tester.pageBack();
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    expect((await persistencia.carregar(idContaA))?['pagina'], 'navegacao');
    expect(tester.takeException(), isNull);
    await fechar(tester);
  });

  testWidgets('lembra configurações após nova montagem do aplicativo', (
    tester,
  ) async {
    await entrar();
    await abrir(tester);
    await tester.tap(find.text('Perfil').last);
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    expect((await persistencia.carregar(idContaA))?['pagina'], 'configuracoes');
    await fechar(tester);
    await abrir(tester);
    expect(find.byType(ConfiguracoesScreen), findsOneWidget);
    await fechar(tester);
  });

  testWidgets('página de outra conta não é restaurada', (tester) async {
    await persistencia.salvar(idContaA, {'pagina': 'configuracoes', 'aba': 2});
    await entrar('b@example.com');
    await abrir(tester);
    expect(find.byType(ConfiguracoesScreen), findsNothing);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
    await fechar(tester);
  });

  testWidgets('questionário continua obrigatório ao restaurar página privada', (
    tester,
  ) async {
    await entrar();
    semQuestionario = true;
    await persistencia.salvar(idContaA, {
      'pagina': 'animal',
      'id': 20,
      'aba': 1,
    });
    await abrir(tester);
    expect(find.byType(TesteCompScreen), findsOneWidget);
    expect(find.byType(FichaAnimalScreen), findsNothing);
    await fechar(tester);
  });

  testWidgets(
    'falha de perfil oferece tentar novamente sem abrir área privada',
    (tester) async {
      await entrar();
      falharPerfil = true;
      await abrir(tester);
      expect(find.text('Tentar novamente'), findsOneWidget);
      expect(find.byType(NavegacaoScreen), findsNothing);
      falharPerfil = false;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      expect(find.byType(NavegacaoScreen), findsOneWidget);
      await fechar(tester);
    },
  );

  testWidgets('logout apaga a página da conta', (tester) async {
    await entrar();
    await abrir(tester);
    await tester.runAsync(() => Supabase.instance.client.auth.signOut());
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    expect(await persistencia.carregar(idContaA), isNull);
    await fechar(tester);
  });

  testWidgets('recuperação por link tem prioridade sobre a página lembrada', (
    tester,
  ) async {
    await entrar();
    await persistencia.salvar(idContaA, {'pagina': 'configuracoes', 'aba': 2});
    await abrir(tester);
    final sessao = Supabase.instance.client.auth.currentSession!;
    await tester.runAsync(
      () => Supabase.instance.client.auth.getSessionFromUrl(
        Uri.parse(
          'http://localhost/#access_token=${sessao.accessToken}&refresh_token=refresh-test&expires_in=3600&token_type=bearer&type=recovery',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AlterarSenhaScreen), findsOneWidget);
    expect(
      tester
          .widget<AlterarSenhaScreen>(find.byType(AlterarSenhaScreen))
          .recuperacao,
      isTrue,
    );
    expect(find.byType(ConfiguracoesScreen), findsNothing);
    await fechar(tester);
  });

  test('preferência inválida não interrompe a restauração', () async {
    SharedPreferences.setMockInitialValues({
      'entre_patas.pagina.v1.$idContaA': '{inválido',
    });
    expect(await persistencia.carregar(idContaA), isNull);
  });

  test('gravação contém somente dados da página', () async {
    await persistencia.salvar(idContaA, {
      'pagina': 'animal',
      'id': 20,
      'aba': 1,
    });
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString('entre_patas.pagina.v1.$idContaA')!;
    expect(jsonDecode(texto), {'pagina': 'animal', 'id': 20, 'aba': 1});
    expect(texto, isNot(contains('token')));
  });
}
