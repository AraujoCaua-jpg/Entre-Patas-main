import 'package:material_ui/material_ui.dart';

class NotificacoesScreen extends StatelessWidget {
  const NotificacoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Notificações'),
        shape: const Border(
          bottom: BorderSide(
            color: Color(0xFFD96C3F),
            width: 2,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [

            for (final item in ['Solicitação de Adoção Enviada', 'Olívia quer adotar Faísca', 'Adoção de Jujuba foi Aprovada'])
              Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.notifications)),
                  title: Text(item),
                  subtitle: const Text('00:00'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => mostrarMensagem(context, item),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void mostrarMensagem(BuildContext context, String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }
}
