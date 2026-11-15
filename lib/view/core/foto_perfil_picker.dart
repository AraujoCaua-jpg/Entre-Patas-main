import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import '../../services/foto_perfil_url.dart';

class FotoPerfilPicker extends StatefulWidget {
  const FotoPerfilPicker({
    super.key,
    this.url,
    required this.onChanged,
    this.enabled = true,
  });
  final String? url;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  @override
  State<FotoPerfilPicker> createState() => _FotoPerfilPickerState();
}

class _FotoPerfilPickerState extends State<FotoPerfilPicker> {
  late final TextEditingController _urlController;

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
              child: FotoPerfilUrl.valida(_urlController.text)
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
