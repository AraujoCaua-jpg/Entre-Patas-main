import 'package:flutter/material.dart';

import '../../../model/cliente.dart';
import '../../../controller/clientes_scope.dart';

import '../../core/app_colors.dart';
import 'cadastroUsuario4.dart';

class CadastroUsuario3Screen extends StatefulWidget {
  const CadastroUsuario3Screen({super.key, required this.cliente});

  final Cliente cliente;

  @override
  State<CadastroUsuario3Screen> createState() => _CadastroUsuario3ScreenState();
}

class _CadastroUsuario3ScreenState extends State<CadastroUsuario3Screen> {
  final usuarioController = TextEditingController();

  @override
  void dispose() {
    usuarioController.dispose();
    super.dispose();
  }

  void avancar() {
    final usuario = usuarioController.text.trim();
    final String mensagem;
    if (usuario.isEmpty) {
      mensagem = 'Digite um nome de usuário para continuar.';
    } else if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(usuario)) {
      mensagem = 'Use apenas letras, números e underline (_).';
    } else if (ClientesScope.of(context).buscarPorUsuario(usuario) != null) {
      mensagem = 'Este nome de usuário já está cadastrado.';
    } else {
      widget.cliente.usuario = usuario;
      FocusScope.of(context).unfocus();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CadastroUsuario4Screen(cliente: widget.cliente),
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
                  'Etapa 3 de 4',
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
                        color: etapa < 3 ? AppColors.verde : AppColors.cinza,
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
                      Icons.alternate_email,
                      color: AppColors.laranja,
                      size: 28,
                    ),
                  ),

                  Text(
                    'Nome de Usuário',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    'Escolha como será identificado no Entre Patas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF888888), fontSize: 16),
                  ),

                  SizedBox(height: 40),

                  TextField(
                    controller: usuarioController,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Nome de Usuário',
                      prefixIcon: const Icon(
                        Icons.alternate_email,
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

                  Container(
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: AppColors.rosa,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: AppColors.laranja,
                              size: 18,
                            ),
                            Text(
                              ' Dicas para o seu nome:',
                              style: TextStyle(
                                color: AppColors.laranja,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 8),

                        Text(
                          '1. Escolha um nome fácil de lembrar;\n'
                          '2. Use letras, números e underline (_);\n'
                          '3. Exemplo: amantede_pets.',
                          style: TextStyle(color: Colors.black, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),
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
                          Text('Entrar', style: TextStyle(fontSize: 24)),
                          SizedBox(width: 10),
                          Icon(Icons.arrow_forward),
                        ],
                      ),
                    ),
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
