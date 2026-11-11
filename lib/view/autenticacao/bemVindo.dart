import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'login.dart';
import 'cadastro/cadastroUsuario.dart';

class BemVindoScreen extends StatelessWidget {
  const BemVindoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      appBar: AppBar(
        centerTitle: true,
        title: Image.asset('assets/logo.png', height: 25, fit: BoxFit.contain),

        shape: const Border(
          bottom: BorderSide(color: Color(0xFFD96C3F), width: 2),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 390,
              height: 844,
              child: Stack(
                children: [
                  Container(width: 390, height: 844, color: AppColors.fundo),

                  Positioned(
                    left: 0,
                    top: 117,
                    child: Image.asset(
                      'assets/animais.png',
                      width: 390,
                      height: 335,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    top: 472,
                    child: SizedBox(
                      width: 390,
                      child: Text.rich(
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
                        style: TextStyle(fontSize: 43),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 65,
                    top: 542,
                    child: SizedBox(
                      width: 260,
                      child: Text(
                        'Encontre seu\nmelhor amigo aqui!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 21,
                    top: 656,
                    child: SizedBox(
                      width: 345,
                      height: 62,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.laranja,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Fazer Login',
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 21,
                    top: 730,
                    child: SizedBox(
                      width: 345,
                      height: 62,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const CadastroUsuarioScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.verde,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Criar Conta',
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
