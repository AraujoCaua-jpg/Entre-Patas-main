
import 'package:flutter/material.dart';

import 'controller/clientes_scope.dart';
import 'view/core/app_colors.dart';
import 'view/autenticacao/bemVindo.dart';
import 'view/navagacao.dart';

void main() {
  runApp(const MeuApp());
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  final bool logado = false;

  @override
  Widget build(BuildContext context) {
    return ClientesScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Entre Patas',
        theme: ThemeData(
          fontFamily: 'NunitoSans',
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.laranja),
          useMaterial3: true,
        ),
        home: logado ? const NavegacaoScreen() : const BemVindoScreen(),
      ),
    );
  }
}
