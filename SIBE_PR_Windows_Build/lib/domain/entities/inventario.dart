class Inventario {
  final int idInventario;
  final int idProducto;
  final int idUbicacion;
  final int cantidad;

  const Inventario({
    required this.idInventario,
    required this.idProducto,
    required this.idUbicacion,
    required this.cantidad,
  });

  Inventario copyWith({
    int? idInventario,
    int? idProducto,
    int? idUbicacion,
    int? cantidad,
  }) {
    return Inventario(
      idInventario: idInventario ?? this.idInventario,
      idProducto: idProducto ?? this.idProducto,
      idUbicacion: idUbicacion ?? this.idUbicacion,
      cantidad: cantidad ?? this.cantidad,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_inventario': idInventario,
      'id_producto': idProducto,
      'id_ubicacion': idUbicacion,
      'cantidad': cantidad,
    };
  }

  factory Inventario.fromJson(Map<String, dynamic> json) {
    return Inventario(
      idInventario: json['id_inventario'] as int,
      idProducto: json['id_producto'] as int,
      idUbicacion: json['id_ubicacion'] as int,
      cantidad: json['cantidad'] as int,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Inventario && other.idInventario == idInventario;
  }

  @override
  int get hashCode => idInventario.hashCode;

  @override
  String toString() {
    return 'Inventario(idInventario: $idInventario, cantidad: $cantidad)';
  }
}

