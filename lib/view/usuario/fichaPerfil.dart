import 'package:material_ui/material_ui.dart';

import '../../controller/clientes_scope.dart';
import '../../model/cliente.dart';
import '../../model/animais.dart';
import '../../service/auth_api.dart';
import '../animal/fichaAnimal.dart';
import '../core/app_colors.dart';

class FichaPerfilScreen extends StatefulWidget {
  const FichaPerfilScreen({super.key, this.clienteId});
  final int? clienteId;
  @override
  State<FichaPerfilScreen> createState() => _FichaPerfilScreenState();
}

class _FichaPerfilScreenState extends State<FichaPerfilScreen> {
  Future<Cliente>? _consulta;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.clienteId != null) {
      _consulta ??= ClientesScope.of(context)
          .buscarClienteRemoto(widget.clienteId!);
    }
  }

  @override
  void didUpdateWidget(covariant FichaPerfilScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clienteId != widget.clienteId) {
      _consulta = widget.clienteId == null
          ? null
          : ClientesScope.of(context).buscarClienteRemoto(widget.clienteId!);
    }
  }

  void _recarregar() {
    final consulta = ClientesScope.of(context)
        .buscarClienteRemoto(widget.clienteId!);
    setState(() {
      _consulta = consulta;
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Cliente>(
    future: _consulta,
    builder: (context, snapshot) {
      final c = snapshot.data;
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          title: Text(
            c == null ? 'Perfil do usuário' : 'Perfil ‘@${c.usuario}’',
            style: const TextStyle(fontSize: 18),
          ),
          shape: const Border(
            bottom: BorderSide(color: AppColors.laranja, width: 1),
          ),
        ),
        body: widget.clienteId == null
            ? const Center(
                child: Text('Este item ainda não tem um usuário vinculado.'),
              )
            : snapshot.hasError
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      snapshot.error is LoginException
                          ? (snapshot.error as LoginException).mensagem
                          : 'Não foi possível carregar o perfil.',
                    ),
                    TextButton(
                      onPressed: _recarregar,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              )
            : c == null
            ? const Center(child: CircularProgressIndicator())
            : Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    children: [
                      Center(
                        child: SizedBox(
                          width: 112,
                          height: 112,
                          child: ClipOval(
                            child: (c.imageUrl ?? '').isEmpty
                                ? const ColoredBox(
                                    color: AppColors.rosaClaro,
                                    child: Icon(
                                      Icons.person,
                                      size: 62,
                                      color: AppColors.laranja,
                                    ),
                                  )
                                : Image.network(
                                    c.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const ColoredBox(
                                      color: AppColors.rosaClaro,
                                      child: Icon(
                                        Icons.person,
                                        size: 62,
                                        color: AppColors.laranja,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${c.nome} ${c.sobrenome}'.trim(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22),
                      ),
                      Text(
                        '@${c.usuario}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.cinzaEscuro,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.cinzaEscuro,
                          ),
                          Flexible(
                            child: Text(
                              [
                                c.cidadeDeResidencia,
                                if ((c.estado ?? '').isNotEmpty) c.estado!,
                              ].where((v) => v.isNotEmpty).join(' - '),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.cinzaEscuro,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: AppColors.laranja, thickness: 1),
                      if (c.larDeAdocao) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.fundo,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Lar de Adoção',
                                style: TextStyle(fontSize: 20),
                              ),
                              if ((c.endereco ?? '').isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  c.endereco!,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                              if (c.telefone.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Tel: ${c.telefone}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                              if (c.email.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  c.email,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Divider(color: AppColors.laranja, thickness: 1),
                      ],
                      const SizedBox(height: 6),
                      const Text(
                        'Animais Disponíveis',
                        style: TextStyle(fontSize: 22),
                      ),
                      const SizedBox(height: 12),
                      _AnimaisDoPerfil(key: ValueKey(c.id), clienteId: c.id),
                    ],
                  ),
                ),
              ),
      );
    },
  );
}

class _AnimaisDoPerfil extends StatefulWidget {
  const _AnimaisDoPerfil({super.key, required this.clienteId});
  final int clienteId;
  @override
  State<_AnimaisDoPerfil> createState() => _AnimaisDoPerfilState();
}

class _AnimaisDoPerfilState extends State<_AnimaisDoPerfil> {
  List<Animal> _animais = [];
  bool _iniciado = false, _carregando = false, _mais = false;
  int _pagina = 1;
  String? _erro;
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
    final pagina = mais ? _pagina + 1 : 1;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final animais = await c.listarAnimais(
        filtros: {
          'id_cliente': '${widget.clienteId}',
          'status': 'Disponível',
          'pagina': '$pagina',
        },
      );
      if (!mounted) return;
      setState(() {
        _animais = mais ? [..._animais, ...animais] : animais;
        _pagina = pagina;
        _mais = animais.length == 50;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = e is LoginException
              ? e.mensagem
              : 'Não foi possível carregar os animais.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (_carregando)
        const Padding(
          padding: EdgeInsets.all(12),
          child: LinearProgressIndicator(),
        ),
      if (_erro != null) ...[
        Text(_erro!),
        TextButton(
          onPressed: () => _carregar(),
          child: const Text('Tentar novamente'),
        ),
      ],
      if (!_carregando && _erro == null && _animais.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text('Nenhum animal disponível no momento.'),
        ),
      LayoutBuilder(
        builder: (context, constraints) {
          final largura = (constraints.maxWidth - 8) / 2;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              mainAxisExtent: largura / 1.45 + 78,
            ),
            itemCount: _animais.length,
            itemBuilder: (context, i) {
              final a = _animais[i];
              return _AnimalPerfilCard(
                animal: a,
                abrir: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FichaAnimalScreen(animalId: a.id),
                    ),
                  );
                  if (mounted) _carregar();
                },
              );
            },
          );
        },
      ),
      if (_mais)
        TextButton(
          onPressed: _carregando ? null : () => _carregar(mais: true),
          child: const Text('Carregar mais'),
        ),
    ],
  );
}

class _AnimalPerfilCard extends StatelessWidget {
  const _AnimalPerfilCard({required this.animal, required this.abrir});
  final Animal animal;
  final VoidCallback abrir;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: AppColors.laranja),
      borderRadius: BorderRadius.circular(7),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: abrir,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.45,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if ((animal.imageUrl ?? '').isEmpty)
                  const ColoredBox(
                    color: AppColors.rosaClaro,
                    child: Icon(Icons.pets, color: AppColors.laranja, size: 42),
                  )
                else
                  Image.network(
                    animal.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: AppColors.rosaClaro,
                      child: Icon(
                        Icons.pets,
                        color: AppColors.laranja,
                        size: 42,
                      ),
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
                        size: 12,
                        color: AppColors.laranja,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 4,
                  bottom: 4,
                  right: 4,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.rosaClaro,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        animal.compatibilidade == null
                            ? 'Para adoção'
                            : '${animal.compatibilidade!['total']}% de compatibilidade',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.laranja,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  animal.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
                _detalhe(Icons.pets_outlined, animal.tipo),
                _detalhe(Icons.access_time, '${animal.idade} ano(s)'),
                _detalhe(
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
  Widget _detalhe(IconData icone, String texto) => Row(
    children: [
      Icon(icone, size: 11, color: AppColors.cinzaEscuro),
      const SizedBox(width: 3),
      Expanded(
        child: Text(
          texto,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            height: 1.2,
            color: AppColors.cinzaEscuro,
          ),
        ),
      ),
    ],
  );
}
