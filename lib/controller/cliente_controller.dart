import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../model/cliente.dart';
import '../service/auth_api.dart';

class ClienteController extends ChangeNotifier {
  ClienteController({AuthApi? authApi}) : _authApi = authApi ?? AuthApi();
  final AuthApi _authApi;
  String? _token;
  bool _autenticando = false;
  final List<Cliente> clientes = [];
  int? _clienteLogadoId;

  Cliente? get clienteLogado =>
      _clienteLogadoId == null ? null : buscarCliente(_clienteLogadoId!);

  Future<void> entrar(String email, String senha) async {
    if (_autenticando) return;
    _autenticando = true;
    try {
      final sessao = await _authApi.entrar(email, senha);
      clientes.removeWhere((cliente) => cliente.id == sessao.cliente.id);
      clientes.add(sessao.cliente);
      _clienteLogadoId = sessao.cliente.id;
      _token = sessao.token;
      notifyListeners();
    } finally {
      _autenticando = false;
    }
  }

  Future<void> sair() async {
    final token = _token;
    if (token != null) await _authApi.sair(token);
    _token = null;
    _clienteLogadoId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authApi.close();
    super.dispose();
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

  // Consulta em memória; não autentica nem verifica senhas.
  Cliente? buscarPorEmail(String email) {
    final procurado = email.trim().toLowerCase();
    for (final cliente in clientes) {
      if (cliente.email.trim().toLowerCase() == procurado) return cliente;
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
      if (_clienteLogadoId == id) _clienteLogadoId = null;
      notifyListeners();
    }

    return clientes.length < quantidadeAnterior;
  }
}
