import 'dart:async';

import '../../model/cliente.dart';
import '../../controller/clientes_scope.dart';
import '../../service/auth_api.dart';

import 'package:entre_patas/view/animal/fichaAnimal.dart';
import 'package:material_ui/material_ui.dart';

import '../core/app_colors.dart';
import '../usuario/fichaPerfil.dart';

class PesquisaScreen extends StatefulWidget {
  const PesquisaScreen({super.key});

  @override
  State<PesquisaScreen> createState() => _PesquisaScreenState();
}

class _PesquisaScreenState extends State<PesquisaScreen> {
  static const List<List> _animais = [
    [
      "Bolt",
      "1 ano",
      "Macho",
      "https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=500&h=340&fit=crop",
    ],
    [
      "Rubi",
      "4 anos",
      "Fêmea",
      "https://images.unsplash.com/photo-1546527868-ccb7ee7dfa6a?w=500&h=340&fit=crop",
    ],
    [
      "Brutos",
      "2 anos",
      "Macho",
      "https://images.unsplash.com/photo-1551717743-49959800b1f6?w=500&h=340&fit=crop",
    ],
    [
      "Brutus",
      "4 meses",
      "Macho",
      "https://images.unsplash.com/photo-1518717758536-85ae29035b6d?w=500&h=340&fit=crop",
    ],
  ];

  List<List> get animais => _animais
      .where(
        (a) => (a[0] as String).toLowerCase().contains(
          pesquisaController.text.toLowerCase(),
        ),
      )
      .toList();
  List<Cliente> _usuarios = [];
  Timer? _debounce;
  int _versao = 0;
  bool _carregando = false;
  String? _erro;
  List<List<dynamic>> get usuarios => _usuarios
      .map(
        (c) => [
          '${c.nome} ${c.sobrenome}',
          '@${c.usuario}',
          c.imageUrl ?? '',
          c.id,
        ],
      )
      .toList();
  void _consultar() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _buscar);
  }

  Future<void> _buscar() async {
    final versao = ++_versao;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final resultados = await ClientesScope.of(context)
          .pesquisarClientes(pesquisaController.text);
      if (mounted && versao == _versao) setState(() => _usuarios = resultados);
    } catch (e) {
      if (mounted && versao == _versao)
        setState(() {
          _usuarios = [];
          _erro = e is LoginException
              ? e.mensagem
              : 'Não foi possível pesquisar.';
        });
    } finally {
      if (mounted && versao == _versao) setState(() => _carregando = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    pesquisaController.dispose();
    super.dispose();
  }

  final TextEditingController pesquisaController = TextEditingController();

  String? pesquisa = "Pets";
  void mudarPesquisa(String estado) {
    setState(() {
      pesquisa = estado;
    });
    _buscar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: pesquisaController,
              onChanged: (_) {
                setState(() {});
                _consultar();
              },
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                hintText: 'Pesquisar Pets, usuários ...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.cinza,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => mudarPesquisa("Pets"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pesquisa == "Pets"
                          ? AppColors.laranja
                          : AppColors.rosa,
                      foregroundColor: pesquisa == "Pets"
                          ? Colors.white
                          : AppColors.laranja,
                      elevation: 0,
                      fixedSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pets, size: 26),
                        SizedBox(width: 10),
                        Text('Pets', style: TextStyle(fontSize: 20)),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 8),

                Expanded(
                  child: ElevatedButton(
                    onPressed: () => mudarPesquisa("Usuários"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pesquisa == "Usuários"
                          ? AppColors.laranja
                          : AppColors.rosa,
                      foregroundColor: pesquisa == "Usuários"
                          ? Colors.white
                          : AppColors.laranja,
                      elevation: 0,
                      fixedSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline_rounded, size: 26),
                        SizedBox(width: 10),
                        Text('Usuários', style: TextStyle(fontSize: 20)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            Container(
              child: pesquisa == "Pets"
                  ? Expanded(
                      child: animais.isEmpty
                          ? const Center(
                              child: Text('Nenhum Animal Cadastrado'),
                            )
                          : ListView.builder(
                              itemCount: animais.length,
                              itemBuilder: (context, index) {
                                final item = animais[index];

                                return _SearchCard(
                                  name: item[0],
                                  desc: "${item[1]} - ${item[2]}",
                                  image: item[3],
                                  page: FichaAnimalScreen(),
                                );
                              },
                            ),
                    )
                  : Expanded(
                      child: _carregando
                          ? const Center(child: CircularProgressIndicator())
                          : _erro != null
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_erro!),
                                  TextButton(
                                    onPressed: _buscar,
                                    child: const Text('Tentar novamente'),
                                  ),
                                ],
                              ),
                            )
                          : usuarios.isEmpty
                          ? const Center(
                              child: Text('Nenhum usuário Cadastrado'),
                            )
                          : ListView.builder(
                              itemCount: usuarios.length,
                              itemBuilder: (context, index) {
                                final item = usuarios[index];

                                return _SearchCard(
                                  name: item[0],
                                  desc: item[1],
                                  image: item[2],
                                  page: FichaPerfilScreen(
                                    clienteId: item[3] as int,
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  const _SearchCard({
    required this.name,
    required this.desc,
    required this.image,
    required this.page,
  });

  final String name;
  final String desc;
  final String image;
  final Widget page;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
                child: image.isEmpty ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 20)),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.cinzaEscuro,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.laranja,
                size: 26,
              ),
            ],
          ),
          const Divider(color: Colors.grey, thickness: 1),
        ],
      ),
    );
  }
}
