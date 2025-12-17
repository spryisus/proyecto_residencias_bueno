import '../../domain/entities/ubicacion.dart';

class UbicacionModel extends Ubicacion {
  const UbicacionModel({
    required super.idUbicacion,
    required super.nombre,
    super.descripcion,
    super.posicion,
  });

  factory UbicacionModel.fromJson(Map<String, dynamic> json) {
    // Función auxiliar para convertir a String? de manera segura
    String? _toStringOrNull(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is int) return value.toString();
      if (value is double) return value.toString();
      return value.toString();
    }

    return UbicacionModel(
      idUbicacion: json['id_ubicacion'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      posicion: _toStringOrNull(json['posicion']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id_ubicacion': idUbicacion,
      'nombre': nombre,
      'descripcion': descripcion,
      'posicion': posicion,
    };
  }

  factory UbicacionModel.fromEntity(Ubicacion entity) {
    return UbicacionModel(
      idUbicacion: entity.idUbicacion,
      nombre: entity.nombre,
      descripcion: entity.descripcion,
      posicion: entity.posicion,
    );
  }

  Ubicacion toEntity() {
    return Ubicacion(
      idUbicacion: idUbicacion,
      nombre: nombre,
      descripcion: descripcion,
      posicion: posicion,
    );
  }
}

