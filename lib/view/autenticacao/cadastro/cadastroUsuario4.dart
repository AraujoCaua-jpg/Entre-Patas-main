import '../../core/scrollable_screen_body.dart';

import '../login.dart';

import 'package:material_ui/material_ui.dart';

import '../../../model/cliente.dart';
import '../../../service/cliente_api.dart';
import '../../../controller/clientes_scope.dart';

import '../../core/app_colors.dart';

class CadastroUsuario4Screen extends StatefulWidget {
  const CadastroUsuario4Screen({
    super.key,
    required this.cliente,
    required this.senha,
  });

  final Cliente cliente;
  final String senha;

  @override
  State<CadastroUsuario4Screen> createState() => _CadastroUsuario4ScreenState();
}

class _CadastroUsuario4ScreenState extends State<CadastroUsuario4Screen> {
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
  final cidadeController = TextEditingController();
  final enderecoController = TextEditingController();
  String? estado;
  bool larDeAdocao = false;
  bool _cadastroConcluido = false;
  bool _salvando = false;
  final _api = ClienteApi();

  @override
  void dispose() {
    _api.close();
    cidadeController.dispose();
    enderecoController.dispose();
    super.dispose();
  }

  Future<void> criarConta() async {
    if (_cadastroConcluido || _salvando) return;
    final String mensagem;
    if (estado == null || cidadeController.text.trim().isEmpty) {
      mensagem = 'Selecione o estado e informe sua cidade.';
    } else if (larDeAdocao && enderecoController.text.trim().isEmpty) {
      mensagem = 'Informe o endereço do lar de adoção.';
    } else {
      final controller = ClientesScope.of(context);
      if (controller.buscarPorEmail(widget.cliente.email) != null ||
          controller.buscarPorUsuario(widget.cliente.usuario) != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'E-mail ou usuário já cadastrado. Volte para corrigir.',
            ),
          ),
        );
        return;
      }
      widget.cliente.cidadeDeResidencia = cidadeController.text.trim();
      widget.cliente.estado = estado;
      widget.cliente.larDeAdocao = larDeAdocao;
      widget.cliente.endereco = larDeAdocao
          ? enderecoController.text.trim()
          : null;
      setState(() => _salvando = true);
      try {
        widget.cliente.id = await _api.cadastrar(widget.cliente, widget.senha);
      } on CadastroException catch (erro) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(erro.mensagem)));
        return;
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível concluir o cadastro.'),
          ),
        );
        return;
      } finally {
        if (mounted) setState(() => _salvando = false);
      }
      if (!mounted) return;
      controller.cadastrarCliente(widget.cliente);
      setState(() => _cadastroConcluido = true);
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('Cadastro concluído'),
            content: const Text('Usuário cadastrado com sucesso!'),
            actions: [
              TextButton(
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (Route<dynamic> route) => false,
                  );
                },
                child: const Text('Entrar na minha conta'),
              ),
            ],
          ),
        ),
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => route.isFirst,
      );
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,

      appBar: AppBar(
        backgroundColor: AppColors.fundo,

        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Image.asset('assets/logo.png', height: 25, fit: BoxFit.contain),

        shape: const Border(
          bottom: BorderSide(color: Color(0xFFD96C3F), width: 2),
        ),
      ),

      body: ScrollableScreenBody(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back, color: AppColors.laranja),
                  label: const Text('Voltar'),
                  iconAlignment: .start,
                ),

                Text(
                  'Etapa 4 de 4',
                  style: TextStyle(color: Colors.black, fontSize: 14),
                ),
              ],
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment
                  .spaceBetween, // Centraliza as barrinhas (opcional)
              children: [
                for (var etapa = 0; etapa < 4; etapa++)
                  Expanded(
                    child: Container(
                      height: 6,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 4,
                      ), // Um espaço leve entre elas
                      decoration: BoxDecoration(
                        // Se a etapa já passou ou é a atual, fica verde. Senão, cinza.
                        color: etapa < 4 ? AppColors.verde : AppColors.cinza,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
              ],
            ),

            Expanded(
              child: Column(
                mainAxisAlignment: .center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.rosaClaro,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.map_outlined,
                      color: AppColors.laranja,
                      size: 28,
                    ),
                  ),

                  Text(
                    'Localização',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    'Informe sua cidade de residência para oferecer melhores resultados.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF888888), fontSize: 16),
                  ),

                  SizedBox(height: 40),

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
                          style: TextStyle(
                            color: Color(0xFF888888),
                            fontSize: 10,
                          ),
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
                ],
              ),
            ),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 62,
                    child: ElevatedButton(
                      onPressed: _cadastroConcluido || _salvando
                          ? null
                          : criarConta,
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
                          Text('Criar conta', style: TextStyle(fontSize: 24)),
                          SizedBox(width: 10),
                          Icon(Icons.arrow_forward),
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
