import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../controller/clientes_scope.dart';
import '../../services/navegacao_persistida_service.dart';
import '../../services/supabase_auth_service.dart';
import '../autenticacao/bem_vindo.dart';
import '../autenticacao/login.dart';
import '../navagacao.dart';
import '../questionario/teste_comp.dart';
import 'pagina_atual_navigation.dart';

class RestaurarSessaoScreen extends StatefulWidget {
  const RestaurarSessaoScreen({super.key});
  @override
  State<RestaurarSessaoScreen> createState() => _RestaurarSessaoScreenState();
}

class _RestaurarSessaoScreenState extends State<RestaurarSessaoScreen> {
  final _persistencia = NavegacaoPersistidaService();
  bool _iniciado = false;
  bool _erro = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_iniciado) {
      _iniciado = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _restaurar());
    }
  }

  bool get _recuperandoSenha => SupabaseAuthService().recuperacaoConfirmada;

  void _abrir(Widget principal, Widget? detalhes, String usuarioId) {
    final navegador = Navigator.of(context);
    final rota = MaterialPageRoute<void>(builder: (_) => principal);
    navegador.pushReplacement(rota);
    if (detalhes == null) return;
    final animacao = rota.animation!;
    void aoAnimar(AnimationStatus status) {
      if (status != AnimationStatus.completed) return;
      animacao.removeStatusListener(aoAnimar);
      if (rota.isCurrent &&
          !_recuperandoSenha &&
          Supabase.instance.client.auth.currentUser?.id == usuarioId) {
        navegador.push(MaterialPageRoute<void>(builder: (_) => detalhes));
      }
    }

    if (animacao.status == AnimationStatus.completed) {
      aoAnimar(AnimationStatus.completed);
    } else {
      animacao.addStatusListener(aoAnimar);
    }
  }

  Future<void> _restaurar() async {
    if (!mounted || _recuperandoSenha) return;
    setState(() => _erro = false);
    final auth = Supabase.instance.client.auth;
    final usuarioId = auth.currentUser?.id;
    final navegador = Navigator.of(context);
    if (auth.currentSession == null || usuarioId == null) {
      navegador.pushReplacement(
        MaterialPageRoute(builder: (_) => const BemVindoScreen()),
      );
      return;
    }
    try {
      if (auth.currentSession!.isExpired) await auth.refreshSession();
      if (!mounted || _recuperandoSenha) return;
      final controller = ClientesScope.of(context);
      await controller.carregarMeuPerfilSupabase();
      final questionario = await controller.carregarQuestionario();
      Map<String, dynamic>? pagina;
      try {
        pagina = await _persistencia.carregar(usuarioId);
      } catch (_) {
        // A sessão ainda pode ser retomada se o armazenamento local falhar.
      }
      if (!mounted || _recuperandoSenha || auth.currentUser?.id != usuarioId) {
        return;
      }
      final etapaTeste = pagina?['pagina']?.toString() ?? '';
      if (questionario == null) {
        final destino =
            etapaTeste.startsWith('teste') && etapaTeste != 'teste_fim'
            ? PaginaAtualNavigation.reconstruir(pagina!)
            : null;
        _abrir(
          const TesteCompScreen(),
          destino is TesteCompScreen ? null : destino,
          usuarioId,
        );
        return;
      }
      final aba = pagina?['aba'];
      final indice = aba is int && aba >= 0 && aba <= 2 ? aba : 0;
      final destino = pagina == null
          ? null
          : PaginaAtualNavigation.reconstruir(pagina);
      _abrir(NavegacaoScreen(paginaInicial: indice), destino, usuarioId);
    } catch (_) {
      if (mounted && !_recuperandoSenha) setState(() => _erro = true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: _erro
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Não foi possível recuperar sua sessão. Confira a conexão e tente novamente.',
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: _restaurar,
                    child: const Text('Tentar novamente'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: const Text('Fazer login'),
                  ),
                ],
              ),
            )
          : const CircularProgressIndicator(),
    ),
  );
}
