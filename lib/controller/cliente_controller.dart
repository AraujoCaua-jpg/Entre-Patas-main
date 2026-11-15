import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../services/supabase_auth_service.dart';
import '../services/login_exception.dart';

import '../model/animais.dart';
import '../model/adocao.dart';
import '../model/cliente.dart';

class ClienteController extends ChangeNotifier {
  ClienteController({SupabaseAuthService? supabaseAuthService})
    : _supabaseAuthServiceInicial = supabaseAuthService;

  final SupabaseAuthService? _supabaseAuthServiceInicial;
  late final SupabaseAuthService _supabaseAuthService =
      _supabaseAuthServiceInicial ?? SupabaseAuthService();
  Future<void>? _logoutPendente;
  int _versaoSessao = 0;

  late final _supabaseService = SupabaseService();

  bool _autenticando = false;
  final List<Cliente> clientes = [];
  int? _clienteLogadoId;
  List<Adocao> _adocoesNotificacoes = [];
  List<Adocao> _notificacoes = [];
  final Set<(int, String)> _notificacoesLidas = {};
  int? _clienteNotificacoes;
  int _versaoNotificacoes = 0;

  List<Adocao> get notificacoes =>
      clienteLogado != null && _clienteNotificacoes == clienteLogado?.id
      ? List.unmodifiable(_notificacoes)
      : const [];
  int get totalNotificacoes => notificacoes.length;

  Future<List<Adocao>> atualizarNotificacoes() async {
    final cliente = clienteLogado;
    if (cliente == null) {
      throw const LoginException('Entre novamente para continuar.');
    }
    final versaoSessao = _versaoSessao;
    if (_clienteNotificacoes != cliente.id) {
      _limparNotificacoes();
      _clienteNotificacoes = cliente.id;
    }
    final versao = ++_versaoNotificacoes;
    final adocoes = await listarAdocoes();
    if (versaoSessao != _versaoSessao || clienteLogado?.id != cliente.id) {
      throw const LoginException('Entre novamente para continuar.');
    }
    if (versao != _versaoNotificacoes) {
      // A consulta ainda responde à tela que a iniciou; só a versão mais
      // recente pode substituir o cache usado pelo badge.
      return List.unmodifiable(adocoes);
    }
    _adocoesNotificacoes = List.of(adocoes);
    _notificacoes = adocoes.where((adocao) {
      final recebida = adocao.idDono == cliente.id
          ? const {'Aguardando', 'Cancelado'}.contains(adocao.status)
          : adocao.idCliente == cliente.id &&
                const {'Aceito', 'Recusado'}.contains(adocao.status);
      return recebida &&
          !_notificacoesLidas.contains((adocao.id, adocao.status));
    }).toList();
    notifyListeners();
    // A tela também é o histórico de adoções. O badge usa apenas as novas.
    return List.unmodifiable(_adocoesNotificacoes);
  }

  Future<void> lerNotificacao(Adocao adocao) async {
    final cliente = clienteLogado;
    if (cliente == null ||
        (adocao.idDono != cliente.id && adocao.idCliente != cliente.id)) {
      throw const LoginException('Entre novamente para continuar.');
    }
    if (_clienteNotificacoes != cliente.id) {
      _limparNotificacoes();
      _clienteNotificacoes = cliente.id;
    }
    // O SQL instalado não persiste leitura de notificações. Mantém a versão
    // exibida em memória nesta sessão, sem alterar o histórico nem usar PHP.
    _notificacoesLidas.add((adocao.id, adocao.status));
    _notificacoes.removeWhere(
      (a) => a.id == adocao.id && a.status == adocao.status,
    );
    notifyListeners();
  }

  void _limparNotificacoes() {
    _versaoNotificacoes++;
    _clienteNotificacoes = null;
    _adocoesNotificacoes = [];
    _notificacoes = [];
    _notificacoesLidas.clear();
  }

  Cliente? get clienteLogado =>
      _clienteLogadoId == null ? null : buscarCliente(_clienteLogadoId!);

