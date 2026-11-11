import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../model/cliente.dart';

class ClienteController extends ChangeNotifier {
  final List<Cliente> clientes = [];
  int? _clienteLogadoId;

  Cliente? get clienteLogado =>
      _clienteLogadoId == null ? null : buscarCliente(_clienteLogadoId!);

  // Identifica o perfil da simulação; não autentica nem armazena senhas.
  bool entrarSimulado(String email) {
    final cliente = buscarPorEmail(email);
    if (cliente == null) return false;
    _clienteLogadoId = cliente.id;
    notifyListeners();
    return true;
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
