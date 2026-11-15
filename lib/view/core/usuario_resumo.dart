import 'package:material_ui/material_ui.dart';

import '../../controller/clientes_scope.dart';
import '../usuario/fichaPerfil.dart';
import 'foto_perfil_avatar.dart';

class UsuarioResumo extends StatefulWidget {
  const UsuarioResumo({super.key, required this.clienteId});

  final int? clienteId;

  @override
  State<UsuarioResumo> createState() => _UsuarioResumoState();
}

class _UsuarioResumoState extends State<UsuarioResumo> {
  Future<Map<String, dynamic>>? dados;

  Future<Map<String, dynamic>> _consultar(int id) {
    return ClientesScope.of(context).buscarResumoResponsavelSupabase(id);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.clienteId != null) {
      dados ??= _consultar(widget.clienteId!);
    }
  }

  @override
  void didUpdateWidget(covariant UsuarioResumo oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.clienteId != widget.clienteId) {
      dados = widget.clienteId == null ? null : _consultar(widget.clienteId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.clienteId == null) {
      return const Text('Usuário ainda não vinculado a este item.');
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: dados,
      builder: (context, s) {
        if (s.hasError) {
          return TextButton(
            onPressed: () {
              setState(() {
                dados = _consultar(widget.clienteId!);
              });
            },
            child: const Text('Não foi possível carregar. Tentar novamente'),
          );
        }

        if (!s.hasData) {
          return const LinearProgressIndicator();
        }

        final c = s.data!;
        final imagem = (c['imagem'] as String?) ?? '';

        return ListTile(
          leading: FotoPerfilAvatar(url: imagem),
          title: Text(c['nome'] as String? ?? ''),
          subtitle: Text('@${c['usuario'] ?? ''}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  FichaPerfilScreen(clienteId: (c['id'] as num).toInt()),
            ),
          ),
        );
      },
    );
  }
}
