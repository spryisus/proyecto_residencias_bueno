class Ubicacion {
  final int idUbicacion;
  final String nombre; // Sala
  final String? descripcion;
  final String? posicion; // Posición específica dentro de la sala

  const Ubicacion({
    required this.idUbicacion,
    required this.nombre,
    this.descripcion,
    this.posicion,
  });

  Ubicacion copyWith({
    int? idUbicacion,
    String? nombre,
    String? descripcion,
    String? posicion,
  }) {
    return Ubicacion(
      idUbicacion: idUbicacion ?? this.idUbicacion,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      posicion: posicion ?? this.posicion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_ubicacion': idUbicacion,
      'nombre': nombre,
      'descripcion': descripcion,
      'posicion': posicion,
    };
  }

  factory Ubicacion.fromJson(Map<String, dynamic> json) {
    // Función auxiliar para convertir a String? de manera segura
    String? _toStringOrNull(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is int) return value.toString();
      if (value is double) return value.toString();
      return value.toString();
    }

    return Ubicacion(
      idUbicacion: json['id_ubicacion'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      posicion: _toStringOrNull(json['posicion']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Ubicacion && other.idUbicacion == idUbicacion;
  }

  @override
  int get hashCode => idUbicacion.hashCode;

  @override
  String toString() {
    return 'Ubicacion(idUbicacion: $idUbicacion, nombre: $nombre)';
  }
}

