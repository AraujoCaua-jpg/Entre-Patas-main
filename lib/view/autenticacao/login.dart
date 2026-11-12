import 'package:material_ui/material_ui.dart';

import '../../controller/clientes_scope.dart';

import '../core/app_colors.dart';
import '../navagacao.dart';
import 'cadastro/cadastroUsuario.dart';
import 'esqueciSenha.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool mostrarSenha = false;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  void entrar() {
    final String mensagem;
    if ([
      emailController,
      senhaController,
    ].any((controller) => controller.text.trim().isEmpty)) {
      mensagem = 'Preencha todos os campos para continuar.';
    } else if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
        .hasMatch(emailController.text.trim())) {
      mensagem = 'Digite um e-mail válido.';
    } else if (!ClientesScope.of(context)
        .entrarSimulado(emailController.text)) {
      mensagem =
          'E-mail não cadastrado nesta execução. Crie uma conta primeiro.';
    } else {
      // Apenas simula a navegação. A senha não é comparada ou persistida.
      senhaController.clear();
      FocusScope.of(context).unfocus();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const NavegacaoScreen(), //HOME
        ),
        (Route<dynamic> route) => false,
      );

      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
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
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.orange),
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
                      Icons.person_outline,
                      color: AppColors.laranja,
                      size: 28,
                    ),
                  ),
                  
                  Text(
                    'Que bom ter você de volta!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 30,
                      height: 1.05,
                    ),
                  ),
                  
                  SizedBox(
                    height: 10,
                  ),

                  Text(
                    'Entre na sua conta e encontre seu\nnovo amigo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),

                  SizedBox(height: 40),

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'E-mail',
                      prefixIcon: const Icon(Icons.mail_outline),
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
                    controller: senhaController,
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

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const EsqueciSenhaScreen(), //RECUPERAR SENHA
                            ),
                          );
                        },

                        child: const Text(
                          'Esqueci minha senha!',
                          style: TextStyle(
                            color: AppColors.laranja,
                            fontSize: 16,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 40),

                  SizedBox(
                    height: 62,
                    child: ElevatedButton(
                      onPressed: entrar,
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

                  SizedBox(height: 10),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const CadastroUsuarioScreen(), // CADASTRO
                        ),
                      );
                    },

                    child: const Text.rich(
                      TextSpan(
                        children: [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Icon(
                              Icons.pets,
                              color: AppColors.laranja,
                              size: 18,
                            ),
                          ),
                          TextSpan(
                            text: ' Não é usuário? ',
                            style: TextStyle(color: Colors.black, fontSize: 16),
                          ),
                          TextSpan(
                            text: 'Crie sua conta!',
                            style: TextStyle(
                              color: AppColors.laranja,
                              fontSize: 16,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
