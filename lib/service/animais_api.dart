import '../model/animais.dart';
import 'clientes_api.dart';

class AnimaisApi {
  AnimaisApi({ClientesApi? api}) : _api = api ?? ClientesApi();
  final ClientesApi _api;

  Future<List<Animal>> listar(
    String token, {
    Map<String, String> filtros = const {},
  }) async {
    final query = Uri(queryParameters: filtros).query;
    final d = await _api.requisicao('animais.php?$query', token: token);
    return (d['animais'] as List)
        .map((a) => Animal.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  Future<Animal> buscar(String token, int id) async => Animal.fromJson(
    (await _api.requisicao(
          'animais.php?acao=id&id=$id',
          token: token,
        ))['animal']
        as Map<String, dynamic>,
  );

  Future<Animal> salvar(
    String token,
    Animal animal, {
    bool editar = false,
  }) async => Animal.fromJson(
    (await _api.requisicao(
          'animais.php?acao=${editar ? 'editar&id=${animal.id}' : 'cadastrar'}',
          token: token,
          dados: animal.toJson(),
        ))['animal']
        as Map<String, dynamic>,
  );

  Future<void> apagar(String token, int id) async {
    await _api.requisicao(
      'animais.php?acao=apagar&id=$id',
      token: token,
      dados: {},
    );
  }

  void close() => _api.close();
}
