import 'package:flutter/widgets.dart';

import 'cliente_controller.dart';

// Mantém uma instância por execução, acima do Navigator e de suas rotas.
class ClientesScope extends StatefulWidget {
  const ClientesScope({super.key, required this.child, this.controller});

  final Widget child;
  final ClienteController? controller;

  static ClienteController of(BuildContext context) {
    final dados = context.dependOnInheritedWidgetOfExactType<_ClientesDados>();
    assert(dados != null, 'Coloque ClientesScope acima do MaterialApp.');
    return dados!.controller;
  }

  @override
  State<ClientesScope> createState() => _ClientesScopeState();
}

class _ClientesScopeState extends State<ClientesScope> {
  late final ClienteController _controller =
      widget.controller ?? ClienteController();

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ClientesDados(controller: _controller, child: widget.child);
  }
}

class _ClientesDados extends InheritedNotifier<ClienteController> {
  const _ClientesDados({
    required ClienteController controller,
    required super.child,
  }) : super(notifier: controller);

  ClienteController get controller => notifier!;
}
