import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

const idContaA = '11111111-1111-4111-8111-111111111111';
const idContaB = '22222222-2222-4222-8222-222222222222';

String _token(String id) {
  String segmento(Map<String, dynamic> dados) =>
      base64Url.encode(utf8.encode(jsonEncode(dados))).replaceAll('=', '');
  final agora = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  return '${segmento({'alg': 'HS256', 'typ': 'JWT'})}.'
      '${segmento({'sub': id, 'aud': 'authenticated', 'role': 'authenticated', 'auth_time': agora, 'exp': agora + 3600})}.'
      'assinatura-simulada';
}

class ServidorAuthSimulado {
  final requisicoes = <http.Request>[];
  bool falharLogout = false;
  bool falharRede = false;
  String? usuario;

  http.Response _json(Object dados, [int status = 200]) => http.Response(
    jsonEncode(dados),
    status,
    headers: {'content-type': 'application/json'},
  );

  Future<http.Response> responder(http.Request request) async {
    final resposta = await _responder(request);
    return http.Response.bytes(
      resposta.bodyBytes,
      resposta.statusCode,
      headers: resposta.headers,
      request: request,
    );
  }

  Future<http.Response> _responder(http.Request request) async {
    requisicoes.add(request);
    final rota = request.url.path;
    if (rota == '/auth/v1/token') {
      final corpo = jsonDecode(request.body) as Map<String, dynamic>;
      if (corpo['password'] != 'senha-simulada') {
        return _json({
          'error_code': 'invalid_credentials',
          'msg': 'Invalid login credentials',
        }, 400);
      }
      usuario = corpo['email'] == 'a@example.com' ? idContaA : idContaB;
      return _json({
        'access_token': _token(usuario!),
        'token_type': 'bearer',
        'expires_in': 3600,
        'refresh_token': 'refresh-simulado-$usuario',
        'user': {
          'id': usuario,
          'aud': 'authenticated',
          'email': corpo['email'],
          'app_metadata': {'provider': 'email'},
          'user_metadata': {},
          'created_at': '2026-01-01T00:00:00Z',
        },
      });
    }
    if (rota == '/auth/v1/logout') {
      if (falharRede) throw http.ClientException('Sem conexão simulada');
      if (falharLogout) {
        return _json({'message': 'Falha simulada no servidor'}, 500);
      }
      usuario = null;
      return http.Response('', 204);
    }
    if (rota == '/rest/v1/cliente') {
      final idAuth = request.url.queryParameters['auth_user_id'];
      final id = idAuth == 'eq.$idContaA' ? 1 : 2;
      expect(idAuth, 'eq.$usuario');
      return _json([
        {
          'id': id,
          'ativo': true,
          'nome': 'Conta $id',
          'usuario': 'conta$id',
          'email': id == 1 ? 'a@example.com' : 'b@example.com',
        },
      ]);
    }
    if (rota == '/rest/v1/questionario') {
      final id = usuario == idContaA ? 1 : 2;
      expect(request.url.queryParameters['id_cliente'], 'eq.$id');
      return _json([
        {
          'id': id,
          'id_cliente': id,
          // Cada conta prefere a espécie do animal da outra conta. Assim o
          // teste de isolamento também respeita o filtro atual da Home.
          'tipo': id == 1 ? 'Cachorro' : 'Gato',
          'sexo': 'Fêmea',
          'porte': 0,
          'energia': 1,
          'dedicacao': 4,
          'sozinho': 5,
          'imovel': 1,
          'apoio': 1,
          'compromisso': 1,
          'moradores': 1,
          'rotina': 1,
          'financeiro': 3,
          'idadeMin': 0,
          'idadeMax': 10,
          'ambiente': 'Apartamento',
          'animais': 'Não',
        },
      ]);
    }
    if (rota == '/rest/v1/animal') {
      final filtro = request.url.queryParameters['id_cliente'];
      final animalId = request.url.queryParameters['id'];
      final donos = [1, 2].where((dono) {
        if (filtro != null) {
          final partes = filtro.split('.');
          expect(partes, hasLength(2));
          expect(partes.first, isIn(['eq', 'neq']));
          final clienteId = int.parse(partes.last);
          if (partes.first == 'eq' && dono != clienteId) return false;
          if (partes.first == 'neq' && dono == clienteId) return false;
        }
        if (animalId != null) {
          expect(animalId, startsWith('eq.'));
          if (dono * 10 != int.parse(animalId.substring(3))) return false;
        }
        return true;
      });
      final animais = [
        for (final dono in donos)
          {
            'id': dono * 10,
            'id_cliente': dono,
            'idade': 2,
            'nome': 'Animal $dono',
            'tipo': dono == 1 ? 'Gato' : 'Cachorro',
            'sexo': 'Fêmea',
            'energia': 'Médio',
            'porte': 'Pequeno',
            'carencia': 'Sim',
            'convivencia': 'Sim',
            'descricao': 'Animal simulado',
            'ativo': true,
            'status': 'Disponível',
          },
      ];
      final inicio =
          int.tryParse(request.url.queryParameters['offset'] ?? '') ?? 0;
      final limite =
          int.tryParse(request.url.queryParameters['limit'] ?? '') ??
          animais.length;
      return _json(animais.skip(inicio).take(limite).toList());
    }
    if (rota == '/rest/v1/rpc/ep_buscar_animais') {
      final parametros = jsonDecode(request.body) as Map<String, dynamic>;
      final meuId = usuario == idContaA ? 1 : 2;
      final outroId = meuId == 1 ? 2 : 1;
      final proprio = parametros['p_somente_proprios'] == true;
      final animalId = parametros['p_animal_id'] as int?;
      final clienteId = parametros['p_cliente_id'] as int?;
      final donos = animalId != null
          ? [animalId ~/ 10]
          : proprio
          ? [meuId]
          : [clienteId ?? outroId];
      return _json([
        for (final dono in donos.where((id) => id == meuId || id == outroId))
          {
            'id': dono * 10,
            'id_cliente': dono,
            'idade': 2,
            'nome': 'Animal $dono',
            'tipo': dono == 1 ? 'Gato' : 'Cachorro',
            'sexo': 'Fêmea',
            'energia': 'Médio',
            'porte': 'Pequeno',
            'carencia': 'Sim',
            'convivencia': 'Sim',
            'descricao': 'Animal simulado',
            'ativo': true,
            'status': 'Disponível',
            'estado': 'SP',
            'cidadeDeResidencia': 'Mogi',
          },
      ]);
    }
    if (rota == '/rest/v1/rpc/buscar_resumo_responsavel' ||
        rota == '/rest/v1/rpc/buscar_perfil_publico') {
      final parametros = jsonDecode(request.body) as Map<String, dynamic>;
      final id = parametros['p_cliente_id'] as int;
      return _json([
        {
          'id': id,
          'nome': 'Conta $id',
          'sobrenome': 'Teste',
          'usuario': 'conta$id',
          'imagem': null,
          'estado': 'SP',
          'cidade': 'Mogi',
          'lar_de_adocao': false,
          'endereco': null,
          'telefone': null,
          'email': null,
        },
      ]);
    }
    if (rota == '/rest/v1/rpc/buscar_clientes_publicos') {
      return _json([
        {
          'id': 2,
          'nome': 'Conta 2',
          'sobrenome': 'Teste',
          'email': null,
          'telefone': null,
          'usuario': 'conta2',
          'imagem': null,
          'estado': 'SP',
          'cidadeDeResidencia': 'Mogi',
          'endereco': null,
          'larDeAdocao': false,
        },
      ]);
    }
    fail('Requisição inesperada: ${request.method} $rota');
  }
}
