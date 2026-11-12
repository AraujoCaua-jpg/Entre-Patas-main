import 'package:material_ui/material_ui.dart';

import '../core/app_colors.dart';
import 'testeCompFim.dart';

class TesteCompCScreen extends StatefulWidget {
  const TesteCompCScreen({super.key});

  @override
  State<TesteCompCScreen> createState() => _TesteCompCScreenState();
}

class _TesteCompCScreenState extends State<TesteCompCScreen> {
  String? imovel = 'Sim';
  String? apoio = 'Sim';
  String? compromisso = 'Sim';
  String? moradores = 'Sim';
  String? financeiro = '3';
  String? rotina = 'Sim';
  
  void avancar() {
    if ([
      imovel,
      apoio,
      compromisso,
      moradores,
      rotina
    ].any((opcao) => opcao == "Não" || financeiro == "1")) {
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Aviso'),
            content: const Text('Você não está totalmente preparado para esse compromisso. Pense melhor antes de uma adoção!'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TesteCompFimScreen(), //HOME
                    ),
                  );

                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.laranja,
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('Ok', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );

    } else {
      FocusScope.of(context).unfocus();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TesteCompFimScreen(),
        ),
      );
      return;
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

      body: SingleChildScrollView (
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
                  'Etapa 4 de 5',
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
                        color: etapa < 4 ? AppColors.verde : AppColors.cinza,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(height: 20,),

            Row(
              mainAxisAlignment: MainAxisAlignment.start, 
              children: [
                Text(
                  "Bloco C",
                  style: TextStyle(
                    fontSize: 24
                  ),
                ),

              ],
            ),

            SizedBox(height: 20,),

            Row(
              children: [
                const Text(
                  '1- O imóvel permite animais?',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          
            Row(
              children: [
                Radio<String>(
                  value: 'Sim',
                  groupValue: imovel,
                  activeColor: AppColors.verde,
                  onChanged: (value) {
                    setState(() {
                      imovel = value;
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
                  groupValue: imovel,
                  activeColor: AppColors.laranja,
                  onChanged: (value) {
                    setState(() {
                      imovel = value;
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
                const 
                Expanded(
                  child: Text(
                    '2- Você tem apoio para viagens ou emergências?',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          
            Row(
              children: [
                Radio<String>(
                  value: 'Sim',
                  groupValue: apoio,
                  activeColor: AppColors.verde,
                  onChanged: (value) {
                    setState(() {
                      apoio = value;
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
                  groupValue: apoio,
                  activeColor: AppColors.laranja,
                  onChanged: (value) {
                    setState(() {
                      apoio = value;
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
                const 
                Expanded(
                  child: Text(
                    '3- Você está preparado para um compromisso de longo prazo?',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          
            Row(
              children: [
                Radio<String>(
                  value: 'Sim',
                  groupValue: compromisso,
                  activeColor: AppColors.verde,
                  onChanged: (value) {
                    setState(() {
                      compromisso = value;
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
                  groupValue: compromisso,
                  activeColor: AppColors.laranja,
                  onChanged: (value) {
                    setState(() {
                      compromisso = value;
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
                const 
                Expanded(
                  child: Text(
                    '4- Todos os moradores concordam com a adoção?',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          
            Row(
              children: [
                Radio<String>(
                  value: 'Sim',
                  groupValue: moradores,
                  activeColor: AppColors.verde,
                  onChanged: (value) {
                    setState(() {
                      moradores = value;
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
                  groupValue: moradores,
                  activeColor: AppColors.laranja,
                  onChanged: (value) {
                    setState(() {
                      moradores = value;
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
                const 
                Expanded(
                  child: Text(
                    '5- Qual é a sua disponibilidade financeira para cuidar do animal?',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Radio<String>(
                  value: '3',
                  groupValue: financeiro,
                  activeColor: AppColors.laranja,
                  onChanged: (value) {
                    setState(() {
                      financeiro = value;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    'Consigo arcar com alimentação, cuidados preventivos e despesas veterinárias previstas.',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Radio<String>(
                  value: '2',
                  groupValue: financeiro,
                  activeColor: AppColors.laranja,
                  onChanged: (value) {
                    setState(() {
                      financeiro = value;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    'Consigo arcar com os cuidados básicos, mas precisaria me planejar para despesas extras.',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Radio<String>(
                  value: '1',
                  groupValue: financeiro,
                  activeColor: AppColors.laranja,
                  onChanged: (value) {
                    setState(() {
                      financeiro = value;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    'Ainda não tenho condições de assumir esses custos.',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),

            

            SizedBox(height: 20,),
            
            Row(
              children: [
                const 
                Expanded(
                  child: Text(
                    '6 - Consegue manter uma rotina de alimentação, higiene e cuidados?',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          
            Row(
              children: [
                Radio<String>(
                  value: 'Sim',
                  groupValue: rotina,
                  activeColor: AppColors.verde,
                  onChanged: (value) {
                    setState(() {
                      rotina = value;
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
                  groupValue: rotina,
                  activeColor: AppColors.laranja,
                  onChanged: (value) {
                    setState(() {
                      rotina = value;
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
