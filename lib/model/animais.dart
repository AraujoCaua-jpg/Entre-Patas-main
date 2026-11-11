class Animal {
  int id;
  String nome;
  int idade;
  String? imageUrl;
  String tipo;
  String descricao;
  String sexo;
  String status;
  String energia;
  String porte;
  String convivencia;
  String carencia;
  int idCliente;

  Animal({
    required this.id,
    required this.nome,
    required this.idade,
    this.imageUrl,
    required this.tipo,
    required this.energia,
    required this.porte,
    required this.convivencia,
    required this.carencia,
    required this.descricao,
    required this.sexo,
    required this.status,
    required this.idCliente,
  });
}
