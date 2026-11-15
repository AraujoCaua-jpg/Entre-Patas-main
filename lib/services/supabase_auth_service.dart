import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_exception.dart';
import '../service/validacao_senha.dart';

class ReautenticacaoNecessariaException extends LoginException {
  const ReautenticacaoNecessariaException()
    : super('Confirme o código enviado por e-mail para alterar sua senha.');
}

class SupabaseAuthService {
  final SupabaseClient _client = Supabase.instance.client;
  static String? _tokenRecuperacao;
  static String? _tokenSenhaAtualVerificada;
  static SupabaseClient? _clienteRecuperacao;
  static SupabaseClient? _clienteSenhaVerificada;
  static bool _validandoCodigoRecuperacao = false;

  // Entrar com e-mail e senha
  Future<AuthResponse> entrar(String email, String senha) async {
    return await _client.auth.signInWithPassword(
      email: email.trim(),
      password: senha,
    );
  }

  // Verificar usuário autenticado
  User? get usuarioAtual => _client.auth.currentUser;

  bool get validandoCodigoRecuperacao => _validandoCodigoRecuperacao;

  bool get recuperacaoConfirmada {
    final sessao = _client.auth.currentSession;
    return sessao != null &&
        !sessao.isExpired &&
        identical(_clienteRecuperacao, _client) &&
        sessao.accessToken == _tokenRecuperacao;
  }

  // Apenas o evento emitido pelo SDK após verificar um link pode autorizar
  // a redefinição. Um parâmetro de rota, sozinho, não concede essa permissão.
  void registrarRecuperacao(AuthState estado) {
    final sessao = estado.session;
    if (estado.event == AuthChangeEvent.passwordRecovery &&
        sessao != null &&
        sessao.accessToken == _client.auth.currentSession?.accessToken) {
      _tokenRecuperacao = sessao.accessToken;
      _clienteRecuperacao = _client;
    }
  }

  Future<void> alterarSenha(
    String atual,
    String nova, {
    String? codigoReautenticacao,
  }) async {
    _validarNovaSenha(nova);
    final usuario = _usuarioAutenticado();
    final email = usuario.email;
    if (atual.isEmpty || email == null || email.isEmpty) {
      throw const LoginException('Informe sua senha atual para continuar.');
    }

    await _executar(() async {
      if (codigoReautenticacao == null) {
        // Renovar a sessão com a senha atual atende à autenticação recente.
        final resposta = await _client.auth.signInWithPassword(
          email: email,
          password: atual,
        );
        if (resposta.user?.id != usuario.id || resposta.session == null) {
          throw const LoginException('Entre novamente para alterar sua senha.');
        }
        _tokenSenhaAtualVerificada = resposta.session!.accessToken;
        _clienteSenhaVerificada = _client;
      } else if (!identical(_clienteSenhaVerificada, _client) ||
          _client.auth.currentSession?.accessToken !=
              _tokenSenhaAtualVerificada) {
        throw const LoginException('Confirme sua senha atual novamente.');
      }

      _confirmarUsuario(usuario.id);
      final resultado = await _client.auth.updateUser(
        UserAttributes(
          password: nova,
          currentPassword: atual,
          nonce: codigoReautenticacao?.trim(),
        ),
      );
      if (resultado.user?.id != usuario.id) {
        throw const LoginException(
          'Não foi possível confirmar a alteração da senha.',
        );
      }
      _tokenSenhaAtualVerificada = null;
      _clienteSenhaVerificada = null;
    }, 'Não foi possível alterar a senha. Tente novamente.');
  }

  Future<void> solicitarCodigoReautenticacao() async {
    _usuarioAutenticado();
    await _executar(
      () => _client.auth.reauthenticate(),
      'Não foi possível enviar o código. Tente novamente.',
    );
  }

