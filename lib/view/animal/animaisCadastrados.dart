import 'package:entre_patas/view/core/app_colors.dart';
import 'package:material_ui/material_ui.dart';

import 'cadastroAnimal.dart';
import 'editarAnimal.dart';
import 'fichaAnimal.dart';
import '../../controller/clientes_scope.dart';
import '../../model/animais.dart';
import '../../service/auth_api.dart';

class AnimaisCadastradosScreen extends StatefulWidget {
  const AnimaisCadastradosScreen({super.key});
  @override
  State<AnimaisCadastradosScreen> createState() =>
      _AnimaisCadastradosScreenState();
}

class _AnimaisCadastradosScreenState extends State<AnimaisCadastradosScreen> {
  List<Animal> _animais = [];
  bool _iniciado = false, _carregando = false;
  String? _erro;
  int _pagina = 1;
  bool _mais = false;
  List<List<dynamic>> get animais => _animais
      .map((a) => [a.nome, '${a.idade} ano(s)', a.sexo, a.imageUrl ?? '', a.id])
      .toList();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_iniciado) {
      _iniciado = true;
      _carregar();
    }
  }

  Future<void> _carregar({bool mais = false}) async {
    final c = ClientesScope.of(context);
    setState(() {
      _carregando = true;
      _erro = null;
    });
    final pagina = mais ? _pagina + 1 : 1;
    try {
      final lista = await c.listarAnimais(
        filtros: {
          'id_cliente': '${c.clienteLogado?.id ?? 0}',
          'pagina': '$pagina',
        },
      );
      if (!mounted) return;
      setState(() {
        _animais = mais ? [..._animais, ...lista] : lista;
        _pagina = pagina;
        _mais = lista.length == 50;
      });
    } catch (e) {
      if (mounted)
        setState(
          () => _erro = e is LoginException
              ? e.mensagem
              : 'Não foi possível carregar os animais.',
        );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _abrir(Widget tela) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => tela));
    if (mounted) _carregar();
  }

  Future<void> _excluir(BuildContext dialogContext, int id) async {
    Navigator.of(dialogContext).pop();
    try {
      await ClientesScope.of(context).apagarAnimal(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Animal apagado!')));
      await _carregar();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is LoginException
                  ? e.mensagem
                  : 'Não foi possível apagar o animal.',
            ),
          ),
        );
    }
  }

  void apagar(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Deletar'),
          content: const Text(
            'Tem certeza que deseja apagar este animal do sistema?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Não',
                style: TextStyle(color: AppColors.laranja),
              ),
            ),
            ElevatedButton(
              onPressed: () => _excluir(dialogContext, id),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.laranja,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Sim', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Animais Publicados'),
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFD96C3F), width: 2),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_carregando) const LinearProgressIndicator(),
            if (_erro != null)
              TextButton(onPressed: () => _carregar(), child: Text(_erro!)),
            if (_mais)
              TextButton(
                onPressed: _carregando ? null : () => _carregar(mais: true),
                child: const Text('Carregar mais'),
              ),
            Expanded(
              child: animais.isEmpty
                  ? const Center(child: Text('Nenhum Animal Cadastrado'))
                  : ListView.builder(
                      itemCount: animais.length,
                      itemBuilder: (context, index) {
                        final item = animais[index];

                        return Card(
                          elevation: 2,
                          child: Padding(
                            padding: EdgeInsets.all(
                              8.0,
                            ), // Espaçamento interno em todos os lados
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius:
                                      30, // Define o tamanho do raio do círculo
                                  backgroundImage: (item[3] as String).isEmpty
                                      ? null
                                      : NetworkImage(item[3]),
                                  child: (item[3] as String).isEmpty
                                      ? const Icon(Icons.pets)
                                      : null,
                                  // Ou use NetworkImage, AssetImage, etc.
                                ),

                                SizedBox(width: 10),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item[0],
                                        style: TextStyle(fontSize: 20),
                                      ),
                                      Text(
                                        "${item[1]} - ${item[2]}",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.cinzaEscuro,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_note_rounded,
                                    color: AppColors.cinzaEscuro,
                                    size: 26,
                                  ),
                                  onPressed: () => _abrir(
                                    EditarAnimalScreen(
                                      animalId: item[4] as int,
                                    ),
                                  ),
                                ),

                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 26,
                                  ),
                                  onPressed: () =>
                                      apagar(context, item[4] as int),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrir(const CadastroAnimalScreen()),
        tooltip: 'Publicar Animal',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ListaAnimais extends StatefulWidget {
  const ListaAnimais({super.key, this.meus = false, this.usuarioId});
  final bool meus;
  final int? usuarioId;
  @override
  State<ListaAnimais> createState() => _ListaAnimaisState();
}

class _ListaAnimaisState extends State<ListaAnimais> {
  final _nome = TextEditingController(),
      _cidade = TextEditingController(),
      _estado = TextEditingController();
  String _tipo = '',
      _porte = '',
      _sexo = '',
      _energia = '',
      _convivencia = '',
      _carencia = '';
  List<Animal> _animais = [];
  bool _iniciado = false, _carregando = false, _mais = false;
  int _pagina = 1, _versao = 0;
  String? _erro;
  Map<String, String> _filtrosAtuais = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_iniciado) {
      _iniciado = true;
      _buscar();
    }
  }

  Future<void> _buscar({bool mais = false}) async {
    final c = ClientesScope.of(context);
    final versao = ++_versao;
    final pagina = mais ? _pagina + 1 : 1;
    final filtros = mais
        ? _filtrosAtuais
        : <String, String>{
            'q': _nome.text.trim(),
            'cidade': _cidade.text.trim(),
            'estado': _estado.text.trim().toUpperCase(),
            'tipo': _tipo,
            'porte': _porte,
            'sexo': _sexo,
            'energia': _energia,
            'convivencia': _convivencia,
            'carencia': _carencia,
            if (widget.meus) 'id_cliente': '${c.clienteLogado?.id ?? 0}',
            if (widget.usuarioId != null) 'id_cliente': '${widget.usuarioId}',
          };
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final lista = await c.listarAnimais(
        filtros: {...filtros, 'pagina': '$pagina'},
      );
      if (!mounted || versao != _versao) return;
      setState(() {
        _animais = mais ? [..._animais, ...lista] : lista;
        _pagina = pagina;
        _mais = lista.length == 50;
        _filtrosAtuais = filtros;
      });
    } catch (e) {
      if (mounted && versao == _versao)
        setState(
          () => _erro = e is LoginException
              ? e.mensagem
              : 'Não foi possível carregar os animais.',
        );
    } finally {
      if (mounted && versao == _versao) setState(() => _carregando = false);
    }
  }

  Future<void> _abrir(Widget tela) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => tela));
    if (mounted) _buscar();
  }

  Future<void> _apagar(Animal a) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar animal'),
        content: Text('Deseja apagar ${a.nome}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    try {
      await ClientesScope.of(context).apagarAnimal(a.id);
      if (mounted) await _buscar();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is LoginException ? e.mensagem : 'Não foi possível apagar.',
            ),
          ),
        );
    }
  }

  Widget _filtro(
    String titulo,
    String valor,
    List<String> opcoes,
    ValueChanged<String> mudar,
  ) => SizedBox(
    width: 180,
    child: DropdownButtonFormField<String>(
      initialValue: valor,
      decoration: InputDecoration(labelText: titulo),
      items: ['', ...opcoes]
          .map(
            (v) => DropdownMenuItem(
              value: v,
              child: Text(v.isEmpty ? 'Todos' : v),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => mudar(v!)),
    ),
  );
  @override
  void dispose() {
    _nome.dispose();
    _cidade.dispose();
    _estado.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 280),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _nome,
                  decoration: const InputDecoration(
                    labelText: 'Pesquisar animal pelo nome',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (_) => _buscar(),
                ),
                ExpansionTile(
                  title: const Text('Região e preferências'),
                  children: [
                    TextField(
                      controller: _estado,
                      maxLength: 2,
                      decoration: const InputDecoration(
                        labelText: 'Estado (UF)',
                      ),
                    ),
                    TextField(
                      controller: _cidade,
                      decoration: const InputDecoration(labelText: 'Cidade'),
                    ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _filtro('Espécie', _tipo, [
                          'Cachorro',
                          'Gato',
                        ], (v) => _tipo = v),
                        _filtro('Porte', _porte, [
                          'Pequeno',
                          'Médio',
                          'Grande',
                        ], (v) => _porte = v),
                        _filtro('Sexo', _sexo, [
                          'Macho',
                          'Fêmea',
                        ], (v) => _sexo = v),
                        _filtro('Energia', _energia, [
                          'Baixo',
                          'Médio',
                          'Alto',
                        ], (v) => _energia = v),
                        _filtro('Convive com animais', _convivencia, [
                          'Sim',
                          'Não',
                        ], (v) => _convivencia = v),
                        _filtro('Precisa de companhia', _carencia, [
                          'Sim',
                          'Não',
                        ], (v) => _carencia = v),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _carregando ? null : () => _buscar(),
                      child: const Text('Buscar'),
                    ),
                    if (widget.meus)
                      TextButton.icon(
                        onPressed: () => _abrir(const CadastroAnimalScreen()),
                        icon: const Icon(Icons.add),
                        label: const Text('Publicar Animal'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      if (_carregando) const LinearProgressIndicator(),
      if (_erro != null)
        Padding(padding: const EdgeInsets.all(8), child: Text(_erro!)),
      Expanded(
        child: _animais.isEmpty && !_carregando
            ? const Center(child: Text('Nenhum animal encontrado.'))
            : ListView.builder(
                itemCount: _animais.length + (_mais ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == _animais.length)
                    return TextButton(
                      onPressed: _carregando ? null : () => _buscar(mais: true),
                      child: const Text('Carregar mais'),
                    );
                  final a = _animais[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: (a.imageUrl ?? '').isEmpty
                          ? null
                          : NetworkImage(a.imageUrl!),
                      child: (a.imageUrl ?? '').isEmpty
                          ? const Icon(Icons.pets)
                          : null,
                    ),
                    title: Text(a.nome),
                    subtitle: Text(
                      '${a.idade} ano(s) • ${a.sexo}\n${a.cidade} - ${a.estado}',
                    ),
                    onTap: () => _abrir(FichaAnimalScreen(animalId: a.id)),
                    trailing: widget.meus
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Editar',
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    _abrir(EditarAnimalScreen(animalId: a.id)),
                              ),
                              IconButton(
                                tooltip: 'Apagar',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _apagar(a),
                              ),
                            ],
                          )
                        : null,
                  );
                },
              ),
      ),
    ],
  );
}
