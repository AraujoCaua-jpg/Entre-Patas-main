import 'package:entre_patas/view/core/app_dialog.dart';
import 'package:material_ui/material_ui.dart';

import '../core/app_colors.dart';
import 'teste_comp_fim.dart';
import '../../controller/clientes_scope.dart';
import '../../services/login_exception.dart';

class TesteCompCScreen extends StatefulWidget {
  const TesteCompCScreen({super.key, this.respostas = const {}});
  final Map<String, dynamic> respostas;

  @override
  State<TesteCompCScreen> createState() => _TesteCompCScreenState();
}

class _TesteCompCScreenState extends State<TesteCompCScreen> {
  String? imovel;
  String? apoio;
  String? compromisso;
  String? moradores;
  String? financeiro;
  String? rotina;

  bool _salvando = false;
  @override
  void initState() {
    super.initState();
    String? resposta(String k) => widget.respostas[k] == null
        ? null
        : '${widget.respostas[k]}' == '1'
        ? 'Sim'
        : 'Não';
    imovel = resposta('imovel');
    apoio = resposta('apoio');
    compromisso = resposta('compromisso');
    moradores = resposta('moradores');
    rotina = resposta('rotina');
    financeiro = widget.respostas['financeiro']?.toString();
  }

  Future<void> avancar() async {
    if (_salvando) return;
    if ([
      imovel,
      apoio,
      compromisso,
      moradores,
      financeiro,
      rotina,
    ].contains(null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Responda todas as perguntas para continuar.'),
        ),
      );
      return;
    }
    setState(() => _salvando = true);
    try {
      await ClientesScope.of(context).salvarQuestionario({
        ...widget.respostas,
        'imovel': imovel == 'Sim' ? 1 : 0,
        'apoio': apoio == 'Sim' ? 1 : 0,
        'compromisso': compromisso == 'Sim' ? 1 : 0,
        'moradores': moradores == 'Sim' ? 1 : 0,
        'rotina': rotina == 'Sim' ? 1 : 0,
        'financeiro': int.parse(financeiro!),
      });
      if (!mounted) return;
      if ([imovel, apoio, compromisso, moradores, rotina].contains('Não') ||
          financeiro == '1') {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AppDialog(
            title: const Text('Aviso'),
            content: const Text(
              'Algumas respostas indicam pontos para preparar antes da adoção. Converse com o responsável pelo animal.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Entendi'),
              ),
            ],
          ),
        );
      }
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TesteCompFimScreen()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is LoginException
                  ? e.mensagem
                  : 'Não foi possível salvar o teste.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
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
                  'Etapa 4 de 5',
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
                          color: etapa < 4 ? AppColors.verde : AppColors.cinza,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [Text("Bloco C", style: TextStyle(fontSize: 24))],
            ),

            SizedBox(height: 20),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    '1- O imóvel permite animais?',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),

            RadioGroup<String>(
              groupValue: imovel,
              onChanged: (value) => setState(() => imovel = value),
              child: Row(
                children: [
                  Radio<String>(value: 'Sim', activeColor: AppColors.verde),
                  const Text('Sim', style: TextStyle(fontSize: 18)),

                  const SizedBox(width: 8),

                  Radio<String>(value: 'Não', activeColor: AppColors.laranja),
                  const Text('Não', style: TextStyle(fontSize: 18)),
                ],
              ),
            ),

            SizedBox(height: 20),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    '2- Você tem apoio para viagens ou emergências?',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),

            RadioGroup<String>(
              groupValue: apoio,
              onChanged: (value) => setState(() => apoio = value),
              child: Row(
                children: [
                  Radio<String>(value: 'Sim', activeColor: AppColors.verde),
                  const Text('Sim', style: TextStyle(fontSize: 18)),

                  const SizedBox(width: 8),

                  Radio<String>(value: 'Não', activeColor: AppColors.laranja),
                  const Text('Não', style: TextStyle(fontSize: 18)),
                ],
              ),
            ),

            SizedBox(height: 20),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    '3- Você está preparado para um compromisso de longo prazo?',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),

            RadioGroup<String>(
              groupValue: compromisso,
              onChanged: (value) => setState(() => compromisso = value),
              child: Row(
                children: [
                  Radio<String>(value: 'Sim', activeColor: AppColors.verde),
                  const Text('Sim', style: TextStyle(fontSize: 18)),

                  const SizedBox(width: 8),

                  Radio<String>(value: 'Não', activeColor: AppColors.laranja),
                  const Text('Não', style: TextStyle(fontSize: 18)),
                ],
              ),
            ),

            SizedBox(height: 20),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    '4- Todos os moradores concordam com a adoção?',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),

            RadioGroup<String>(
              groupValue: moradores,
              onChanged: (value) => setState(() => moradores = value),
              child: Row(
                children: [
                  Radio<String>(value: 'Sim', activeColor: AppColors.verde),
                  const Text('Sim', style: TextStyle(fontSize: 18)),

                  const SizedBox(width: 8),

                  Radio<String>(value: 'Não', activeColor: AppColors.laranja),
                  const Text('Não', style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
            SizedBox(height: 20),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    '5- Qual é a sua disponibilidade financeira para cuidar do animal?',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),

            RadioGroup<String>(
              groupValue: financeiro,
              onChanged: (value) => setState(() => financeiro = value),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Radio<String>(value: '3', activeColor: AppColors.laranja),
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
                      Radio<String>(value: '2', activeColor: AppColors.laranja),
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
                      Radio<String>(value: '1', activeColor: AppColors.laranja),
                      Expanded(
                        child: Text(
                          'Ainda não tenho condições de assumir esses custos.',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    '6 - Consegue manter uma rotina de alimentação, higiene e cuidados?',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),

            RadioGroup<String>(
              groupValue: rotina,
              onChanged: (value) => setState(() => rotina = value),
              child: Row(
                children: [
                  Radio<String>(value: 'Sim', activeColor: AppColors.verde),
                  const Text('Sim', style: TextStyle(fontSize: 18)),

                  const SizedBox(width: 8),

                  Radio<String>(value: 'Não', activeColor: AppColors.laranja),
                  const Text('Não', style: TextStyle(fontSize: 18)),
                ],
              ),
            ),

            SizedBox(height: 20),

            SizedBox(
              height: 62,
              child: ElevatedButton(
                onPressed: _salvando ? null : avancar,
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
