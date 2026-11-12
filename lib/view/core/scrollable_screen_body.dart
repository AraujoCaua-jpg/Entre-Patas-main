import 'package:material_ui/material_ui.dart';

/// Centers forms on wide windows and allows scrolling on short screens.
class ScrollableScreenBody extends StatelessWidget {
  const ScrollableScreenBody({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: padding,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 560,
                minHeight: (constraints.maxHeight - padding.vertical).clamp(
                  0.0,
                  double.infinity,
                ),
              ),
              child: IntrinsicHeight(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
