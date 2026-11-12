import 'package:material_ui/material_ui.dart';

import '../core/app_colors.dart';
import '../questionario/testeComp.dart';

class CompatibilidadeAnimal extends StatelessWidget {
  const CompatibilidadeAnimal({
    super.key,
    required this.dados,
    required this.atualizar,
  });
  final Map<String, dynamic>? dados;
  final VoidCallback atualizar;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Compatibilidade', style: TextStyle(fontSize: 24)),
      const SizedBox(height: 10),
      if (dados != null) ...[
        for (final item in {
          'rotina': 'Rotina',
          'ambiente': 'Ambiente',
          'preferencias': 'Preferências',
        }.entries) ...[
          Text(
            '${item.value}: ${dados![item.key]}%',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (dados![item.key] as num).toDouble() / 100,
              minHeight: 12,
              backgroundColor: AppColors.cinza,
              valueColor: const AlwaysStoppedAnimation(AppColors.laranja),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Text(
          'Nota de Compatibilidade: ${dados!['total']}%',
          style: const TextStyle(fontSize: 18, color: AppColors.verde),
        ),
        const Text(
          'Nota = (Rotina × 5 + Ambiente × 3 + Preferências × 2) / 10',
          style: TextStyle(fontSize: 10, color: AppColors.cinzaEscuro),
        ),
        const SizedBox(height: 8),
        const Text(
          'Afinidade estimada pelas suas respostas. A decisão de adoção é do responsável.',
        ),
      ] else
        const Text('Responda ao teste para ver sua afinidade com este animal.'),
      TextButton.icon(
        icon: const Icon(
          Icons.question_answer_outlined,
          color: AppColors.laranja,
        ),
        label: Text(
          dados == null
              ? 'Fazer teste de compatibilidade'
              : 'Refazer teste de compatibilidade',
        ),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TesteCompScreen()),
          );
          if (context.mounted) atualizar();
        },
      ),
    ],
  );
}
