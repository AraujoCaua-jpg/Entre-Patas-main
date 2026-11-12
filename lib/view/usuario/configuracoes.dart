import 'package:entre_patas/view/autenticacao/bemVindo.dart';
import 'package:entre_patas/view/usuario/alterarSenha.dart';
import 'package:material_ui/material_ui.dart';
import '../core/app_colors.dart';
import 'editarPerfil.dart';

class ConfiguracoesScreen extends StatelessWidget {
  const ConfiguracoesScreen({super.key});

  void apagar(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Apagar conta'),
          content: const Text(
            'Tem certeza que deseja apagar sua conta?',
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
              onPressed: () {
                Navigator.of(dialogContext).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Conta apagada!'),
                    duration: Duration(seconds: 3),
                  ),
                );

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BemVindoScreen(), //HOME
                  ),
                  (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.laranja,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                'Sim',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
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
          bottom: BorderSide(
            color: Color(0xFFD96C3F),
            width: 2,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Text("Perfil", style: TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.start),
              ],
            ),
            
            //REFAZER TESTE
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
                  
                  Icon(Icons.quiz_outlined, size: 24,),
                  SizedBox(width: 10),
                  Text(
                    'Refazer teste',
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
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
                  
                  Icon(Icons.edit_note_rounded, size: 24,),
                  SizedBox(width: 10),
                  Text(
                    'Editar Perfil',
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
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
                  
                  Icon(Icons.lock_outlined, size: 24,),
                  SizedBox(width: 10),
                  Text(
                    'Alterar Senha',
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),

            Divider(
              color: AppColors.laranja,
              thickness: 2,             
            ),
            
            SizedBox(height: 8,),

            Row(
              children: [
                Text("Mais informações e Suporte", style: TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.start),
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
                  
                  Icon(Icons.info_outline, size: 24,),
                  SizedBox(width: 10),
                  Text(
                    'Sobre o App',
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
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
                  
                  Icon(Icons.help_outline, size: 24,),
                  SizedBox(width: 10),
                  Text(
                    'Ajuda',
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            
            Divider(
              color: AppColors.laranja,
              thickness: 2,             
            ),
            
            SizedBox(height: 8,),

            Row(
              children: [
                Text("Entrar", style: TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.start),
              ],
            ),

            //SAIR DO APLICATIVO
            ElevatedButton(
              onPressed: () {
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
                  
                  Icon(Icons.logout_outlined, size: 24,),
                  SizedBox(width: 10),
                  Text(
                    'Sair do Aplicativo',
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
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
                  
                  Icon(Icons.delete_forever_outlined, size: 24,),
                  SizedBox(width: 10),
                  Text(
                    'Apagar Conta',
                    style: TextStyle(
                      fontSize: 20,
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
