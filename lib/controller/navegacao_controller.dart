import 'package:flutter/material.dart';

class NavegacaoController extends ChangeNotifier {
  int paginaAtual = 0;

  void mudarPagina(int indice) {
    paginaAtual = indice;
    notifyListeners();
  }
}