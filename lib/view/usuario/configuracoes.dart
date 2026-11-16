import 'package:entre_patas/view/core/app_dialog.dart';

import '../../controller/clientes_scope.dart';

import 'package:entre_patas/view/autenticacao/bem_vindo.dart';
import 'package:entre_patas/view/usuario/alterar_senha.dart';
import 'package:material_ui/material_ui.dart';

import '../../services/login_exception.dart';
import '../core/app_colors.dart';
import '../questionario/teste_comp.dart';
import 'editar_perfil.dart';

class ConfiguracoesScreen extends StatelessWidget {
  const ConfiguracoesScreen({super.key});

  Future<void> apagar(BuildContext context) async {
    final senhaController = TextEditingController();
    final senha = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AppDialog(
          title: const Text('Apagar conta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tem certeza que deseja apagar sua conta?'),
              const SizedBox(height: 12),
              TextField(
                controller: senhaController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'Senha atual'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Não',
                style: TextStyle(color: AppColors.laranja),
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(senhaController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.laranja,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Sim', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
    senhaController.dispose();
    if (senha == null || !context.mounted) return;

    var limpezaStoragePendente = false;
    try {
      limpezaStoragePendente = await ClientesScope.of(context)
          .apagarConta(senha);
    } catch (erro) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              erro is LoginException
                  ? erro.mensagem
                  : 'Não foi possível apagar a conta. Tente novamente.',
            ),
          ),
        );
      }
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          limpezaStoragePendente
              ? 'Conta apagada. A limpeza de alguns arquivos será concluída pelo servidor.'
              : 'Conta apagada!',
        ),
        duration: const Duration(seconds: 3),
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const BemVindoScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Configurações'),
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFD96C3F), width: 2),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  "Perfil",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.start,
                ),
              ],
            ),

            //REFAZER TESTE
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TesteCompScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.quiz_outlined, size: 24),
                  SizedBox(width: 10),
                  Text('Refazer teste', style: TextStyle(fontSize: 20)),
                ],
              ),
            ),

            //EDITAR PERFIL
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditarPerfilScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.edit_note_rounded, size: 24),
                  SizedBox(width: 10),
                  Text('Editar Perfil', style: TextStyle(fontSize: 20)),
                ],
              ),
            ),

            //ALTERAR SENHA
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AlterarSenhaScreen(), //HOME
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outlined, size: 24),
                  SizedBox(width: 10),
                  Text('Alterar Senha', style: TextStyle(fontSize: 20)),
                ],
              ),
            ),

            Divider(color: AppColors.laranja, thickness: 2),

            SizedBox(height: 8),

            Row(
              children: [
                Text(
                  "Mais informações e Suporte",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.start,
                ),
              ],
            ),

            //SOBRE O APP
            ElevatedButton(
              onPressed: () {
                // Navigator.pushReplacement(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => const NavegacaoScreen(), //HOME
                //   ),
                // );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 24),
                  SizedBox(width: 10),
                  Text('Sobre o App', style: TextStyle(fontSize: 20)),
                ],
              ),
            ),

            //AJUDA
            ElevatedButton(
              onPressed: () {
                // Navigator.pushReplacement(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => const NavegacaoScreen(), //HOME
                //   ),
                // );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.help_outline, size: 24),
                  SizedBox(width: 10),
                  Text('Ajuda', style: TextStyle(fontSize: 20)),
                ],
              ),
            ),

            Divider(color: AppColors.laranja, thickness: 2),

            SizedBox(height: 8),

            Row(
              children: [
                Text(
                  "Entrar",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.start,
                ),
              ],
            ),

            //SAIR DO APLICATIVO
            ElevatedButton(
              onPressed: () async {
                try {
                  await ClientesScope.of(context).sair();
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Não foi possível sair. Confira a conexão e tente novamente.',
                      ),
                    ),
                  );
                  return;
                }
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BemVindoScreen(), //HOME
                  ),
                  (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.logout_outlined, size: 24),
                  SizedBox(width: 10),
                  Text('Sair do Aplicativo', style: TextStyle(fontSize: 20)),
                ],
              ),
            ),

            //APAGAR CONTA
            ElevatedButton(
              onPressed: () => apagar(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.delete_forever_outlined, size: 24),
                  SizedBox(width: 10),
                  Text('Apagar Conta', style: TextStyle(fontSize: 20)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
