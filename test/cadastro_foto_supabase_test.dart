import 'dart:convert';

import 'package:entre_patas/controller/clientes_scope.dart';
import 'package:entre_patas/model/cliente.dart';
import 'package:entre_patas/services/login_exception.dart';
import 'package:entre_patas/services/foto_perfil_url.dart';
import 'package:entre_patas/services/supabase_service.dart';
import 'package:entre_patas/view/autenticacao/cadastro/cadastroUsuario.dart';
import 'package:entre_patas/view/autenticacao/cadastro/cadastroUsuario2.dart';
import 'package:entre_patas/view/core/foto_perfil_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Cliente _cliente({String? imagem}) => Cliente(
  id: 0,
  nome: 'Pessoa',
  sobrenome: 'Fictícia',
  email: 'cadastro@example.com',
  telefone: '(11) 99999-8888',
  cidadeDeResidencia: 'Cidade fictícia',
  usuario: 'cadastro_ficticio',
  estado: 'SP',
  imageUrl: imagem,
);

class _ServidorCadastro {
  final requisicoes = <http.Request>[];

  Future<http.Response> responder(http.Request request) async {
    requisicoes.add(request);
    if (request.url.path != '/auth/v1/signup') {
      fail('Rota inesperada: ${request.method} ${request.url.path}');
    }

    final dados = jsonDecode(request.body) as Map<String, dynamic>;
    final user = {
      'id': '11111111-1111-4111-8111-111111111111',
      'aud': 'authenticated',
      'email': dados['email'],
      'created_at': '2026-01-01T00:00:00Z',
      'app_metadata': {'provider': 'email'},
      'user_metadata': dados['data'],
    };
    return http.Response(
      jsonEncode({
        'id': user['id'],
        'aud': user['aud'],
        'email': user['email'],
        'created_at': user['created_at'],
        'app_metadata': user['app_metadata'],
        'user_metadata': user['user_metadata'],
      }),
      200,
      request: request,
      headers: {'content-type': 'application/json'},
    );
  }

  List<http.Request> get cadastros => requisicoes
      .where((request) => request.url.path == '/auth/v1/signup')
      .toList();

  List<http.Request> get uploads => requisicoes
      .where((request) => request.url.path.startsWith('/storage/v1/object/'))
      .toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _ServidorCadastro servidor;
  late SupabaseService service;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (call) async => call.method == 'getAll' ? <String, Object>{} : true,
        );
    servidor = _ServidorCadastro();
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-key',
      httpClient: MockClient(servidor.responder),
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
    );
    service = SupabaseService();
  });

  tearDown(() async => Supabase.instance.dispose());

  test('Cadastro sem foto envia imagem nula e não acessa Storage', () async {
    await service.cadastrarClienteSupabase(_cliente(), 'senha-simulada');

    expect(servidor.cadastros, hasLength(1));
    final dados = jsonDecode(servidor.cadastros.single.body) as Map;
    expect(dados['email'], 'cadastro@example.com');
    expect(dados['data']['telefone'], '11999998888');
    expect(dados['data']['origem_cadastro'], 'entre_patas');
    expect(dados['data']['imagem'], isNull);
    expect(servidor.uploads, isEmpty);
  });

  test('Cadastro envia URL de imagem como metadado sem fazer upload', () async {
    const url = 'https://example.com/foto-perfil.jpg';
    await service.cadastrarClienteSupabase(
      _cliente(imagem: url),
      'senha-simulada',
    );

    final dados = jsonDecode(servidor.cadastros.single.body) as Map;
    expect(dados['data']['imagem'], url);
    expect(servidor.uploads, isEmpty);
    expect(
      servidor.requisicoes.any(
        (request) => request.url.path == '/auth/v1/user',
      ),
      isFalse,
    );
  });

  test('Cadastro recusa URL inválida antes de criar a conta', () async {
    await expectLater(
      service.cadastrarClienteSupabase(
        _cliente(imagem: 'javascript:alert(1)'),
        'senha-simulada',
      ),
      throwsA(isA<LoginException>()),
    );
    expect(servidor.cadastros, isEmpty);
  });

  test('Validador aceita somente URL HTTP ou HTTPS com host', () {
    expect(FotoPerfilUrl.valida('https://example.com/foto.jpg'), isTrue);
    expect(FotoPerfilUrl.valida('http://example.com/foto.jpg'), isTrue);
    expect(FotoPerfilUrl.valida('javascript:alert(1)'), isFalse);
    expect(FotoPerfilUrl.valida('https:///foto.jpg'), isFalse);
    expect(FotoPerfilUrl.valida(null), isFalse);
  });

  testWidgets('Campo aceita e permite remover o link da foto', (tester) async {
    String? url;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FotoPerfilPicker(onChanged: (value) => url = value),
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextField),
      'https://example.com/foto.jpg',
    );
    await tester.pump();
    expect(url, 'https://example.com/foto.jpg');
    expect(find.text('Link da imagem (opcional)'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();
    expect(url, isNull);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
  });

  testWidgets('Primeira etapa mantém a URL para as demais etapas', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ClientesScope(child: MaterialApp(home: CadastroUsuarioScreen())),
    );

    final campos = find.byType(TextField);
    for (final (indice, texto) in [
      (0, 'https://example.com/perfil.png'),
      (1, 'Ana'),
      (2, 'Silva'),
      (3, 'ana@example.com'),
      (4, '(11) 99999-8888'),
    ]) {
      await tester.ensureVisible(campos.at(indice));
      await tester.enterText(campos.at(indice), texto);
      await tester.pump();
    }

    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    final etapa = tester.widget<CadastroUsuario2Screen>(
      find.byType(CadastroUsuario2Screen),
    );
    expect(etapa.cliente.imageUrl, 'https://example.com/perfil.png');
  });
}