  Future<void> solicitarRecuperacao(String email, {String? redirectTo}) async {
    _tokenRecuperacao = null;
    _clienteRecuperacao = null;
    await _executar(() async {
      try {
        await _client.auth.resetPasswordForEmail(
          email.trim().toLowerCase(),
          redirectTo: redirectTo,
        );
      } on AuthException catch (erro) {
        // A solicitação não informa se o endereço pertence a uma conta.
        if (erro.code != 'user_not_found') rethrow;
      }
    }, 'Não foi possível solicitar a recuperação. Tente novamente.');
  }

  Future<void> verificarCodigoRecuperacao(String email, String codigo) async {
    if (email.trim().isEmpty || codigo.trim().isEmpty) {
      throw const LoginException('Informe o código recebido por e-mail.');
    }
    _validandoCodigoRecuperacao = true;
    try {
      await _executar(() async {
        final resposta = await _client.auth.verifyOTP(
          email: email.trim().toLowerCase(),
          token: codigo.trim(),
          type: OtpType.recovery,
        );
        final sessao = resposta.session;
        if (sessao == null ||
            sessao.accessToken != _client.auth.currentSession?.accessToken) {
          throw const LoginException(
            'Código ou link inválido ou expirado. Solicite a recuperação novamente.',
          );
        }
        _tokenRecuperacao = sessao.accessToken;
        _clienteRecuperacao = _client;
      }, 'Não foi possível validar o código. Tente novamente.');
    } finally {
      _validandoCodigoRecuperacao = false;
    }
  }

  Future<void> redefinirSenha(
    String nova, {
    String? codigoReautenticacao,
  }) async {
    if (!recuperacaoConfirmada) {
      throw const LoginException(
        'Confirme o link ou código recebido por e-mail antes de redefinir a senha.',
      );
    }
    _validarNovaSenha(nova);
    await _executar(() async {
      final usuarioId = _usuarioAutenticado().id;
      final resultado = await _client.auth.updateUser(
        UserAttributes(password: nova, nonce: codigoReautenticacao?.trim()),
      );
      if (resultado.user?.id != usuarioId) {
        throw const LoginException(
          'Não foi possível confirmar a alteração da senha.',
        );
      }
      _tokenRecuperacao = null;
      _clienteRecuperacao = null;
    }, 'Não foi possível alterar a senha. Tente novamente.');
  }

  Future<void> solicitarAlteracaoEmail(
    String novoEmail, {
    String? redirectTo,
  }) async {
    _usuarioAutenticado();
    await _executar(() async {
      // O perfil continua usando o e-mail confirmado. A sincronização com
      // cliente deve ocorrer no banco após a confirmação do Supabase Auth.
      await _client.auth.updateUser(
        UserAttributes(email: novoEmail.trim().toLowerCase()),
        emailRedirectTo: redirectTo,
      );
    }, 'Não foi possível solicitar a alteração do e-mail. Tente novamente.');
  }

  Future<bool> apagarConta(String senha) async {
    final usuario = _usuarioAutenticado();
    final email = usuario.email;
    if (senha.isEmpty || email == null || email.isEmpty) {
      throw const LoginException(
        'Informe sua senha atual para confirmar a exclusão.',
      );
    }

    try {
      final autenticacao = await _client.auth.signInWithPassword(
        email: email,
        password: senha,
      );
      if (autenticacao.user?.id != usuario.id ||
          autenticacao.session == null ||
          _client.auth.currentUser?.id != usuario.id) {
        throw const LoginException(
          'Entre novamente para confirmar a exclusão da conta.',
        );
      }

      final resposta = await _client.functions.invoke('excluir-conta');
      final dados = resposta.data;
      if (resposta.status < 200 ||
          resposta.status >= 300 ||
          dados is! Map ||
          dados['deleted'] != true) {
        throw const LoginException(
          'Não foi possível confirmar a exclusão da conta.',
        );
      }

      try {
        await _client.auth.signOut(scope: SignOutScope.local);
      } on AuthException {
        if (_client.auth.currentUser != null) rethrow;
      }
      return dados['storageCleanupPending'] == true;
    } on LoginException {
      rethrow;
    } on AuthException catch (erro) {
      throw traduzirErro(
        erro,
        mensagemPadrao: 'Não foi possível confirmar sua identidade.',
      );
    } on FunctionException catch (erro) {
      if (erro.status == 401 || erro.status == 403) {
        throw const LoginException(
          'Confirme sua identidade novamente para excluir a conta.',
        );
      }
      if (erro.status == 404) {
        throw const LoginException(
          'A exclusão de conta ainda precisa ser configurada no Supabase.',
        );
      }
      throw const LoginException(
        'Não foi possível excluir a conta. Tente novamente.',
      );
    }
  }

