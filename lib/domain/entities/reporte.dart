enum ReporteTipo {
  conteoCiclico,
  conteoTotal,
  auditoria,
  ajuste,
}

enum ArchivoFormato {
  pdf,
  xlsx,
  csv,
  json,
}

class Reporte {
  final int idReporte;
  final String idEmpleado;
  final ReporteTipo tipoReporte;
  final DateTime fechaCreacion;
  final String? descripcion;
  final ArchivoFormato formatoArchivo;
  final String storageKey;
  final String? mimeType;
  final int? tamanoBytes;

  const Reporte({
    required this.idReporte,
    required this.idEmpleado,
    required this.tipoReporte,
    required this.fechaCreacion,
    this.descripcion,
    required this.formatoArchivo,
    required this.storageKey,
    this.mimeType,
    this.tamanoBytes,
  });

  Reporte copyWith({
    int? idReporte,
    String? idEmpleado,
    ReporteTipo? tipoReporte,
    DateTime? fechaCreacion,
    String? descripcion,
    ArchivoFormato? formatoArchivo,
    String? storageKey,
    String? mimeType,
    int? tamanoBytes,
  }) {
    return Reporte(
      idReporte: idReporte ?? this.idReporte,
      idEmpleado: idEmpleado ?? this.idEmpleado,
      tipoReporte: tipoReporte ?? this.tipoReporte,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      descripcion: descripcion ?? this.descripcion,
      formatoArchivo: formatoArchivo ?? this.formatoArchivo,
      storageKey: storageKey ?? this.storageKey,
      mimeType: mimeType ?? this.mimeType,
      tamanoBytes: tamanoBytes ?? this.tamanoBytes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_reporte': idReporte,
      'id_empleado': idEmpleado,
      'tipo_reporte': tipoReporte.name,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'descripcion': descripcion,
      'formato_archivo': formatoArchivo.name,
      'storage_key': storageKey,
      'mime_type': mimeType,
      'tamano_bytes': tamanoBytes,
    };
  }

  factory Reporte.fromJson(Map<String, dynamic> json) {
    return Reporte(
      idReporte: json['id_reporte'] as int,
      idEmpleado: json['id_empleado'] as String,
      tipoReporte: ReporteTipo.values.firstWhere(
        (e) => e.name == json['tipo_reporte'],
        orElse: () => ReporteTipo.conteoCiclico,
      ),
      fechaCreacion: DateTime.parse(json['fecha_creacion'] as String),
      descripcion: json['descripcion'] as String?,
      formatoArchivo: ArchivoFormato.values.firstWhere(
        (e) => e.name == json['formato_archivo'],
        orElse: () => ArchivoFormato.pdf,
      ),
      storageKey: json['storage_key'] as String,
      mimeType: json['mime_type'] as String?,
      tamanoBytes: json['tamano_bytes'] as int?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Reporte && other.idReporte == idReporte;
  }

  @override
  int get hashCode => idReporte.hashCode;

  @override
  String toString() {
    return 'Reporte(idReporte: $idReporte, tipoReporte: $tipoReporte)';
  }
}

