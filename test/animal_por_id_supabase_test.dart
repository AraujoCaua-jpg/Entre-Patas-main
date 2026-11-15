import 'dart:convert';

import 'package:entre_patas/services/login_exception.dart';
import 'package:entre_patas/services/supabase_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<http.Request> requests;
  late List<Map<String, dynamic>> resposta;
  late SupabaseService service;
  bool negar = false;

  setUp(() async {
    requests = [];
    negar = false;
    resposta = [
      {
        'id': 9,
        'id_cliente': 1,
        'nome': 'Animal próprio',
        'idade': 2,
        'status': 'Adotado',
        'ativo': true,
      },
    ];
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
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode(
            negar
                ? {'code': '42501', 'message': 'permission denied'}
                : resposta,
          ),
          negar ? 403 : 200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    service = SupabaseService();
  });
  tearDown(() async => Supabase.instance.dispose());

  test('Ficha consulta somente ID sem filtros de recomendação', () async {
    final animal = await service.buscarAnimalPorIdSupabase(9);
    expect(animal.id, 9);
    expect(animal.status, 'Adotado');
    expect(requests.single.url.path, '/rest/v1/animal');
    expect(requests.single.url.queryParameters, {'select': '*', 'id': 'eq.9'});
  });

  test(
    'Ficha retorna mensagem de ausência quando a RLS não revela o ID',
    () async {
      resposta = [];
      await expectLater(
        service.buscarAnimalPorIdSupabase(9),
        throwsA(isA<LoginException>()),
      );
    },
  );

  test('Ficha não contorna erro de permissão do servidor', () async {
    negar = true;
    await expectLater(
      service.buscarAnimalPorIdSupabase(9),
      throwsA(isA<PostgrestException>()),
    );
    expect(requests, hasLength(1));
  });

  test('Ficha rejeita ID inválido antes de acessar o servidor', () async {
    await expectLater(
      service.buscarAnimalPorIdSupabase(0),
      throwsA(isA<LoginException>()),
    );
    expect(requests, isEmpty);
  });
}
