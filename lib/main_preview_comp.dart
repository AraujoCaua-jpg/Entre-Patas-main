import 'package:material_ui/material_ui.dart';

import 'controller/cliente_controller.dart';
import 'controller/clientes_scope.dart';
import 'view/core/app_colors.dart';
import 'view/questionario/testeCompA.dart';

class _PreviewController extends ClienteController {
  @override
  Future<Map<String, dynamic>?> carregarQuestionario() async => null;
}

void main() {
  runApp(
    ClientesScope(
      controller: _PreviewController(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Entre Patas - Compatibilidade',
        theme: ThemeData(
          fontFamily: 'NunitoSans',
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.laranja),
          useMaterial3: true,
        ),
        home: const TesteCompAScreen(),
      ),
    ),
  );
}