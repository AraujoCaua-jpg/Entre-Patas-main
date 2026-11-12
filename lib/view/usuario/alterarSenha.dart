import 'package:material_ui/material_ui.dart';

import '../../controller/clientes_scope.dart';
import '../../service/auth_api.dart';
import '../../service/clientes_api.dart';
import '../autenticacao/login.dart';
import '../core/scrollable_screen_body.dart';

class AlterarSenhaScreen extends StatefulWidget {
  const AlterarSenhaScreen({super.key, this.recuperacao = false});
  final bool recuperacao;
  @override
  State<AlterarSenhaScreen> createState() => _AlterarSenhaScreenState();
}

class _AlterarSenhaScreenState extends State<AlterarSenhaScreen> {
  final atual = TextEditingController();
  final nova = TextEditingController();
  final confirmacao = TextEditingController();
  final api = ClientesApi();
  bool salvando = false;
  @override
  void dispose() {
    atual.dispose();
    nova.dispose();
    confirmacao.dispose();
    api.close();
    super.dispose();
  }

  Future<void> salvar() async {
    if (salvando) return;
    if (nova.text != confirmacao.text ||
        nova.text.isEmpty ||
        atual.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha os campos e confirme a mesma senha.'),
        ),
      );
      return;
    }
    final controller = ClientesScope.of(context);
    setState(() => salvando = true);
    try {
      if (widget.recuperacao) {
        await api.recuperar(atual.text, nova.text);
      } else {
        await controller.alterarSenha(atual.text, nova.text);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha atualizada. Entre novamente.')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } on LoginException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.mensagem)));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível alterar a senha.')),
        );
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Alterar senha')),
    body: ScrollableScreenBody(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.recuperacao
                ? 'Digite o código recebido por e-mail'
                : 'Confirme sua senha atual',
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: atual,
            obscureText: !widget.recuperacao,
            decoration: InputDecoration(
              labelText: widget.recuperacao
                  ? 'Código de recuperação'
                  : 'Senha atual',
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nova senha: de 8 a 72 bytes, com maiúscula, minúscula, número e símbolo.',
          ),
          TextField(
            controller: nova,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Nova senha'),
          ),
          TextField(
            controller: confirmacao,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirme a nova senha',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: salvando ? null : salvar,
            child: Text(salvando ? 'Salvando...' : 'Salvar senha'),
          ),
        ],
      ),
    ),
  );
}
