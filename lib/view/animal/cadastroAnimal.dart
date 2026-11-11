import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class CadastroAnimalScreen extends StatefulWidget {
  const CadastroAnimalScreen({super.key});

  @override
  State<CadastroAnimalScreen> createState() =>
      _CadastroAnimalScreenState();
}

class _CadastroAnimalScreenState extends State<CadastroAnimalScreen> {
  final nomeController = TextEditingController();
  final idadeController = TextEditingController();

  String? sexo = 'Macho';
  String? tipo;

  final descricaoController = TextEditingController();

  double energia = 1;
  double porte = 1;

  String? carencia = 'Sim';
  String? convivencia = 'Sim';
  String? castrado = 'Sim';
  String? vacinado = 'Sim';

  void dispose() {
    nomeController.dispose();
    idadeController.dispose();
    descricaoController.dispose();
    super.dispose();
  }

  void mudarTipo(String estado) {
    setState(() {
      tipo = estado;
    });
  }

  void cadastrarAnimal(){
    final String mensagem;
    if ([
      nomeController,
      idadeController,
      descricaoController,
    ].any((controller) => controller.text.trim().isEmpty)) {
      mensagem = 'Preencha todos os campos para continuar.'
;
    }else if (tipo == null){
	    mensagem = 'Selecione a espécie do animal';
    }else{
      mensagem = 'Animal Publicado';

      FocusScope.of(context).unfocus();
      Navigator.pop(context);
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }
    
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Publicar Animal'),
        shape: const Border(
          bottom: BorderSide(
            color: Color(0xFFD96C3F),
            width: 2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [

            TextField(
              controller: nomeController,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words, 
              decoration: InputDecoration(
                hintText: 'Nome',
                prefixIcon: const Icon(Icons.pets, color: Color(0xFF888888)),
                filled: true,
                fillColor: AppColors.cinza,
                hintStyle: const TextStyle(color: Color(0xFF888888)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            SizedBox(height: 20,),

            TextField(
              controller: idadeController,
              keyboardType: TextInputType.number, 
              decoration: InputDecoration(
                hintText: 'Idade (anos)',
                prefixIcon: const Icon(Icons.timer_outlined, color: Color(0xFF888888)),
                filled: true,
                fillColor: AppColors.cinza,
                hintStyle: const TextStyle(color: Color(0xFF888888)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            
            SizedBox(height: 20,),

            Row(
              children: [
                const Text(
                  'Sexo:',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          
            Row(
              children: [
                Radio<String>(
                  value: 'Macho',
                  groupValue: sexo,
                  activeColor: AppColors.laranja,
                  onChanged: (value) {
                    setState(() {
                      sexo = value;
                    });
                  },
                ),
                const Text(
                  'Macho',
                  style: TextStyle(fontSize: 18),
                ),

                const SizedBox(width: 8),

                Radio<String>(
                  value: 'Fêmea',
                  groupValue: sexo,
                  activeColor: AppColors.laranja,
                  onChanged: (value) {
                    setState(() {
                      sexo = value;
                    });
                  },
                ),
                const Text(
                  'Fêmea',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),

            SizedBox(height: 20,),

            Row(
              children: [
                const Text(
                  'Espécie de animal:',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),

            SizedBox(height: 8,),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => mudarTipo("Cachorro"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tipo == "Cachorro"? AppColors.laranja : AppColors.rosa,
                      foregroundColor: tipo == "Cachorro"? Colors.white : AppColors.laranja,
                      elevation: 0,
                      fixedSize: const Size(double.infinity, 80),                   
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pets),
                        SizedBox(width: 10),
                        Text(
                          'Cachorro',
                          style: TextStyle(
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 8,),

                Expanded(
                  child: ElevatedButton(
                    onPressed: () => mudarTipo("Gato"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tipo == "Gato"? AppColors.verde : AppColors.verdeClaro,
                      foregroundColor: tipo == "Gato"? Colors.white : AppColors.verde,
                      elevation: 0,
                      fixedSize: const Size(double.infinity, 80),                   
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pets),
                        SizedBox(width: 10),
                        Text(
                          'Gato',
                          style: TextStyle(
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              ],
            ),

            SizedBox(height: 20,),

            Row(
              children: [
                const Text(
                  'Descrição',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),

            SizedBox(height: 8,),

            TextField(
              controller: descricaoController,
              minLines: 4,
              maxLines: 4,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.cinza,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),

            SizedBox(height: 20,),

            Row(
              children: [
                const Text(
                  'Energia',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),

            SizedBox(height: 8,),

            Slider(
              value: energia,
              min: 0.0,
              max: 2.0,
              divisions: 2,
              activeColor: AppColors.laranja,   // Parte preenchida
              inactiveColor: Colors.grey,   // Parte não preenchida
              thumbColor: Colors.white,
              onChanged: (double valor) {
                setState(() {
                  energia = valor;
                });
              },
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Baixo'),
                Text('Médio'),
                Text('Alto'),
              ],
            ),

            SizedBox(height: 20,),

            Row(
              children: [
                const Text(
                  'Porte',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),

            SizedBox(height: 8,),

            Slider(
              value: porte,
              min: 0.0,
              max: 2.0,
              divisions: 2,
              activeColor: AppColors.verde,   // Parte preenchida
              inactiveColor: Colors.grey,   // Parte não preenchida
              thumbColor: Colors.white,
              onChanged: (double valor) {
                setState(() {
                  porte = valor;
                });
              },
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pqueno'),
                Text('Médio'),
                Text('Grande'),
              ],
            ),

            SizedBox(height: 20,),

            Row(
              children: [
                const Text(
                  'O animal precisa de compania?',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          
            Row(
              children: [
                Radio<String>(
                  value: 'Sim',
                  groupValue: carencia,
                  activeColor: AppColors.verde,
                  onChanged: (value) {
                    setState(() {
                      carencia = value;
                    });
                  },
                ),
                const Text(
                  'Sim',
                  style: TextStyle(fontSize: 18),
                ),

                const SizedBox(width: 8),

                Radio<String>(
                  value: 'Não',
                  groupValue: carencia,
                  activeColor: AppColors.laranja,
                  onChanged: (value) {
                    setState(() {
                      carencia = value;
                    });
                  },
                ),
                const Text(
                  'Não',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),

            SizedBox(height: 20,),

            Row(
              children: [
                const Text(
                  'O animal sabe conviver bem com outros animais?',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          
            Row(
              children: [
                Radio<String>(
                  value: 'Sim',
                  groupValue: convivencia,
                  activeColor: AppColors.verde,
                  onChanged: (value) {
                    setState(() {
                      convivencia = value;
                    });
                  },
                ),
                const Text(
                  'Sim',
                  style: TextStyle(fontSize: 18),
                ),

                const SizedBox(width: 8),

                Radio<String>(
                  value: 'Não',
                  groupValue: convivencia,
                  activeColor: AppColors.laranja,
                  onChanged: (value) {
                    setState(() {
                      convivencia = value;
                    });
                  },
                ),
                const Text(
                  'Não',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),

            SizedBox(height: 20,),

            Row(
              children: [
                const Text(
                  'O animal é castrado?',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          
            Row(
              children: [
                Radio<String>(
                  value: 'Sim',
                  groupValue: castrado,
                  activeColor: AppColors.verde,
                  onChanged: (value) {
                    setState(() {
                      castrado = value;
                    });
                  },
                ),
                const Text(
                  'Sim',
                  style: TextStyle(fontSize: 18),
                ),

                const SizedBox(width: 8),

                Radio<String>(
                  value: 'Não',
                  groupValue: castrado,
                  activeColor: AppColors.laranja,
                  onChanged: (value) {
                    setState(() {
                      castrado = value;
                    });
                  },
                ),
                const Text(
                  'Não',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),

            SizedBox(height: 20,),

            Row(
              children: [
                const Text(
                  'O animal foi vacinado regularmente?',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          
            Row(
              children: [
                Radio<String>(
                  value: 'Sim',
                  groupValue: vacinado,
                  activeColor: AppColors.verde,
                  onChanged: (value) {
                    setState(() {
                      vacinado = value;
                    });
                  },
                ),
                const Text(
                  'Sim',
                  style: TextStyle(fontSize: 18),
                ),

                const SizedBox(width: 8),

                Radio<String>(
                  value: 'Não',
                  groupValue: vacinado,
                  activeColor: AppColors.laranja,
                  onChanged: (value) {
                    setState(() {
                      vacinado = value;
                    });
                  },
                ),
                const Text(
                  'Não',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),

            SizedBox(height: 20,),

            SizedBox(
              height: 62,
              child: ElevatedButton(
                onPressed: cadastrarAnimal,
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
                      'Publicar Animal',
                      style: TextStyle(
                        fontSize: 24,
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(Icons.pets),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),

    );
  }
}
