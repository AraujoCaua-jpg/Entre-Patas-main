import 'package:entre_patas/view/core/app_colors.dart';
import 'package:material_ui/material_ui.dart';
import 'cadastroAnimal.dart';
import 'editarAnimal.dart';

class AnimaisCadastradosScreen extends StatelessWidget {
  const AnimaisCadastradosScreen({super.key});

  static const List<List> animais = [
    ["Bolt", "1 ano", "Macho", "https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=500&h=340&fit=crop"],
    ["Rubi", "4 anos", "Fêmea", "https://images.unsplash.com/photo-1546527868-ccb7ee7dfa6a?w=500&h=340&fit=crop"],
    ["Brutos", "2 anos", "Macho", "https://images.unsplash.com/photo-1551717743-49959800b1f6?w=500&h=340&fit=crop"],
    ["Brutus", "4 meses", "Macho", "https://images.unsplash.com/photo-1518717758536-85ae29035b6d?w=500&h=340&fit=crop"],
  ];

  void apagar(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Deletar'),
          content: const Text(
            'Tem certeza que deseja apagar este animal do sistema?',
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
                    content: Text('Animal apagado!'),
                    duration: Duration(seconds: 3),
                  ),
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
        title: const Text('Animais Publicados'),
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
            Expanded(
              child: animais.isEmpty
              ? const Center(child: Text('Nenhum Animal Cadastrado'))
              : ListView.builder(
                itemCount: animais.length,
                itemBuilder: (context, index) {
                  final item = animais[index];

                  return Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(8.0), // Espaçamento interno em todos os lados
                      child:Row(
                        children: [
                          CircleAvatar(
                            radius: 30, // Define o tamanho do raio do círculo
                            backgroundImage: NetworkImage(item[3]),
                            // Ou use NetworkImage, AssetImage, etc.
                          ),

                          SizedBox(width: 10,),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item[0], style: TextStyle(fontSize: 20),),
                                Text("${item[1]} - ${item[2]}", style: TextStyle(fontSize: 14 , color: AppColors.cinzaEscuro),),
                              ],
                            )
                          ),

                          IconButton(
                            icon: const Icon(Icons.edit_note_rounded, color: AppColors.cinzaEscuro, size: 26,),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EditarAnimalScreen(),
                                ),
                              );
                            },
                          ),

                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 26),
                            onPressed: () => apagar(context)
                          ),
                        ],
                      ),
                    ),
                  );

                },
              ),
            ),
            
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CadastroAnimalScreen(),
            ),
          );
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
