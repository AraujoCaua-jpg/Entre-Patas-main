import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import 'foto_perfil_storage_service.dart';
import 'login_exception.dart';

/// A confirmação de e-mail pode encerrar o cadastro sem uma sessão de upload.
/// Mantém a foto neste navegador, vinculada ao ID Auth retornado pelo cadastro.
class FotoPerfilPendenteService {
  String _chave(String usuarioId) => 'entre_patas.foto_pendente.v1.$usuarioId';

  Future<void> guardar(String usuarioId, Uint8List foto) async {
    FotoPerfilStorageService.validarFoto(foto);
    final preferencias = await SharedPreferences.getInstance();
    final salvou = await preferencias.setString(
      _chave(usuarioId),
      base64Encode(foto),
    );
    if (!salvou) {
      throw const LoginException(
        'Não foi possível guardar a foto neste navegador.',
      );
    }
  }

  Future<Uint8List?> carregar(String usuarioId) async {
    final preferencias = await SharedPreferences.getInstance();
    final registro = preferencias.getString(_chave(usuarioId));
    if (registro == null) return null;
    try {
      final foto = base64Decode(registro);
      FotoPerfilStorageService.validarFoto(foto);
      return foto;
    } on FormatException {
      throw const LoginException(
        'Selecione novamente sua foto em Editar perfil.',
      );
    }
  }

  Future<void> remover(String usuarioId) async {
    final preferencias = await SharedPreferences.getInstance();
    if (!await preferencias.remove(_chave(usuarioId))) {
      throw const LoginException(
        'Não foi possível concluir a atualização local da foto.',
      );
    }
  }
}
