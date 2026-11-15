import 'support/logout_supabase_backend.dart';

import 'package:entre_patas/controller/cliente_controller.dart';
import 'package:entre_patas/services/supabase_auth_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ServidorAuthSimulado servidor;
  late SupabaseAuthService auth;
  late ClienteController controller;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (call) async => call.method == 'getAll' ? <String, Object>{} : true,
        );
    servidor = ServidorAuthSimulado();
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-key',
      httpClient: MockClient(servidor.responder),
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        autoRefreshToken: false,
      ),
    );
    auth = SupabaseAuthService();
    controller = ClienteController();
  });
  tearDown(() async {
    controller.dispose();
    await Supabase.instance.dispose();
  });

  Future<void> entrar(String email) async {
    await auth.entrar(email, 'senha-simulada');
    await controller.carregarMeuPerfilSupabase();
  }

  test('SDK real encerra sessão e limpa o perfil após logout', () async {
    await entrar('a@example.com');
    expect(Supabase.instance.client.auth.currentUser?.id, idContaA);
    expect(controller.clienteLogado?.id, 1);
    await controller.sair();
    expect(Supabase.instance.client.auth.currentSession, isNull);
    expect(Supabase.instance.client.auth.currentUser, isNull);
    expect(controller.clienteLogado, isNull);
    expect(controller.clientes, isEmpty);
    expect(
      servidor.requisicoes.where((r) => r.url.path == '/auth/v1/logout'),
      hasLength(1),
    );
    expect(
      servidor.requisicoes.any((r) => r.url.path.endsWith('.php')),
      isFalse,
    );
  });

  test(
    'Troca A para B consulta perfil, questionário e animais da conta B',
    () async {
      await entrar('a@example.com');
      expect(
        (await controller.buscarMeuQuestionarioSupabase())?['id_cliente'],
        1,
      );
      expect(
        (await controller.listarAnimaisDoClienteSupabase(1)).single.idCliente,
        1,
      );
      await controller.sair();
      await entrar('b@example.com');
      expect(Supabase.instance.client.auth.currentUser?.id, idContaB);
      expect(controller.clienteLogado?.id, 2);
      expect(controller.clientes.map((c) => c.id), [2]);
      expect(controller.buscarCliente(1), isNull);
      expect(
        (await controller.buscarMeuQuestionarioSupabase())?['id_cliente'],
        2,
      );
      expect(
        (await controller.listarAnimaisDoClienteSupabase(2)).single.idCliente,
        2,
      );
    },
  );

  for (final caso in ['HTTP 500', 'sem conexão']) {
    test('Falha $caso deve preservar sessão e perfil coerentes', () async {
      await entrar('a@example.com');
      servidor.falharLogout = caso == 'HTTP 500';
      servidor.falharRede = caso == 'sem conexão';
      await expectLater(controller.sair(), throwsA(isA<AuthException>()));
      expect(controller.clienteLogado?.id, 1);
      expect(
        Supabase.instance.client.auth.currentUser?.id,
        idContaA,
        reason:
            'O requisito exige manter a sessão quando o logout falha. '
            'O SDK não pode ficar desconectado enquanto a tela mantém o perfil.',
      );
      expect(Supabase.instance.client.auth.currentSession, isNotNull);
    });
  }
}
