import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:material_ui/material_ui.dart';

import '../../controller/clientes_scope.dart';
import '../../services/login_exception.dart';
import '../../services/validacao_perfil.dart';
import '../core/scrollable_screen_body.dart';
import '../core/app_colors.dart';
import '../navagacao.dart';
import '../questionario/teste_comp.dart';
import 'cadastro/cadastro_usuario.dart';
import 'esqueci_senha.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool mostrarSenha = false;
  bool _entrando = false;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  Future<void> entrar() async {
    if (_entrando) return;

    final email = emailController.text.trim();
    final senha = senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha e-mail e senha para continuar.'),
        ),
      );
      return;
    }
    if (!emailValido(email)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Digite um e-mail válido.')));
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _entrando = true);

    try {
      final controller = ClientesScope.of(context);
      await controller.entrar(email, senha);

      if (!mounted) return;

      senhaController.clear();

      // Verifica se o usuário já concluiu
      // o teste de compatibilidade.
      final perfil = controller.clienteLogado;
      if (perfil == null) {
        throw const LoginException('Perfil não encontrado ou inativo.');
      }
      // A existência das respostas salvas decide o acesso, inclusive para
      // contas legadas cujo marcador de pendência tem default false.
      final questionario = await controller.carregarQuestionario();

      if (!mounted) return;

      // Se não existe questionário, abre o teste.
      // Caso contrário, abre a Home.
      final avisoFoto = controller.avisoFotoLogin;
      if (avisoFoto != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(avisoFoto)));
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => questionario == null
              ? const TesteCompScreen()
              : const NavegacaoScreen(),
        ),
        (route) => false,
      );
    } on LoginException catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(erro.mensagem)));
    } on AuthException catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro no login: ${erro.message}')));
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível entrar. Tente novamente.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _entrando = false);
      }
    }
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

                  SizedBox(height: 10),

                  Text(
                    'Entre na sua conta e encontre seu\nnovo amigo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black, fontSize: 14),
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
                      onPressed: _entrando ? null : entrar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.laranja,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _entrando ? 'Entrando...' : 'Entrar',
                            style: const TextStyle(fontSize: 24),
                          ),
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
