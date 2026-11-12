import 'package:material_ui/material_ui.dart';

import '../../controller/clientes_scope.dart';
import '../../model/cliente.dart';
import '../usuario/fichaPerfil.dart';

class UsuarioResumo extends StatefulWidget {
  const UsuarioResumo({super.key, required this.clienteId});
  final int? clienteId;
  @override
  State<UsuarioResumo> createState() => _UsuarioResumoState();
}

class _UsuarioResumoState extends State<UsuarioResumo> {
  Future<Cliente>? dados;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.clienteId != null)
      dados ??= ClientesScope.of(context)
          .buscarClienteRemoto(widget.clienteId!, basico: true);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.clienteId == null)
      return const Text('Usuário ainda não vinculado a este item.');
    return FutureBuilder<Cliente>(
      future: dados,
      builder: (context, s) {
        if (s.hasError)
          return TextButton(
            onPressed: () => setState(
              () =>
                  dados = ClientesScope.of(context)
                      .buscarClienteRemoto(widget.clienteId!, basico: true),
            ),
            child: const Text('Não foi possível carregar. Tentar novamente'),
          );
        if (!s.hasData) return const LinearProgressIndicator();
        final c = s.data!;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: c.imageUrl?.isNotEmpty == true
                ? NetworkImage(c.imageUrl!)
                : null,
            child: c.imageUrl?.isNotEmpty == true
                ? null
                : const Icon(Icons.person),
          ),
          title: Text(c.nome),
          subtitle: Text('@${c.usuario}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FichaPerfilScreen(clienteId: c.id),
            ),
          ),
        );
      },
    );
  }
}
