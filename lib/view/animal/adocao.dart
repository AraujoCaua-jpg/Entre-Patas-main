import 'package:material_ui/material_ui.dart';

import '../../controller/clientes_scope.dart';
import '../../model/adocao.dart';
import '../../model/animais.dart';
import '../../service/auth_api.dart';
import '../core/app_colors.dart';
import '../core/usuario_resumo.dart';
import '../usuario/editarPerfil.dart';

class AdocaoScreen extends StatefulWidget {
  const AdocaoScreen({super.key, this.animalId, this.adocaoId})
    : assert(animalId != null || adocaoId != null);
  final int? animalId, adocaoId;
  @override
  State<AdocaoScreen> createState() => _AdocaoScreenState();
}

class _AdocaoScreenState extends State<AdocaoScreen> {
  Animal? _animal;
  Adocao? _adocao;
  bool _iniciado = false, _carregando = true, _ocupado = false;
  String? _erro;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_iniciado) {
      _iniciado = true;
      _carregar();
    }
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final c = ClientesScope.of(context);
      if (widget.adocaoId != null) {
        final d = await c.buscarAdocao(widget.adocaoId!);
        if (!mounted) return;
        _adocao = d;
      } else {
        final a = await c.buscarAnimalRemoto(widget.animalId!);
        if (!mounted) return;
        _animal = a;
      }
    } catch (e) {
      if (mounted)
        _erro = e is LoginException
            ? e.mensagem
            : 'Não foi possível carregar a solicitação.';
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _acao(String acao) async {
    if (_ocupado) return;
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          acao == 'solicitar' ? 'Enviar solicitação?' : 'Confirmar ação?',
        ),
        content: Text(
          acao == 'solicitar'
              ? 'Seu nome, e-mail e telefone ficarão disponíveis ao responsável para conversar sobre a adoção.'
              : acao == 'aceitar'
              ? 'O animal será marcado como adotado. As outras solicitações pendentes serão recusadas.'
              : 'Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    setState(() => _ocupado = true);
    try {
      final c = ClientesScope.of(context);
      final resultado = acao == 'solicitar'
          ? await c.solicitarAdocao(_animal!.id)
          : await c.responderAdocao(_adocao!.id, acao);
      if (!mounted) return;
      setState(() => _adocao = resultado);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Solicitação atualizada.')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is LoginException ? e.mensagem : 'Não foi possível concluir.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Widget _caixa(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.rosaClaro,
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );
  Widget _titulo(String texto) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(texto, style: const TextStyle(fontSize: 24)),
  );
  Widget _botao(String texto, VoidCallback acao) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: SizedBox(
      width: double.infinity,
      height: 62,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.laranja,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: _ocupado ? null : acao,
        child: Text(texto, style: const TextStyle(fontSize: 20)),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final c = ClientesScope.of(context).clienteLogado;
    final d = _adocao?.detalhes ?? <String, dynamic>{};
    final nome = d['animal_nome'] as String? ?? _animal?.nome ?? '';
    final imagem = d['animal_imagem'] as String? ?? _animal?.imageUrl ?? '';
    final dono = _adocao?.idDono ?? _animal?.idCliente;
    final souDono = dono == c?.id;
    final status = _adocao?.status ?? 'Ainda não enviada';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          _adocao == null
              ? 'Solicitação de Adoção'
              : 'Adoção ID#${_adocao!.id}',
        ),
        shape: const Border(
          bottom: BorderSide(color: AppColors.laranja, width: 2),
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
          ? Center(
              child: TextButton(onPressed: _carregar, child: Text(_erro!)),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _titulo('Solicitação de Adoção'),
                Text(
                  'Confira as informações sobre a adoção de $nome.',
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.cinzaEscuro,
                  ),
                ),
                const SizedBox(height: 20),
                _caixa(
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: imagem.isEmpty
                            ? const SizedBox(
                                width: 100,
                                height: 100,
                                child: Icon(
                                  Icons.pets,
                                  color: AppColors.laranja,
                                  size: 48,
                                ),
                              )
                            : Image.network(
                                imagem,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: Icon(Icons.pets),
                                ),
                              ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nome, style: const TextStyle(fontSize: 24)),
                            Text(
                              '${d['animal_idade'] ?? _animal?.idade} ano(s) - ${d['animal_sexo'] ?? _animal?.sexo}',
                            ),
                            Text(
                              '${d['cidadeDeResidencia'] ?? _animal?.cidade} - ${d['estado'] ?? _animal?.estado}',
                            ),
                            if (_animal?.compatibilidade != null)
                              Text(
                                '${_animal!.compatibilidade!['total']}% de compatibilidade',
                                style: const TextStyle(color: AppColors.verde),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _titulo('Publicado por:'),
                UsuarioResumo(clienteId: dono),
                _titulo(souDono ? 'Dados do solicitante:' : 'Seus dados:'),
                _caixa(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nome: ${d['solicitante_nome'] ?? c?.nome ?? ''} ${d['solicitante_sobrenome'] ?? c?.sobrenome ?? ''}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      Text(
                        'E-mail: ${d['solicitante_email'] ?? c?.email ?? ''}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      Text(
                        'Telefone: ${d['solicitante_telefone'] ?? c?.telefone ?? ''}',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
                _titulo('Informações da Solicitação:'),
                _caixa(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_adocao != null)
                        Text(
                          'Data e hora: ${_adocao!.data.day.toString().padLeft(2, '0')}/${_adocao!.data.month.toString().padLeft(2, '0')}/${_adocao!.data.year} ${_adocao!.data.hour.toString().padLeft(2, '0')}:${_adocao!.data.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 18),
                        ),
                      Text(
                        'Status: $status',
                        style: TextStyle(
                          fontSize: 18,
                          color: status == 'Aceito'
                              ? AppColors.verde
                              : AppColors.laranja,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_adocao == null && !souDono && _animal?.status != 'Adotado')
                  _botao('Enviar solicitação', () => _acao('solicitar')),
                if (_adocao == null && souDono)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Este animal foi publicado por você.'),
                  ),
                if (_adocao == null && _animal?.status == 'Adotado')
                  const Text('Este animal já foi adotado.'),
                if (_adocao?.status == 'Aguardando' && souDono) ...[
                  _botao('Aprovar adoção', () => _acao('aceitar')),
                  _botao('Recusar solicitação', () => _acao('recusar')),
                ],
                if (_adocao?.status == 'Aguardando' && !souDono)
                  _botao('Cancelar solicitação', () => _acao('cancelar')),
                if (!souDono)
                  _botao('Editar Perfil', () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditarPerfilScreen(),
                      ),
                    );
                    if (mounted) setState(() {});
                  }),
              ],
            ),
    );
  }
}
