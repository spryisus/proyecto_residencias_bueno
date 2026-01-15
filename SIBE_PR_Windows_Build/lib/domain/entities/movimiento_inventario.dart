enum MovimientoTipo {
  entrada,
  salida,
  ajuste,
  envio,
  recepcion,
}

class MovimientoInventario {
  final int idMovimiento;
  final int idProducto;
  final int idUbicacion;
  final MovimientoTipo tipo;
  final int cantidadDelta;
  final String? motivo;
  final int? idEnvioDetalle;
  final int? idReporte;
  final String? creadoPor;
  final DateTime creadoEn;

  const MovimientoInventario({
    required this.idMovimiento,
    required this.idProducto,
    required this.idUbicacion,
    required this.tipo,
    required this.cantidadDelta,
    this.motivo,
    this.idEnvioDetalle,
    this.idReporte,
    this.creadoPor,
    required this.creadoEn,
  });

  MovimientoInventario copyWith({
    int? idMovimiento,
    int? idProducto,
    int? idUbicacion,
    MovimientoTipo? tipo,
    int? cantidadDelta,
    String? motivo,
    int? idEnvioDetalle,
    int? idReporte,
    String? creadoPor,
    DateTime? creadoEn,
  }) {
    return MovimientoInventario(
      idMovimiento: idMovimiento ?? this.idMovimiento,
      idProducto: idProducto ?? this.idProducto,
      idUbicacion: idUbicacion ?? this.idUbicacion,
      tipo: tipo ?? this.tipo,
      cantidadDelta: cantidadDelta ?? this.cantidadDelta,
      motivo: motivo ?? this.motivo,
      idEnvioDetalle: idEnvioDetalle ?? this.idEnvioDetalle,
      idReporte: idReporte ?? this.idReporte,
      creadoPor: creadoPor ?? this.creadoPor,
      creadoEn: creadoEn ?? this.creadoEn,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_movimiento': idMovimiento,
      'id_producto': idProducto,
      'id_ubicacion': idUbicacion,
      'tipo': tipo.name,
      'cantidad_delta': cantidadDelta,
      'motivo': motivo,
      'id_envio_detalle': idEnvioDetalle,
      'id_reporte': idReporte,
      'creado_por': creadoPor,
      'creado_en': creadoEn.toIso8601String(),
    };
  }

  /// Método para generar JSON sin id_movimiento para inserciones
  /// (id_movimiento es una columna de identidad GENERATED ALWAYS)
  Map<String, dynamic> toJsonForInsert() {
    final json = <String, dynamic>{
      'id_producto': idProducto,
      'id_ubicacion': idUbicacion,
      'tipo': tipo.name,
      'cantidad_delta': cantidadDelta,
      'creado_en': creadoEn.toIso8601String(),
    };
    
    // Solo incluir campos opcionales si tienen valor
    if (motivo != null && motivo!.isNotEmpty) {
      json['motivo'] = motivo;
    }
    if (idEnvioDetalle != null) {
      json['id_envio_detalle'] = idEnvioDetalle;
    }
    if (idReporte != null) {
      json['id_reporte'] = idReporte;
    }
    if (creadoPor != null && creadoPor!.isNotEmpty) {
      json['creado_por'] = creadoPor;
    }
    
    return json;
  }

  factory MovimientoInventario.fromJson(Map<String, dynamic> json) {
    return MovimientoInventario(
      idMovimiento: json['id_movimiento'] as int,
      idProducto: json['id_producto'] as int,
      idUbicacion: json['id_ubicacion'] as int,
      tipo: MovimientoTipo.values.firstWhere(
        (e) => e.name == json['tipo'],
        orElse: () => MovimientoTipo.entrada,
      ),
      cantidadDelta: json['cantidad_delta'] as int,
      motivo: json['motivo'] as String?,
      idEnvioDetalle: json['id_envio_detalle'] as int?,
      idReporte: json['id_reporte'] as int?,
      creadoPor: json['creado_por'] as String?,
      creadoEn: DateTime.parse(json['creado_en'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MovimientoInventario && other.idMovimiento == idMovimiento;
  }

  @override
  int get hashCode => idMovimiento.hashCode;

  @override
  String toString() {
    return 'MovimientoInventario(idMovimiento: $idMovimiento, tipo: $tipo, cantidadDelta: $cantidadDelta)';
  }
}

