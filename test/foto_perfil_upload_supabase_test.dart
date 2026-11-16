import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:entre_patas/controller/cliente_controller.dart';
import 'package:entre_patas/model/cliente.dart';
import 'package:entre_patas/model/animais.dart';
import 'package:entre_patas/services/foto_perfil_pendente_service.dart';
import 'package:entre_patas/services/foto_perfil_storage_service.dart';
import 'package:entre_patas/services/login_exception.dart';
import 'package:entre_patas/services/supabase_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/foto_perfil_fixture.dart';
import 'support/logout_supabase_backend.dart';

class _Servidor {
  final auth = ServidorAuthSimulado();
  final chamadas = <http.Request>[];
  bool falharUpload = false, falharPerfil = false;
  bool falharAnimal = false;
  bool perderRespostaAnimal = false;
  Map<String, dynamic> metadados = {};
  Map<String, dynamic>? usuarioAuth;
  final perfil = <String, dynamic>{
    'id': 1,
    'auth_user_id': idContaA,
    'ativo': true,
    'nome': 'Ana',
    'sobrenome': 'Silva',
    'email': 'a@example.com',
    'telefone': '11999998888',
    'usuario': 'ana',
    'cidadeDeResidencia': 'Mogi',
    'estado': 'SP',
    'larDeAdocao': false,
    'imagem': 'https://example.com/anterior.png',
  };

  Future<http.Response> responder(http.Request request) async {
    chamadas.add(request);
    http.Response json(Object dados, [int status = 200]) => http.Response(
      jsonEncode(dados),
      status,
      request: request,
      headers: {'content-type': 'application/json'},
    );
    if (request.url.path == '/auth/v1/user' && request.method == 'PUT') {
      final atributos = jsonDecode(request.body) as Map;
      metadados.addAll(Map<String, dynamic>.from(atributos['data'] as Map));
      return json({...usuarioAuth!, 'user_metadata': metadados});
    }
    if (request.url.path.startsWith('/auth/')) {
      final resposta = await auth.responder(request);
      if (request.url.path == '/auth/v1/token') {
        final sessao = jsonDecode(resposta.body) as Map<String, dynamic>;
        usuarioAuth = Map<String, dynamic>.from(sessao['user'] as Map);
        return json({
          ...sessao,
          'user': {...usuarioAuth!, 'user_metadata': metadados},
        });
      }
      return resposta;
    }
    if (request.url.path == '/rest/v1/cliente') {
      expect(request.url.queryParameters['auth_user_id'], 'eq.$idContaA');
      if (request.method == 'PATCH') {
        if (falharPerfil) {
          return json({
            'code': '42501',
            'message': 'Sem permissão simulada',
          }, 403);
        }
        perfil.addAll(
          Map<String, dynamic>.from(jsonDecode(request.body) as Map),
        );
        return json(perfil);
      }
      return json([perfil]);
    }
    if (request.url.path == '/rest/v1/animal') {
      if (perderRespostaAnimal) throw http.ClientException('Conexão perdida');
      if (falharAnimal) {
        return json({'code': '42501', 'message': 'Sem permissão'}, 403);
      }
      final dados = jsonDecode(request.body) as Map;
      return json({'id': 42, 'id_cliente': 1, ...dados});
    }
    if (request.url.path.startsWith('/storage/v1/object/avatars/')) {
      expect(request.method, 'POST');
      expect(
        request.url.path,
        startsWith('/storage/v1/object/avatars/$idContaA/'),
      );
      expect(
        request.headers['content-type'],
        startsWith('multipart/form-data'),
      );
      expect(
        latin1.decode(request.bodyBytes).toLowerCase(),
        contains('content-type: image/png'),
      );
      if (falharUpload) {
        return json({
          'statusCode': '403',
          'error': 'Unauthorized',
          'message': 'Sem permissão',
        }, 403);
      }
      return json({
        'Key': request.url.path.substring('/storage/v1/object/'.length),
      });
    }
    if (request.url.path == '/storage/v1/object/avatars' &&
        request.method == 'DELETE') {
      final dados = jsonDecode(request.body) as Map;
      final caminhos = (dados['prefixes'] as List).cast<String>();
      expect(caminhos.single, startsWith('$idContaA/'));
      expect(caminhos.single, isNot(contains('anterior')));
      return json([
        {'name': caminhos.single},
      ]);
    }
    fail('Requisição inesperada: ${request.method} ${request.url.path}');
  }

