import 'package:flutter/material.dart';

import '../../model/cliente.dart';
import '../../controller/clientes_scope.dart';
import '../core/app_colors.dart';
import '../core/telefone_formatter.dart';

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  int? _clienteId;
  bool _dadosCarregados = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dadosCarregados) return;
    _dadosCarregados = true;
    final cliente = ClientesScope.of(context).clienteLogado;
    if (cliente == null) return;
    _clienteId = cliente.id;
    nomeController.text = cliente.nome;
    sobrenomeController.text = cliente.sobrenome;
    emailController.text = cliente.email;
    telefoneController.text = cliente.telefone;
    usuarioController.text = cliente.usuario;
    cidadeController.text = cliente.cidadeDeResidencia;
    enderecoController.text = cliente.endereco ?? '';
    estado = estados.containsKey(cliente.estado) ? cliente.estado : null;
    larDeAdocao = cliente.larDeAdocao;
  }

  final nomeController = TextEditingController();
  final sobrenomeController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = TextEditingController();

  final usuarioController = TextEditingController();

  final cidadeController = TextEditingController();
  final enderecoController = TextEditingController();
  String? estado;
  bool larDeAdocao = false;

  static const estados = <String, String>{
    'AC': 'Acre',
    'AL': 'Alagoas',
    'AP': 'Amapá',
    'AM': 'Amazonas',
    'BA': 'Bahia',
    'CE': 'Ceará',
    'DF': 'Distrito Federal',
    'ES': 'Espírito Santo',
    'GO': 'Goiás',
    'MA': 'Maranhão',
    'MT': 'Mato Grosso',
    'MS': 'Mato Grosso do Sul',
    'MG': 'Minas Gerais',
    'PA': 'Pará',
    'PB': 'Paraíba',
    'PR': 'Paraná',
    'PE': 'Pernambuco',
    'PI': 'Piauí',
    'RJ': 'Rio de Janeiro',
    'RN': 'Rio Grande do Norte',
    'RS': 'Rio Grande do Sul',
    'RO': 'Rondônia',
    'RR': 'Roraima',
    'SC': 'Santa Catarina',
    'SP': 'São Paulo',
    'SE': 'Sergipe',
    'TO': 'Tocantins',
  };

  @override
  void dispose() {
    nomeController.dispose();
    sobrenomeController.dispose();
    emailController.dispose();
    telefoneController.dispose();
    usuarioController.dispose();
    cidadeController.dispose();
    enderecoController.dispose();
    super.dispose();
  }

  void editarConta() {
    final controller = ClientesScope.of(context);
    final cliente = controller.clienteLogado;
    if (cliente == null || cliente.id != _clienteId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entre novamente para editar seu perfil.'),
        ),
      );
      return;
    }
    final String mensagem;
    if ([
      nomeController,
      sobrenomeController,
      emailController,
      telefoneController,
      usuarioController,
      cidadeController,
    ].any((controller) => controller.text.trim().isEmpty)) {
      mensagem = 'Preencha todos os campos para continuar.';
    } else if (estado == null) {
      mensagem = 'Selecione o estado.';
    } else if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
        .hasMatch(emailController.text.trim())) {
      mensagem = 'Digite um e-mail válido.';
    } else if (telefoneController.text.replaceAll(RegExp(r'\D'), '').length <
        10) {
      mensagem = 'Digite um telefone com DDD.';
    } else if (!RegExp(r'^[a-zA-Z0-9_]+$')
        .hasMatch(usuarioController.text.trim())) {
      mensagem = 'Use apenas letras, números e underline (_).';
    } else if (larDeAdocao && enderecoController.text.trim().isEmpty) {
      mensagem = 'Informe o endereço do lar de adoção.';
    } else if (controller.listarClientes().any(
      (outro) =>
          outro.id != cliente.id &&
          outro.email.trim().toLowerCase() ==
              emailController.text.trim().toLowerCase(),
    )) {
      mensagem = 'Este e-mail já está cadastrado.';
    } else if (controller.listarClientes().any(
      (outro) =>
          outro.id != cliente.id &&
          outro.usuario == usuarioController.text.trim(),
    )) {
      mensagem = 'Este nome de usuário já está cadastrado.';
    } else {
      final atualizado = controller.editarCliente(
        cliente.id,
        Cliente(
          id: cliente.id,
          nome: nomeController.text.trim(),
          sobrenome: sobrenomeController.text.trim(),
          email: emailController.text.trim(),
          telefone: telefoneController.text.trim(),
          usuario: usuarioController.text.trim(),
          cidadeDeResidencia: cidadeController.text.trim(),
          imageUrl: cliente.imageUrl,
          estado: estado,
          larDeAdocao: larDeAdocao,
          endereco: larDeAdocao ? enderecoController.text.trim() : null,
        ),
      );
      if (!atualizado) return;
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Perfil atualizado!')));
      Navigator.pop(context, true);
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    if (ClientesScope.of(context).clienteLogado == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar Perfil')),
        body: const Center(
          child: Text('Entre novamente para editar seu perfil.'),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Editar Perfil'),
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFD96C3F), width: 2),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Text("Dados Pessoais", style: TextStyle(fontSize: 20)),
              ],
            ),

            SizedBox(height: 20),

            TextField(
              controller: nomeController,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Nome',
                prefixIcon: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF888888),
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

            SizedBox(height: 20),

            TextField(
              controller: sobrenomeController,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Sobrenome',
                prefixIcon: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF888888),
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

            SizedBox(height: 20),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'E-mail',
                prefixIcon: const Icon(
                  Icons.mail_outline,
                  color: Color(0xFF888888),
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

            SizedBox(height: 20),

            TextField(
              controller: telefoneController,
              inputFormatters: [TelefoneInputFormatter()],
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Telefone',
                prefixIcon: const Icon(
                  Icons.phone_outlined,
                  color: Color(0xFF888888),
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

            SizedBox(height: 20),

            TextField(
              controller: usuarioController,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Nome de Usuário',
                prefixIcon: const Icon(
                  Icons.alternate_email,
                  color: Color(0xFF888888),
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

            SizedBox(height: 20),

            Row(children: [Text("Endereço", style: TextStyle(fontSize: 20))]),

            SizedBox(height: 20),

            DropdownButtonFormField<String>(
              initialValue: estado,
              isExpanded: true,
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'NunitoSans',
                fontSize: 16,
              ),
              dropdownColor: Colors.white,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF888888),
              ),
              decoration: InputDecoration(
                hintText: 'Estado',
                prefixIcon: const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF888888),
                ),
                filled: true,
                fillColor: AppColors.cinza,
                hintStyle: const TextStyle(color: Color(0xFF888888)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              items: estados.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => estado = value),
            ),

            SizedBox(height: 20),

            TextField(
              controller: cidadeController,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Cidade',
                prefixIcon: const Icon(
                  Icons.location_city,
                  color: Color(0xFF888888),
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

            SizedBox(height: 20),

            Divider(height: 1, thickness: 1, color: AppColors.laranja),

            SizedBox(height: 20),

            Row(
              children: [
                Checkbox(
                  value: larDeAdocao,
                  activeColor: AppColors.laranja,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  onChanged: (value) =>
                      setState(() => larDeAdocao = value ?? false),
                ),

                GestureDetector(
                  onTap: () => setState(() => larDeAdocao = !larDeAdocao),
                  child: const Text(
                    'Sou um Lar de Adoção',
                    style: TextStyle(color: Colors.black, fontSize: 20),
                  ),
                ),
              ],
            ),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Uma conta de lar de adoção tem informações adicionadas no perfil para contato, (telefone e e-mail)',
                    textAlign: TextAlign.left,
                    softWrap: true,
                    style: TextStyle(color: Color(0xFF888888), fontSize: 10),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            if (larDeAdocao)
              TextField(
                controller: enderecoController,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(color: Colors.black),

                decoration: InputDecoration(
                  hintText: 'Endereço',
                  prefixIcon: const Icon(
                    Icons.location_city,
                    color: Color(0xFF888888),
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

            SizedBox(height: 20),

            SizedBox(
              height: 62,
              child: ElevatedButton(
                onPressed: editarConta,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.laranja,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Salvar alterações', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
