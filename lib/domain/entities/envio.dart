enum EnvioEstatus {
  pendiente,
  enTransito,
  entregado,
  cancelado,
  devuelto,
}

class Envio {
  final int idEnvio;
  final int idOrigen;
  final int idDestino;
  final DateTime fechaEnvio;
  final DateTime? fechaEntrega;
  final EnvioEstatus estatus;
  final String? numeroRastreo;
  final String? descripcion;
  final DateTime creadoEn;

  const Envio({
    required this.idEnvio,
    required this.idOrigen,
    required this.idDestino,
    required this.fechaEnvio,
    this.fechaEntrega,
    required this.estatus,
    this.numeroRastreo,
    this.descripcion,
    required this.creadoEn,
  });

  Envio copyWith({
    int? idEnvio,
    int? idOrigen,
    int? idDestino,
    DateTime? fechaEnvio,
    DateTime? fechaEntrega,
    EnvioEstatus? estatus,
    String? numeroRastreo,
    String? descripcion,
    DateTime? creadoEn,
  }) {
    return Envio(
      idEnvio: idEnvio ?? this.idEnvio,
      idOrigen: idOrigen ?? this.idOrigen,
      idDestino: idDestino ?? this.idDestino,
      fechaEnvio: fechaEnvio ?? this.fechaEnvio,
      fechaEntrega: fechaEntrega ?? this.fechaEntrega,
      estatus: estatus ?? this.estatus,
      numeroRastreo: numeroRastreo ?? this.numeroRastreo,
      descripcion: descripcion ?? this.descripcion,
      creadoEn: creadoEn ?? this.creadoEn,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_envio': idEnvio,
      'id_origen': idOrigen,
      'id_destino': idDestino,
      'fecha_envio': fechaEnvio.toIso8601String(),
      'fecha_entrega': fechaEntrega?.toIso8601String(),
      'estatus': estatus.name,
      'numero_rastreo': numeroRastreo,
      'descripcion': descripcion,
      'creado_en': creadoEn.toIso8601String(),
    };
  }

  factory Envio.fromJson(Map<String, dynamic> json) {
    return Envio(
      idEnvio: json['id_envio'] as int,
      idOrigen: json['id_origen'] as int,
      idDestino: json['id_destino'] as int,
      fechaEnvio: DateTime.parse(json['fecha_envio'] as String),
      fechaEntrega: json['fecha_entrega'] != null 
          ? DateTime.parse(json['fecha_entrega'] as String)
          : null,
      estatus: EnvioEstatus.values.firstWhere(
        (e) => e.name == json['estatus'],
        orElse: () => EnvioEstatus.pendiente,
      ),
      numeroRastreo: json['numero_rastreo'] as String?,
      descripcion: json['descripcion'] as String?,
      creadoEn: DateTime.parse(json['creado_en'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Envio && other.idEnvio == idEnvio;
  }

  @override
  int get hashCode => idEnvio.hashCode;

  @override
  String toString() {
    return 'Envio(idEnvio: $idEnvio, estatus: $estatus)';
  }
}

