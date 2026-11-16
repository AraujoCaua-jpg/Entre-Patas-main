import '../model/cliente.dart';
import '../model/estados_brasil.dart';
import 'foto_perfil_url.dart';
import 'login_exception.dart';

bool emailValido(String valor) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(valor.trim());

bool usuarioValido(String valor) =>
    RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(valor.trim());

bool telefoneValido(String valor) =>
    RegExp(r'^\d{10,11}$').hasMatch(valor.replaceAll(RegExp(r'\D'), ''));

void validarPerfil(Cliente cliente) {
  final campos = {
    'nome': (cliente.nome, 50),
    'sobrenome': (cliente.sobrenome, 100),
    'e-mail': (cliente.email, 100),
    'usuário': (cliente.usuario, 50),
    'cidade': (cliente.cidadeDeResidencia, 100),
  };
  for (final campo in campos.entries) {
    final texto = campo.value.$1.trim();
    if (texto.isEmpty || texto.runes.length > campo.value.$2) {
      throw LoginException('Confira o campo ${campo.key}.');
    }
  }
  if (!emailValido(cliente.email)) {
    throw const LoginException('Digite um e-mail válido.');
  }
  if (!telefoneValido(cliente.telefone)) {
    throw const LoginException('Digite um telefone com DDD.');
  }
  if (!usuarioValido(cliente.usuario)) {
    throw const LoginException('Use apenas letras, números e underline (_).');
  }
  if (!estadosBrasil.containsKey(cliente.estado)) {
    throw const LoginException('Selecione o estado.');
  }
  if (cliente.larDeAdocao && (cliente.endereco?.trim().isEmpty ?? true)) {
    throw const LoginException('Informe o endereço do lar de adoção.');
  }
  if ((cliente.endereco?.runes.length ?? 0) > 255 ||
      (cliente.imageUrl?.runes.length ?? 0) > 255) {
    throw const LoginException(
      'Endereço e imagem devem ter até 255 caracteres.',
    );
  }
  if (cliente.imageUrl != null &&
      cliente.imageUrl!.trim().isNotEmpty &&
      !FotoPerfilUrl.valida(cliente.imageUrl)) {
    throw const LoginException(
      'Digite um link de imagem válido (http ou https).',
    );
  }
}
