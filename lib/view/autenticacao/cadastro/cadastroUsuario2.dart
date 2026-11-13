import '../../core/scrollable_screen_body.dart';

import 'package:material_ui/material_ui.dart';

import '../../../model/cliente.dart';
import '../../../service/validacao_senha.dart';

import '../../core/app_colors.dart';
import 'cadastroUsuario3.dart';

class CadastroUsuario2Screen extends StatefulWidget {
  const CadastroUsuario2Screen({super.key, required this.cliente});

  final Cliente cliente;

  @override
  State<CadastroUsuario2Screen> createState() => _CadastroUsuario2ScreenState();
}

class _CadastroUsuario2ScreenState extends State<CadastroUsuario2Screen> {
  final senhaController = TextEditingController();
  final confirmacaoController = TextEditingController();
  bool mostrarSenha = false;

  Map<String, bool> get requisitos => requisitosSenha(senhaController.text);

  @override
  void dispose() {
    senhaController.dispose();
    confirmacaoController.dispose();
    super.dispose();
  }

  void avancar() {
    final senha = senhaController.text;
    final erroSenha = validarSenha(senha);

    final String mensagem;
    if (erroSenha != null) {
      mensagem = erroSenha;
    } else if (senha != confirmacaoController.text) {
      mensagem = 'As senhas devem ser iguais.';
    } else {
      FocusScope.of(context).unfocus();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CadastroUsuario3Screen(cliente: widget.cliente, senha: senha),
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

      body: ScrollableScreenBody(
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
                  'Etapa 2 de 4',
                  style: TextStyle(color: Colors.black, fontSize: 14),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 28),
              child: Row(
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
                          color: etapa < 2 ? AppColors.verde : AppColors.cinza,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                ],
              ),
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
                    'Senha',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    'Escolha uma senha para proteger sua conta.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF888888), fontSize: 16),
                  ),

                  SizedBox(height: 40),

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
                          style: TextStyle(color: Colors.black, fontSize: 14),
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

                  SizedBox(height: 20),

                  TextField(
                    controller: senhaController,
                    onChanged: senhaController == senhaController
                        ? (_) => setState(() {})
                        : null,
                    obscureText: !mostrarSenha,
                    decoration: InputDecoration(
                      hintText: 'Senha',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFF888888),
                      ),
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

                  SizedBox(height: 20),

                  TextField(
                    controller: confirmacaoController,
                    obscureText: !mostrarSenha,
                    decoration: InputDecoration(
                      hintText: 'Digite Novamente',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
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
