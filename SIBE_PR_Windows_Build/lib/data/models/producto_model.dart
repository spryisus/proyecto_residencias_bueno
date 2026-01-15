import '../../domain/entities/producto.dart';

class ProductoModel extends Producto {
  const ProductoModel({
    required super.idProducto,
    required super.nombre,
    super.descripcion,
    super.unidad,
    super.tamano,
    super.rack,
    super.contenedor,
  });

  factory ProductoModel.fromJson(Map<String, dynamic> json) {
    // Función auxiliar para convertir a String? de manera segura
    String? _toStringOrNull(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is int) return value.toString();
      if (value is double) return value.toString();
      return value.toString();
    }

    return ProductoModel(
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

  factory ProductoModel.fromEntity(Producto entity) {
    return ProductoModel(
      idProducto: entity.idProducto,
      nombre: entity.nombre,
      descripcion: entity.descripcion,
      unidad: entity.unidad,
      tamano: entity.tamano,
      rack: entity.rack,
      contenedor: entity.contenedor,
    );
  }

  Producto toEntity() {
    return Producto(
      idProducto: idProducto,
      nombre: nombre,
      descripcion: descripcion,
      unidad: unidad,
      tamano: tamano,
      rack: rack,
      contenedor: contenedor,
    );
  }
}

