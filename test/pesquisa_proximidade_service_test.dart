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
  late SupabaseService service;
  late List<http.Request> chamadas;
  late List<Map<String, dynamic>> animais;
  int status = 200;
  const localizacao = {'estado': 'SP', 'cidade': 'Mogi'};
  setUp(() async {
    chamadas = [];
    status = 200;
    animais = List.generate(
      65,
      (i) => {
        'id': i + 1,
        'id_cliente': 2,
        'nome': 'Animal ${i.toString().padLeft(3, '0')}',
        'tipo': i.isEven ? 'Gato' : 'Cachorro',
        'sexo': 'Fêmea',
        'porte': 'Pequeno',
        'idade': 2,
      },
    );
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
        chamadas.add(request);
        return http.Response(
          jsonEncode(
            status == 200
                ? animais
                : {'code': 'PGRST202', 'message': 'ausente'},
          ),
          status,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    service = SupabaseService();
  });
  tearDown(() async => Supabase.instance.dispose());

  test(
    'proximidade combina nome, espécie, sexo e porte antes de paginar',
    () async {
      final resultado = await service.buscarAnimais(
        tipo: 'Gato',
        filtros: {
          ...localizacao,
          'q': 'ANIMAL 00',
          'sexo': 'Fêmea',
          'porte': 'Pequeno',
        },
      );
      expect(resultado.map((a) => a['id']), [1, 3, 5, 7, 9]);
      expect(chamadas.single.url.path, '/rest/v1/rpc/ep_animais_perto_de_mim');
      expect(jsonDecode(chamadas.single.body), isEmpty);
      expect(
        await service.buscarAnimais(filtros: {...localizacao, 'sexo': 'Macho'}),
        isEmpty,
      );
    },
  );

  test('páginas próximas não repetem a primeira página', () async {
    final primeira = await service.buscarAnimais(filtros: localizacao);
    final segunda = await service.buscarAnimais(
      filtros: localizacao,
      pagina: 2,
    );
    expect(primeira, hasLength(50));
    expect(segunda, hasLength(15));
    expect(
      {...primeira, ...segunda}.map((a) => a['id']).toSet(),
      hasLength(65),
    );
    expect(segunda.first['id'], 51);
  });

  test(
    'consulta completa da proximidade faz apenas uma RPC mesmo com mais de 50',
    () async {
      final resultado = await service.buscarAnimaisModel(filtros: localizacao);
      expect(resultado, hasLength(65));
      expect(chamadas, hasLength(1));
    },
  );

  test('nome igual usa ID para ordenação estável', () async {
    animais = [
      {...animais.first, 'id': 8, 'nome': 'Lua'},
      {...animais.first, 'id': 3, 'nome': 'Lua'},
    ];
    final resultado = await service.buscarAnimais(filtros: localizacao);
    expect(resultado.map((a) => a['id']), [3, 8]);
  });

  test(
    'RPC ausente retorna erro claro sem tentar PHP ou outra tabela',
    () async {
      status = 404;
      await expectLater(
        service.buscarAnimais(filtros: localizacao),
        throwsA(isA<LoginException>()),
      );
      expect(chamadas, hasLength(1));
    },
  );

  test('consulta comum usa ordenação estável para paginar', () async {
    await service.buscarAnimais(pagina: 2);
    expect(
      chamadas.single.url.queryParameters['order'],
      'nome.desc.nullslast,id.desc.nullslast',
    );
    expect(chamadas.single.url.queryParameters['offset'], '50');
  });
}
