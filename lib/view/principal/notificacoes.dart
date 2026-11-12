import 'package:material_ui/material_ui.dart';

import '../../controller/clientes_scope.dart';
import '../../model/adocao.dart';
import '../../service/auth_api.dart';
import '../animal/adocao.dart';
import '../core/app_colors.dart';

class NotificacoesScreen extends StatefulWidget {
  const NotificacoesScreen({super.key});
  @override
  State<NotificacoesScreen> createState() => _NotificacoesScreenState();
}

class _NotificacoesScreenState extends State<NotificacoesScreen> {
  Future<List<Adocao>>? _consulta;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _consulta ??= ClientesScope.of(context).listarAdocoes();
  }

  void _atualizar() {
    final consulta = ClientesScope.of(context).listarAdocoes();
    setState(() {
      _consulta = consulta;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      title: const Text('Notificações'),
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: _atualizar,
          icon: const Icon(Icons.refresh),
        ),
      ],
      shape: const Border(
        bottom: BorderSide(color: AppColors.laranja, width: 2),
      ),
    ),
    body: FutureBuilder<List<Adocao>>(
      future: _consulta,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(
            child: TextButton(
              onPressed: _atualizar,
              child: Text(
                snapshot.error is LoginException
                    ? (snapshot.error as LoginException).mensagem
                    : 'Não foi possível carregar as solicitações.',
              ),
            ),
          );
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final lista = snapshot.data!;
        if (lista.isEmpty)
          return const Center(child: Text('Nenhuma solicitação de adoção.'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: lista.length,
          itemBuilder: (context, i) {
            final a = lista[i];
            final dono =
                a.idDono == ClientesScope.of(context).clienteLogado?.id;
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.notifications)),
                title: Text(
                  dono
                      ? '${a.detalhes['solicitante_nome']} quer adotar ${a.detalhes['animal_nome']}'
                      : 'Sua solicitação para ${a.detalhes['animal_nome']}',
                ),
                subtitle: Text(
                  '${a.status} • ${a.data.day}/${a.data.month}/${a.data.year}',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdocaoScreen(adocaoId: a.id),
                    ),
                  );
                  if (mounted) _atualizar();
                },
              ),
            );
          },
        );
      },
    ),
  );
}
