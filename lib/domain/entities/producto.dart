class Producto {
  final int idProducto;
  final String nombre;
  final String? descripcion;
  final String? unidad;
  final int? tamano;
  final String? rack;
  final String? contenedor;

  const Producto({
    required this.idProducto,
    required this.nombre,
    this.descripcion,
    this.unidad,
    this.tamano,
    this.rack,
    this.contenedor,
  });

  Producto copyWith({
    int? idProducto,
    String? nombre,
    String? descripcion,
    String? unidad,
    int? tamano,
    String? rack,
    String? contenedor,
  }) {
    return Producto(
      idProducto: idProducto ?? this.idProducto,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      unidad: unidad ?? this.unidad,
      tamano: tamano ?? this.tamano,
      rack: rack ?? this.rack,
      contenedor: contenedor ?? this.contenedor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_producto': idProducto,
      'nombre': nombre,
      'descripcion': descripcion,
      'unidad': unidad,
      'tamano': tamano,
      'rack': rack,
      'contenedor': contenedor,
    };
  }

  factory Producto.fromJson(Map<String, dynamic> json) {
    // Función auxiliar para convertir a String? de manera segura
    String? _toStringOrNull(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is int) return value.toString();
      if (value is double) return value.toString();
      return value.toString();
    }

    return Producto(
      idProducto: json['id_producto'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      unidad: json['unidad'] as String?,
      tamano: json['tamano'] as int?,
      rack: _toStringOrNull(json['rack']),
      contenedor: _toStringOrNull(json['contenedor']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Producto && other.idProducto == idProducto;
  }

  @override
  int get hashCode => idProducto.hashCode;

  @override
  String toString() {
    return 'Producto(idProducto: $idProducto, nombre: $nombre)';
  }
}

