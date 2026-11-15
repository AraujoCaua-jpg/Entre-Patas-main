import 'dart:developer' as developer;

import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

class FotoPerfilPicker extends StatefulWidget {
  const FotoPerfilPicker({
    super.key,
    this.url,
    required this.onChanged,
    this.onBusy,
    this.enabled = true,
  });
  final String? url;
  final ValueChanged<Uint8List?> onChanged;
  final ValueChanged<bool>? onBusy;
  final bool enabled;
  @override
  State<FotoPerfilPicker> createState() => _FotoPerfilPickerState();
}

class _FotoPerfilPickerState extends State<FotoPerfilPicker> {
  Uint8List? _foto;
  bool _selecionandoFoto = false;
  Future<void> _escolherFoto() async {
    if (_selecionandoFoto) return;
    setState(() => _selecionandoFoto = true);
    widget.onBusy?.call(true);
    try {
      final arquivo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (arquivo == null || !mounted) return;
      if (await arquivo.length() > 3 * 1024 * 1024) {
        throw const FormatException('Escolha uma foto de até 3 MB.');
      }
      final bytes = await arquivo.readAsBytes();
      final jpg =
          bytes.length >= 3 &&
          bytes[0] == 0xff &&
          bytes[1] == 0xd8 &&
          bytes[2] == 0xff;
      final png =
          bytes.length >= 8 &&
          bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4e &&
          bytes[3] == 0x47;
      final webp =
          bytes.length >= 12 &&
          String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
          String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP';
      if (!jpg && !png && !webp) {
        throw const FormatException('Escolha uma foto JPG, PNG ou WebP.');
      }
      final codec = await PaintingBinding.instance
          .instantiateImageCodecWithSize(
            await ImmutableBuffer.fromUint8List(bytes),
          );
      try {
        final frame = await codec.getNextFrame();
        frame.image.dispose();
      } finally {
        codec.dispose();
      }
      if (!mounted) return;
      setState(() => _foto = bytes);
      widget.onChanged(bytes);
    } catch (erro, stack) {
      developer.log(
        'Falha ao selecionar foto de perfil',
        name: 'cadastro.foto',
        error: erro,
        stackTrace: stack,
      );
      if (!mounted) return;
      final String mensagem;
      if (erro is MissingPluginException || erro is UnimplementedError) {
        mensagem = 'O seletor de fotos ainda não foi carregado. Feche o app e execute novamente; Hot Reload não é suficiente.';
      } else if (erro is PlatformException) {
        mensagem =
            erro.code.contains('denied') || erro.code.contains('permission')
            ? 'Permita o acesso às fotos nas configurações do dispositivo e tente novamente.'
            : 'Não foi possível abrir o seletor de fotos (${erro.code}). Feche e abra o app novamente.';
      } else {
        mensagem = erro is FormatException ? erro.message.toString() : 'Não foi possível ler a foto. Tente outro arquivo JPG, PNG ou WebP.';
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensagem)));
    } finally {
      if (mounted) {
        setState(() => _selecionandoFoto = false);
        widget.onBusy?.call(false);
      }
    }
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
        const Text(
          'Foto de perfil',
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
              child: _foto != null
                  ? Image.memory(_foto!, fit: BoxFit.cover)
                  : (widget.url?.isNotEmpty ?? false)
                  ? Image.network(
                      widget.url!,
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
        OutlinedButton.icon(
          onPressed: !widget.enabled || _selecionandoFoto
              ? null
              : _escolherFoto,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(
            _selecionandoFoto
                ? 'Abrindo fotos...'
                : _foto != null || (widget.url?.isNotEmpty ?? false)
                ? 'Trocar foto'
                : 'Escolher foto',
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.laranja,
            side: const BorderSide(color: AppColors.laranja),
            minimumSize: const Size(180, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (_foto != null || (widget.url?.isNotEmpty ?? false))
          TextButton.icon(
            onPressed: !widget.enabled || _selecionandoFoto
                ? null
                : () {
                    setState(() => _foto = null);
                    widget.onChanged(null);
                  },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Remover foto'),
            style: TextButton.styleFrom(foregroundColor: AppColors.laranja),
          ),
        const SizedBox(height: 8),
        const Text(
          'JPG, PNG ou WebP • até 3 MB',
          style: TextStyle(color: AppColors.cinzaEscuro, fontSize: 12),
        ),
      ],
    );
  }
}
