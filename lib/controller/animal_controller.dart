import 'dart:developer' as developer;

import '../model/animais.dart';

class AnimalController {
  List<Animal> animais = [];

  //cadastrar animais
  void cadastrarAnimal(Animal animal) {
    animais.add(animal);
    developer.log('Animal cadastrado com sucesso: ${animal.nome}');
  }

  // Buscar animal pelo ID
  Animal? buscarAnimal(int id) {
    for (final animal in animais) {
      if (animal.id == id) {
        return animal;
      }
    }
    return null;
  }

  // Excluir animal
  void excluirAnimal(int id) {
    animais.removeWhere((animal) => animal.id == id);
  }

  //Listar Animais
  List<Animal> getAllAnimals() {
    return animais;
  }
}
