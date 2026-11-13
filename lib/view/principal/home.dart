import 'package:material_ui/material_ui.dart';

import '../core/app_colors.dart';
import '../../controller/clientes_scope.dart';
import '../../model/animais.dart';
import '../../service/auth_api.dart';
import '../animal/fichaAnimal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List<Animal>>? _consulta;
  String? _tipo;
  bool _preferenciaCarregada = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _consulta ??= _carregar();
  }

  Future<List<Animal>> _carregar() async {
    final controller = ClientesScope.of(context);
    if (!_preferenciaCarregada) {
      final respostas = await controller.carregarQuestionario();
      if (!mounted) return [];
      final tipo = respostas?['tipo'];
      _tipo = tipo == 'Cachorro' || tipo == 'Gato' ? tipo as String : null;
      _preferenciaCarregada = true;
    }
    return controller.listarAnimais(
      filtros: {'acao': 'melhores', 'tipo': ?_tipo},
    );
  }

  void _selecionarTipo(String tipo) {
    if (_tipo == tipo) return;
    _tipo = tipo;
    _recarregar();
  }

  void _recarregar() {
    final consulta = _carregar();
    setState(() {
      _consulta = consulta;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<List<Animal>>(
        future: _consulta,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: TextButton(
                onPressed: _recarregar,
                child: Text(
                  snapshot.error is LoginException
                      ? (snapshot.error as LoginException).mensagem
                      : 'Não foi possível carregar os animais.',
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final animais = snapshot.data!;
          return SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Encontre seu amiguinho',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),

                Row(
                  children: [
                    Text(
                      'Amiguinhos esperando por um lar!',
                      style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                Row(
                  children: [
                    for (final tipo in ['Cachorro', 'Gato']) ...[
                      if (tipo == 'Gato') const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _selecionarTipo(tipo),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _tipo == tipo
                                ? AppColors.laranja
                                : AppColors.rosa,
                            foregroundColor: _tipo == tipo
                                ? Colors.white
                                : AppColors.laranja,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            tipo == 'Cachorro' ? 'Cachorros' : 'Gatos',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                if (animais.isEmpty) const Text('Nenhum Animal Cadastrado'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const minCardWidth = 160.0;

                      const spacing = 8.0;

                      final columns =
                          ((constraints.maxWidth + spacing) /
                                  (minCardWidth + spacing))
                              .floor()
                              .clamp(1, 100);

                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        crossAxisCount: columns,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 167 / 162,
                        children: animais
                            .map(
                              (a) => InkWell(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          FichaAnimalScreen(animalId: a.id),
                                    ),
                                  );
                                  if (mounted) _recarregar();
                                },
                                child: _PetCard(
                                  name: a.nome,
                                  age: '${a.idade} ano(s)',
                                  gender: a.sexo,
                                  status: a.status,
                                  compatibilidade: a.compatibilidade,
                                  image: a.imageUrl ?? '',
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PetCard extends StatefulWidget {
  const _PetCard({
    required this.name,
    required this.age,
    required this.gender,
    required this.status,
    this.compatibilidade,
    required this.image,
  });

  final String name;
  final String age;
  final String gender;
  final String status;
  final Map<String, dynamic>? compatibilidade;
  final String image;

  @override
  State<_PetCard> createState() => _PetCardState();
}

class _PetCardState extends State<_PetCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.laranja, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagem do pet
          AspectRatio(
            aspectRatio: 167 / 116,
            child: Stack(
              children: [
                Positioned.fill(
                  child: widget.image.isEmpty
                      ? const ColoredBox(
                          color: AppColors.rosaClaro,
                          child: Center(
                            child: Icon(
                              Icons.pets,
                              size: 48,
                              color: AppColors.laranja,
                            ),
                          ),
                        )
                      : Image.network(
                          widget.image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.rosaClaro,
                              child: const Center(
                                child: Icon(
                                  Icons.pets,
                                  size: 48,
                                  color: AppColors.laranja,
                                ),
                              ),
                            );
                          },
                        ),
                ),

                Positioned(
                  left: 5,
                  bottom: 7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE7DC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.pets_outlined,
                          size: 15,
                          color: AppColors.laranja,
                        ),
                        const SizedBox(width: 3),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.compatibilidade == null
                                  ? widget.status
                                  : '${widget.compatibilidade!['total']}%',
                              style: const TextStyle(
                                fontSize: 10,
                                height: 1,
                                color: AppColors.laranja,
                              ),
                            ),
                            Text(
                              widget.compatibilidade == null
                                  ? 'adoção'
                                  : 'compatibilidade',
                              style: TextStyle(
                                fontSize: 6,
                                height: 1.2,
                                color: AppColors.laranja,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Informações do pet
          Padding(
            padding: const EdgeInsets.only(left: 7, top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(fontSize: 14, height: 1.05),
                ),
                _detail(Icons.access_time, widget.age),
                _detail(
                  widget.gender == 'Fêmea' ? Icons.female : Icons.male,
                  widget.gender,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 11, color: const Color(0xFFAAAAAA)),
      const SizedBox(width: 3),
      Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          height: 1.15,
          color: Color(0xFFAAAAAA),
        ),
      ),
    ],
  );
}
