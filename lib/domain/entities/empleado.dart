class Empleado {
  final String idEmpleado;
  final String nombreUsuario;
  final bool activo;
  final DateTime creadoEn;

  const Empleado({
    required this.idEmpleado,
    required this.nombreUsuario,
    required this.activo,
    required this.creadoEn,
  });

  Empleado copyWith({
    String? idEmpleado,
    String? nombreUsuario,
    bool? activo,
    DateTime? creadoEn,
  }) {
    return Empleado(
      idEmpleado: idEmpleado ?? this.idEmpleado,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      activo: activo ?? this.activo,
      creadoEn: creadoEn ?? this.creadoEn,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_empleado': idEmpleado,
      'nombre_usuario': nombreUsuario,
      'activo': activo,
      'creado_en': creadoEn.toIso8601String(),
    };
  }

  factory Empleado.fromJson(Map<String, dynamic> json) {
    // Manejar el campo activo de forma robusta
    bool activo = false;
    final activoValue = json['activo'];
    if (activoValue != null) {
      if (activoValue is bool) {
        activo = activoValue;
      } else if (activoValue is String) {
        // Si viene como string, convertir a bool
        activo = activoValue.toLowerCase() == 'true' || activoValue == '1';
      } else if (activoValue is int) {
        // Si viene como int (0 o 1), convertir a bool
        activo = activoValue == 1;
      }
    }
    
    return Empleado(
      idEmpleado: json['id_empleado'] as String,
      nombreUsuario: json['nombre_usuario'] as String,
      activo: activo,
      creadoEn: DateTime.parse(json['creado_en'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Empleado && other.idEmpleado == idEmpleado;
  }

  @override
  int get hashCode => idEmpleado.hashCode;

  @override
  String toString() {
    return 'Empleado(idEmpleado: $idEmpleado, nombreUsuario: $nombreUsuario)';
  }
}

