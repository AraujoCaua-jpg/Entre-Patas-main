import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../model/cliente.dart';
import '../../model/animais.dart';
import '../../controller/clientes_scope.dart';
import '../../service/auth_api.dart';
import '../animal/fichaAnimal.dart';
import '../usuario/fichaPerfil.dart';
import '../core/app_colors.dart';

const _laranja = Color(0xFFFF642F);
const _rosa = Color(0xFFF8D7C8);

class PesquisaScreen extends StatefulWidget {
  const PesquisaScreen({super.key});
  @override
  State<PesquisaScreen> createState() => _PesquisaScreenState();
}

class _PesquisaScreenState extends State<PesquisaScreen> {
  final _texto = TextEditingController();
  final _resultados = GlobalKey();
  List<Animal> _pets = [];
  List<Cliente> _usuarios = [];
  Timer? _debounce;
  int _versao = 0;
  bool _carregando = false, _iniciada = false, _usuariosAtivos = false;
  String _categoria = 'Todos';
  String? _sexo, _porte, _erro;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_iniciada) {
      _iniciada = true;
      _buscar();
    }
  }

  Future<void> _buscar() async {
    _debounce?.cancel();
    final versao = ++_versao;
    final usuarios = _usuariosAtivos;
    final controller = ClientesScope.of(context);
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      if (usuarios) {
        final encontrados = await controller.pesquisarClientes(
          _texto.text.trim(),
        );
        if (mounted && versao == _versao) {
          setState(() => _usuarios = encontrados);
        }
      } else {
        final filtros = <String, String>{
          'q': _texto.text.trim(),
          if (_categoria == 'Cachorros') 'tipo': 'Cachorro',
          if (_categoria == 'Gatos') 'tipo': 'Gato',
          'sexo': ?_sexo,
          'porte': ?_porte,
        };
        if (_categoria == 'Perto de mim') {
          final cliente = controller.clienteLogado;
          if (cliente == null ||
              cliente.cidadeDeResidencia.trim().isEmpty ||
              (cliente.estado ?? '').trim().isEmpty) {
            throw const LoginException(
              'Preencha sua cidade e estado no perfil para encontrar pets perto de você.',
            );
          }
          filtros['cidade'] = cliente.cidadeDeResidencia;
          filtros['estado'] = cliente.estado!;
        }
        final encontrados = await controller.listarAnimais(filtros: filtros);
        if (mounted && versao == _versao) {
          setState(
            () => _pets = _categoria == 'Outros'
                ? encontrados
                      .where((a) => a.tipo != 'Cachorro' && a.tipo != 'Gato')
                      .toList()
                : encontrados,
          );
        }
      }
    } catch (e) {
      if (mounted && versao == _versao) {
        setState(
          () => _erro = e is LoginException
              ? e.mensagem
              : 'Não foi possível pesquisar.',
        );
      }
    } finally {
      if (mounted && versao == _versao) setState(() => _carregando = false);
    }
  }

  void _alternar(bool usuarios) {
    if (_usuariosAtivos == usuarios) return;
    setState(() => _usuariosAtivos = usuarios);
    _buscar();
  }

  void _verTodos() {
    setState(() {
      _categoria = 'Todos';
      _sexo = null;
      _porte = null;
      _texto.clear();
    });
    _buscar();
    final alvo = _resultados.currentContext;
    if (alvo != null) {
      Scrollable.ensureVisible(
        alvo,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  Future<void> _filtros() async {
    var sexo = _sexo;
    var porte = _porte;
    final aplicar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) => StatefulBuilder(
        builder: (context, atualizar) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filtrar pets', style: TextStyle(fontSize: 22)),
                const SizedBox(height: 16),
                const Text('Sexo'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final opcao in ['Todos', 'Macho', 'Fêmea'])
                      ChoiceChip(
                        label: Text(opcao),
                        selected: opcao == (sexo ?? 'Todos'),
                        onSelected: (_) => atualizar(
                          () => sexo = opcao == 'Todos' ? null : opcao,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Porte'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final opcao in ['Todos', 'Pequeno', 'Médio', 'Grande'])
                      ChoiceChip(
                        label: Text(opcao),
                        selected: opcao == (porte ?? 'Todos'),
                        onSelected: (_) => atualizar(
                          () => porte = opcao == 'Todos' ? null : opcao,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  children: [
                    TextButton(
                      onPressed: () => atualizar(() {
                        sexo = null;
                        porte = null;
                      }),
                      child: const Text('Limpar filtros'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Aplicar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (aplicar == true && mounted) {
      setState(() {
        _sexo = sexo;
        _porte = porte;
      });
      _buscar();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _texto,
                      onChanged: (_) {
                        // Invalida consultas anteriores assim que o texto muda.
                        _versao++;
                        _debounce?.cancel();
                        _debounce = Timer(
                          const Duration(milliseconds: 300),
                          _buscar,
                        );
                      },
                      onSubmitted: (_) => _buscar(),
                      decoration: InputDecoration(
                        hintText: 'Pesquisar pets, usuários...',
                        hintStyle: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF999999),
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 20,
                          color: Color(0xFF999999),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 32,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFEEEEEE),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  if (!_usuariosAtivos) ...[
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Filtros',
                      onPressed: _filtros,
                      style: IconButton.styleFrom(
                        backgroundColor: _rosa,
                        foregroundColor: _laranja,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(
                        _sexo != null || _porte != null
                            ? Icons.filter_alt
                            : Icons.tune,
                        size: 21,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _aba('Pets', Icons.pets_outlined, false),
                  const SizedBox(width: 6),
                  _aba('Usuários', Icons.people_outline, true),
                ],
              ),
              if (!_usuariosAtivos) ...[
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final item in [
                          ('Todos', Icons.grid_view_outlined),
                          ('Cachorros', Icons.pets_outlined),
                          ('Gatos', Icons.pets),
                          ('Outros', Icons.cruelty_free_outlined),
                          ('Perto de mim', Icons.location_on_outlined),
                        ])
                          SizedBox(
                            width: (constraints.maxWidth / 5).clamp(
                              56.0,
                              144.0,
                            ),
                            child: Semantics(
                              selected: _categoria == item.$1,
                              button: true,
                              child: InkWell(
                                onTap: () {
                                  setState(() => _categoria = item.$1);
                                  _buscar();
                                },
                                borderRadius: BorderRadius.circular(24),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _rosa,
                                        border: _categoria == item.$1
                                            ? Border.all(
                                                color: _laranja,
                                                width: 1.5,
                                              )
                                            : null,
                                      ),
                                      child: Icon(
                                        item.$2,
                                        size: 22,
                                        color: _categoria == item.$1
                                            ? _laranja
                                            : const Color(0xFF92583F),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.$1,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: _categoria == item.$1
                                            ? _laranja
                                            : const Color(0xFF60483E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _banner(),
              ],
              const SizedBox(height: 14),
              Row(
                key: _resultados,
                children: [
                  Expanded(
                    child: Text(
                      _usuariosAtivos
                          ? 'Explore usuários:'
                          : 'Explorar novos amigos:',
                      style: const TextStyle(
                        fontSize: 17,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _verTodos,
                    style: TextButton.styleFrom(
                      foregroundColor: _laranja,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: const Row(
                      children: [
                        Text('Ver todos', style: TextStyle(fontSize: 11)),
                        SizedBox(width: 3),
                        Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
              if (_carregando)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_erro != null)
                Column(
                  children: [
                    Text(_erro!),
                    TextButton(
                      onPressed: _buscar,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                )
              else if (_usuariosAtivos ? _usuarios.isEmpty : _pets.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    _usuariosAtivos
                        ? 'Nenhum usuário encontrado.'
                        : 'Nenhum animal encontrado.',
                  ),
                )
              else if (_usuariosAtivos)
                for (final usuario in _usuarios)
                  _SearchCard(
                    name: '${usuario.nome} ${usuario.sobrenome}',
                    desc: '@${usuario.usuario}',
                    image: usuario.imageUrl,
                    location: [
                      usuario.cidadeDeResidencia,
                      usuario.estado ?? '',
                    ].where((s) => s.isNotEmpty).join(' - '),
                    pet: false,
                    page: FichaPerfilScreen(clienteId: usuario.id),
                  )
              else
                for (final animal in _pets)
                  _SearchCard(
                    name: animal.nome,
                    desc:
                        '${animal.idade} ${animal.idade == 1 ? 'ano' : 'anos'} - ${animal.sexo}',
                    image: animal.imageUrl,
                    location: [
                      animal.cidade,
                      animal.estado,
                    ].where((s) => s.isNotEmpty).join(' - '),
                    pet: true,
                    page: FichaAnimalScreen(animalId: animal.id),
                  ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _aba(String texto, IconData icon, bool usuarios) => Expanded(
    child: ElevatedButton.icon(
      onPressed: () => _alternar(usuarios),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        backgroundColor: _usuariosAtivos == usuarios
            ? AppColors.laranja
            : _rosa,
        foregroundColor: _usuariosAtivos == usuarios ? Colors.white : _laranja,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 23),
      label: Text(texto, style: const TextStyle(fontSize: 12)),
    ),
  );

  Widget _banner() => Container(
    height: 154,
    decoration: BoxDecoration(
      color: _rosa,
      borderRadius: BorderRadius.circular(16),
    ),
    padding: const EdgeInsets.all(8),
    child: Row(
      children: [
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: 170,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Encontre seu novo\namigo ! 🐾',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.25,
                        color: Color(0xFF814C37),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Diversos pets esperando por\num lar cheio de amor.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Color(0xFF814C37)),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: FilledButton(
                        onPressed: _verTodos,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.laranja,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Ver todos', style: TextStyle(fontSize: 11)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward, size: 17),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/cachorro.jpg',
              height: double.infinity,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SearchCard extends StatelessWidget {
  const _SearchCard({
    required this.name,
    required this.desc,
    required this.image,
    required this.location,
    required this.pet,
    required this.page,
  });
  final String name, desc, location;
  final String? image;
  final bool pet;
  final Widget page;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 3),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _rosa, width: 1)),
      ),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 56,
              height: 56,
              child: image == null || image!.isEmpty
                  ? _placeholder()
                  : Image.network(
                      image!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stack) => _placeholder(),
                    ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, height: 1.1),
                ),
                Text(desc, style: const TextStyle(fontSize: 12, height: 1.3)),
                if (location.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward, color: _laranja, size: 20),
        ],
      ),
    ),
  );

  Widget _placeholder() => ColoredBox(
    color: _rosa,
    child: Icon(
      pet ? Icons.pets : Icons.person_outline,
      color: AppColors.laranja,
    ),
  );
}
