import '../../domain/entities/categoria.dart';

class CategoriaModel extends Categoria {
  const CategoriaModel({
    required super.idCategoria,
    required super.nombre,
    super.descripcion,
  });

  factory CategoriaModel.fromJson(Map<String, dynamic> json) {
    return CategoriaModel(
      idCategoria: json['id_categoria'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id_categoria': idCategoria,
      'nombre': nombre,
      'descripcion': descripcion,
    };
  }

  factory CategoriaModel.fromEntity(Categoria entity) {
    return CategoriaModel(
      idCategoria: entity.idCategoria,
      nombre: entity.nombre,
      descripcion: entity.descripcion,
    );
  }

  Categoria toEntity() {
    return Categoria(
      idCategoria: idCategoria,
      nombre: nombre,
      descripcion: descripcion,
    );
  }
}