  List<http.Request> get uploads => chamadas
      .where((r) => r.method == 'POST' && r.url.path.startsWith('/storage/'))
      .toList();
  List<http.Request> get patches =>
      chamadas.where((r) => r.method == 'PATCH').toList();
  List<http.Request> get exclusoes =>
      chamadas.where((r) => r.method == 'DELETE').toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Servidor servidor;
  late SupabaseService service;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    servidor = _Servidor();
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
  Future<void> entrar() async {
    await Supabase.instance.client.auth.signInWithPassword(
      email: 'a@example.com',
      password: 'senha-simulada',
    );
  }

  Cliente edicao() =>
      Cliente.fromJson(servidor.perfil)..fotoCadastro = fotoPng();

  Animal animal() => Animal(
    id: 42,
    nome: 'Mel',
    idade: 2,
    imageUrl: 'https://example.com/anterior.png',
    fotoCadastro: fotoPng(),
    tipo: 'Cachorro',
    energia: 'Médio',
    porte: 'Pequeno',
    convivencia: 'Boa',
    carencia: 'Baixa',
    descricao: 'Dócil',
    sexo: 'Fêmea',
    status: 'Disponível',
    idCliente: 1,
  );

  test('publica animal com arquivo e persiste somente sua URL', () async {
    await entrar();
    final novo = animal()..id = 0;
    await service.publicarAnimal(novo);
    expect(servidor.uploads.single.url.path, contains('/$idContaA/animal_'));
    final requisicao = servidor.chamadas.singleWhere(
      (r) => r.url.path == '/rest/v1/animal',
    );
    final dados = jsonDecode(requisicao.body) as Map;
    expect(dados['imagem'], novo.imageUrl);
    expect(dados['imagem'], contains('/public/avatars/$idContaA/animal_'));
    expect(dados.containsKey('fotoCadastro'), isFalse);
    expect(novo.fotoCadastro, isNull);
    expect(novo.id, 42);
  });

  test('troca foto do animal filtrando por proprietário', () async {
    await entrar();
    final existente = animal();
    await service.editarAnimalSupabase(existente);
    final patch = servidor.patches.single;
    expect(patch.url.queryParameters['id_cliente'], 'eq.1');
    expect(patch.url.queryParameters['id'], 'eq.42');
    expect((jsonDecode(patch.body) as Map)['imagem'], existente.imageUrl);
    expect(servidor.exclusoes, isEmpty);
  });

  test('upload rejeitado não publica animal nem perde seleção', () async {
    await entrar();
    servidor.falharUpload = true;
    final novo = animal();
    await expectLater(
      service.publicarAnimal(novo),
      throwsA(isA<LoginException>()),
    );
    expect(
      servidor.chamadas.where((r) => r.url.path == '/rest/v1/animal'),
      isEmpty,
    );
    expect(novo.fotoCadastro, isNotNull);
    expect(novo.imageUrl, 'https://example.com/anterior.png');
  });

  test('rejeição do animal descarta apenas o arquivo novo', () async {
    await entrar();
    servidor.falharAnimal = true;
    await expectLater(
      service.publicarAnimal(animal()),
      throwsA(isA<PostgrestException>()),
    );
    expect(servidor.exclusoes, hasLength(1));
  });

  test(
    'resposta perdida do animal conserva arquivo possivelmente vinculado',
    () async {
      await entrar();
      servidor.perderRespostaAnimal = true;
      await expectLater(service.publicarAnimal(animal()), throwsA(anything));
      expect(servidor.exclusoes, isEmpty);
    },
  );

  test('animal sem foto mantém URL legada sem upload', () async {
    await entrar();
    final novo = animal()..fotoCadastro = null;
    await service.publicarAnimal(novo);
    expect(servidor.uploads, isEmpty);
    expect(novo.imageUrl, 'https://example.com/anterior.png');
  });

  test('não envia arquivo sem autenticação', () async {
    await expectLater(
      FotoPerfilStorageService.enviar(fotoPng()),
      throwsA(isA<LoginException>()),
    );
    expect(servidor.chamadas, isEmpty);
  });

  test('envia bytes na pasta Auth e salva somente a URL pública no perfil', () async {
    await entrar();
    final cliente = edicao();
    final atualizado = await service.editarMeuPerfilSupabase(cliente);
    expect(servidor.uploads, hasLength(1));
    final corpo = servidor.uploads.single.bodyBytes;
    final inicioPng = corpo.indexOf(137);
    expect(inicioPng, greaterThanOrEqualTo(0));
    expect(corpo.sublist(inicioPng, inicioPng + fotoPng().length), fotoPng());
    expect(
      atualizado.imageUrl,
      startsWith(
        'https://example.supabase.co/storage/v1/object/public/avatars/$idContaA/',
      ),
    );
    final patch = jsonDecode(servidor.patches.single.body) as Map;
    expect(patch['imagem'], atualizado.imageUrl);
    expect(patch.containsKey('fotoBase64'), isFalse);
    expect(cliente.fotoCadastro, isNull);
    expect(servidor.exclusoes, isEmpty);
  });

