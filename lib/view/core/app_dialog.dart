import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });

  final Widget title;
  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: AppColors.rosaClaro),
    ),
    titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
    contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
    actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.rosa,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.pets_outlined,
            color: AppColors.laranja,
            size: 26,
          ),
        ),
        const SizedBox(height: 16),
        title,
      ],
    ),
    titleTextStyle: const TextStyle(
      fontFamily: 'NunitoSans',
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: Color(0xFF60483E),
    ),
    contentTextStyle: const TextStyle(
      fontFamily: 'NunitoSans',
      fontSize: 15,
      height: 1.5,
      color: Color(0xFF60483E),
    ),
    content: content,
    scrollable: true,
    actions: [
      SizedBox(
        width: double.infinity,
        child: Row(
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    textButtonTheme: TextButtonThemeData(
                      style: _style(i == actions.length - 1),
                    ),
                    elevatedButtonTheme: ElevatedButtonThemeData(
                      style: _style(i == actions.length - 1),
                    ),
                    filledButtonTheme: FilledButtonThemeData(
                      style: _style(i == actions.length - 1),
                    ),
                  ),
                  child: actions[i],
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );

  ButtonStyle _style(bool principal) => TextButton.styleFrom(
    backgroundColor: principal ? AppColors.laranja : AppColors.rosa,
    foregroundColor: principal ? Colors.white : AppColors.laranja,
    minimumSize: const Size(0, 48),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    textStyle: const TextStyle(
      fontFamily: 'NunitoSans',
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    elevation: 0,
  );
}
