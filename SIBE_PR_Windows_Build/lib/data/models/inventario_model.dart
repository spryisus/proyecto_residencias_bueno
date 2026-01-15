import '../../domain/entities/inventario.dart';

class InventarioModel extends Inventario {
  const InventarioModel({
    required super.idInventario,
    required super.idProducto,
    required super.idUbicacion,
    required super.cantidad,
  });

  factory InventarioModel.fromJson(Map<String, dynamic> json) {
    return InventarioModel(
      idInventario: json['id_inventario'] as int,
      idProducto: json['id_producto'] as int,
      idUbicacion: json['id_ubicacion'] as int,
      cantidad: json['cantidad'] as int,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id_inventario': idInventario,
      'id_producto': idProducto,
      'id_ubicacion': idUbicacion,
      'cantidad': cantidad,
    };
  }

  factory InventarioModel.fromEntity(Inventario entity) {
    return InventarioModel(
      idInventario: entity.idInventario,
      idProducto: entity.idProducto,
      idUbicacion: entity.idUbicacion,
      cantidad: entity.cantidad,
    );
  }

  Inventario toEntity() {
    return Inventario(
      idInventario: idInventario,
      idProducto: idProducto,
      idUbicacion: idUbicacion,
      cantidad: cantidad,
    );
  }
}