  Future<Cliente> carregarMeuPerfilSupabase() async {
    final versaoSessao = _versaoSessao;
    final usuario = Supabase.instance.client.auth.currentUser;

    if (usuario == null) {
      throw const LoginException('Entre novamente para continuar.');
    }

    final dados = await Supabase.instance.client
        .from('cliente')
        .select()
        .eq('auth_user_id', usuario.id)
        .maybeSingle();

    // Uma consulta iniciada antes do logout não pode restaurar o perfil antigo.
    if (versaoSessao != _versaoSessao ||
        Supabase.instance.client.auth.currentUser?.id != usuario.id) {
      throw const LoginException('Entre novamente para continuar.');
    }

    if (dados == null || dados['ativo'] != true) {
      throw const LoginException('Perfil não encontrado ou inativo.');
    }

    final cliente = Cliente(
      id: (dados['id'] as num).toInt(),
      nome: dados['nome'] as String? ?? '',
      sobrenome: dados['sobrenome'] as String? ?? '',
      email: dados['email'] as String? ?? '',
      telefone: dados['telefone'] as String? ?? '',
      usuario: dados['usuario'] as String? ?? '',
      cidadeDeResidencia: dados['cidadeDeResidencia'] as String? ?? '',
      estado: dados['estado'] as String?,
      endereco: dados['endereco'] as String?,
      imageUrl: dados['imagem'] as String?,
      larDeAdocao: dados['larDeAdocao'] == true,
      questionarioPendente:
          dados['questionario_pendente'] == true ||
          dados['questionario_pendente'] == 1 ||
          // O trigger legado usa default 0. Cadastros do app continuam
          // obrigados a responder; respostas já salvas têm precedência.
          usuario.userMetadata?['origem_cadastro'] == 'entre_patas',
    );

    _clienteLogadoId = cliente.id;
    _atualizar(cliente);

    return cliente;
  }

  Future<void> entrar(String email, String senha) async {
    if (_autenticando) return;
    _autenticando = true;

    try {
      final resposta = await _supabaseAuthService.entrar(email, senha);
      if (resposta.user == null || resposta.session == null) {
        throw const LoginException('Não foi possível iniciar a sessão.');
      }
      _limparNotificacoes();
      await carregarMeuPerfilSupabase();
    } finally {
      _autenticando = false;
    }
  }

  Future<void> sair() {
    return _logoutPendente ??= _sairDoSupabase().whenComplete(() {
      _logoutPendente = null;
    });
  }

  Future<void> _sairDoSupabase() async {
    await _supabaseAuthService.sair();
    limparSessao();
  }

  // Cadastrar cliente
  void cadastrarCliente(Cliente cliente) {
    clientes.add(cliente);
    notifyListeners();

    developer.log('Cliente cadastrado com sucesso!');
  }

  // Listar todos os clientes
  List<Cliente> listarClientes() {
    return clientes;
  }

  // Buscar cliente pelo e-mail
  Cliente? buscarPorEmail(String email) {
    final procurado = email.trim().toLowerCase();

    for (final cliente in clientes) {
      if (cliente.email.trim().toLowerCase() == procurado) {
        return cliente;
      }
    }

    return null;
  }

  // Buscar cliente pelo ID
  Cliente? buscarCliente(int id) {
    for (final cliente in clientes) {
      if (cliente.id == id) {
        return cliente;
      }
    }

    return null;
  }

  // Buscar cliente pelo usuário (@)
  Cliente? buscarPorUsuario(String usuario) {
    for (final cliente in clientes) {
      if (cliente.usuario == usuario) {
        return cliente;
      }
    }

    return null;
  }

  // Editar cliente
  bool editarCliente(int id, Cliente novosDados) {
    final cliente = buscarCliente(id);

    if (cliente == null) {
      return false;
    }

    cliente.nome = novosDados.nome;
    cliente.sobrenome = novosDados.sobrenome;
    cliente.email = novosDados.email;
    cliente.telefone = novosDados.telefone;
    cliente.imageUrl = novosDados.imageUrl;
    cliente.cidadeDeResidencia = novosDados.cidadeDeResidencia;
    cliente.usuario = novosDados.usuario;
    cliente.estado = novosDados.estado;
    cliente.endereco = novosDados.endereco;
    cliente.larDeAdocao = novosDados.larDeAdocao;

    notifyListeners();

    developer.log('Cliente atualizado com sucesso!');
    return true;
  }

  // Excluir cliente
  bool excluirCliente(int id) {
    final quantidadeAnterior = clientes.length;

    clientes.removeWhere((cliente) => cliente.id == id);

    if (clientes.length < quantidadeAnterior) {
      if (_clienteLogadoId == id) {
        _clienteLogadoId = null;
      }

      notifyListeners();
    }

    return clientes.length < quantidadeAnterior;
  }

