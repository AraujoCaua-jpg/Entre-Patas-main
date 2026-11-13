import 'dart:convert';

Map<String, bool> requisitosSenha(String senha) => {
  '8 caracteres': senha.runes.length >= 8,
  '1 letra maiúscula': RegExp(r'[A-Z]').hasMatch(senha),
  '1 letra minúscula': RegExp(r'[a-z]').hasMatch(senha),
  '1 número': RegExp(r'[0-9]').hasMatch(senha),
  '1 caractere especial': RegExp(r'[^a-zA-Z0-9\s]').hasMatch(senha),
};

String? validarSenha(String senha) {
  if (utf8.encode(senha).length > 72)
    return 'A senha deve ter no máximo 72 bytes. Letras acentuadas podem ocupar mais de um byte.';
  if (senha.contains('\u0000') ||
      !requisitosSenha(senha).values.every((v) => v)) {
    return 'A senha deve atender a todos os requisitos indicados.';
  }
  return null;
}
