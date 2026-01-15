class Contenedor {
  final int idContenedor;
  final int idProducto;
  final String? rack;
  final String contenedor;
  final int cantidad;
  final DateTime? fechaRegistro;

  const Contenedor({
    required this.idContenedor,
    required this.idProducto,
    this.rack,
    required this.contenedor,
    this.cantidad = 0,
    this.fechaRegistro,
  });

  Contenedor copyWith({
    int? idContenedor,
    int? idProducto,
    String? rack,
    String? contenedor,
    int? cantidad,
    DateTime? fechaRegistro,
  }) {
    return Contenedor(
      idContenedor: idContenedor ?? this.idContenedor,
      idProducto: idProducto ?? this.idProducto,
      rack: rack ?? this.rack,
      contenedor: contenedor ?? this.contenedor,
      cantidad: cantidad ?? this.cantidad,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_contenedor': idContenedor,
      'id_producto': idProducto,
      'rack': rack,
      'contenedor': contenedor,
      'cantidad': cantidad,
      'fecha_registro': fechaRegistro?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJsonForInsert() {
    return {
      'id_producto': idProducto,
      'rack': rack,
      'contenedor': contenedor,
      'cantidad': cantidad,
    };
  }

  factory Contenedor.fromJson(Map<String, dynamic> json) {
    return Contenedor(
      idContenedor: json['id_contenedor'] as int,
      idProducto: json['id_producto'] as int,
      rack: json['rack'] as String?,
      contenedor: json['contenedor'] as String,
      cantidad: json['cantidad'] as int? ?? 0,
      fechaRegistro: json['fecha_registro'] != null
          ? DateTime.tryParse(json['fecha_registro'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Contenedor && other.idContenedor == idContenedor;
  }

  @override
  int get hashCode => idContenedor.hashCode;

  @override
  String toString() {
    return 'Contenedor(idContenedor: $idContenedor, idProducto: $idProducto, contenedor: $contenedor, cantidad: $cantidad)';
  }
}



