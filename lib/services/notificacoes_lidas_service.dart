import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'login_exception.dart';

/// Guarda a leitura neste navegador/aparelho, separada por perfil do app.
class NotificacoesLidasService {
  Future<void>? _ultimaGravacao;
  bool _cacheInvalido = false;

  Future<SharedPreferences> _abrirPreferencias() async {
    final preferencias = await SharedPreferences.getInstance();
    if (_cacheInvalido) {
      await preferencias.reload();
      _cacheInvalido = false;
    }
    return preferencias;
  }

  String _chave(int clienteId) =>
      'entre_patas.notificacoes_lidas.v1.$clienteId';

  Set<(int, String)> _decodificar(List<String> registros) {
    final lidas = <(int, String)>{};
    for (final registro in registros) {
      try {
        final valor = jsonDecode(registro);
        if (valor is List &&
            valor.length == 2 &&
            valor[0] is int &&
            (valor[0] as int) > 0 &&
            valor[1] is String &&
            (valor[1] as String).isNotEmpty) {
          lidas.add((valor[0] as int, valor[1] as String));
        }
      } on FormatException {
        // Um registro inválido não deve apagar as demais leituras salvas.
      }
    }
    return lidas;
  }

  Future<Set<(int, String)>> carregar(int clienteId) async {
    final gravacaoPendente = _ultimaGravacao;
    if (gravacaoPendente != null) await gravacaoPendente;
    try {
      final preferencias = await _abrirPreferencias();
      return _decodificar(preferencias.getStringList(_chave(clienteId)) ?? []);
    } catch (_) {
      throw const LoginException(
        'Não foi possível carregar as notificações vistas.',
      );
    }
  }

  Future<void> marcarComoLida(int clienteId, int adocaoId, String status) {
    // Serializa cliques rápidos para não perder uma leitura ao salvar a outra.
    final gravacao = (_ultimaGravacao ?? Future<void>.value()).then((_) async {
      try {
        final preferencias = await _abrirPreferencias();
        final lidas = _decodificar(
          preferencias.getStringList(_chave(clienteId)) ?? [],
        );
        if (!lidas.add((adocaoId, status))) return;
        final salvou = await preferencias.setStringList(
          _chave(clienteId),
          lidas.map((leitura) => jsonEncode([leitura.$1, leitura.$2])).toList(),
        );
        if (!salvou) throw StateError('Gravação local não confirmada.');
      } catch (_) {
        // O plugin atualiza seu cache antes de confirmar a escrita no disco.
        // Após uma falha, recarrega o valor persistido antes de voltar a usá-lo.
        _cacheInvalido = true;
        throw const LoginException(
          'Não foi possível salvar a leitura da notificação.',
        );
      }
    });
    _ultimaGravacao = gravacao.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return gravacao;
  }
}
