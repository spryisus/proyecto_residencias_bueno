import '../../domain/entities/empleado.dart';

class EmpleadoModel extends Empleado {
  const EmpleadoModel({
    required super.idEmpleado,
    required super.nombreUsuario,
    required super.activo,
    required super.creadoEn,
  });

  factory EmpleadoModel.fromJson(Map<String, dynamic> json) {
    return EmpleadoModel(
      idEmpleado: json['id_empleado'] as String,
      nombreUsuario: json['nombre_usuario'] as String,
      activo: json['activo'] as bool,
      creadoEn: DateTime.parse(json['creado_en'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id_empleado': idEmpleado,
      'nombre_usuario': nombreUsuario,
      'activo': activo,
      'creado_en': creadoEn.toIso8601String(),
    };
  }

  factory EmpleadoModel.fromEntity(Empleado entity) {
    return EmpleadoModel(
      idEmpleado: entity.idEmpleado,
      nombreUsuario: entity.nombreUsuario,
      activo: entity.activo,
      creadoEn: entity.creadoEn,
    );
  }

  Empleado toEntity() {
    return Empleado(
      idEmpleado: idEmpleado,
      nombreUsuario: nombreUsuario,
      activo: activo,
      creadoEn: creadoEn,
    );
  }
}

