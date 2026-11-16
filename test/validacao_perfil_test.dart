import 'package:entre_patas/model/cliente.dart';
import 'package:entre_patas/model/estados_brasil.dart';
import 'package:entre_patas/services/login_exception.dart';
import 'package:entre_patas/services/validacao_perfil.dart';
import 'package:flutter_test/flutter_test.dart';

Cliente perfil() => Cliente(
  id: 1,
  nome: 'Ana',
  sobrenome: 'Silva',
  email: 'ana@example.com',
  telefone: '(11) 99999-8888',
  cidadeDeResidencia: 'Mogi',
  usuario: 'ana_1',
  estado: 'SP',
);

void main() {
  test('e-mail e usuário compartilham as regras dos formulários', () {
    expect(emailValido(' ana@example.com '), isTrue);
    for (final email in ['', 'ana', 'ana@exemplo', 'ana @example.com']) {
      expect(emailValido(email), isFalse);
    }
    expect(usuarioValido('ana_1'), isTrue);
    expect(usuarioValido('ana silva'), isFalse);
    expect(usuarioValido('@ana'), isFalse);
  });

  test('telefone aceita DDD com 10 ou 11 dígitos, inclusive formatado', () {
    expect(telefoneValido('(11) 3333-4444'), isTrue);
    expect(telefoneValido('(11) 99999-8888'), isTrue);
    expect(telefoneValido('123456789'), isFalse);
    expect(telefoneValido('123456789012'), isFalse);
  });

  test('perfil válido preserva dados e foto por URL sem conversão', () {
    final cliente = perfil()..imageUrl = 'https://example.com/foto.png';
    final antes = cliente.toJson();
    validarPerfil(cliente);
    expect(cliente.toJson(), antes);
    expect(estadosBrasil, hasLength(27));
  });

  test('perfil rejeita UF desconhecida, endereço ausente e foto inválida', () {
    final uf = perfil()..estado = 'XX';
    final lar = perfil()..larDeAdocao = true;
    final foto = perfil()..imageUrl = 'javascript:alert(1)';
    for (final cliente in [uf, lar, foto]) {
      expect(() => validarPerfil(cliente), throwsA(isA<LoginException>()));
    }
    lar.endereco = 'Rua de demonstração';
    expect(() => validarPerfil(lar), returnsNormally);
  });
}
