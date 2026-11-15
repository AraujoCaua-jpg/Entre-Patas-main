class FotoPerfilUrl {
  static bool valida(String? valor) {
    final url = valor?.trim();
    if (url == null || url.isEmpty) return false;

    final uri = Uri.tryParse(url);
    return uri != null &&
        (uri.scheme.toLowerCase() == 'http' ||
            uri.scheme.toLowerCase() == 'https') &&
        uri.host.isNotEmpty;
  }
}
