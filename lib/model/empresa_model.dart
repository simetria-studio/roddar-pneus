class Empresa {
  final int id;
  final String codigo_empresa;
  final String razao_social;
  final String nome_fantasia;

  Empresa({
    required this.id,
    required this.codigo_empresa,
    required this.razao_social,
    required this.nome_fantasia,
  });

  factory Empresa.fromJson(Map<String, dynamic> json) {
    return Empresa(
      id: json['id'],
      codigo_empresa: json['codigo_empresa'],
      razao_social: json['razao_social'],
      nome_fantasia: json['nome_fantasia'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo_empresa': codigo_empresa,
      'razao_social': razao_social,
      'nome_fantasia': nome_fantasia,
    };
  }
}
