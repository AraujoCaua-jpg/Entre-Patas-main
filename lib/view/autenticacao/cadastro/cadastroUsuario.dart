import 'package:flutter/material.dart';

import '../../../model/cliente.dart';
import '../../../controller/clientes_scope.dart';

import '../../core/app_colors.dart';
import '../../core/telefone_formatter.dart';
import '../login.dart';
import 'cadastroUsuario2.dart';

class CadastroUsuarioScreen extends StatefulWidget {
  const CadastroUsuarioScreen({super.key});

  @override
  State<CadastroUsuarioScreen> createState() => _CadastroUsuarioScreenState();
}

class _CadastroUsuarioScreenState extends State<CadastroUsuarioScreen> {
  final nomeController = TextEditingController();
  final sobrenomeController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = TextEditingController();

  @override
  void dispose() {
    nomeController.dispose();
    sobrenomeController.dispose();
    emailController.dispose();
    telefoneController.dispose();
    super.dispose();
  }

  void avancar() {
    final String mensagem;
    if ([
      nomeController,
      sobrenomeController,
      emailController,
      telefoneController,
    ].any((controller) => controller.text.trim().isEmpty)) {
      mensagem = 'Preencha todos os campos para continuar.';
    } else if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
        .hasMatch(emailController.text.trim())) {
      mensagem = 'Digite um e-mail válido.';
    } else if (telefoneController.text.replaceAll(RegExp(r'\D'), '').length <
        10) {
      mensagem = 'Digite um telefone com DDD.';
    } else if (ClientesScope.of(context).buscarPorEmail(emailController.text) !=
        null) {
      mensagem = 'Este e-mail já está cadastrado.';
    } else {
      FocusScope.of(context).unfocus();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CadastroUsuario2Screen(
            cliente: Cliente(
              id: 0, // ID definitivo atribuído somente ao concluir o cadastro.
              nome: nomeController.text.trim(),
              sobrenome: sobrenomeController.text.trim(),
              email: emailController.text.trim(),
              telefone: telefoneController.text.trim(),
              cidadeDeResidencia: '',
              usuario: '',
            ),
          ),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,

      appBar: AppBar(
        backgroundColor: AppColors.fundo,

        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Image.asset('assets/logo.png', height: 25, fit: BoxFit.contain),

        shape: const Border(
          bottom: BorderSide(color: Color(0xFFD96C3F), width: 2),
        ),
      ),

      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back, color: AppColors.laranja),
                  label: const Text('Voltar'),
                  iconAlignment: .start,
                ),

                Text(
                  'Etapa 1 de 4',
                  style: TextStyle(color: Colors.black, fontSize: 14),
                ),
              ],
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment
                  .spaceBetween, // Centraliza as barrinhas (opcional)
              children: [
                for (var etapa = 0; etapa < 4; etapa++)
                  Expanded(
                    child: Container(
                      height: 6,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 4,
                      ), // Um espaço leve entre elas
                      decoration: BoxDecoration(
                        // Se a etapa já passou ou é a atual, fica verde. Senão, cinza.
                        color: etapa == 0 ? AppColors.verde : AppColors.cinza,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
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
                      Icons.person_outline,
                      color: AppColors.laranja,
                      size: 28,
                    ),
                  ),

                  Text(
                    'Dados Pessoais',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    'Preencha suas informações para criarmos sua conta',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF888888), fontSize: 16),
                  ),

                  SizedBox(height: 40),

                  TextField(
                    controller: nomeController,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'Nome',
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        color: Color(0xFF888888),
                      ),
                      filled: true,
                      fillColor: AppColors.cinza,
                      hintStyle: const TextStyle(color: Color(0xFF888888)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  TextField(
                    controller: sobrenomeController,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'Sobrenome',
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        color: Color(0xFF888888),
                      ),
                      filled: true,
                      fillColor: AppColors.cinza,
                      hintStyle: const TextStyle(color: Color(0xFF888888)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'E-mail',
                      prefixIcon: const Icon(
                        Icons.mail_outline,
                        color: Color(0xFF888888),
                      ),
                      filled: true,
                      fillColor: AppColors.cinza,
                      hintStyle: const TextStyle(color: Color(0xFF888888)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  TextField(
                    controller: telefoneController,
                    inputFormatters: [TelefoneInputFormatter()],
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Telefone',
                      prefixIcon: const Icon(
                        Icons.phone_outlined,
                        color: Color(0xFF888888),
                      ),
                      filled: true,
                      fillColor: AppColors.cinza,
                      hintStyle: const TextStyle(color: Color(0xFF888888)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  SizedBox(height: 40),
                ],
              ),
            ),

            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
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
                              Text('Entrar', style: TextStyle(fontSize: 24)),
                              SizedBox(width: 10),
                              Icon(Icons.arrow_forward),
                            ],
                          ),
                        ),
                      ),

                      TextButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        ),
                        child: const Text.rich(
                          TextSpan(
                            style: TextStyle(color: Colors.black, fontSize: 16),
                            children: [
                              TextSpan(text: 'Já tem conta? '),
                              TextSpan(
                                text: 'Entre aqui',
                                style: TextStyle(
                                  color: AppColors.laranja,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              TextSpan(text: '!'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
