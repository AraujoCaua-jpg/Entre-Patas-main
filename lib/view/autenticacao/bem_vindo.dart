import 'package:material_ui/material_ui.dart';

import '../core/app_colors.dart';
import '../core/scrollable_screen_body.dart';
import 'login.dart';
import 'cadastro/cadastro_usuario.dart';

class BemVindoScreen extends StatelessWidget {
  const BemVindoScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.fundo,
    appBar: AppBar(
      centerTitle: true,
      title: Image.asset('assets/logo.png', height: 25, fit: BoxFit.contain),
      shape: const Border(
        bottom: BorderSide(color: AppColors.laranja, width: 2),
      ),
    ),
    body: LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        final imagem = Image.asset(
          'assets/animais.png',
          height: desktop ? 380 : 260,
          fit: BoxFit.contain,
        );
        final apresentacao = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Bem ',
                    style: TextStyle(color: Colors.black),
                  ),
                  TextSpan(
                    text: 'Vindo(a)!',
                    style: TextStyle(color: AppColors.laranja),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Encontre seu\nmelhor amigo aqui!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, height: 1.2),
            ),
            const SizedBox(height: 32),
            _botao(context, 'Fazer Login', const LoginScreen(), true),
            const SizedBox(height: 12),
            _botao(
              context,
              'Criar Conta',
              const CadastroUsuarioScreen(),
              false,
            ),
          ],
        );
        return ScrollableScreenBody(
          maxWidth: desktop ? 1100 : 480,
          child: desktop
              ? Row(
                  children: [
                    Expanded(child: imagem),
                    const SizedBox(width: 64),
                    Expanded(child: apresentacao),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [imagem, const SizedBox(height: 24), apresentacao],
                ),
        );
      },
    ),
  );

  Widget _botao(
    BuildContext context,
    String texto,
    Widget destino,
    bool principal,
  ) => ElevatedButton(
    onPressed: () =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => destino)),
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, 56),
      backgroundColor: principal ? AppColors.laranja : Colors.white,
      foregroundColor: principal ? Colors.white : AppColors.laranja,
      elevation: 0,
      side: principal
          ? BorderSide.none
          : const BorderSide(color: AppColors.laranja),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    child: Text(texto, style: const TextStyle(fontSize: 22)),
  );
}
