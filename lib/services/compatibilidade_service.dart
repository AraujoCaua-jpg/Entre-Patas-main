import 'dart:math' as math;

import '../model/animais.dart';

class CompatibilidadeService {
  static const Map<String, int> _niveis = {
    'Baixo': 0,
    'Médio': 1,
    'Alto': 2,
    'Pequeno': 0,
    'Grande': 2,
  };

  static Map<String, dynamic>? calcular(
    Animal animal,
    Map<String, dynamic>? respostas,
  ) {
    final idadeAnimal = animal.idade;
    // Sem a idade não há dados suficientes para calcular as preferências.
    if (respostas == null || idadeAnimal == null) return null;

    final energiaAnimal = _niveis[animal.energia];
    final porteAnimal = _niveis[animal.porte];

    if (energiaAnimal == null || porteAnimal == null) {
      return null;
    }

    int? numero(String campo) {
      final valor = respostas[campo];
      if (valor is num) return valor.toInt();
      return int.tryParse(valor?.toString() ?? '');
    }

    final dedicacao = numero('dedicacao');
    final sozinho = numero('sozinho');
    final imovel = numero('imovel');
    final apoio = numero('apoio');
    final compromisso = numero('compromisso');
    final moradores = numero('moradores');
    final rotinaResposta = numero('rotina');
    final financeiro = numero('financeiro');
    final idadeMin = numero('idadeMin');
    final idadeMax = numero('idadeMax');
    final porteDesejado = numero('porte');
    final energiaDesejada = numero('energia');

    if (dedicacao == null ||
        sozinho == null ||
        imovel == null ||
        apoio == null ||
        compromisso == null ||
        moradores == null ||
        rotinaResposta == null ||
        financeiro == null ||
        idadeMin == null ||
        idadeMax == null ||
        porteDesejado == null ||
        energiaDesejada == null) {
      return null;
    }

    // ROTINA — peso de 50%
    final pontuacaoDedicacao = math.min(1.0, dedicacao / (energiaAnimal + 1));

    final companhia = animal.carencia == 'Sim' ? (sozinho - 1) / 4 : 1.0;

    final preparo =
        (imovel +
            apoio +
            compromisso +
            moradores +
            rotinaResposta +
            (financeiro - 1) / 2) /
        6;

    final rotina = (pontuacaoDedicacao + companhia + preparo) / 3 * 100;

    // AMBIENTE — peso de 30%
    double espaco;

    if (animal.tipo == 'Gato' || porteAnimal == 0) {
      espaco = 1.0;
    } else {
      switch (respostas['ambiente']) {
        case 'Casa c/ Quintal':
          espaco = 1.0;
          break;
        case 'Casa s/ Quintal':
          espaco = porteAnimal == 2 ? 0.6 : 0.8;
          break;
        case 'Apartamento':
          espaco = porteAnimal == 2 ? 0.4 : 0.6;
          break;
        default:
          espaco = 0.5;
      }
    }

    final convivencia =
        respostas['animais'] == 'Sim' && animal.convivencia != 'Sim'
        ? 0.0
        : 1.0;

    final ambiente = (espaco + convivencia) / 2 * 100;

    // PREFERÊNCIAS — peso de 20%
    final preferencias =
        ((respostas['tipo'] == animal.tipo ? 1 : 0) +
            (respostas['sexo'] == animal.sexo ? 1 : 0) +
            (idadeAnimal >= idadeMin && idadeAnimal <= idadeMax ? 1 : 0) +
            (1 - (porteDesejado - porteAnimal).abs() / 2) +
            (1 - (energiaDesejada - energiaAnimal).abs() / 2)) /
        5 *
        100;

    // RESULTADO FINAL — mesma fórmula do PHP
    final total = (rotina * 5 + ambiente * 3 + preferencias * 2) / 10;

    return {
      'rotina': rotina.round(),
      'ambiente': ambiente.round(),
      'preferencias': preferencias.round(),
      'total': total.round(),
      'versao': 1,
    };
  }
}
