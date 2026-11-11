import 'dart:developer' as developer;

import '../model/adocao.dart';

class AdocaoController {
  List<Adocao> adocoes = [];

  // Cadastrar adoção
  void cadastrarAdocao(Adocao adocao) {
    adocoes.add(adocao);
    developer.log('Adoção cadastrada com sucesso: ${adocao.id}');
  }

  // Buscar adoção pelo ID
  Adocao? buscarAdocao(int id) {
    for (final adocao in adocoes) {
      if (adocao.id == id) {
        return adocao;
      }
    }
    return null;
  }

  // Excluir adoção
  void excluirAdocao(int id) {
    adocoes.removeWhere((adocao) => adocao.id == id);
  }

  // Listar adoções
  List<Adocao> getAllAdocoes() {
    return adocoes;
  }
}
