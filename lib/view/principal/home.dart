import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../core/app_colors.dart';
import '../../controller/clientes_scope.dart';
import '../../model/animais.dart';
import '../../service/auth_api.dart';
import '../animal/fichaAnimal.dart';
import '../questionario/testeComp.dart';

const _laranjaHome = Color(0xFFFF642F);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List<Animal>>? _consulta;
  bool _temQuestionario = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // O scope notifica a Home quando as respostas do teste são salvas.
    _consulta = _carregar();
  }

  Future<List<Animal>> _carregar() async {
    final controller = ClientesScope.of(context);
    final respostas = await controller.carregarQuestionario();
    if (!mounted) return [];
    _temQuestionario = respostas != null;
    final tipo = respostas?['tipo'];
    return controller.listarAnimais(
      filtros: {
        'acao': 'melhores',
        if (tipo == 'Cachorro' || tipo == 'Gato') 'tipo': tipo as String,
      },
    );
  }

  Future<void> _recarregar() async {
    final consulta = _carregar();
    setState(() => _consulta = consulta);
    await consulta;
  }

  Future<void> _abrirTeste() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TesteCompScreen()),
    );
    if (mounted) _recarregar();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: RefreshIndicator(
      color: _laranjaHome,
      onRefresh: _recarregar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _BannerHome(),
                const SizedBox(height: 8),
                const Text(
                  'Seus melhores Matches',
                  style: TextStyle(fontSize: 14, height: 1.2),
                ),
                const Text(
                  'Amiguinhos que combinam com você!',
                  style: TextStyle(fontSize: 10, color: AppColors.cinzaEscuro),
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<Animal>>(
                  future: _consulta,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            Text(
                              snapshot.error is LoginException
                                  ? (snapshot.error as LoginException).mensagem
                                  : 'Não foi possível carregar os animais.',
                            ),
                            TextButton(
                              onPressed: _recarregar,
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final animais = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_temQuestionario)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextButton.icon(
                              onPressed: _abrirTeste,
                              icon: const Icon(Icons.pets_outlined),
                              label: const Text(
                                'Faça o teste para descobrir seus matches',
                              ),
                            ),
                          ),
                        if (animais.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              'Nenhum amiguinho disponível no momento.',
                            ),
                          ),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 600 ? 3 : 2;
                            final width =
                                (constraints.maxWidth - (columns - 1) * 8) /
                                columns;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: animais.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 10,
                                    mainAxisExtent: width * .68 + 58,
                                  ),
                              itemBuilder: (context, index) {
                                final animal = animais[index];
                                return _PetCard(
                                  animal: animal,
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => FichaAnimalScreen(
                                          animalId: animal.id,
                                        ),
                                      ),
                                    );
                                    if (mounted) _recarregar();
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _BannerHome extends StatefulWidget {
  const _BannerHome();

  @override
  State<_BannerHome> createState() => _BannerHomeState();
}

class _BannerHomeState extends State<_BannerHome> {
  final _controller = PageController();
  Timer? _timer;
  int _pagina = 0;

  @override
  void initState() {
    super.initState();
    _reiniciarTimer();
  }

  void _reiniciarTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted ||
          !TickerMode.valuesOf(context).enabled ||
          ModalRoute.of(context)?.isCurrent == false ||
          !_controller.hasClients ||
          _controller.position.isScrollingNotifier.value) {
        return;
      }
      _mover(1);
    });
  }

  void _mover(int direcao) {
    if (!_controller.hasClients) return;
    _controller.animateToPage(
      (_pagina + direcao) % _imagens.length,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  static const _imagens = [
    (
      'assets/banners/boas_vindas_corrigida.png',
      'Entre Patas: encontre seu melhor amigo aqui',
    ),
    ('assets/banners/gato.png', 'Gato descansando no tapete'),
    ('assets/banners/cachorro.png', 'Cachorro preto e branco'),
  ];

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 682 / 438,
    // As artes já incluem a borda e o indicador da respectiva página.
    child: Stack(
      fit: StackFit.expand,
      children: [
        PageView(
          key: const ValueKey('carrossel-home'),
          controller: _controller,
          onPageChanged: (pagina) {
            _pagina = pagina;
            _reiniciarTimer();
          },
          children: [
            for (var i = 0; i < _imagens.length; i++)
              Image.asset(
                _imagens[i].$1,
                fit: BoxFit.contain,
                semanticLabel:
                    '${_imagens[i].$2}. Imagem ${i + 1} de ${_imagens.length}',
              ),
          ],
        ),
        for (final anterior in [true, false])
          Positioned(
            left: anterior ? 0 : null,
            right: anterior ? null : 0,
            top: 0,
            bottom: 0,
            width: 48,
            child: Semantics(
              button: true,
              label: anterior ? 'Imagem anterior' : 'Próxima imagem',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _mover(anterior ? -1 : 1);
                  _reiniciarTimer();
                },
                child: const MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: SizedBox.expand(),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _PetCard extends StatelessWidget {
  const _PetCard({required this.animal, required this.onTap});
  final Animal animal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: _laranjaHome, width: 1.5),
      borderRadius: BorderRadius.circular(8),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: animal.imageUrl == null || animal.imageUrl!.isEmpty
                      ? _semFoto()
                      : Image.network(
                          animal.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stack) => _semFoto(),
                        ),
                ),
                const Positioned(
                  top: 5,
                  right: 5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(3),
                      child: Icon(
                        Icons.favorite_border,
                        color: _laranjaHome,
                        size: 13,
                      ),
                    ),
                  ),
                ),
                if (animal.compatibilidade != null)
                  Positioned(
                    bottom: 5,
                    left: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.rosaClaro,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.pets_outlined,
                            size: 13,
                            color: _laranjaHome,
                          ),
                          const SizedBox(width: 3),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${animal.compatibilidade!['total']}%',
                                style: const TextStyle(
                                  fontSize: 10,
                                  height: 1,
                                  color: _laranjaHome,
                                ),
                              ),
                              const Text(
                                'compatibilidade',
                                style: TextStyle(
                                  fontSize: 6,
                                  height: 1.1,
                                  color: _laranjaHome,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 3, 7, 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  animal.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, height: 1.1),
                ),
                _detail(
                  Icons.pets_outlined,
                  '${animal.idade} ${animal.idade == 1 ? 'ano' : 'anos'}',
                ),
                _detail(
                  animal.sexo == 'Fêmea' ? Icons.female : Icons.male,
                  animal.sexo,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _semFoto() => const ColoredBox(
    color: AppColors.rosaClaro,
    child: Center(child: Icon(Icons.pets, size: 40, color: _laranjaHome)),
  );

  Widget _detail(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 11, color: Color(0xFFAAAAAA)),
      const SizedBox(width: 3),
      Expanded(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            height: 1.15,
            color: Color(0xFFAAAAAA),
          ),
        ),
      ),
    ],
  );
}
