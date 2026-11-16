/// Aplica os filtros adicionais ao conjunto já autorizado/localizado pela RPC.
/// Não substitui a seleção geográfica nem as permissões do servidor.
List<Map<String, dynamic>> filtrarAnimaisProximos(
  List<Map<String, dynamic>> animais, {
  String? tipo,
  Map<String, String> filtros = const {},
  int? clienteId,
  int? animalId,
}) {
  final especie = tipo ?? filtros['tipo'];
  final termo = filtros['q']?.trim().toLowerCase() ?? '';
  final responsavel = clienteId ?? int.tryParse(filtros['id_cliente'] ?? '');
  final resultado = animais.where((animal) {
    if (responsavel != null && animal['id_cliente'] != responsavel) {
      return false;
    }
    if (animalId != null && animal['id'] != animalId) return false;
    if (especie == 'Outros') {
      if (const {'Cachorro', 'Gato'}.contains(animal['tipo'])) return false;
    } else if (especie != null &&
        especie.isNotEmpty &&
        animal['tipo'] != especie) {
      return false;
    }
    if (termo.isNotEmpty &&
        !(animal['nome']?.toString().toLowerCase().contains(termo) ?? false)) {
      return false;
    }
    for (final campo in [
      'sexo',
      'porte',
      'energia',
      'convivencia',
      'carencia',
    ]) {
      final valor = filtros[campo];
      if (valor != null && valor.isNotEmpty && animal[campo] != valor) {
        return false;
      }
    }
    return true;
  }).toList();
  resultado.sort((a, b) {
    final nome = '${a['nome'] ?? ''}'.compareTo('${b['nome'] ?? ''}');
    return nome != 0 ? nome : (a['id'] as num).compareTo(b['id'] as num);
  });
  return resultado;
}