  void _atualizar(Cliente c) {
    clientes.removeWhere((outro) => outro.id == c.id);

    clientes.add(c);
    notifyListeners();
  }

  // Atualizar perfil
  Future<Cliente> atualizarPerfil() async {
    final versaoSessao = _versaoSessao;
    final c = await _supabaseService.buscarMeuPerfilSupabase();
    if (versaoSessao != _versaoSessao) {
      throw const LoginException('Entre novamente para editar seu perfil.');
    }
    _clienteLogadoId = c.id;
    _atualizar(c);
    return c;
  }

  // Buscar cliente remoto
  Future<Cliente> buscarClienteRemoto(int id, {bool basico = false}) async {
    final dados = basico
        ? await _supabaseService.buscarResumoResponsavel(id)
        : await _supabaseService.buscarPerfilPublicoSupabase(id);
    return Cliente.fromJson({
      ...dados,
      'cidadeDeResidencia': dados['cidade'] ?? '',
      'larDeAdocao': dados['lar_de_adocao'] ?? false,
    });
  }

  Future<List<Animal>> listarAnimais({
    Map<String, String> filtros = const {},
  }) async {
    final pagina = int.tryParse(filtros['pagina'] ?? '') ?? 1;
    return listarAnimaisSupabase(
      filtros: filtros,
      pagina: filtros.containsKey('pagina') ? pagina : null,
      somenteMeus: filtros['somenteMeus'] == 'true',
    );
  }

  Future<List<Animal>> listarAnimaisSupabase({
    String? tipo,
    Map<String, String> filtros = const {},
    int? pagina,
    bool somenteMeus = false,
  }) async {
    if (pagina == null) {
      return _supabaseService.buscarAnimaisModel(tipo: tipo, filtros: filtros);
    }
    final dados = await _supabaseService.buscarAnimais(
      tipo: tipo,
      filtros: filtros,
      pagina: pagina,
      somenteMeus: somenteMeus,
    );
    return dados.map(Animal.fromJson).toList();
  }

  Future<List<Animal>> listarAnimaisDoClienteSupabase(int clienteId) async {
    return _supabaseService.buscarAnimaisDoCliente(clienteId);
  }

  // Buscar animal por ID
  Future<Animal> buscarAnimalRemoto(int id) =>
      _supabaseService.buscarAnimalPorIdSupabase(id);

  Future<Animal> buscarAnimalPorIdSupabase(int animalId) {
    return _supabaseService.buscarAnimalPorIdSupabase(animalId);
  }

  Future<Map<String, dynamic>> buscarResumoResponsavelSupabase(int clienteId) {
    return _supabaseService.buscarResumoResponsavel(clienteId);
  }

  // Salvar animal
  Future<Animal> salvarAnimal(Animal animal, {bool editar = false}) async {
    if (editar) {
      await editarAnimalSupabase(animal);
    } else {
      await publicarAnimalSupabase(animal);
    }
    return animal;
  }

  Future<void> publicarAnimalSupabase(Animal animal) async {
    await _supabaseService.publicarAnimal(animal);
    notifyListeners();
  }

  Future<Animal> buscarMeuAnimalParaEditarSupabase(int animalId) {
    return _supabaseService.buscarMeuAnimalParaEditar(animalId);
  }

  Future<void> editarAnimalSupabase(Animal animal) async {
    await _supabaseService.editarAnimalSupabase(animal);
    notifyListeners();
  }

  // Apagar animal
  Future<void> apagarAnimal(int id) => apagarAnimalSupabase(id);

  Future<void> apagarAnimalSupabase(int animalId) async {
    await _supabaseService.excluirMeuAnimalSupabase(animalId);
    notifyListeners();
  }

  // Carregar questionário
  Future<Map<String, dynamic>?> carregarQuestionario() async {
    final versaoSessao = _versaoSessao;
    final clienteId = clienteLogado?.id;
    final respostas = await _supabaseService.buscarMeuQuestionarioSupabase();
    if (versaoSessao != _versaoSessao) {
      throw const LoginException('Entre novamente para continuar.');
    }
    if (respostas != null && clienteLogado?.id == clienteId) {
      clienteLogado?.questionarioPendente = false;
    }
    return respostas;
  }

