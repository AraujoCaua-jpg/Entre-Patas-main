import 'dart:async';
import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/animais.dart';
import '../model/adocao.dart';
import '../model/cliente.dart';
import 'validacao_perfil.dart';
import 'filtros_animais.dart';
import 'foto_perfil_url.dart';
import 'login_exception.dart';
import 'foto_perfil_storage_service.dart';
import 'foto_perfil_pendente_service.dart';

class SupabaseService {
  SupabaseService({FotoPerfilPendenteService? fotoPendente})
    : _fotoPendente = fotoPendente ?? FotoPerfilPendenteService();

  final SupabaseClient _client = Supabase.instance.client;
  final FotoPerfilPendenteService _fotoPendente;

  Future<List<Adocao>> listarAdocoesSupabase() async {
    final dados = await _executarAdocaoRpc('listar_minhas_adocoes');
    if (dados is! List) {
      throw const LoginException('Não foi possível carregar as solicitações.');
    }
    return dados.map((item) => _converterAdocao(item)).toList();
  }

  Future<Adocao> buscarAdocaoSupabase(int adocaoId) async {
    _validarIdAdocao(adocaoId);
    return _converterAdocao(
      await _executarAdocaoRpc(
        'buscar_minha_adocao',
        params: {'p_adocao_id': adocaoId},
      ),
    );
  }

  Future<Adocao> solicitarAdocaoSupabase(int animalId) async {
    _validarIdAdocao(animalId);
    return _converterAdocao(
      await _executarAdocaoRpc(
        'solicitar_adocao',
        params: {'p_animal_id': animalId},
      ),
    );
  }

  Future<Adocao> responderAdocaoSupabase(int adocaoId, String acao) async {
    _validarIdAdocao(adocaoId);
    if (!const {'aceitar', 'recusar', 'cancelar'}.contains(acao)) {
      throw const LoginException('Você não pode realizar esta ação.');
    }
    return _converterAdocao(
      await _executarAdocaoRpc(
        'responder_adocao',
        params: {'p_adocao_id': adocaoId, 'p_acao': acao},
      ),
    );
  }

  void _validarIdAdocao(int id) {
    if (id <= 0) throw const LoginException('ID inválido.');
  }

  Adocao _converterAdocao(dynamic dados) {
    try {
      return Adocao.fromJson(Map<String, dynamic>.from(dados as Map));
    } catch (_) {
      throw const LoginException('Não foi possível carregar a solicitação.');
    }
  }

