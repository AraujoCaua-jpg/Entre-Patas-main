import 'package:entre_patas/view/questionario/testeCompC.dart';
import 'package:material_ui/material_ui.dart';

import '../core/app_colors.dart';

class TesteCompBScreen extends StatefulWidget {
  const TesteCompBScreen({super.key, this.respostas = const {}});
  final Map<String, dynamic> respostas;

  @override
  State<TesteCompBScreen> createState() => _TesteCompBScreenState();
}

class _TesteCompBScreenState extends State<TesteCompBScreen> {
  String? residencia = 'Casa c/ Quintal';
  String? sozinho = "5";
  String? dedicacao = "1";
  String? convivencia = 'Sim';

  @override
  void initState() {
    super.initState();
    residencia = widget.respostas['ambiente'] as String? ?? residencia;
    sozinho = '${widget.respostas['sozinho'] ?? sozinho}';
    dedicacao = '${widget.respostas['dedicacao'] ?? dedicacao}';
    convivencia = widget.respostas['animais'] as String? ?? convivencia;
  }

  void avancar() {
    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TesteCompCScreen(
          respostas: {
            ...widget.respostas,
            'ambiente': residencia!,
            'sozinho': int.parse(sozinho!),
            'dedicacao': int.parse(dedicacao!),
            'animais': convivencia!,
          },
        ),
      ),
    );
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
                  'Etapa 3 de 5',
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
                          color: etapa < 3 ? AppColors.verde : AppColors.cinza,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [Text("Bloco B", style: TextStyle(fontSize: 24))],
            ),

            SizedBox(height: 20),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    '1- Qual o ambiente que você mora?',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),

            Row(
              children: [
                Radio<String>(
                  value: 'Casa c/ Quintal',
                  groupValue: residencia,
                  activeColor: AppColors.laranja,
                  onChanged: (value) {
                    setState(() {
                      residencia = value;
                    });
                  },
                ),
                const Text('Casa c/ Quintal', style: TextStyle(fontSize: 18)),
              ],
            ),

            Row(
              children: [
                Radio<String>(
                  value: 'Casa s/ Quintal',
                  groupValue: residencia,
                  activeColor: AppColors.laranja,
                  onChanged: (value) {
                    setState(() {
                      residencia = value;
                    });
                  },
                ),
                const Text('Casa s/ Quintal', style: TextStyle(fontSize: 18)),
              ],
            ),

            Row(
              children: [
                Radio<String>(
                  value: 'Apartamento',
                  groupValue: residencia,
                  activeColor: AppColors.laranja,
                  onChanged: (value) {
                    setState(() {
                      residencia = value;
                    });
                  },
                ),
                const Text('Apartamento', style: TextStyle(fontSize: 18)),
              ],
            ),

            Row(
              children: [
                Radio<String>(
                  value: 'Outro',
                  groupValue: residencia,
                  activeColor: AppColors.laranja,
                  onChanged: (value) {
                    setState(() {
                      residencia = value;
                    });
                  },
                ),
                const Text('Outro', style: TextStyle(fontSize: 18)),
              ],
            ),

            SizedBox(height: 20),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    '2- Quantas horas por dia o animal ficaria sozinho?',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),

            Row(
              children: [
                Radio<String>(
                  value: '5',
                  groupValue: sozinho,
                  activeColor: AppColors.laranja,
                  onChanged: (value) {
                    setState(() {
                      sozinho = value;
                    });
                  },
                ),
                const Text('0-2', style: TextStyle(fontSize: 18)),
              ],
            ),
            Row(
              children: [
                Radio<String>(
                  value: '4',
                  groupValue: sozinho,
                  activeColor: AppColors.laranja,
                  onChanged: (value) {
                    setState(() {
                      sozinho = value;
                    });
                  },
                ),
                const Text('2-4', style: TextStyle(fontSize: 18)),
              ],
            ),
            Row(
              children: [
                Radio<String>(
                  value: '3',
                  groupValue: sozinho,
                  activeColor: AppColors.laranja,
                  onChanged: (value) {
                    setState(() {
                      sozinho = value;
                    });
                  },
                ),
                const Text('4-6', style: TextStyle(fontSize: 18)),
              ],
            ),
            Row(
              children: [
                Radio<String>(
                  value: '2',
                  groupValue: sozinho,
                  activeColor: AppColors.laranja,
                  onChanged: (value) {
                    setState(() {
                      sozinho = value;
                    });
                  },
                ),
                const Text('6-8', style: TextStyle(fontSize: 18)),
              ],
            ),
            Row(
              children: [
                Radio<String>(
                  value: '1',
                  groupValue: sozinho,
                  activeColor: AppColors.laranja,
                  onChanged: (value) {
                    setState(() {
                      sozinho = value;
                    });
                  },
                ),
                const Text('8+', style: TextStyle(fontSize: 18)),
              ],
            ),

            SizedBox(height: 20),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    '3- Quanto tempo você tem para dedicar ao animal (passeio e brincadeiras)?',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),

            Row(
              children: [
                Radio<String>(
                  value: '1',
                  groupValue: dedicacao,
                  activeColor: AppColors.laranja,
                  onChanged: (value) {
                    setState(() {
                      dedicacao = value;
                    });
                  },
                ),
                const Text('0-30 min', style: TextStyle(fontSize: 18)),
              ],
            ),
            Row(
              children: [
                Radio<String>(
                  value: '2',
                  groupValue: dedicacao,
                  activeColor: AppColors.laranja,
                  onChanged: (value) {
                    setState(() {
                      dedicacao = value;
                    });
                  },
                ),
                const Text('30-60 min', style: TextStyle(fontSize: 18)),
              ],
            ),
            Row(
              children: [
                Radio<String>(
                  value: '3',
                  groupValue: dedicacao,
                  activeColor: AppColors.laranja,
                  onChanged: (value) {
                    setState(() {
                      dedicacao = value;
                    });
                  },
                ),
                const Text('1-2 horas', style: TextStyle(fontSize: 18)),
              ],
            ),
            Row(
              children: [
                Radio<String>(
                  value: '4',
                  groupValue: dedicacao,
                  activeColor: AppColors.laranja,
                  onChanged: (value) {
                    setState(() {
                      dedicacao = value;
                    });
                  },
                ),
                const Text('+2 horas', style: TextStyle(fontSize: 18)),
              ],
            ),

            SizedBox(height: 20),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    '4- Você tem outros animais em sua residência?',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),

            Row(
              children: [
                Radio<String>(
                  value: 'Sim',
                  groupValue: convivencia,
                  activeColor: AppColors.laranja,
                  onChanged: (value) {
                    setState(() {
                      convivencia = value;
                    });
                  },
                ),
                const Text('Sim', style: TextStyle(fontSize: 18)),

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
                const Text('Não', style: TextStyle(fontSize: 18)),
              ],
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
