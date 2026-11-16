import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/navegacao_persistida_service.dart';
import '../navagacao.dart';
import '../animal/ficha_animal.dart';
import '../animal/cadastro_animal.dart';
import '../animal/editar_animal.dart';
import '../animal/animais_cadastrados.dart';
import '../animal/adocao.dart';
import '../principal/notificacoes.dart';
import '../usuario/ficha_perfil.dart';
import '../usuario/editar_perfil.dart';
import '../usuario/configuracoes.dart';
import '../usuario/alterar_senha.dart';
import '../questionario/teste_comp.dart';
import '../questionario/teste_comp_a.dart';
import '../questionario/teste_comp_b.dart';
import '../questionario/teste_comp_c.dart';
import '../questionario/teste_comp_fim.dart';

/// Guarda apenas a localização e argumentos de navegação, nunca credenciais.
class PaginaAtualNavigation extends NavigatorObserver {
  PaginaAtualNavigation() {
    NavegacaoPersistidaService.abaAtual.addListener(_agendar);
    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      estado,
    ) {
      final anterior = _usuarioId;
      _usuarioId = estado.session?.user.id;
      if (estado.event == AuthChangeEvent.signedOut && anterior != null) {
        _guardar(anterior, null);
      }
    });
  }

  String? _usuarioId = Supabase.instance.client.auth.currentUser?.id;
  late final StreamSubscription<AuthState> _subscription;
  PageRoute<dynamic>? _pagina;
  bool _disposed = false;
  final _persistencia = NavegacaoPersistidaService();

  void _guardar(String id, Map<String, dynamic>? dados) {
    unawaited(
      _persistencia.salvar(id, dados).catchError((Object _) {
        // Falha local não bloqueia a navegação nem a autenticação.
      }),
    );
  }

  void _agendar() {
    final pagina = _pagina;
    final usuario = Supabase.instance.client.auth.currentUser?.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed ||
          pagina == null ||
          pagina != _pagina ||
          usuario == null ||
          Supabase.instance.client.auth.currentUser?.id != usuario) {
        return;
      }
      Map<String, dynamic>? dados;
      void visitar(Element element) {
        if (dados != null) return;
        dados = descrever(element.widget);
        if (dados == null) element.visitChildElements(visitar);
      }

      pagina.subtreeContext?.visitChildElements(visitar);
      if (dados != null) {
        _guardar(usuario, {
          ...dados!,
          'aba': NavegacaoPersistidaService.abaAtual.value,
        });
      }
    });
  }

  static Map<String, dynamic>? descrever(Widget widget) {
    if (widget is NavegacaoScreen) return {'pagina': 'navegacao'};
    if (widget is FichaAnimalScreen) {
      return {'pagina': 'animal', 'id': widget.animalId};
    }
    if (widget is CadastroAnimalScreen) {
      return {'pagina': 'cadastro_animal', 'id': widget.animalId};
    }
    if (widget is EditarAnimalScreen) {
      return {'pagina': 'cadastro_animal', 'id': widget.animalId};
    }
    if (widget is AnimaisCadastradosScreen) return {'pagina': 'meus_animais'};
    if (widget is ListaAnimais && widget.usuarioId != null) {
      return {'pagina': 'animais_responsavel', 'id': widget.usuarioId};
    }
    if (widget is AdocaoScreen) {
      return {
        'pagina': 'adocao',
        'animal': widget.animalId,
        'adocao': widget.adocaoId,
      };
    }
    if (widget is FichaPerfilScreen) {
      return {'pagina': 'perfil_publico', 'id': widget.clienteId};
    }
    if (widget is NotificacoesScreen) return {'pagina': 'notificacoes'};
    if (widget is EditarPerfilScreen) return {'pagina': 'editar_perfil'};
    if (widget is ConfiguracoesScreen) return {'pagina': 'configuracoes'};
    if (widget is AlterarSenhaScreen && !widget.recuperacao) {
      return {'pagina': 'alterar_senha'};
    }
    if (widget is TesteCompScreen) return {'pagina': 'teste'};
    if (widget is TesteCompAScreen) return {'pagina': 'teste_a'};
    if (widget is TesteCompBScreen) {
      return {'pagina': 'teste_b', 'respostas': widget.respostas};
    }
    if (widget is TesteCompCScreen) {
      return {'pagina': 'teste_c', 'respostas': widget.respostas};
    }
    if (widget is TesteCompFimScreen) return {'pagina': 'teste_fim'};
    return null;
  }

  static Widget? reconstruir(Map<String, dynamic> dados) {
    int? id(String chave) => dados[chave] is int && (dados[chave] as int) > 0
        ? dados[chave] as int
        : null;
    final respostas = dados['respostas'] is Map<String, dynamic>
        ? dados['respostas'] as Map<String, dynamic>
        : <String, dynamic>{};
    return switch (dados['pagina']) {
      'animal' when id('id') != null => FichaAnimalScreen(animalId: id('id')!),
      'cadastro_animal' => CadastroAnimalScreen(animalId: id('id')),
      'meus_animais' => const AnimaisCadastradosScreen(),
      'animais_responsavel' when id('id') != null => Scaffold(
        appBar: AppBar(title: const Text('Animais deste responsável')),
        body: ListaAnimais(usuarioId: id('id')),
      ),
      'adocao' when id('animal') != null || id('adocao') != null =>
        AdocaoScreen(animalId: id('animal'), adocaoId: id('adocao')),
      'perfil_publico' when id('id') != null => FichaPerfilScreen(
        clienteId: id('id'),
      ),
      'notificacoes' => const NotificacoesScreen(),
      'editar_perfil' => const EditarPerfilScreen(),
      'configuracoes' => const ConfiguracoesScreen(),
      'alterar_senha' => const AlterarSenhaScreen(),
      'teste' => const TesteCompScreen(),
      'teste_a' => const TesteCompAScreen(),
      'teste_b' => TesteCompBScreen(respostas: respostas),
      'teste_c' => TesteCompCScreen(respostas: respostas),
      'teste_fim' => const TesteCompFimScreen(),
      _ => null,
    };
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is! PageRoute) return;
    _pagina = route;
    _agendar();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute is! PageRoute) return;
    _pagina = previousRoute;
    _agendar();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute is! PageRoute) return;
    _pagina = newRoute;
    _agendar();
  }

  void dispose() {
    _disposed = true;
    NavegacaoPersistidaService.abaAtual.removeListener(_agendar);
    unawaited(_subscription.cancel());
  }
}
