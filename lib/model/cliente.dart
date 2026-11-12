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
  bool questionarioPendente;

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
    this.questionarioPendente = false,
  });
  factory Cliente.fromJson(Map<String, dynamic> c) => Cliente(
    id: c['id'] as int,
    nome: c['nome'] as String? ?? '',
    sobrenome: c['sobrenome'] as String? ?? '',
    email: c['email'] as String? ?? '',
    telefone: c['telefone'] as String? ?? '',
    usuario: c['usuario'] as String? ?? '',
    cidadeDeResidencia: c['cidadeDeResidencia'] as String? ?? '',
    estado: c['estado'] as String?,
    endereco: c['endereco'] as String?,
    imageUrl: c['imagem'] as String?,
    larDeAdocao: c['larDeAdocao'] == true || c['larDeAdocao'] == 1,
    questionarioPendente:
        c['questionario_pendente'] == true || c['questionario_pendente'] == 1,
  );
  Map<String, dynamic> toJson() => {
    'nome': nome,
    'sobrenome': sobrenome,
    'email': email,
    'telefone': telefone,
    'usuario': usuario,
    'cidadeDeResidencia': cidadeDeResidencia,
    'estado': estado,
    'endereco': endereco,
    'imagem': imageUrl,
    'larDeAdocao': larDeAdocao,
  };
}
