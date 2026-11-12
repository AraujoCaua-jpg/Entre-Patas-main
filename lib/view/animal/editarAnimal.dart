import 'package:material_ui/material_ui.dart';

import 'cadastroAnimal.dart';

class EditarAnimalScreen extends StatelessWidget {
  const EditarAnimalScreen({super.key, required this.animalId});
  final int animalId;
  @override
  Widget build(BuildContext context) =>
      CadastroAnimalScreen(animalId: animalId);
}
