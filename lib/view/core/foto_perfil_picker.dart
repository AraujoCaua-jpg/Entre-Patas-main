import 'package:material_ui/material_ui.dart';

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image_picker/image_picker.dart';

import 'app_colors.dart';
import '../../services/foto_perfil_url.dart';
import '../../services/foto_perfil_storage_service.dart';
import '../../services/login_exception.dart';

class FotoPerfilPicker extends StatefulWidget {
  const FotoPerfilPicker({
    super.key,
    this.url,
    required this.onChanged,
    this.enabled = true,
    this.foto,
    this.onFotoChanged,
    this.selecionarImagem,
    this.titulo = 'Foto de perfil',
  });
  final String? url;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  final Uint8List? foto;
  final ValueChanged<Uint8List?>? onFotoChanged;
  final Future<XFile?> Function()? selecionarImagem;
  final String titulo;
  @override
  State<FotoPerfilPicker> createState() => _FotoPerfilPickerState();
}

class _FotoPerfilPickerState extends State<FotoPerfilPicker> {
  late final TextEditingController _urlController;
  bool _selecionando = false;

  Future<void> _escolherFoto() async {
    if (_selecionando || !widget.enabled) return;
    setState(() => _selecionando = true);
    try {
      final arquivo =
          await (widget.selecionarImagem?.call() ??
              ImagePicker().pickImage(
                source: ImageSource.gallery,
                maxWidth: 1024,
                maxHeight: 1024,
                imageQuality: 80,
              ));
      if (arquivo == null) return;
      if (await arquivo.length() > FotoPerfilStorageService.limiteBytes) {
        throw const LoginException('Escolha uma foto de até 2 MB.');
      }
      final foto = await arquivo.readAsBytes();
      FotoPerfilStorageService.validarFoto(foto);
      final codec = await ui.instantiateImageCodec(foto, targetWidth: 256);
      try {
        final quadro = await codec.getNextFrame();
        quadro.image.dispose();
      } finally {
        codec.dispose();
      }
      if (!mounted) return;
      widget.onFotoChanged?.call(foto);
      widget.onChanged(null);
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            erro is LoginException
                ? erro.mensagem
                : 'Não foi possível abrir a imagem. Escolha outra foto.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _selecionando = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.url ?? '');
  }

  @override
  void didUpdateWidget(covariant FotoPerfilPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url && _urlController.text != widget.url) {
      _urlController.text = widget.url ?? '';
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const placeholder = Icon(
      Icons.person_outline,
      size: 64,
      color: AppColors.laranja,
    );
    return Column(
      children: [
        Text(
          widget.titulo,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          width: 140,
          height: 140,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.laranja, width: 2),
          ),
          child: ClipOval(
            child: ColoredBox(
              color: AppColors.rosa,
              child: widget.foto != null
                  ? Image.memory(
                      widget.foto!,
                      fit: BoxFit.cover,
                      cacheWidth: 280,
                      errorBuilder: (_, error, stack) => placeholder,
                    )
                  : FotoPerfilUrl.valida(_urlController.text)
                  ? Image.network(
                      _urlController.text.trim(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stack) => placeholder,
                    )
                  : placeholder,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Prévia da foto',
          style: TextStyle(color: AppColors.cinzaEscuro),
        ),
        const SizedBox(height: 12),
        if (widget.onFotoChanged != null) ...[
          Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: widget.enabled && !_selecionando
                    ? _escolherFoto
                    : null,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(_selecionando ? 'Abrindo...' : 'Escolher foto'),
              ),
              if (widget.foto != null || _urlController.text.isNotEmpty)
                TextButton.icon(
                  onPressed: widget.enabled && !_selecionando
                      ? () {
                          widget.onFotoChanged!(null);
                          widget.onChanged(null);
                        }
                      : null,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remover foto'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'JPG, PNG ou WebP · até 2 MB',
            style: TextStyle(color: AppColors.cinzaEscuro),
          ),
        ] else
          TextField(
            controller: _urlController,
            enabled: widget.enabled,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            onChanged: (valor) {
              setState(() {});
              final url = valor.trim();
              widget.onChanged(url.isEmpty ? null : url);
            },
            decoration: InputDecoration(
              hintText: 'Link da imagem (opcional)',
              prefixIcon: const Icon(Icons.link, color: Color(0xFF888888)),
              suffixIcon: _urlController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Remover foto',
                      onPressed: widget.enabled
                          ? () {
                              _urlController.clear();
                              setState(() {});
                              widget.onChanged(null);
                            }
                          : null,
                      icon: const Icon(Icons.clear),
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
      ],
    );
  }
}
