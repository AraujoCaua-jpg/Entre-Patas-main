import 'package:entre_patas/view/autenticacao/login.dart';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class AlterarSenhaScreen extends StatefulWidget {
  const AlterarSenhaScreen({super.key});

  @override
  State<AlterarSenhaScreen> createState() => _AlterarSenhaScreenState();
}

class _AlterarSenhaScreenState extends State<AlterarSenhaScreen> {
  final senhaController = TextEditingController();
  final confirmacaoController = TextEditingController();
  bool mostrarSenha = false;

  Map<String, bool> get requisitos => {
    '8 caracteres': senhaController.text.runes.length >= 8,
    '1 letra maiúscula': RegExp(r'[A-Z]').hasMatch(senhaController.text),
    '1 letra minúscula': RegExp(r'[a-z]').hasMatch(senhaController.text),
    '1 número': RegExp(r'[0-9]').hasMatch(senhaController.text),
    '1 caractere especial': RegExp(
      r'[^a-zA-Z0-9\s]',
    ).hasMatch(senhaController.text),
  };

  @override
  void dispose() {
    senhaController.dispose();
    confirmacaoController.dispose();
    super.dispose();
  }

  void avancar() {
    final senha = senhaController.text;
    final valida = requisitos.values.every((atendido) => atendido);

    final String mensagem;
    if (!valida) {
      mensagem = 'A senha deve atender a todos os requisitos indicados.';
    } else if (senha != confirmacaoController.text) {
      mensagem = 'As senhas devem ser iguais.';
    } else {
      mensagem = 'Senha alterada com sucesso!';

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Image.asset(
          'assets/logo.png',
          height: 25,
          fit: BoxFit.contain,
        ),

        shape: const Border(
          bottom: BorderSide(
            color: Color(0xFFD96C3F),
            width: 2,
          ),
        ),
      ),

      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(   
          children: [
            
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back, color: AppColors.laranja),
                  label: const Text('Voltar'),
                  iconAlignment: .start,
                ),
              ],
            ),

            Expanded(
              child: Column(
                mainAxisAlignment: .center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.rosaClaro,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: AppColors.laranja,
                      size: 28,
                    ),
                  ),

                  Text(
                    'Alterar Senha',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),


                  Text(
                    'Escolha uma nova senha segura para proteger sua conta',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 16,
                    ),
                  ),

                  SizedBox(
                    height: 40,
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 16,
                    ),

                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2EC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sua senha deve conter pelo menos:',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                          ),
                        ),
                        for (final requisito in requisitos.entries)
                          Row(
                            children: [
                              Icon(
                                requisito.value
                                    ? Icons.check_circle_outline
                                    : Icons.cancel_outlined,
                                size: 16,
                                color: requisito.value
                                    ? Colors.green.shade800
                                    : Colors.red.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                requisito.key,
                                style: TextStyle(
                                  color: requisito.value
                                      ? Colors.green.shade800
                                      : Colors.red.shade700,
                                  fontSize: 14,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  
                  SizedBox(
                    height: 20,
                  ),

                  TextField(
                    controller: senhaController,
		                onChanged: senhaController == senhaController ? (_) => setState(() {}) : null,
                    obscureText: !mostrarSenha,
                    decoration: InputDecoration(
                      hintText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          mostrarSenha
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            mostrarSenha = !mostrarSenha;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: AppColors.cinza,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  
                  SizedBox(
                    height: 20,
                  ),

                  TextField(
                    controller: confirmacaoController,
                    obscureText: !mostrarSenha,
                    decoration: InputDecoration(
                      hintText: 'Digite novamente',
                      prefixIcon: const Icon(Icons.lock_outline),
                      
                      filled: true,
                      fillColor: AppColors.cinza,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  SizedBox(
                    height: 40,
                  ),
                ],
              ),
            ),
            
            Row(
              children: [ 
                Expanded(
                  child: SizedBox(
                    height: 62,
                    child: ElevatedButton(
                      onPressed: avancar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.laranja,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Entrar',
                            style: TextStyle(
                              fontSize: 24,
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(Icons.arrow_forward),
                        ],
                      ),
                    ),
                  ),
                )
                

              ],
            ),

          ],
        ),
      ),
    );
  }
}



