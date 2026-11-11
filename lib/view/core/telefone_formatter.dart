import 'package:flutter/services.dart';

class TelefoneInputFormatter extends TextInputFormatter {
  const TelefoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final numeros = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (numeros.length > 11) return oldValue;
    if (numeros.isEmpty) return TextEditingValue.empty;

    final buffer = StringBuffer('(');
    for (var i = 0; i < numeros.length; i++) {
      if (i == 2) buffer.write(') ');
      if (i == (numeros.length > 10 ? 7 : 6)) buffer.write('-');
      buffer.write(numeros[i]);
    }
    final texto = buffer.toString();
    final cursor = newValue.selection.extentOffset;
    final antesDoCursor = newValue.text
        .substring(0, cursor.clamp(0, newValue.text.length))
        .replaceAll(RegExp(r'\D'), '')
        .length;
    var posicao = 0;
    var contagem = 0;
    while (posicao < texto.length && contagem < antesDoCursor) {
      if (RegExp(r'\d').hasMatch(texto[posicao])) contagem++;
      posicao++;
    }
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: posicao),
    );
  }
}
