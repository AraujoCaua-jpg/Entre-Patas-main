import 'package:material_ui/material_ui.dart';

import '../core/app_colors.dart';
import 'testeCompB.dart';

class TesteCompAScreen extends StatefulWidget {
  const TesteCompAScreen({super.key});

  @override
  State<TesteCompAScreen> createState() => _TesteCompAScreenState();
}

class _TesteCompAScreenState extends State<TesteCompAScreen> {
  final idadeMinController = TextEditingController();
  final idadeMaxController = TextEditingController();

  String? sexo;
  String? tipo;
  double? energia;
  double? porte;

  void mudarTipo(String estado) {
    setState(() {
      tipo = estado;
    });
  }

  @override
  void dispose() {
    idadeMinController.dispose();
    idadeMaxController.dispose();
    super.dispose();
  }

  void avancar() {
    final String mensagem;
    int idadeMax = int.tryParse(idadeMaxController.text) ?? -1;
    int idadeMin = int.tryParse(idadeMinController.text) ?? -1;
    if ([
      idadeMinController,
      idadeMaxController,
    ].any((controller) => controller.text.trim().isEmpty)) {
      mensagem = 'Preencha todos os campos para continuar.';
    } else if (sexo == null || energia == null || porte == null) {
      mensagem = 'Selecione uma opção em todos os campos para continuar.';
    } else if (tipo == null) {
      mensagem = 'Selecione a espécie do animal';
    } else if (idadeMin < 0 ||
        idadeMax < 0 ||
        idadeMax > 2147483647 ||
        idadeMin > 2147483647) {
      mensagem = 'Informe idades inteiras a partir de zero.';
    } else if (idadeMax < idadeMin) {
      mensagem = 'A idade máxima não pode ser menor que a idade mínima';
    } else {
      FocusScope.of(context).unfocus();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TesteCompBScreen(
            respostas: {
              'tipo': tipo!,
              'sexo': sexo!,
              'idadeMin': idadeMin,
              'idadeMax': idadeMax,
              'porte': porte!.round(),
              'energia': energia!.round(),
            },
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

      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Etapa 2 de 5',
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
                  for (var etapa = 0; etapa < 5; etapa++)
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

            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [Text("Bloco A", style: TextStyle(fontSize: 24))],
            ),

            SizedBox(height: 20),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    '1 - Qual a espécie de animal?',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),

            SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => mudarTipo("Cachorro"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tipo == "Cachorro"
                          ? AppColors.laranja
                          : AppColors.rosa,
                      foregroundColor: tipo == "Cachorro"
                          ? Colors.white
                          : AppColors.laranja,
                      elevation: 0,
                      fixedSize: const Size(double.infinity, 96),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pets),
                        SizedBox(width: 10),
                        Text('Cachorro', style: TextStyle(fontSize: 24)),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 8),

                Expanded(
                  child: ElevatedButton(
                    onPressed: () => mudarTipo("Gato"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tipo == "Gato"
                          ? AppColors.verde
                          : AppColors.verdeClaro,
                      foregroundColor: tipo == "Gato"
                          ? Colors.white
                          : AppColors.verde,
                      elevation: 0,
                      fixedSize: const Size(double.infinity, 96),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pets),
                        SizedBox(width: 10),
                        Text('Gato', style: TextStyle(fontSize: 24)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    '2 - Qual a faixa etária?',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),

            SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: idadeMinController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Idade mínima',
                      filled: true,
                      fillColor: AppColors.cinza,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: TextField(
                    controller: idadeMaxController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Idade máxima',
                      filled: true,
                      fillColor: AppColors.cinza,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    '3 - Qual o sexo do animal?',
                    style: TextStyle(fontSize: 18),
                  ),
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
                const Text('Macho', style: TextStyle(fontSize: 18)),

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
                const Text('Fêmea', style: TextStyle(fontSize: 18)),
              ],
            ),

            SizedBox(height: 20),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    '4 - Qual o porte do animal você prefere?',
                    style: TextStyle(fontSize: 18),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            SizedBox(height: 8),

            Slider(
              value: porte ?? 0.0,
              min: 0.0,
              max: 2.0,
              divisions: 2,
              activeColor: porte == null ? Colors.grey : AppColors.verde,
              inactiveColor: Colors.grey, // Parte não preenchida
              thumbColor: porte == null ? Colors.transparent : Colors.white,
              onChanged: (double valor) {
                setState(() {
                  porte = valor;
                });
              },
            ),

            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('Pequeno'), Text('Médio'), Text('Grande')],
            ),

            SizedBox(height: 20),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    '5 - Você prefere um animal com qual nível de energia?',
                    style: TextStyle(fontSize: 18),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            SizedBox(height: 8),

            Slider(
              value: energia ?? 0.0,
              min: 0.0,
              max: 2.0,
              divisions: 2,
              activeColor: energia == null ? Colors.grey : AppColors.laranja,
              inactiveColor: Colors.grey, // Parte não preenchida
              thumbColor: energia == null ? Colors.transparent : Colors.white,
              onChanged: (double valor) {
                setState(() {
                  energia = valor;
                });
              },
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('Baixo'), Text('Médio'), Text('Alto')],
            ),

            SizedBox(height: 20),

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
                    Text('Avançar', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_forward),
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
