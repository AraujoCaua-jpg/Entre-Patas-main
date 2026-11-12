class Adocao {
  int id;
  DateTime data;
  String status;
  int idAnimal;
  int idCliente;
  int idDono;
  Map<String, dynamic> detalhes;

  Adocao({
    required this.id,
    required this.data,
    required this.status,
    required this.idAnimal,
    required this.idCliente,
    required this.idDono,
    this.detalhes = const {},
  });

  factory Adocao.fromJson(Map<String, dynamic> d) => Adocao(
    id: (d['id'] as num).toInt(),
    data: DateTime.parse(d['data'] as String),
    status: d['status'] as String,
    idAnimal: (d['id_animal'] as num).toInt(),
    idCliente: (d['id_cliente'] as num).toInt(),
    idDono: (d['id_dono'] as num).toInt(),
    detalhes: d,
  );
}
