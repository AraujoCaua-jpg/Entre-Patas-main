import 'package:material_ui/material_ui.dart';

class NavegacaoController extends ChangeNotifier {
  int paginaAtual = 0;

  void mudarPagina(int indice) {
    paginaAtual = indice;
    notifyListeners();
  }
}