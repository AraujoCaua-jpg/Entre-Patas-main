import 'package:entre_patas/view/questionario/testeCompA.dart';
import 'package:material_ui/material_ui.dart';

import '../core/app_colors.dart';

class TesteCompScreen extends StatelessWidget {
  const TesteCompScreen({super.key});

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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Etapa 1 de 5',
                  style: TextStyle(color: Colors.black, fontSize: 14),
                ),
              ],
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment
                  .spaceBetween, // Centraliza as barrinhas (opcional)
              children: [
                for (var etapa = 0; etapa < 5; etapa++)
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
                      Icons.question_answer_outlined,
                      color: AppColors.laranja,
                      size: 28,
                    ),
                  ),
                  
                  Text(
                    'Teste de Compatibilidade',
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
                    'Esse teste avaliará as melhores opções\nde pet para você.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ]
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
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TesteCompAScreen(), //HOME
                              ),
                              (Route<dynamic> route) => false,
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
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Começar', style: TextStyle(fontSize: 24)),
                              SizedBox(width: 10),
                              Icon(Icons.arrow_forward),
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
