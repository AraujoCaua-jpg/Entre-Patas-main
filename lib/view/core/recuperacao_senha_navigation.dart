import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../controller/clientes_scope.dart';
import '../../services/supabase_auth_service.dart';
import '../usuario/alterarSenha.dart';

// Não desenha uma nova tela: encaminha somente callbacks já verificados pelo SDK.
class RecuperacaoSenhaNavigation extends NavigatorObserver {
  RecuperacaoSenhaNavigation() {
    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      _aoAlterarAutenticacao,
      onError: (Object erro, StackTrace stack) {
        const errosDeLink = {
          'otp_expired',
          'bad_code_verifier',
          'flow_state_not_found',
          'flow_state_expired',
          'invalid_token',
        };
        // getSessionFromUrl usa statusCode para error_code do callback.
        final erroNoLink =
            erro is AuthException &&
            (errosDeLink.contains(erro.code) ||
                errosDeLink.contains(erro.statusCode));
        if (_recuperacaoPendente != null ||
            _rotaAtual?.settings.name == '/recuperar-senha' ||
            erroNoLink) {
          _erroPendente = true;
          _agendarNavegacao();
        }
      },
    );
  }

  final navigatorKey = GlobalKey<NavigatorState>();
  final _auth = SupabaseAuthService();
  late final StreamSubscription<AuthState> _subscription;
  AuthState? _recuperacaoPendente;
  Route<dynamic>? _rotaAtual;
  bool _pronto = false;
  bool _agendado = false;
  bool _disposed = false;
  bool _erroPendente = false;

  void _aoAlterarAutenticacao(AuthState estado) {
    if (_disposed || estado.event != AuthChangeEvent.passwordRecovery) return;
    _auth.registrarRecuperacao(estado);
    if (!_auth.recuperacaoConfirmada) return;
    // O formulário que valida um OTP já está no fluxo correto.
    if (_auth.validandoCodigoRecuperacao) return;
    _recuperacaoPendente = estado;
    _agendarNavegacao();
  }

  void navigatorConstruido() {
    if (_disposed) return;
    _pronto = true;
    _agendarNavegacao();
  }

  void _agendarNavegacao() {
    if (!_pronto ||
        _disposed ||
        _agendado ||
        (_recuperacaoPendente == null && !_erroPendente)) {
      return;
    }
    _agendado = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _agendado = false;
      if (_disposed) return;
      final navegador = navigatorKey.currentState;
      if (navegador == null) return;
      if (_erroPendente) {
        _erroPendente = false;
        ScaffoldMessenger.maybeOf(navegador.context)?.showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível confirmar a autenticação. '
              'Solicite um novo link e tente novamente.',
            ),
          ),
        );
      }
      final estado = _recuperacaoPendente;
      _recuperacaoPendente = null;
      if (estado == null ||
          !_auth.recuperacaoConfirmada ||
          estado.session?.accessToken !=
              Supabase.instance.client.auth.currentSession?.accessToken) {
        return;
      }
      ClientesScope.of(navegador.context).limparSessao();
      // O link pode ser aberto enquanto o formulário de código já está visível.
      // Nesse caso ele próprio atualiza o campo, sem empilhar outra tela.
      if (_rotaAtual?.settings.name == '/recuperar-senha') return;
      navegador.pushAndRemoveUntil(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/recuperar-senha'),
          builder: (_) => const AlterarSenhaScreen(
            recuperacao: true,
            recuperacaoPorLink: true,
          ),
        ),
        (_) => false,
      );
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _rotaAtual = route;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _rotaAtual = previousRoute;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (_rotaAtual == oldRoute) _rotaAtual = newRoute;
  }

  void dispose() {
    _disposed = true;
    unawaited(_subscription.cancel());
  }
}
