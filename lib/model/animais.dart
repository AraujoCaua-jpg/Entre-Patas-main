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
  String estado;
  String cidade;
  Map<String, dynamic>? compatibilidade;

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
    this.estado = '',
    this.cidade = '',
    this.compatibilidade,
  });

  factory Animal.fromJson(Map<String, dynamic> d) => Animal(
    id: (d['id'] as num).toInt(),
    nome: d['nome'] as String? ?? '',
    idade: (d['idade'] as num).toInt(),
    imageUrl: d['imagem'] as String?,
    tipo: d['tipo'] as String? ?? '',
    descricao: d['descricao'] as String? ?? '',
    sexo: d['sexo'] as String? ?? '',
    status: d['status'] as String? ?? '',
    energia: d['energia'] as String? ?? '',
    porte: d['porte'] as String? ?? '',
    convivencia: d['convivencia'] as String? ?? '',
    carencia: d['carencia'] as String? ?? '',
    idCliente: (d['id_cliente'] as num).toInt(),
    estado: d['estado'] as String? ?? '',
    cidade: d['cidadeDeResidencia'] as String? ?? '',
    compatibilidade: d['compatibilidade'] as Map<String, dynamic>?,
  );

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'idade': idade,
    'imagem': imageUrl,
    'tipo': tipo,
    'descricao': descricao,
    'sexo': sexo,
    'status': status,
    'energia': energia,
    'porte': porte,
    'convivencia': convivencia,
    'carencia': carencia,
  };
}