  test(
    'falha de upload preserva foto anterior e não altera o perfil',
    () async {
      await entrar();
      servidor.falharUpload = true;
      await expectLater(
        service.editarMeuPerfilSupabase(edicao()),
        throwsA(isA<LoginException>()),
      );
      expect(servidor.perfil['imagem'], 'https://example.com/anterior.png');
      expect(servidor.patches, isEmpty);
    },
  );

  test('remover foto não recupera a URL antiga dos metadados Auth', () async {
    servidor.metadados = {'imagem': 'https://example.com/antiga.png'};
    await entrar();
    final cliente = Cliente.fromJson(servidor.perfil)..imageUrl = null;
    await service.editarMeuPerfilSupabase(cliente);
    expect(servidor.perfil['imagem'], isNull);
    expect((await service.buscarMeuPerfilSupabase()).imageUrl, isNull);
    expect(servidor.metadados['imagem'], isNull);
    expect(servidor.uploads, isEmpty);
  });

  test('falha de PATCH descarta só o objeto recém-enviado', () async {
    await entrar();
    servidor.falharPerfil = true;
    await expectLater(
      service.editarMeuPerfilSupabase(edicao()),
      throwsA(isA<LoginException>()),
    );
    expect(servidor.exclusoes, hasLength(1));
    expect(servidor.perfil['imagem'], 'https://example.com/anterior.png');
  });

  test(
    'login envia foto pendente apenas do próprio Auth e não repete o envio',
    () async {
      servidor.perfil['imagem'] = null;
      final pendentes = FotoPerfilPendenteService();
      await pendentes.guardar(idContaA, fotoPng());
      final controller = ClienteController();
      try {
        await controller.entrar('a@example.com', 'senha-simulada');
        expect(controller.avisoFotoLogin, isNull);
        expect(
          controller.clienteLogado!.imageUrl,
          contains('/avatars/$idContaA/'),
        );
        expect(await pendentes.carregar(idContaA), isNull);
        expect(servidor.uploads, hasLength(1));
        await controller.entrar('a@example.com', 'senha-simulada');
        expect(servidor.uploads, hasLength(1));
      } finally {
        controller.dispose();
      }
    },
  );

  test('foto pendente de outra conta não é carregada nem enviada', () async {
    await FotoPerfilPendenteService().guardar(idContaB, fotoPng());
    await entrar();
    expect(await service.finalizarFotoPendenteCadastro(), isNull);
    expect(servidor.uploads, isEmpty);
    expect(await FotoPerfilPendenteService().carregar(idContaB), isNotNull);
  });

  test('trocar de conta enquanto lê a pendência não envia a foto da conta anterior', () async {
    await entrar();
    final pendente = _PendenteLenta();
    final servicoLento = SupabaseService(fotoPendente: pendente);
    final envio = servicoLento.finalizarFotoPendenteCadastro();
    final expectativa = expectLater(envio, throwsA(isA<LoginException>()));
    await pendente.iniciou.future;
    await Supabase.instance.client.auth.signInWithPassword(
      email: 'b@example.com',
      password: 'senha-simulada',
    );
    pendente.resposta.complete(fotoPng());
    await expectativa;
    expect(servidor.uploads, isEmpty);
    expect(servidor.patches, isEmpty);
  });

  test('upload indisponível não impede login e conserva foto para tentar novamente', () async {
    servidor.perfil['imagem'] = null;
    servidor.falharUpload = true;
    await FotoPerfilPendenteService().guardar(idContaA, fotoPng());
    final controller = ClienteController();
    try {
      await controller.entrar('a@example.com', 'senha-simulada');
      expect(controller.clienteLogado, isNotNull);
      expect(controller.avisoFotoLogin, contains('foto ficou pendente'));
      expect(await FotoPerfilPendenteService().carregar(idContaA), isNotNull);
    } finally {
      controller.dispose();
    }
  });

  test(
    'foto já alterada manualmente não é sobrescrita por pendência antiga',
    () async {
      await FotoPerfilPendenteService().guardar(idContaA, fotoPng());
      await entrar();
      expect(
        await service.finalizarFotoPendenteCadastro(),
        'https://example.com/anterior.png',
      );
      expect(servidor.uploads, isEmpty);
      expect(await FotoPerfilPendenteService().carregar(idContaA), isNull);
    },
  );
}

class _PendenteLenta extends FotoPerfilPendenteService {
  final iniciou = Completer<void>();
  final resposta = Completer<Uint8List?>();
  @override
  Future<Uint8List?> carregar(String usuarioId) {
    iniciou.complete();
    return resposta.future;
  }
}
