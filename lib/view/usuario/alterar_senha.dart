import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../controller/clientes_scope.dart';
import '../../services/login_exception.dart';
import '../../service/validacao_senha.dart';
import '../../services/supabase_auth_service.dart';
import '../autenticacao/login.dart';
import '../core/app_colors.dart';
import '../core/scrollable_screen_body.dart';

class AlterarSenhaScreen extends StatefulWidget {
  const AlterarSenhaScreen({
    super.key,
    this.recuperacao = false,
    this.emailRecuperacao,
    this.recuperacaoPorLink = false,
  });
  final bool recuperacao;
  final String? emailRecuperacao;
  final bool recuperacaoPorLink;
  @override
  State<AlterarSenhaScreen> createState() => _AlterarSenhaScreenState();
}

class _AlterarSenhaScreenState extends State<AlterarSenhaScreen> {
  final atual = TextEditingController();
  final nova = TextEditingController();
  final confirmacao = TextEditingController();
  final _auth = SupabaseAuthService();
  bool salvando = false;
  bool mostrarSenha = false;
  bool _aguardandoReautenticacao = false;
  String _senhaAtualConfirmada = '';
  bool _linkConfirmado = false;
  StreamSubscription<AuthState>? _recuperacaoSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.recuperacaoPorLink && _auth.recuperacaoConfirmada) {
      _linkConfirmado = true;
      atual.text = 'Confirmado pelo link';
    }
    if (widget.recuperacao) {
      _recuperacaoSubscription = Supabase.instance.client.auth.onAuthStateChange
          .listen((estado) {
            if (!mounted ||
                salvando ||
                estado.event != AuthChangeEvent.passwordRecovery ||
                !_auth.recuperacaoConfirmada ||
                _auth.validandoCodigoRecuperacao) {
              return;
            }
            setState(() {
              _linkConfirmado = true;
              atual.text = 'Confirmado pelo link';
            });
          }, onError: (Object erro, StackTrace stack) {});
    }
  }

  Map<String, bool> get requisitos => requisitosSenha(nova.text);

  @override
  void dispose() {
    unawaited(_recuperacaoSubscription?.cancel());
    atual.dispose();
    nova.dispose();
    confirmacao.dispose();
    _senhaAtualConfirmada = '';
    super.dispose();
  }

  Future<void> salvar() async {
    if (salvando) return;
    if (nova.text != confirmacao.text ||
        nova.text.isEmpty ||
        (atual.text.isEmpty &&
            (!widget.recuperacao ||
                !_auth.recuperacaoConfirmada ||
                _aguardandoReautenticacao))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha os campos e confirme a mesma senha.'),
        ),
      );
      return;
    }
    final erroSenha = validarSenha(nova.text);
    if (erroSenha != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(erroSenha)));
      return;
    }
    final controller = ClientesScope.of(context);
    setState(() => salvando = true);
    try {
      if (widget.recuperacao) {
        if (!_auth.recuperacaoConfirmada) {
          final email = widget.emailRecuperacao;
          if (email == null) {
            throw const LoginException(
              'Abra o link recebido por e-mail para recuperar sua senha.',
            );
          }
          await _auth.verificarCodigoRecuperacao(email, atual.text.trim());
          controller.limparSessao();
        }
        await _auth.redefinirSenha(
          nova.text,
          codigoReautenticacao: _aguardandoReautenticacao
              ? atual.text.trim()
              : null,
        );
      } else {
        if (!_aguardandoReautenticacao) {
          _senhaAtualConfirmada = atual.text;
        }
        await controller.alterarSenha(
          _senhaAtualConfirmada,
          nova.text,
          codigoReautenticacao: _aguardandoReautenticacao
              ? atual.text.trim()
              : null,
        );
      }
      if (!mounted) return;
      _senhaAtualConfirmada = '';
      if (widget.recuperacao) controller.limparSessao();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha atualizada. Entre novamente.')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } on ReautenticacaoNecessariaException {
      try {
        await _auth.solicitarCodigoReautenticacao();
        if (!mounted) return;
        setState(() {
          _aguardandoReautenticacao = true;
          atual.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Digite o código de reautenticação enviado ao seu e-mail.',
            ),
          ),
        );
      } on LoginException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.mensagem)));
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível enviar o código. Tente novamente.'),
          ),
        );
      }
    } on LoginException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.mensagem)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível alterar a senha.')),
        );
      }
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titulo = _aguardandoReautenticacao
        ? 'Digite o código de reautenticação'
        : widget.recuperacao
        ? 'Digite o código recebido por e-mail'
        : 'Confirme sua senha atual';

    final labelAtual = _aguardandoReautenticacao
        ? 'Código de reautenticação'
        : widget.recuperacao
        ? 'Código de recuperação'
        : 'Senha atual';

    return Scaffold(
      backgroundColor: AppColors.fundo,
      appBar: AppBar(
        backgroundColor: AppColors.fundo,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back, color: AppColors.laranja),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Image.asset('assets/logo.png', height: 25, fit: BoxFit.contain),
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFD96C3F), width: 2),
        ),
      ),
      body: ScrollableScreenBody(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.rosaClaro,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: AppColors.laranja,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.recuperacao ? 'Alterar senha' : 'Senha',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    titulo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2EC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sua senha deve conter pelo menos:',
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                        for (final requisito in requisitos.entries)
                          Row(
                            children: [
                              Icon(
                                requisito.value
                                    ? Icons.check_circle_outline
                                    : Icons.cancel_outlined,
                                size: 16,
                                color: requisito.value
                                    ? Colors.green.shade800
                                    : Colors.red.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                requisito.key,
                                style: TextStyle(
                                  color: requisito.value
                                      ? Colors.green.shade800
                                      : Colors.red.shade700,
                                  fontSize: 14,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: atual,
                    readOnly:
                        _linkConfirmado &&
                        _auth.recuperacaoConfirmada &&
                        !_aguardandoReautenticacao,
                    obscureText:
                        !widget.recuperacao &&
                        !_aguardandoReautenticacao &&
                        !mostrarSenha,
                    decoration: InputDecoration(
                      hintText: labelAtual,
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFF888888),
                      ),
                      suffixIcon: widget.recuperacao
                          ? null
                          : IconButton(
                              icon: Icon(
                                mostrarSenha
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() => mostrarSenha = !mostrarSenha);
                              },
                            ),
                      filled: true,
                      fillColor: AppColors.cinza,
                      hintStyle: const TextStyle(color: Color(0xFF888888)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nova,
                    onChanged: (_) => setState(() {}),
                    obscureText: !mostrarSenha,
                    decoration: InputDecoration(
                      hintText: 'Nova senha',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFF888888),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          mostrarSenha
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => mostrarSenha = !mostrarSenha);
                        },
                      ),
                      filled: true,
                      fillColor: AppColors.cinza,
                      hintStyle: const TextStyle(color: Color(0xFF888888)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: confirmacao,
                    obscureText: !mostrarSenha,
                    decoration: InputDecoration(
                      hintText: 'Digite Novamente',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFF888888),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          mostrarSenha
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => mostrarSenha = !mostrarSenha);
                        },
                      ),
                      filled: true,
                      fillColor: AppColors.cinza,
                      hintStyle: const TextStyle(color: Color(0xFF888888)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 62,
                    child: ElevatedButton(
                      onPressed: salvando ? null : salvar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.laranja,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            salvando ? 'Salvando...' : 'Entrar',
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.arrow_forward),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
