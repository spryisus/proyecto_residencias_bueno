class Categoria {
  final int idCategoria;
  final String nombre;
  final String? descripcion;

  const Categoria({
    required this.idCategoria,
    required this.nombre,
    this.descripcion,
  });

  Categoria copyWith({
    int? idCategoria,
    String? nombre,
    String? descripcion,
  }) {
    return Categoria(
      idCategoria: idCategoria ?? this.idCategoria,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_categoria': idCategoria,
      'nombre': nombre,
      'descripcion': descripcion,
    };
  }

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      idCategoria: json['id_categoria'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Categoria && other.idCategoria == idCategoria;
  }

  @override
  int get hashCode => idCategoria.hashCode;

  @override
  String toString() {
    return 'Categoria(idCategoria: $idCategoria, nombre: $nombre)';
  }
}

