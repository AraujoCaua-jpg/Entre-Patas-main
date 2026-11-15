import 'package:material_ui/material_ui.dart';

import '../../services/foto_perfil_url.dart';

class FotoPerfilAvatar extends StatelessWidget {
  const FotoPerfilAvatar({
    super.key,
    this.url,
    this.radius,
    this.backgroundColor,
    this.foregroundColor,
    this.icon = Icons.person,
    this.iconSize,
  });

  final String? url;
  final double? radius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData icon;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final imagem = url?.trim();
    final placeholder = Center(
      child: Icon(icon, size: iconSize, color: foregroundColor),
    );

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      child: ClipOval(
        child: SizedBox.expand(
          child: FotoPerfilUrl.valida(imagem)
              ? Image.network(
                  imagem!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progresso) =>
                      progresso == null ? child : placeholder,
                  errorBuilder: (context, error, stackTrace) => placeholder,
                )
              : placeholder,
        ),
      ),
    );
  }
}
