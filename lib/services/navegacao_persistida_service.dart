import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavegacaoPersistidaService {
  static final abaAtual = ValueNotifier<int>(0);
  Future<void>? _fila;

  Future<Map<String, dynamic>?> carregar(String usuarioId) async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString('entre_patas.pagina.v1.$usuarioId');
    if (texto == null || texto.length > 32768) return null;
    try {
      final dados = jsonDecode(texto);
      return dados is Map<String, dynamic> ? dados : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> salvar(String usuarioId, Map<String, dynamic>? pagina) {
    Future<void> gravar() async {
      final prefs = await SharedPreferences.getInstance();
      final chave = 'entre_patas.pagina.v1.$usuarioId';
      final sucesso = pagina == null
          ? await prefs.remove(chave)
          : await prefs.setString(chave, jsonEncode(pagina));
      if (!sucesso) throw StateError('Não foi possível lembrar a página.');
    }

    final anterior = _fila;
    final tarefa = anterior == null
        ? gravar()
        : anterior.catchError((Object _) {}).then((_) => gravar());
    _fila = tarefa;
    return tarefa;
  }
}
