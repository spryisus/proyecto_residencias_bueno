class Rol {
  final int idRol;
  final String nombre;
  final String? descripcion;

  const Rol({
    required this.idRol,
    required this.nombre,
    this.descripcion,
  });

  Rol copyWith({
    int? idRol,
    String? nombre,
    String? descripcion,
  }) {
    return Rol(
      idRol: idRol ?? this.idRol,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_rol': idRol,
      'nombre': nombre,
      'descripcion': descripcion,
    };
  }

  factory Rol.fromJson(Map<String, dynamic> json) {
    return Rol(
      idRol: json['id_rol'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Rol && other.idRol == idRol;
  }

  @override
  int get hashCode => idRol.hashCode;

  @override
  String toString() {
    return 'Rol(idRol: $idRol, nombre: $nombre)';
  }
}

