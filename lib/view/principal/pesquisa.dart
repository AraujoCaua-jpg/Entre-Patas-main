import 'dart:async';

import '../../model/cliente.dart';
import '../../model/animais.dart';
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
  List<Animal> _pets = [];
  List<List<dynamic>> get animais => _pets
      .map((a) => [a.nome, '${a.idade} ano(s)', a.sexo, a.imageUrl ?? '', a.id])
      .toList();
  List<Cliente> _usuarios = [];
  Timer? _debounce;
  int _versao = 0;
  bool _carregando = false;
  String? _erro;
  bool _iniciada = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_iniciada) {
      _iniciada = true;
      _buscar();
    }
  }

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
    final buscarPets = pesquisa == "Pets";
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      if (buscarPets) {
        final pets = await ClientesScope.of(context)
            .listarAnimais(filtros: {'q': pesquisaController.text});
        if (mounted && versao == _versao) setState(() => _pets = pets);
        return;
      }
      final resultados = await ClientesScope.of(context)
          .pesquisarClientes(pesquisaController.text);
      if (mounted && versao == _versao) setState(() => _usuarios = resultados);
    } catch (e) {
      if (mounted && versao == _versao) {
        setState(() {
          _usuarios = [];
          if (buscarPets) _pets = [];
          _erro = e is LoginException
              ? e.mensagem
              : 'Não foi possível pesquisar.';
        });
      }
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
                      child: _carregando
                          ? const Center(child: CircularProgressIndicator())
                          : _erro != null
                          ? Center(
                              child: TextButton(
                                onPressed: _buscar,
                                child: Text(_erro!),
                              ),
                            )
                          : animais.isEmpty
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
                                  page: FichaAnimalScreen(
                                    animalId: item[4] as int,
                                  ),
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
