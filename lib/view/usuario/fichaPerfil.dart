import 'package:material_ui/material_ui.dart';

import '../../controller/clientes_scope.dart';
import '../../model/cliente.dart';
import '../../service/auth_api.dart';

class FichaPerfilScreen extends StatefulWidget {
  const FichaPerfilScreen({super.key, this.clienteId});
  final int? clienteId;
  @override
  State<FichaPerfilScreen> createState() => _FichaPerfilScreenState();
}

class _FichaPerfilScreenState extends State<FichaPerfilScreen> {
  Future<Cliente>? dados;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.clienteId != null) {
      dados ??= ClientesScope.of(context)
          .buscarClienteRemoto(widget.clienteId!);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Perfil do usuário')),
    body: widget.clienteId == null
        ? const Center(
            child: Text('Este item ainda não tem um usuário vinculado.'),
          )
        : FutureBuilder<Cliente>(
            future: dados,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        snapshot.error is LoginException
                            ? (snapshot.error as LoginException).mensagem
                            : 'Não foi possível carregar o perfil.',
                      ),
                      TextButton(
                        onPressed: () {
                          final consulta = ClientesScope.of(context)
                              .buscarClienteRemoto(widget.clienteId!);
                          setState(() {
                            dados = consulta;
                          });
                        },
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final c = snapshot.data!;
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: c.imageUrl?.isNotEmpty == true
                        ? NetworkImage(c.imageUrl!)
                        : null,
                    child: c.imageUrl?.isNotEmpty == true
                        ? null
                        : const Icon(Icons.person, size: 48),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${c.nome} ${c.sobrenome}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 26),
                  ),
                  Text('@${c.usuario}', textAlign: TextAlign.center),
                  Text(
                    '${c.cidadeDeResidencia} ${c.estado ?? ''}',
                    textAlign: TextAlign.center,
                  ),
                  if (c.larDeAdocao) ...[
                    const Divider(),
                    const Text('Lar de adoção'),
                    Text(c.email),
                    Text(c.telefone),
                    Text(c.endereco ?? ''),
                  ],
                ],
              );
            },
          ),
  );
}