  User _usuarioAutenticado() {
    final usuario = _client.auth.currentUser;
    if (usuario == null || _client.auth.currentSession == null) {
      throw const LoginException('Entre novamente para continuar.');
    }
    return usuario;
  }

  void _confirmarUsuario(String id) {
    if (_client.auth.currentUser?.id != id) {
      throw const LoginException('Entre novamente para continuar.');
    }
  }

  void _validarNovaSenha(String senha) {
    final erro = validarSenha(senha);
    if (erro != null) throw LoginException(erro);
  }

  Future<void> _executar(
    Future<void> Function() operacao,
    String mensagemPadrao,
  ) async {
    try {
      await operacao();
    } on LoginException {
      rethrow;
    } on AuthException catch (erro) {
      throw traduzirErro(erro, mensagemPadrao: mensagemPadrao);
    } catch (_) {
      throw LoginException(mensagemPadrao);
    }
  }

  static LoginException traduzirErro(
    AuthException erro, {
    String mensagemPadrao = 'Não foi possível concluir. Tente novamente.',
  }) {
    switch (erro.code) {
      case 'invalid_credentials':
        return const LoginException('Senha atual incorreta. Tente novamente.');
      case 'weak_password':
        return const LoginException(
          'A senha deve atender a todos os requisitos indicados.',
        );
      case 'same_password':
        return const LoginException(
          'A nova senha deve ser diferente da atual.',
        );
      case 'reauthentication_needed':
      case 'reauth_nonce_missing':
        return const ReautenticacaoNecessariaException();
      case 'reauthentication_not_valid':
        return const LoginException(
          'Código de confirmação inválido ou expirado.',
        );
      case 'otp_expired':
      case 'otp_disabled':
      case 'bad_code_verifier':
      case 'flow_state_not_found':
      case 'flow_state_expired':
        return const LoginException(
          'Código ou link inválido ou expirado. Solicite a recuperação novamente.',
        );
      case 'email_exists':
      case 'email_address_not_authorized':
        return const LoginException('Não foi possível utilizar este e-mail.');
      case 'over_request_rate_limit':
      case 'over_email_send_rate_limit':
        return const LoginException(
          'Aguarde alguns instantes antes de tentar novamente.',
        );
      case 'session_not_found':
      case 'session_expired':
      case 'session_missing':
      case 'bad_jwt':
      case 'no_authorization':
        return const LoginException('Sua sessão expirou. Entre novamente.');
      case 'email_not_confirmed':
        return const LoginException('Confirme seu e-mail antes de continuar.');
      case 'insufficient_aal':
        return const LoginException(
          'Confirme a autenticação da sua conta antes de continuar.',
        );
    }
    if (erro is AuthRetryableFetchException) {
      return const LoginException(
        'Não foi possível acessar o servidor. Confira sua conexão e tente novamente.',
      );
    }
    return LoginException(mensagemPadrao);
  }

  // Encerrar sessão
  Future<void> sair() async {
    final sessao = _client.auth.currentSession;
    if (sessao == null) return;

    try {
      await _client.auth.signOut(scope: SignOutScope.local);
    } catch (erro, stackTrace) {
      await _client.auth.recoverSession(jsonEncode(sessao.toJson()));
      Error.throwWithStackTrace(erro, stackTrace);
    }
  }
}
