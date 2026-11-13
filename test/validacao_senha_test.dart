import 'package:flutter_test/flutter_test.dart';
import 'package:entre_patas/service/validacao_senha.dart';

void main() {
  test('cadastro e troca usam limite de 72 bytes inclusive com acentos', () {
    expect(validarSenha('Aa1!${'x' * 68}'), isNull);
    expect(validarSenha('Aa1!${'á' * 34}'), isNull);
    expect(validarSenha('Aa1!${'x' * 69}'), isNotNull);
    expect(validarSenha('Aa1!${'á' * 35}'), isNotNull);
  });
  test('exige os requisitos existentes e rejeita caractere nulo', () {
    for (final senha in [
      '12345678',
      'Senha123',
      'senha!123',
      'SENHA!123',
      'Senha!abc',
      'Aa1!',
      'Senha!123\u0000',
    ]) {
      expect(validarSenha(senha), isNotNull);
    }
    expect(validarSenha('SenhaValida!123'), isNull);
  });
}
