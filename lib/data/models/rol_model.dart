import '../../domain/entities/rol.dart';

class RolModel extends Rol {
  const RolModel({
    required super.idRol,
    required super.nombre,
    super.descripcion,
  });

  factory RolModel.fromJson(Map<String, dynamic> json) {
    return RolModel(
      idRol: json['id_rol'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id_rol': idRol,
      'nombre': nombre,
      'descripcion': descripcion,
    };
  }

  factory RolModel.fromEntity(Rol entity) {
    return RolModel(
      idRol: entity.idRol,
      nombre: entity.nombre,
      descripcion: entity.descripcion,
    );
  }

  Rol toEntity() {
    return Rol(
      idRol: idRol,
      nombre: nombre,
      descripcion: descripcion,
    );
  }
}

