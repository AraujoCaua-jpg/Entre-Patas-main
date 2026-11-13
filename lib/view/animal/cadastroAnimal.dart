import 'package:material_ui/material_ui.dart';

import '../core/app_colors.dart';
import '../../controller/clientes_scope.dart';
import '../../model/animais.dart';
import '../../service/auth_api.dart';

class CadastroAnimalScreen extends StatefulWidget {
  const CadastroAnimalScreen({super.key, this.animalId});
  final int? animalId;

  @override
  State<CadastroAnimalScreen> createState() => _CadastroAnimalScreenState();
}

class _CadastroAnimalScreenState extends State<CadastroAnimalScreen> {
  final nomeController = TextEditingController();
  final idadeController = TextEditingController();

  String? sexo;
  String? tipo;

  final descricaoController = TextEditingController();

  double? energia;
  double? porte;

  String? carencia;
  String? convivencia;
  String? castrado;
  String? vacinado;

  @override
  void dispose() {
    nomeController.dispose();
    idadeController.dispose();
    descricaoController.dispose();
    imagemController.dispose();
    super.dispose();
  }

  void mudarTipo(String estado) {
    setState(() {
      tipo = estado;
    });
  }

  bool _iniciado = false;
  bool _carregando = false;
  bool _salvando = false;
  String? _erro;
  Animal? _animal;
  final imagemController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_iniciado) {
      _iniciado = true;
      if (widget.animalId != null) _carregar();
    }
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final a = await ClientesScope.of(context)
          .buscarAnimalRemoto(widget.animalId!);
      if (!mounted) return;
      _animal = a;
      nomeController.text = a.nome;
      idadeController.text = '${a.idade}';
      descricaoController.text = a.descricao;
      imagemController.text = a.imageUrl ?? '';
      sexo = a.sexo;
      tipo = a.tipo;
      energia = [
        'Baixo',
        'Médio',
        'Alto',
      ].indexOf(a.energia).clamp(0, 2).toDouble();
      porte = [
        'Pequeno',
        'Médio',
        'Grande',
      ].indexOf(a.porte).clamp(0, 2).toDouble();
      carencia = a.carencia;
      convivencia = a.convivencia;
      vacinado = a.vacinado;
      castrado = a.castrado;
    } catch (e) {
      if (mounted)
        _erro = e is LoginException
            ? e.mensagem
            : 'Não foi possível carregar o animal.';
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> cadastrarAnimal() async {
    if (_salvando) return;
    final idade = int.tryParse(idadeController.text.trim());
    String? erro;
    if ([
      nomeController,
      idadeController,
      descricaoController,
    ].any((c) => c.text.trim().isEmpty)) {
      erro = 'Preencha todos os campos para continuar.';
    } else if (sexo == null ||
        energia == null ||
        porte == null ||
        carencia == null ||
        convivencia == null) {
      erro = 'Selecione uma opção em todos os campos para continuar.';
    } else if (tipo == null) {
      erro = 'Selecione a espécie do animal.';
    } else if (idade == null || idade < 0 || idade > 2147483647) {
      erro = 'Informe uma idade inteira em anos, a partir de zero.';
    } else if (vacinado == null || castrado == null) {
      erro = 'Informe se o animal é vacinado e castrado.';
    }
    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro)));
      return;
    }
    setState(() => _salvando = true);
    try {
      final c = ClientesScope.of(context);
      await c.salvarAnimal(
        Animal(
          id: widget.animalId ?? 0,
          nome: nomeController.text.trim(),
          idade: idade!,
          imageUrl: imagemController.text.trim(),
          tipo: tipo!,
          descricao: descricaoController.text.trim(),
          sexo: sexo!,
          status: _animal?.status ?? 'Disponível',
          energia: ['Baixo', 'Médio', 'Alto'][energia!.round()],
          porte: ['Pequeno', 'Médio', 'Grande'][porte!.round()],
          convivencia: convivencia!,
          carencia: carencia!,
          vacinado: vacinado,
          castrado: castrado,
          idCliente: c.clienteLogado?.id ?? 0,
        ),
        editar: widget.animalId != null,
      );
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is LoginException
                  ? e.mensagem
                  : 'Não foi possível salvar o animal.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          widget.animalId == null ? 'Publicar Animal' : 'Editar Animal',
        ),
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFD96C3F), width: 2),
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_erro!),
                  TextButton(
                    onPressed: _carregar,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: nomeController,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'Nome',
                      prefixIcon: const Icon(
                        Icons.pets,
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
                    controller: idadeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Idade (anos)',
                      prefixIcon: const Icon(
                        Icons.timer_outlined,
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

                  Row(
                    children: [
                      const Text('Sexo:', style: TextStyle(fontSize: 18)),
                    ],
                  ),

                  Row(
                    children: [
                      Radio<String>(
                        value: 'Macho',
                        groupValue: sexo,
                        activeColor: AppColors.laranja,
                        onChanged: (value) {
                          setState(() {
                            sexo = value;
                          });
                        },
                      ),
                      const Text('Macho', style: TextStyle(fontSize: 18)),

                      const SizedBox(width: 8),

                      Radio<String>(
                        value: 'Fêmea',
                        groupValue: sexo,
                        activeColor: AppColors.laranja,
                        onChanged: (value) {
                          setState(() {
                            sexo = value;
                          });
                        },
                      ),
                      const Text('Fêmea', style: TextStyle(fontSize: 18)),
                    ],
                  ),

                  SizedBox(height: 20),

                  Row(
                    children: [
                      const Text(
                        'Espécie de animal:',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),

                  SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => mudarTipo("Cachorro"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tipo == "Cachorro"
                                ? AppColors.laranja
                                : AppColors.rosa,
                            foregroundColor: tipo == "Cachorro"
                                ? Colors.white
                                : AppColors.laranja,
                            elevation: 0,
                            fixedSize: const Size(double.infinity, 80),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.pets),
                              SizedBox(width: 10),
                              Text('Cachorro', style: TextStyle(fontSize: 24)),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(width: 8),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => mudarTipo("Gato"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tipo == "Gato"
                                ? AppColors.verde
                                : AppColors.verdeClaro,
                            foregroundColor: tipo == "Gato"
                                ? Colors.white
                                : AppColors.verde,
                            elevation: 0,
                            fixedSize: const Size(double.infinity, 80),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.pets),
                              SizedBox(width: 10),
                              Text('Gato', style: TextStyle(fontSize: 24)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  Row(
                    children: [
                      const Text('Descrição', style: TextStyle(fontSize: 18)),
                    ],
                  ),

                  SizedBox(height: 8),

                  TextField(
                    controller: descricaoController,
                    minLines: 4,
                    maxLines: 4,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.cinza,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),

                  SizedBox(height: 20),

                  Row(
                    children: [
                      const Text('Energia', style: TextStyle(fontSize: 18)),
                    ],
                  ),

                  SizedBox(height: 8),

                  DropdownButtonFormField<double>(
                    initialValue: energia,
                    hint: const Text('Selecione uma opção'),
                    items: [
                      DropdownMenuItem(value: 0.0, child: Text('Baixo')),
                      DropdownMenuItem(value: 1.0, child: Text('Médio')),
                      DropdownMenuItem(value: 2.0, child: Text('Alto')),
                    ],
                    onChanged: (valor) => setState(() => energia = valor),
                  ),

                  SizedBox(height: 20),

                  Row(
                    children: [
                      const Text('Porte', style: TextStyle(fontSize: 18)),
                    ],
                  ),

                  SizedBox(height: 8),

                  DropdownButtonFormField<double>(
                    initialValue: porte,
                    hint: const Text('Selecione uma opção'),
                    items: [
                      DropdownMenuItem(value: 0.0, child: Text('Pequeno')),
                      DropdownMenuItem(value: 1.0, child: Text('Médio')),
                      DropdownMenuItem(value: 2.0, child: Text('Grande')),
                    ],
                    onChanged: (valor) => setState(() => porte = valor),
                  ),

                  SizedBox(height: 20),

                  Row(
                    children: [
                      const Text(
                        'O animal precisa de companhia?',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      Radio<String>(
                        value: 'Sim',
                        groupValue: carencia,
                        activeColor: AppColors.verde,
                        onChanged: (value) {
                          setState(() {
                            carencia = value;
                          });
                        },
                      ),
                      const Text('Sim', style: TextStyle(fontSize: 18)),

                      const SizedBox(width: 8),

                      Radio<String>(
                        value: 'Não',
                        groupValue: carencia,
                        activeColor: AppColors.laranja,
                        onChanged: (value) {
                          setState(() {
                            carencia = value;
                          });
                        },
                      ),
                      const Text('Não', style: TextStyle(fontSize: 18)),
                    ],
                  ),

                  SizedBox(height: 20),

                  Row(
                    children: [
                      const Text(
                        'Convive bem com outros animais?',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      Radio<String>(
                        value: 'Sim',
                        groupValue: convivencia,
                        activeColor: AppColors.verde,
                        onChanged: (value) {
                          setState(() {
                            convivencia = value;
                          });
                        },
                      ),
                      const Text('Sim', style: TextStyle(fontSize: 18)),

                      const SizedBox(width: 8),

                      Radio<String>(
                        value: 'Não',
                        groupValue: convivencia,
                        activeColor: AppColors.laranja,
                        onChanged: (value) {
                          setState(() {
                            convivencia = value;
                          });
                        },
                      ),
                      const Text('Não', style: TextStyle(fontSize: 18)),
                    ],
                  ),

                  SizedBox(height: 20),

                  Row(
                    children: [
                      const Text(
                        'O animal é castrado?',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      Radio<String>(
                        value: 'Sim',
                        groupValue: castrado,
                        activeColor: AppColors.verde,
                        onChanged: (value) => setState(() => castrado = value),
                      ),
                      const Text('Sim', style: TextStyle(fontSize: 18)),

                      const SizedBox(width: 8),

                      Radio<String>(
                        value: 'Não',
                        groupValue: castrado,
                        activeColor: AppColors.laranja,
                        onChanged: (value) => setState(() => castrado = value),
                      ),
                      const Text('Não', style: TextStyle(fontSize: 18)),
                    ],
                  ),

                  SizedBox(height: 20),

                  Row(
                    children: [
                      const Text(
                        'Vacinação regular?',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      Radio<String>(
                        value: 'Sim',
                        groupValue: vacinado,
                        activeColor: AppColors.verde,
                        onChanged: (value) => setState(() => vacinado = value),
                      ),
                      const Text('Sim', style: TextStyle(fontSize: 18)),

                      const SizedBox(width: 8),

                      Radio<String>(
                        value: 'Não',
                        groupValue: vacinado,
                        activeColor: AppColors.laranja,
                        onChanged: (value) => setState(() => vacinado = value),
                      ),
                      const Text('Não', style: TextStyle(fontSize: 18)),
                    ],
                  ),

                  SizedBox(height: 20),

                  TextField(
                    controller: imagemController,
                    maxLength: 255,
                    decoration: InputDecoration(
                      hintText: 'Link da imagem (opcional)',
                      prefixIcon: const Icon(
                        Icons.image_outlined,
                        color: Color(0xFF888888),
                      ),
                      filled: true,
                      fillColor: AppColors.cinza,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 62,
                    child: ElevatedButton(
                      onPressed: _salvando ? null : cadastrarAnimal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.laranja,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _salvando
                                ? 'Salvando...'
                                : widget.animalId == null
                                ? 'Publicar Animal'
                                : 'Salvar Alterações',
                            style: TextStyle(fontSize: 24),
                          ),
                          SizedBox(width: 10),
                          Icon(Icons.pets),
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
