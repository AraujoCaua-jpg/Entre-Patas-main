import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class FotoPerfilStorageService {
  static Future<String?> enviarFoto(Uint8List? foto) async {
    if (foto == null) return null;

    if (foto.lengthInBytes > 5 * 1024 * 1024) {
      throw Exception('A foto deve ter no máximo 5 MB.');
    }

    final supabase = Supabase.instance.client;
    final usuario = supabase.auth.currentUser;

    if (usuario == null) {
      throw Exception('Faça login antes de enviar a foto.');
    }

    // Identifica o formato pelos bytes da imagem.
    final jpeg =
        foto.length >= 3 &&
        foto[0] == 0xFF &&
        foto[1] == 0xD8 &&
        foto[2] == 0xFF;

    final png =
        foto.length >= 8 &&
        foto[0] == 0x89 &&
        foto[1] == 0x50 &&
        foto[2] == 0x4E &&
        foto[3] == 0x47;

    final webp =
        foto.length >= 12 &&
        String.fromCharCodes(foto.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(foto.sublist(8, 12)) == 'WEBP';

    if (!jpeg && !png && !webp) {
      throw Exception('Formato de imagem não permitido.');
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

    final caminho =
        '${usuario.id}/perfil_${DateTime.now().microsecondsSinceEpoch}.$extensao';

    await supabase.storage
        .from('avatars')
        .uploadBinary(
          caminho,
          foto,
          fileOptions: FileOptions(contentType: mime, upsert: false),
        );

    return supabase.storage.from('avatars').getPublicUrl(caminho);
  }
}
