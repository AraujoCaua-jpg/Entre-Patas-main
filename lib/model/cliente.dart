class Cliente {
  int id;
  String nome;
  String sobrenome;
  String email;
  String telefone;
  String? imageUrl;
  String cidadeDeResidencia;
  String usuario;
  String? estado;
  String? endereco;
  bool larDeAdocao;

  Cliente({
    required this.id,
    required this.nome,
    required this.sobrenome,
    required this.email,
    required this.telefone,
    this.imageUrl,
    required this.cidadeDeResidencia,
    required this.usuario,
    this.estado,
    this.endereco,
    this.larDeAdocao = false,
  });
}
