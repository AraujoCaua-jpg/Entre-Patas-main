import 'dart:typed_data';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_exception.dart';

typedef FotoPerfilEnviada = ({String url, String caminho, String usuarioId});

class FotoPerfilStorageService {
  static const limiteBytes = 2 * 1024 * 1024;

  static ({String extensao, String mime}) validarFoto(Uint8List foto) {
    if (foto.isEmpty || foto.lengthInBytes > limiteBytes) {
      throw const LoginException('Escolha uma foto de até 2 MB.');
    }

    // Identifica o formato pelos bytes da imagem.
    final jpeg =
        foto.length >= 3 &&
        foto[0] == 0xFF &&
        foto[1] == 0xD8 &&
        foto[2] == 0xFF;

    final png =
        foto.length >= 8 &&
        foto.take(8).join(',') == '137,80,78,71,13,10,26,10';

    final webp =
        foto.length >= 12 &&
        String.fromCharCodes(foto.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(foto.sublist(8, 12)) == 'WEBP';

    if (!jpeg && !png && !webp) {
      throw const LoginException('Escolha uma imagem JPG, PNG ou WebP.');
    }

    final extensao = jpeg
        ? 'jpg'
        : png
        ? 'png'
        : 'webp';
    final mime = jpeg
        ? 'image/jpeg'
        : png
        ? 'image/png'
        : 'image/webp';

    return (extensao: extensao, mime: mime);
  }

  static Future<FotoPerfilEnviada> enviar(
    Uint8List foto, {
    SupabaseClient? client,
  }) => _enviar(foto, client: client, prefixo: 'perfil');

  static Future<FotoPerfilEnviada> enviarAnimal(
    Uint8List foto, {
    SupabaseClient? client,
  }) => _enviar(foto, client: client, prefixo: 'animal');

  static Future<FotoPerfilEnviada> _enviar(
    Uint8List foto, {
    SupabaseClient? client,
    required String prefixo,
  }) async {
    final formato = validarFoto(foto);
    final supabase = client ?? Supabase.instance.client;
    final usuario = supabase.auth.currentUser;
    if (usuario == null) {
      throw const LoginException('Entre na sua conta antes de enviar a foto.');
    }
    final sufixo = Random.secure().nextInt(0x100000000).toRadixString(16);
    final caminho =
        '${usuario.id}/${prefixo}_${DateTime.now().microsecondsSinceEpoch}_$sufixo.${formato.extensao}';
    try {
      await supabase.storage
          .from('avatars')
          .uploadBinary(
            caminho,
            foto,
            fileOptions: FileOptions(contentType: formato.mime, upsert: false),
          );
    } on StorageException catch (erro) {
      if (const {'400', '403', '404'}.contains(erro.statusCode)) {
        throw const LoginException(
          'O envio de fotos ainda precisa ser habilitado no aplicativo.',
        );
      }
      throw const LoginException(
        'Não foi possível enviar a foto. Tente novamente.',
      );
    } catch (_) {
      throw const LoginException(
        'Não foi possível enviar a foto. Confira sua conexão.',
      );
    }
    return (
      url: supabase.storage.from('avatars').getPublicUrl(caminho),
      caminho: caminho,
      usuarioId: usuario.id,
    );
  }

  static Future<String?> enviarFoto(Uint8List? foto) async =>
      foto == null ? null : (await enviar(foto)).url;

  static Future<void> descartar(
    FotoPerfilEnviada foto,
    SupabaseClient client,
  ) async {
    if (client.auth.currentUser?.id != foto.usuarioId) return;
    // Somente o objeto novo deste envio; nunca remove a foto anterior.
    await client.storage.from('avatars').remove([foto.caminho]);
  }
}