  Future<dynamic> _executarRpcNaSessaoAtual(
    String nome, {
    Map<String, dynamic> params = const {},
  }) async {
    final sessao = _client.auth.currentSession;
    if (sessao == null || _client.auth.currentUser == null) {
      throw const LoginException('Entre novamente para continuar.');
    }
    var sessaoSubstituida = false;
    var sessaoObservada = false;
    final inicioObservado = Completer<void>();
    final alteracoesAuth = _client.auth.onAuthStateChange.listen(
      (estado) {
        // O SDK reproduz o histórico. Só observa mudanças posteriores ao
        // evento da instância de sessão na qual esta operação começou.
        if (!sessaoObservada) {
          sessaoObservada = identical(estado.session, sessao);
          if (sessaoObservada) inicioObservado.complete();
          return;
        }
        if (estado.event == AuthChangeEvent.signedOut ||
            ((estado.event == AuthChangeEvent.signedIn ||
                    estado.event == AuthChangeEvent.passwordRecovery) &&
                !identical(estado.session, sessao))) {
          sessaoSubstituida = true;
        }
      },
      // A RPC trata seus próprios erros; uma falha transitória de renovação
      // não deve gerar uma exceção não tratada neste observador temporário.
      onError: (Object _) {},
    );
    void validarSessao() {
      if (sessaoSubstituida ||
          _client.auth.currentUser?.id != sessao.user.id ||
          _client.auth.currentSession == null) {
        throw const LoginException('Entre novamente para continuar.');
      }
    }

    try {
      await inicioObservado.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () =>
            throw const LoginException('Entre novamente para continuar.'),
      );
      // Drena os eventos reproduzidos antes de enviar uma operação. Isso
      // também detecta uma troca de sessão ocorrida durante a assinatura.
      await Future<void>.delayed(Duration.zero);
      validarSessao();
      final dados = await _client.rpc(nome, params: params);
      // Renovar o token mantém a sessão. Logout ou um novo login, inclusive
      // da mesma conta, invalidam a resposta iniciada na sessão anterior.
      await Future<void>.delayed(Duration.zero);
      validarSessao();
      return dados;
    } finally {
      await alteracoesAuth.cancel();
    }
  }

  Future<dynamic> _executarAdocaoRpc(
    String nome, {
    Map<String, dynamic> params = const {},
  }) async {
    try {
      // O banco identifica adotante e responsável pelo auth.uid(). O app envia
      // somente o identificador do animal/pedido e a ação, nunca status ou donos.
      return await _executarRpcNaSessaoAtual(nome, params: params);
    } on LoginException {
      rethrow;
    } on PostgrestException catch (erro) {
      throw _erroAdocao(erro);
    } catch (_) {
      throw const LoginException(
        'Não foi possível concluir a solicitação de adoção. '
        'Confira a conexão e tente novamente.',
      );
    }
  }

  LoginException _erroAdocao(PostgrestException erro) {
    if (const {'PGRST202', '42883', 'PGRST205', '42P01'}.contains(erro.code)) {
      return const LoginException(
        'As solicitações de adoção ainda precisam ser configuradas no Supabase.',
      );
    }
    if (erro.code == '23505') {
      return const LoginException(
        'Já existe uma solicitação em andamento ou aprovada para este animal.',
      );
    }
    const mensagensConhecidas = {
      'ID inválido.',
      'Entre novamente para continuar.',
      'Perfil não encontrado ou inativo.',
      'Solicitação não encontrada.',
      'Animal não encontrado.',
      'Você não pode solicitar a adoção do próprio animal.',
      'Este animal não está disponível para adoção.',
      'Você já possui uma solicitação em andamento para este animal.',
      'Você não pode realizar esta ação.',
      'Esta solicitação já foi finalizada.',
      'Não é possível aprovar esta adoção.',
    };
    if (const {
          'PT400',
          'PT401',
          'PT403',
          'PT404',
          'PT409',
          'P0001',
        }.contains(erro.code) &&
        mensagensConhecidas.contains(erro.message)) {
      return LoginException(erro.message);
    }
    if (const {
      'PT401',
      'PGRST301',
      'PGRST302',
      'PGRST303',
    }.contains(erro.code)) {
      return const LoginException('Entre novamente para continuar.');
    }
    if (erro.code == '42501' || erro.code == 'PT403') {
      return const LoginException('Você não pode realizar esta ação.');
    }
    return const LoginException(
      'Não foi possível concluir a solicitação de adoção. Tente novamente.',
    );
  }

  // Ativar somente após configurar a sincronização do e-mail confirmado no banco.
  static const alteracaoEmailHabilitada = bool.fromEnvironment(
    'SUPABASE_PROFILE_EMAIL_SYNC_ENABLED',
    defaultValue: false,
  );

  Future<Cliente> buscarMeuPerfilSupabase() async {
    final usuario = _client.auth.currentUser;
    if (usuario == null) {
      throw const LoginException('Entre novamente para editar seu perfil.');
    }
    try {
      final dados = await _client
          .from('cliente')
          .select()
          .eq('auth_user_id', usuario.id)
          .eq('ativo', true)
          .maybeSingle();
      if (_client.auth.currentUser?.id != usuario.id) {
        throw const LoginException('Entre novamente para editar seu perfil.');
      }
      if (dados == null || dados['ativo'] != true) {
        throw const LoginException('Perfil não encontrado ou inativo.');
      }
      final imagemBanco = dados['imagem']?.toString();
      final imagemAuth =
          usuario.userMetadata?['imagem']?.toString() ??
          usuario.userMetadata?['avatar_url']?.toString();
      final imagem = FotoPerfilUrl.valida(imagemBanco)
          ? imagemBanco
          : FotoPerfilUrl.valida(imagemAuth)
          ? imagemAuth
          : null;
      return Cliente.fromJson({
        ...dados,
        'imagem': imagem,
        'questionario_pendente':
            dados['questionario_pendente'] == true ||
            dados['questionario_pendente'] == 1 ||
            usuario.userMetadata?['origem_cadastro'] == 'entre_patas',
      });
    } on PostgrestException catch (erro) {
      throw _erroPerfil(erro);
    }
  }

  Future<Cliente> editarMeuPerfilSupabase(Cliente cliente) async {
    final usuario = _client.auth.currentUser;
    if (usuario == null) {
      throw const LoginException('Entre novamente para editar seu perfil.');
    }
    validarPerfil(cliente);
    final novoEmail = cliente.email.trim().toLowerCase();
    if (novoEmail != usuario.email?.trim().toLowerCase() &&
        !alteracaoEmailHabilitada) {
      throw const LoginException(
        'A alteração de e-mail ainda precisa ser habilitada com segurança. '
        'Mantenha seu e-mail atual para salvar os outros dados.',
      );
    }
    final imagemInformada = cliente.imageUrl?.trim();
    FotoPerfilEnviada? fotoEnviada;
    var perfilSalvo = false;
    var patchIniciado = false;

    try {
      if (cliente.fotoCadastro == null &&
          (imagemInformada?.isEmpty ?? true) &&
          (usuario.userMetadata?['imagem'] != null ||
              usuario.userMetadata?['avatar_url'] != null)) {
        try {
          // Limpar o fallback também evita recuperar a foto antiga após removê-la.
          final resposta = await _client.auth.updateUser(
            UserAttributes(data: {'imagem': null, 'avatar_url': null}),
          );
          if (resposta.user?.id != usuario.id) {
            throw const LoginException(
              'Entre novamente para remover sua foto.',
            );
          }
        } on AuthException {
          throw const LoginException(
            'Não foi possível remover a foto. Tente novamente.',
          );
        }
      }
      if (cliente.fotoCadastro != null) {
        fotoEnviada = await FotoPerfilStorageService.enviar(
          cliente.fotoCadastro!,
          client: _client,
        );
      }
      if (_client.auth.currentUser?.id != usuario.id) {
        throw const LoginException('Entre novamente para editar seu perfil.');
      }
      final imagem = fotoEnviada?.url ?? imagemInformada;
      // Lista explícita: e-mail é gerenciado pelo Auth, nunca por este PATCH.
      patchIniciado = true;
      final dados = await _client
          .from('cliente')
          .update({
            'nome': cliente.nome.trim(),
            'sobrenome': cliente.sobrenome.trim(),
            'telefone': cliente.telefone.replaceAll(RegExp(r'\D'), ''),
            'usuario': cliente.usuario.trim(),
            'cidadeDeResidencia': cliente.cidadeDeResidencia.trim(),
            'estado': cliente.estado,
            'larDeAdocao': cliente.larDeAdocao,
            'endereco': cliente.larDeAdocao ? cliente.endereco?.trim() : null,
            'imagem': (imagem?.isNotEmpty ?? false) ? imagem : null,
          })
          .eq('id', cliente.id)
          .eq('auth_user_id', usuario.id)
          .eq('ativo', true)
          .select()
          .maybeSingle();
      perfilSalvo = dados != null;
      if (_client.auth.currentUser?.id != usuario.id) {
        throw const LoginException('Entre novamente para editar seu perfil.');
      }
      if (dados == null) {
        throw const LoginException('Perfil não encontrado ou sem permissão.');
      }
      final atualizado = Cliente.fromJson(dados);
      if (fotoEnviada != null) {
        cliente.fotoCadastro = null;
      }
      // Uma edição manual também substitui a escolha pendente do cadastro.
      await _limparFotoPendente(usuario.id);
      return atualizado;
    } on PostgrestException catch (erro) {
      if (!perfilSalvo) await _descartarFoto(fotoEnviada);
      throw _erroPerfil(erro);
    } catch (_) {
      // Uma falha de transporte após enviar o PATCH pode ocorrer mesmo com a
      // foto já vinculada. Não apagar o arquivo se a confirmação for incerta.
      if (!patchIniciado && !perfilSalvo) await _descartarFoto(fotoEnviada);
      rethrow;
    }
  }

  Future<void> _descartarFoto(FotoPerfilEnviada? foto) async {
    if (foto == null) return;
    try {
      await FotoPerfilStorageService.descartar(foto, _client);
    } catch (_) {
      developer.log('A limpeza do novo arquivo de foto ficou pendente.');
    }
  }

  Future<void> _limparFotoPendente(String usuarioId) async {
    try {
      await _fotoPendente.remover(usuarioId);
    } catch (_) {
      // A imagem já está vinculada no servidor. No próximo login, a existência
      // dessa imagem evita reenviar a foto e permite repetir só a limpeza local.
      developer.log(
        'A limpeza da foto pendente local será repetida no próximo login.',
      );
    }
  }

  Future<String?> finalizarFotoPendenteCadastro() async {
    final usuario = _client.auth.currentUser;
    if (usuario == null) {
      throw const LoginException('Entre para enviar sua foto.');
    }
    final foto = await _fotoPendente.carregar(usuario.id);
    if (_client.auth.currentUser?.id != usuario.id) {
      throw const LoginException('Entre novamente para enviar sua foto.');
    }
    if (foto == null) return null;
    final perfil = await buscarMeuPerfilSupabase();
    if (_client.auth.currentUser?.id != usuario.id) {
      throw const LoginException('Entre novamente para enviar sua foto.');
    }
    if (FotoPerfilUrl.valida(perfil.imageUrl)) {
      await _limparFotoPendente(usuario.id);
      return perfil.imageUrl;
    }
    perfil.fotoCadastro = foto;
    return (await editarMeuPerfilSupabase(perfil)).imageUrl;
  }

  LoginException _erroPerfil(PostgrestException erro) {
    if (erro.code == '23505') {
      return const LoginException(
        'E-mail, telefone ou nome de usuário já cadastrado.',
      );
    }
    if (erro.code == '42501') {
      return const LoginException(
        'Você não tem permissão para editar este perfil.',
      );
    }
    if (erro.code == '23514' || erro.code == '22001') {
      return const LoginException('Confira os dados informados no perfil.');
    }
    return const LoginException(
      'Não foi possível atualizar o perfil. Confira a conexão e tente novamente.',
    );
  }

  Future<List<Map<String, dynamic>>> buscarAnimais({
    String? tipo,
    Map<String, String> filtros = const {},
    int pagina = 1,
    int? clienteId,
    bool somenteMeus = false,
    int? animalId,
  }) async {
    final estado = filtros['estado']?.trim() ?? '';
    final cidade = filtros['cidade']?.trim() ?? '';

    if (!somenteMeus && estado.isNotEmpty && cidade.isNotEmpty) {
      final dados = await _buscarAnimaisProximos(
        tipo: tipo,
        filtros: filtros,
        clienteId: clienteId,
        animalId: animalId,
      );
      final inicio = ((pagina < 1 ? 1 : pagina) - 1) * 50;
      return dados.skip(inicio).take(50).toList();
    }

    final usuario = _client.auth.currentUser;
    int? meuClienteId;

    if (usuario != null) {
      final perfil = await _client
          .from('cliente')
          .select('id')
          .eq('auth_user_id', usuario.id)
          .maybeSingle();

      if (perfil != null) {
        meuClienteId = int.tryParse('${perfil['id']}');
      }
    }

    var consulta = _client.from('animal').select();

    final idFiltro = clienteId ?? int.tryParse(filtros['id_cliente'] ?? '');

    if (somenteMeus) {
      if (meuClienteId == null) {
        throw const LoginException('Perfil não encontrado.');
      }
      consulta = consulta.eq('id_cliente', meuClienteId).eq('ativo', true);
    } else {
      consulta = consulta.eq('ativo', true).eq('status', 'Disponível');

      if (idFiltro != null) {
        consulta = consulta.eq('id_cliente', idFiltro);
      } else if (meuClienteId != null) {
        consulta = consulta.neq('id_cliente', meuClienteId);
      }
    }

    if (animalId != null) {
      consulta = consulta.eq('id', animalId);
    }

    final tipoFiltro = tipo ?? filtros['tipo'];

    if (tipoFiltro != null && tipoFiltro.isNotEmpty) {
      if (tipoFiltro == 'Outros') {
        consulta = consulta.not('tipo', 'in', '("Cachorro","Gato")');
      } else {
        consulta = consulta.eq('tipo', tipoFiltro);
      }
    }

    final termo = filtros['q']?.trim() ?? '';
    if (termo.isNotEmpty) {
      consulta = consulta.ilike('nome', '%$termo%');
    }

    for (final campo in [
      'sexo',
      'porte',
      'energia',
      'convivencia',
      'carencia',
    ]) {
      final valor = filtros[campo];
      if (valor != null && valor.isNotEmpty) {
        consulta = consulta.eq(campo, valor);
      }
    }

    if (somenteMeus && (filtros['status']?.isNotEmpty ?? false)) {
      consulta = consulta.eq('status', filtros['status']!);
    }

    final inicio = ((pagina < 1 ? 1 : pagina) - 1) * 50;

    final dados = await consulta
        .order('nome')
        .order('id')
        .range(inicio, inicio + 49);

    return dados.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<List<Animal>> buscarAnimaisModel({
    String? tipo,
    Map<String, String> filtros = const {},
  }) async {
    if ((filtros['estado']?.trim().isNotEmpty ?? false) &&
        (filtros['cidade']?.trim().isNotEmpty ?? false)) {
      // A RPC devolve seu conjunto em uma chamada; não repetir a mesma busca
      // a cada página nem acrescentar os mesmos animais até atingir o limite.
      final dados = await _buscarAnimaisProximos(tipo: tipo, filtros: filtros);
      return dados.map(Animal.fromJson).toList();
    }
    final todos = <Animal>[];
    for (var pagina = 1; pagina <= 1000; pagina++) {
      final dados = await buscarAnimais(
        tipo: tipo,
        filtros: filtros,
        pagina: pagina,
      );
      todos.addAll(dados.map(Animal.fromJson));
      if (dados.length < 50) return todos;
    }
    throw const LoginException(
      'Há muitos animais para carregar de uma só vez. Use a pesquisa paginada.',
    );
  }

  Future<List<Map<String, dynamic>>> _buscarAnimaisProximos({
    String? tipo,
    Map<String, String> filtros = const {},
    int? clienteId,
    int? animalId,
  }) async {
    final dados = await _executarBuscaRpc('ep_animais_perto_de_mim', const {});
    if (dados is! List) {
      throw const LoginException(
        'Não foi possível carregar os animais próximos.',
      );
    }
    return filtrarAnimaisProximos(
      dados.map((item) => Map<String, dynamic>.from(item as Map)).toList(),
      tipo: tipo,
      filtros: filtros,
      clienteId: clienteId,
      animalId: animalId,
    );
  }

  Future<List<Animal>> buscarAnimaisDoCliente(int clienteId) async {
    final todos = <Animal>[];
    for (var pagina = 1; pagina <= 1000; pagina++) {
      final dados = await buscarAnimais(
        pagina: pagina,
        clienteId: clienteId,
        somenteMeus: true,
      );
      todos.addAll(dados.map(Animal.fromJson));
      if (dados.length < 50) return todos;
    }
    throw const LoginException(
      'Há muitos animais para carregar de uma só vez. Use a paginação.',
    );
  }

  Future<void> publicarAnimal(Animal animal) =>
      _salvarAnimalComFoto(animal, (imagem) => _publicarAnimal(animal, imagem));

  Future<void> _salvarAnimalComFoto(
    Animal animal,
    Future<void> Function(String? imagem) salvar,
  ) async {
    final usuarioId = _client.auth.currentUser?.id;
    if (usuarioId == null) {
      throw const LoginException('Entre novamente para salvar o animal.');
    }
    FotoPerfilEnviada? enviada;
    var gravacaoIniciada = false;
    try {
      if (animal.fotoCadastro != null) {
        enviada = await FotoPerfilStorageService.enviarAnimal(
          animal.fotoCadastro!,
          client: _client,
        );
      }
      if (_client.auth.currentUser?.id != usuarioId) {
        throw const LoginException('Entre novamente para salvar o animal.');
      }
      gravacaoIniciada = true;
      final imagem = enviada?.url ?? animal.imageUrl;
      await salvar(imagem);
      animal.imageUrl = imagem;
      animal.fotoCadastro = null;
    } on PostgrestException {
      await _descartarFoto(enviada);
      rethrow;
    } catch (_) {
      // Uma resposta perdida pode ocorrer depois de o banco salvar a URL.
      if (!gravacaoIniciada) await _descartarFoto(enviada);
      rethrow;
    }
  }

  Future<void> _publicarAnimal(Animal animal, String? imagem) async {
    final usuario = _client.auth.currentUser;

    if (usuario == null) {
      throw Exception('Entre novamente para publicar um animal.');
    }

    // Busca o perfil vinculado à conta autenticada
    final perfil = await _client
        .from('cliente')
        .select('id, ativo')
        .eq('auth_user_id', usuario.id)
        .maybeSingle();

    if (perfil == null || perfil['ativo'] != true) {
      throw Exception('Perfil não encontrado ou inativo.');
    }

    if (_client.auth.currentUser?.id != usuario.id) {
      throw const LoginException('Entre novamente para salvar o animal.');
    }

    // Publica o animal no Supabase
    final dados = await _client
        .from('animal')
        .insert({
          ...animal.toJson(),
          'imagem': imagem,
          'id_cliente': perfil['id'],
          'ativo': true,
          'status': 'Disponível',
        })
        .select()
        .single();
    animal.id = (dados['id'] as num).toInt();
    animal.idCliente = (dados['id_cliente'] as num).toInt();
  }

  Future<Animal> buscarMeuAnimalParaEditar(int animalId) async {
    final usuario = _client.auth.currentUser;
    if (usuario == null) {
      throw Exception('Entre novamente.');
    }

    final perfil = await _client
        .from('cliente')
        .select('id')
        .eq('auth_user_id', usuario.id)
        .maybeSingle();

    if (perfil == null) {
      throw Exception('Perfil não encontrado.');
    }

    final dados = await _client
        .from('animal')
        .select()
        .eq('id', animalId)
        .eq('id_cliente', perfil['id'])
        .maybeSingle();

    if (dados == null) {
      throw Exception('Animal não encontrado ou sem permissão.');
    }

    return Animal.fromJson(dados);
  }

  Future<void> editarAnimalSupabase(Animal animal) =>
      _salvarAnimalComFoto(animal, (imagem) => _editarAnimal(animal, imagem));

  Future<void> _editarAnimal(Animal animal, String? imagem) async {
    final usuario = _client.auth.currentUser;
    if (usuario == null) {
      throw Exception('Entre novamente.');
    }

    final perfil = await _client
        .from('cliente')
        .select('id')
        .eq('auth_user_id', usuario.id)
        .eq('ativo', true)
        .maybeSingle();

    if (perfil == null) {
      throw Exception('Perfil não encontrado ou inativo.');
    }

    if (_client.auth.currentUser?.id != usuario.id) {
      throw const LoginException('Entre novamente para salvar o animal.');
    }

    final atualizado = await _client
        .from('animal')
        .update({
          'nome': animal.nome,
          'idade': animal.idade,
          'imagem': imagem,
          'tipo': animal.tipo,
          'descricao': animal.descricao,
          'sexo': animal.sexo,
          'energia': animal.energia,
          'porte': animal.porte,
          'convivencia': animal.convivencia,
          'carencia': animal.carencia,
          'vacinado': animal.vacinado,
          'castrado': animal.castrado,
        })
        .eq('id', animal.id)
        .eq('id_cliente', perfil['id'])
        .select('id')
        .maybeSingle();

    if (atualizado == null) {
      throw Exception('Animal não encontrado ou sem permissão para editar.');
    }
  }

  Future<void> excluirMeuAnimalSupabase(int animalId) async {
    if (animalId <= 0) {
      throw const LoginException('ID inválido.');
    }
    try {
      // A RPC valida o proprietário pelo Auth e desativa sem conceder ao
      // cliente permissão para alterar ativo ou apagar o histórico do animal.
      final dados = await _executarRpcNaSessaoAtual(
        'excluir_meu_animal',
        params: {'p_animal_id': animalId},
      );
      if (dados is! Map || dados['id'] != animalId || dados['ativo'] != false) {
        throw const LoginException(
          'Não foi possível confirmar a exclusão do animal.',
        );
      }
    } on LoginException {
      rethrow;
    } on PostgrestException catch (erro) {
      if (const {
        'PGRST202',
        '42883',
        'PGRST205',
        '42P01',
      }.contains(erro.code)) {
        throw const LoginException(
          'A exclusão de animais ainda precisa ser configurada no Supabase.',
        );
      }
      const mensagensConhecidas = {
        'ID inválido.',
        'Entre novamente para continuar.',
        'Perfil não encontrado ou inativo.',
        'Animal não encontrado ou sem permissão para excluir.',
      };
      if (const {'PT400', 'PT401', 'PT403', 'PT404'}.contains(erro.code) &&
          mensagensConhecidas.contains(erro.message)) {
        throw LoginException(erro.message);
      }
      if (const {
        'PT401',
        'PGRST301',
        'PGRST302',
        'PGRST303',
      }.contains(erro.code)) {
        throw const LoginException('Entre novamente para continuar.');
      }
      if (erro.code == '42501' || erro.code == 'PT403') {
        throw const LoginException(
          'Animal não encontrado ou sem permissão para excluir.',
        );
      }
      throw const LoginException(
        'Não foi possível excluir o animal. Tente novamente.',
      );
    } catch (_) {
      throw const LoginException(
        'Não foi possível excluir o animal. Tente novamente.',
      );
    }
  }

  Future<Animal> buscarAnimalPorIdSupabase(int animalId) async {
    if (animalId <= 0) {
      throw const LoginException('ID inválido.');
    }
    // A ficha consulta o ID diretamente. Disponibilidade e propriedade são
    // verificadas pela RLS, sem os filtros de recomendação/pesquisa do feed.
    final dados = await _client
        .from('animal')
        .select()
        .eq('id', animalId)
        .maybeSingle();
    if (dados == null) {
      throw const LoginException('Animal não encontrado ou indisponível.');
    }
    return Animal.fromJson(dados);
  }

  Future<Map<String, dynamic>> buscarResumoResponsavel(int clienteId) async {
    return _buscarRegistroPublicoRpc(
      'buscar_resumo_responsavel',
      clienteId,
      indisponivel: 'Responsável não encontrado.',
      invalido: 'Dados do responsável inválidos.',
    );
  }

  Future<Map<String, dynamic>> buscarPerfilPublicoSupabase(
    int clienteId,
  ) async {
    return _buscarRegistroPublicoRpc(
      'buscar_perfil_publico',
      clienteId,
      indisponivel: 'Perfil público indisponível.',
      invalido: 'Dados do perfil público inválidos.',
    );
  }

  Future<Map<String, dynamic>> _buscarRegistroPublicoRpc(
    String nome,
    int clienteId, {
    required String indisponivel,
    required String invalido,
  }) async {
    if (clienteId <= 0) {
      throw const LoginException('ID inválido.');
    }
    try {
      // A RPC decide a visibilidade. O perfil consultado pode ser legado,
      // sem vínculo Auth e sem animais; somente o solicitante precisa de sessão.
      final resultado = await _executarRpcNaSessaoAtual(
        nome,
        params: {'p_cliente_id': clienteId},
      );
      if (resultado is! List) throw LoginException(invalido);
      if (resultado.isEmpty) throw LoginException(indisponivel);
      if (resultado.length != 1) throw LoginException(invalido);
      final dados = resultado.single;
      if (dados is! Map || dados.keys.any((chave) => chave is! String)) {
        throw LoginException(invalido);
      }
      final id = dados['id'];
      if (id is! num ||
          !id.isFinite ||
          id <= 0 ||
          id != id.truncateToDouble() ||
          id != clienteId) {
        throw LoginException(invalido);
      }
      const textosPublicos = {
        'nome',
        'sobrenome',
        'usuario',
        'imagem',
        'cidade',
        'estado',
      };
      for (final campo in textosPublicos) {
        final valor = dados[campo];
        if (valor != null && valor is! String) {
          throw LoginException(invalido);
        }
      }
      final lar = dados['lar_de_adocao'];
      if (lar != null && lar is! bool) throw LoginException(invalido);
      // Não propaga contatos ou outros campos privados inesperados na resposta.
      return {
        'id': id,
        for (final campo in textosPublicos)
          if (dados.containsKey(campo)) campo: dados[campo],
        if (dados.containsKey('lar_de_adocao')) 'lar_de_adocao': lar,
      };
    } on LoginException {
      rethrow;
    } on PostgrestException catch (erro) {
      if (const {
        'PGRST202',
        '42883',
        'PGRST205',
        '42P01',
      }.contains(erro.code)) {
        throw const LoginException(
          'A consulta de perfis públicos ainda precisa ser configurada no Supabase.',
        );
      }
      if (const {
        'PT401',
        'PGRST301',
        'PGRST302',
        'PGRST303',
      }.contains(erro.code)) {
        throw const LoginException('Entre novamente para continuar.');
      }
      if (erro.code == '42501' || erro.code == 'PT403') {
        throw const LoginException(
          'Você não tem permissão para consultar este perfil.',
        );
      }
      if (erro.code == 'PT404') throw LoginException(indisponivel);
      throw const LoginException(
        'Não foi possível consultar os dados públicos no Supabase.',
      );
    } catch (_) {
      throw const LoginException(
        'Não foi possível consultar os dados públicos no Supabase.',
      );
    }
  }

  Future<List<Animal>> listarAnimaisDisponiveisDoClienteSupabase(
    int clienteId, {
    int pagina = 1,
  }) async {
    final dados = await buscarAnimais(pagina: pagina, clienteId: clienteId);
    return dados.map(Animal.fromJson).toList();
  }

  Future<List<Cliente>> pesquisarClientesSupabase(String termo) async {
    final dados = await _executarBuscaRpc('buscar_clientes_publicos', {
      'p_termo': termo.trim(),
    });
    if (dados is! List) {
      throw const LoginException(
        'Não foi possível pesquisar usuários no Supabase.',
      );
    }
    return dados
        .map((item) => Cliente.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<dynamic> _executarBuscaRpc(
    String nome,
    Map<String, dynamic> parametros,
  ) async {
    try {
      return await _client.rpc(nome, params: parametros);
    } on PostgrestException catch (erro) {
      if (const {
        'PGRST202',
        '42883',
        'PGRST205',
        '42P01',
      }.contains(erro.code)) {
        throw const LoginException(
          'A pesquisa Supabase ainda precisa ser configurada no banco.',
        );
      }
      if (erro.code == 'PT400' || erro.code == 'PT403') {
        throw LoginException(erro.message);
      }
      throw const LoginException(
        'Não foi possível consultar os dados públicos no Supabase.',
      );
    }
  }

  Future<String?> cadastrarClienteSupabase(
    Cliente cliente,
    String senha,
  ) async {
    final foto = cliente.fotoCadastro;
    if (foto != null) FotoPerfilStorageService.validarFoto(foto);
    final imagem = cliente.imageUrl?.trim();
    if (imagem != null && imagem.isNotEmpty && !FotoPerfilUrl.valida(imagem)) {
      throw const LoginException(
        'Digite um link de imagem válido (http ou https).',
      );
    }

    final resultado = await _client.auth.signUp(
      email: cliente.email.trim().toLowerCase(),
      password: senha,
      data: {
        'origem_cadastro': 'entre_patas',
        'nome': cliente.nome.trim(),
        'sobrenome': cliente.sobrenome.trim(),
        'telefone': cliente.telefone.replaceAll(RegExp(r'\D'), ''),
        'usuario': cliente.usuario.trim(),
        'estado': cliente.estado,
        'cidade': cliente.cidadeDeResidencia.trim(),
        'larDeAdocao': cliente.larDeAdocao,
        'endereco': cliente.larDeAdocao ? cliente.endereco?.trim() : null,
        'imagem': foto == null && (imagem?.isNotEmpty ?? false) ? imagem : null,
      },
    );

    if (resultado.user == null) {
      throw Exception('Não foi possível iniciar o cadastro.');
    }
    if (foto == null) return null;
    try {
      await _fotoPendente.guardar(resultado.user!.id, foto);
      cliente.fotoCadastro = null;
    } catch (_) {
      // O cadastro já foi confirmado pelo Auth: não pedir para criar outra conta.
      return 'Não foi possível guardar sua foto. Após entrar, envie-a em Editar perfil.';
    }
    if (resultado.session != null &&
        _client.auth.currentUser?.id == resultado.user!.id) {
      try {
        await finalizarFotoPendenteCadastro();
        return null;
      } catch (_) {
        return 'Sua foto ficou pendente. Você poderá enviá-la ao entrar novamente ou em Editar perfil.';
      }
    }
    return 'Sua foto será enviada após confirmar o e-mail e entrar neste mesmo navegador.';
  }

  Future<void> salvarQuestionarioSupabase(Map<String, dynamic> dados) async {
    // Identifica o usuário autenticado no Supabase.
    final usuario = _client.auth.currentUser;

    if (usuario == null) {
      throw Exception('Você precisa estar conectado para salvar o teste.');
    }

    // Encontra o perfil desse usuário na tabela cliente.
    final perfil = await _client
        .from('cliente')
        .select('id')
        .eq('auth_user_id', usuario.id)
        .maybeSingle();

    if (perfil == null) {
      throw Exception('Perfil do usuário não encontrado.');
    }

    // Salva as respostas vinculadas ao cliente.
    // Se ele já tiver um questionário, atualiza o existente.
    await _client.from('questionario').upsert({
      ...dados,
      'id_cliente': perfil['id'],
    }, onConflict: 'id_cliente');
  }

  Future<Map<String, dynamic>?> buscarMeuQuestionarioSupabase() async {
    // Identifica o usuário conectado.
    final usuario = _client.auth.currentUser;

    if (usuario == null) {
      throw Exception('Usuário não autenticado.');
    }

    // Localiza o perfil desse usuário.
    final perfil = await _client
        .from('cliente')
        .select('id')
        .eq('auth_user_id', usuario.id)
        .maybeSingle();

    if (perfil == null) {
      throw Exception('Perfil não encontrado.');
    }

    // Busca somente o questionário do usuário.
    final questionario = await _client
        .from('questionario')
        .select()
        .eq('id_cliente', perfil['id'])
        .maybeSingle();

    return questionario;
  }
}
