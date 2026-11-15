import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'support/logout_supabase_backend.dart';

void main() {
  for (final caso in [
    ('sem filtro', <String, String>{}, [10, 20]),
    ('próprios da conta A', {'id_cliente': 'eq.1'}, [10]),
    ('feed da conta A', {'id_cliente': 'neq.1'}, [20]),
    ('perfil da conta B', {'id_cliente': 'eq.2'}, [20]),
    ('feed da conta B', {'id_cliente': 'neq.2'}, [10]),
    ('ficha individual', {'id': 'eq.20'}, [20]),
    (
      'ficha excluída pelo feed',
      {'id': 'eq.10', 'id_cliente': 'neq.1'},
      <int>[],
    ),
    ('paginação', {'offset': '1', 'limit': '1'}, [20]),
  ]) {
    test('Fixture de animais respeita ${caso.$1}', () async {
      final servidor = ServidorAuthSimulado()..usuario = idContaA;
      final resposta = await servidor.responder(
        http.Request(
          'GET',
          Uri.https('example.supabase.co', '/rest/v1/animal', caso.$2),
        ),
      );
      final animais = jsonDecode(resposta.body) as List;
      expect(animais.map((animal) => animal['id']), caso.$3);
    });
  }
}