  // Salvar questionário
  Future<void> salvarQuestionario(Map<String, dynamic> dados) async {
    final versaoSessao = _versaoSessao;
    final clienteId = clienteLogado?.id;
    await _supabaseService.salvarQuestionarioSupabase(dados);
    if (versaoSessao != _versaoSessao) {
      throw const LoginException('Entre novamente para continuar.');
    }
    if (clienteLogado?.id == clienteId) {
      clienteLogado?.questionarioPendente = false;
    }
    notifyListeners();
  }

  // Listar adoções
  Future<List<Adocao>> listarAdocoes() async =>
      _supabaseService.listarAdocoesSupabase();

  // Buscar adoção
  Future<Adocao> buscarAdocao(int id) =>
      _supabaseService.buscarAdocaoSupabase(id);

  // Solicitar adoção
  Future<Adocao> solicitarAdocao(int animalId) async {
    final versaoSessao = _versaoSessao;
    final resultado = await _supabaseService.solicitarAdocaoSupabase(animalId);
    if (versaoSessao != _versaoSessao) {
      throw const LoginException('Entre novamente para continuar.');
    }
    notifyListeners();
    return resultado;
  }

  // Responder adoção
  Future<Adocao> responderAdocao(int id, String acao) async {
    final versaoSessao = _versaoSessao;
    final d = await _supabaseService.responderAdocaoSupabase(id, acao);
    if (versaoSessao != _versaoSessao) {
      throw const LoginException('Entre novamente para continuar.');
    }

    notifyListeners();
    return d;
  }

  // Pesquisar clientes
  Future<List<Cliente>> pesquisarClientes(String termo) =>
      _supabaseService.pesquisarClientesSupabase(termo);

  // Editar cliente remoto
  Future<bool> editarClienteRemoto(Cliente c) async {
    if (clienteLogado?.id != c.id) {
      throw const LoginException('Entre novamente para editar seu perfil.');
    }
    final versaoSessao = _versaoSessao;
    final usuario = Supabase.instance.client.auth.currentUser;
    final novoEmail = c.email.trim().toLowerCase();
    final atualizado = await _supabaseService.editarMeuPerfilSupabase(c);
    if (versaoSessao != _versaoSessao ||
        usuario == null ||
        Supabase.instance.client.auth.currentUser?.id != usuario.id) {
      throw const LoginException('Entre novamente para editar seu perfil.');
    }

    _atualizar(atualizado);
    if (novoEmail != usuario.email?.trim().toLowerCase()) {
      try {
        // A confirmação do Auth sincroniza cliente.email no banco, não no PATCH.
        await _supabaseAuthService.solicitarAlteracaoEmail(novoEmail);
      } on LoginException catch (erro) {
        throw LoginException(
          'Os outros dados do perfil foram salvos. '
          'A alteração do e-mail não foi concluída: ${erro.mensagem}',
        );
      }
    }
    return true;
  }

  // Limpar sessão
  void limparSessao() {
    _versaoSessao++;
    _limparNotificacoes();
    _clienteLogadoId = null;
    clientes.clear();

    notifyListeners();
  }

  // Apagar conta
  Future<bool> apagarConta(String senha) async {
    final limpezaStoragePendente = await _supabaseAuthService.apagarConta(
      senha,
    );
    limparSessao();
    return limpezaStoragePendente;
  }

  // Alterar senha
  Future<void> alterarSenha(
    String atual,
    String nova, {
    String? codigoReautenticacao,
  }) async {
    await _supabaseAuthService.alterarSenha(
      atual,
      nova,
      codigoReautenticacao: codigoReautenticacao,
    );

    limparSessao();
  }

  Future<Map<String, dynamic>> buscarPerfilPublicoSupabase(int clienteId) {
    return _supabaseService.buscarPerfilPublicoSupabase(clienteId);
  }

  Future<List<Animal>> listarAnimaisDisponiveisDoClienteSupabase(
    int clienteId, {
    int pagina = 1,
  }) {
    return _supabaseService.listarAnimaisDisponiveisDoClienteSupabase(
      clienteId,
      pagina: pagina,
    );
  }

  Future<void> cadastrarClienteSupabase(Cliente cliente, String senha) async {
    await _supabaseService.cadastrarClienteSupabase(cliente, senha);
  }

  Future<Map<String, dynamic>?> buscarMeuQuestionarioSupabase() async {
    return await _supabaseService.buscarMeuQuestionarioSupabase();
  }
}
