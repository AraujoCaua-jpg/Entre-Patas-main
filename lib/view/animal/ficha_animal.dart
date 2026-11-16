import 'package:entre_patas/view/animal/adocao.dart';
import 'package:material_ui/material_ui.dart';

import '../core/app_colors.dart';

import '../core/usuario_resumo.dart';
import '../../controller/clientes_scope.dart';
import '../../model/animais.dart';
import '../../services/compatibilidade_service.dart';
import '../../services/login_exception.dart';
import 'animais_cadastrados.dart';
import 'compatibilidade_animal.dart';

class FichaAnimalScreen extends StatefulWidget {
  const FichaAnimalScreen({super.key, required this.animalId});
  final int animalId;
  @override
  State<FichaAnimalScreen> createState() => _FichaAnimalScreenState();
}

class _FichaAnimalScreenState extends State<FichaAnimalScreen> {
  Future<Animal>? _consulta;

  Future<Animal> _buscarAnimalComCompatibilidade() async {
    final controller = ClientesScope.of(context);

    // Busca os dados do animal no Supabase.
    final animal = await controller.buscarAnimalPorIdSupabase(widget.animalId);

    final meuId = controller.clienteLogado?.id;

    // Não calcula compatibilidade para animais
    // cadastrados pelo próprio usuário.
    if (meuId == null || animal.idCliente == meuId) {
      animal.compatibilidade = null;
      return animal;
    }

    // Busca o questionário do usuário conectado.
    final questionario = await controller.buscarMeuQuestionarioSupabase();

    // Utiliza exatamente o mesmo algoritmo da Home.
    animal.compatibilidade = CompatibilidadeService.calcular(
      animal,
      questionario,
    );

    return animal;
  }

  void _recarregar() {
    if (!mounted) return;
    final consulta = _buscarAnimalComCompatibilidade();
    setState(() {
      _consulta = consulta;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // O controller notifica os ouvintes após salvar o questionário.
    // Reconsulta o Supabase para não reutilizar percentuais antigos.
    _consulta = _buscarAnimalComCompatibilidade();
  }

  @override
  void didUpdateWidget(covariant FichaAnimalScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animalId != widget.animalId) {
      _consulta = _buscarAnimalComCompatibilidade();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Animal>(
      future: _consulta,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            snapshot.hasError ||
            !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Ficha do Animal')),
            body: snapshot.hasError
                ? Center(
                    child: TextButton(
                      onPressed: _recarregar,
                      child: Text(
                        snapshot.error is LoginException
                            ? (snapshot.error as LoginException).mensagem
                            : 'Não foi possível carregar o animal.',
                      ),
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          );
        }
        final animal = snapshot.data!;
        final donoId = animal.idCliente;
        final souDono = donoId == ClientesScope.of(context).clienteLogado?.id;
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: Text(animal.nome),
            shape: const Border(
              bottom: BorderSide(color: Color(0xFFD96C3F), width: 2),
            ),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3, // Define a proporção (Largura / Altura)
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      16.0,
                    ), // Bordas arredondadas
                    child: (animal.imageUrl ?? '').isEmpty
                        ? const ColoredBox(
                            color: AppColors.rosaClaro,
                            child: Center(
                              child: Icon(
                                Icons.pets,
                                size: 64,
                                color: AppColors.laranja,
                              ),
                            ),
                          )
                        : Image.network(
                            animal.imageUrl!,
                            errorBuilder: (_, _, _) =>
                                const Center(child: Icon(Icons.pets, size: 64)),
                            fit: BoxFit.cover, // Garante que a imagem preencha todo o espaço sem distorcer
                          ),
                  ),
                ),

                SizedBox(height: 20),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 5,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.rosa,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.pets, color: AppColors.laranja),
                          SizedBox(width: 10),
                          Text(
                            animal.status,
                            style: TextStyle(color: AppColors.laranja),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment
                      .start, // 👈 Alinha os elementos para a esquerda
                  children: [
                    Expanded(
                      child: Text(animal.nome, style: TextStyle(fontSize: 28)),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment
                      .start, // 👈 Alinha os elementos para a esquerda
                  children: [
                    Expanded(
                      child: Text(
                        '${animal.idade == null ? 'Idade não informada' : '${animal.idade} ano(s)'} - ${animal.sexo}',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment
                      .start, // 👈 Alinha os elementos para a esquerda
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: AppColors.laranja,
                    ),
                    Flexible(
                      child: Text(
                        '${animal.cidade} - ${animal.estado}',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment
                      .start, // 👈 Alinha os elementos para a esquerda
                  children: [
                    Expanded(
                      child: Text("Sobre mim", style: TextStyle(fontSize: 24)),
                    ),
                  ],
                ),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        animal.descricao,
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.cinzaEscuro,
                        ),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment
                      .start, // 👈 Alinha os elementos para a esquerda
                  children: [
                    Expanded(
                      child: Text(
                        "Informações",
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.rosaClaro,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Espécie:"),
                      Text(animal.tipo, style: TextStyle(fontSize: 20)),
                    ],
                  ),
                ),

                SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.rosaClaro,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Energia:"),
                            Text(
                              animal.energia,
                              style: TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(width: 8),

                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.rosaClaro,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Porte:"),
                            Text(animal.porte, style: TextStyle(fontSize: 20)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.rosaClaro,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Carência:"),
                            Text(
                              animal.carencia,
                              style: TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(width: 8),

                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.rosaClaro,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Convivência:"),
                            Text(
                              animal.convivencia,
                              style: TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.rosaClaro,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Vacinado:"),
                            Text(
                              animal.vacinado ?? 'Não informado',
                              style: TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(width: 8),

                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.rosaClaro,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Castrado:"),
                            Text(
                              animal.castrado ?? 'Não informado',
                              style: TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                if (!souDono)
                  SizedBox(
                    height: 62,
                    child: ElevatedButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AdocaoScreen(animalId: animal.id),
                          ),
                        );
                        if (mounted) _recarregar();
                      },
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
                          Flexible(
                            child: Text(
                              'Quero Adotar',
                              style: TextStyle(fontSize: 24),
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(Icons.pets),
                        ],
                      ),
                    ),
                  ),

                if (!souDono) ...[
                  const SizedBox(height: 20),
                  CompatibilidadeAnimal(
                    dados: animal.compatibilidade,
                    atualizar: _recarregar,
                  ),
                ],
                const SizedBox(height: 20),
                const Divider(color: AppColors.laranja, thickness: 1),

                Row(
                  mainAxisAlignment: MainAxisAlignment
                      .start, // 👈 Alinha os elementos para a esquerda
                  children: [
                    Expanded(
                      child: Text(
                        souDono ? 'Publicado por você' : 'Publicado por: ',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ],
                ),

                if (!souDono) ...[
                  const SizedBox(height: 10),
                  UsuarioResumo(clienteId: donoId),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(
                            title: const Text('Animais deste responsável'),
                          ),
                          body: ListaAnimais(usuarioId: donoId),
                        ),
                      ),
                    ),
                    child: const Text('Ver animais deste responsável'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
