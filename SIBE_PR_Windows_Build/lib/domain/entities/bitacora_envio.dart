import 'estado_envio.dart';

class BitacoraEnvio {
  final int? idBitacora;
  final String consecutivo;
  final DateTime fecha;
  final String? tecnico;
  final String? tarjeta;
  final String? codigo;
  final String? serie;
  final String? folio;
  final String? envia;
  final String? recibe;
  final String? guia;
  final String? anexos;
  final String? observaciones;
  final String? cobo;
  final EstadoEnvio estado;
  final DateTime creadoEn;
  final DateTime actualizadoEn;
  final String? creadoPor;
  final String? actualizadoPor;

  const BitacoraEnvio({
    this.idBitacora,
    required this.consecutivo,
    required this.fecha,
    this.tecnico,
    this.tarjeta,
    this.codigo,
    this.serie,
    this.folio,
    this.envia,
    this.recibe,
    this.guia,
    this.anexos,
    this.observaciones,
    this.cobo,
    this.estado = EstadoEnvio.recibido,
    required this.creadoEn,
    required this.actualizadoEn,
    this.creadoPor,
    this.actualizadoPor,
  });

  BitacoraEnvio copyWith({
    int? idBitacora,
    String? consecutivo,
    DateTime? fecha,
    String? tecnico,
    String? tarjeta,
    String? codigo,
    String? serie,
    String? folio,
    String? envia,
    String? recibe,
    String? guia,
    String? anexos,
    String? observaciones,
    String? cobo,
    EstadoEnvio? estado,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
    String? creadoPor,
    String? actualizadoPor,
  }) {
    return BitacoraEnvio(
      idBitacora: idBitacora ?? this.idBitacora,
      consecutivo: consecutivo ?? this.consecutivo,
      fecha: fecha ?? this.fecha,
      tecnico: tecnico ?? this.tecnico,
      tarjeta: tarjeta ?? this.tarjeta,
      codigo: codigo ?? this.codigo,
      serie: serie ?? this.serie,
      folio: folio ?? this.folio,
      envia: envia ?? this.envia,
      recibe: recibe ?? this.recibe,
      guia: guia ?? this.guia,
      anexos: anexos ?? this.anexos,
      observaciones: observaciones ?? this.observaciones,
      cobo: cobo ?? this.cobo,
      estado: estado ?? this.estado,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
      creadoPor: creadoPor ?? this.creadoPor,
      actualizadoPor: actualizadoPor ?? this.actualizadoPor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_bitacora': idBitacora,
      'consecutivo': consecutivo.toString(),
      'fecha': fecha.toIso8601String().split('T')[0], // Solo la fecha sin hora
      'tecnico': tecnico,
      'tarjeta': tarjeta,
      'codigo': codigo,
      'serie': serie,
      'folio': folio,
      'envia': envia,
      'recibe': recibe,
      'guia': guia,
      'anexos': anexos,
      'observaciones': observaciones,
      'cobo': cobo,
      'estado': estado.toDbString(),
      'creado_en': creadoEn.toIso8601String(),
      'actualizado_en': actualizadoEn.toIso8601String(),
      'creado_por': creadoPor,
      'actualizado_por': actualizadoPor,
    };
  }

  /// Método para convertir a JSON excluyendo campos auto-generados
  /// Úsalo cuando vayas a INSERTAR un nuevo registro
  Map<String, dynamic> toJsonForInsert() {
    final json = <String, dynamic>{
      'consecutivo': consecutivo.toString(),
      'fecha': fecha.toIso8601String().split('T')[0], // Solo la fecha sin hora
      'tecnico': tecnico,
      'tarjeta': tarjeta,
      'codigo': codigo,
      'serie': serie,
      'folio': folio,
      'envia': envia,
      'recibe': recibe,
      'guia': guia,
      'anexos': anexos,
      'observaciones': observaciones,
      'cobo': cobo,
      'estado': estado.toDbString(),
      'creado_en': creadoEn.toIso8601String(),
      'actualizado_en': actualizadoEn.toIso8601String(),
      'creado_por': creadoPor,
      'actualizado_por': actualizadoPor,
    };
    
    // Remover campos null para que Supabase use los valores por defecto
    json.removeWhere((key, value) => value == null);
    
    return json;
  }

  factory BitacoraEnvio.fromJson(Map<String, dynamic> json) {
    return BitacoraEnvio(
      idBitacora: json['id_bitacora'] as int?,
      consecutivo: json['consecutivo'].toString(),
      fecha: _parseDate(json['fecha']),
      tecnico: json['tecnico'] as String?,
      tarjeta: json['tarjeta'] as String?,
      codigo: json['codigo'] as String?,
      serie: json['serie'] as String?,
      folio: json['folio'] as String?,
      envia: json['envia'] as String?,
      recibe: json['recibe'] as String?,
      guia: json['guia'] as String?,
      anexos: json['anexos'] as String?,
      observaciones: json['observaciones'] as String?,
      cobo: json['cobo'] as String?,
      estado: EstadoEnvio.fromDbString(json['estado'] as String?),
      creadoEn: _parseDateTime(json['creado_en']),
      actualizadoEn: _parseDateTime(json['actualizado_en']),
      creadoPor: json['creado_por'] as String?,
      actualizadoPor: json['actualizado_por'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BitacoraEnvio && other.idBitacora == idBitacora;
  }

  @override
  int get hashCode => idBitacora.hashCode;

  @override
  String toString() {
    return 'BitacoraEnvio(idBitacora: $idBitacora, consecutivo: $consecutivo, fecha: $fecha)';
  }

  // Función auxiliar para parsear fechas (solo fecha, sin hora)
  static DateTime _parseDate(dynamic fechaValue) {
    if (fechaValue == null) {
      return DateTime.now();
    }

    String fechaStr = fechaValue.toString().trim();

    // Si ya es un DateTime, retornarlo
    if (fechaValue is DateTime) {
      return fechaValue;
    }

    // Intentar formato ISO estándar (YYYY-MM-DD)
    try {
      return DateTime.parse(fechaStr);
    } catch (_) {}

    // Intentar formato DD/MM/YY o DD/MM/YYYY
    if (fechaStr.contains('/')) {
      final partes = fechaStr.split('/');
      
      // Caso 1: Formato estándar DD/MM/YY o DD/MM/YYYY (3 partes)
      if (partes.length == 3) {
        try {
          final dia = int.parse(partes[0]);
          final mes = int.parse(partes[1]);
          var anio = int.parse(partes[2]);

          // Si el año es de 2 dígitos, convertirlo a 4 dígitos
          if (anio < 100) {
            // Asumir años 00-30 como 2000-2030, y 31-99 como 1931-1999
            anio = anio <= 30 ? 2000 + anio : 1900 + anio;
          }

          if (mes >= 1 && mes <= 12 && dia >= 1 && dia <= 31) {
            return DateTime(anio, mes, dia);
          }
        } catch (_) {}
      }
      
      // Caso 2: Formato DD/MMYY (2 partes, donde la segunda contiene mes y año concatenados)
      // Ejemplo: "19/0320" = 19/03/20, "14/1124" = 14/11/24
      if (partes.length == 2) {
        try {
          final dia = int.parse(partes[0]);
          final mesAnioStr = partes[1];
          
          // Si la segunda parte tiene 4 dígitos, asumir MMYY
          // Si tiene 3 dígitos, asumir MYY o MMY
          if (mesAnioStr.length == 4) {
            // Formato MMYY: "0320" = mes 03, año 20
            final mes = int.parse(mesAnioStr.substring(0, 2));
            final anio = int.parse(mesAnioStr.substring(2, 4));
            final anioCompleto = anio <= 30 ? 2000 + anio : 1900 + anio;
            
            if (mes >= 1 && mes <= 12 && dia >= 1 && dia <= 31) {
              return DateTime(anioCompleto, mes, dia);
            }
          } else if (mesAnioStr.length == 3) {
            // Intentar MYY primero (1 dígito mes, 2 dígitos año)
            try {
              final mes = int.parse(mesAnioStr.substring(0, 1));
              final anio = int.parse(mesAnioStr.substring(1, 3));
              final anioCompleto = anio <= 30 ? 2000 + anio : 1900 + anio;
              
              if (mes >= 1 && mes <= 12 && dia >= 1 && dia <= 31) {
                return DateTime(anioCompleto, mes, dia);
              }
            } catch (_) {}
            
            // Intentar MMY (2 dígitos mes, 1 dígito año - menos común)
            try {
              final mes = int.parse(mesAnioStr.substring(0, 2));
              final anio = int.parse(mesAnioStr.substring(2, 3));
              final anioCompleto = 2000 + anio; // Asumir 2000-2009
              
              if (mes >= 1 && mes <= 12 && dia >= 1 && dia <= 31) {
                return DateTime(anioCompleto, mes, dia);
              }
            } catch (_) {}
          }
        } catch (_) {}
      }
    }

    // Intentar formato numérico de 6 dígitos (YYMMDD)
    if (fechaStr.length == 6 && fechaStr.contains(RegExp(r'^\d{6}$'))) {
      try {
        final anio = 2000 + int.parse(fechaStr.substring(0, 2));
        final mes = int.parse(fechaStr.substring(2, 4));
        final dia = int.parse(fechaStr.substring(4, 6));
        return DateTime(anio, mes, dia);
      } catch (_) {}
    }

    // Intentar formato numérico de 5 dígitos (YYMMD)
    // Ejemplo: 18119 = 18/11/9 (18 de noviembre de 2009) o 18119 = 18/1/19 (18 de enero de 2019)
    if (fechaStr.length == 5 && fechaStr.contains(RegExp(r'^\d{5}$'))) {
      try {
        // Intentar YYMMD (año 2 dígitos, mes 2 dígitos, día 1 dígito)
        // Ejemplo: 18119 = año 18, mes 11, día 9
        final anio = 2000 + int.parse(fechaStr.substring(0, 2));
        final mes = int.parse(fechaStr.substring(2, 4));
        final dia = int.parse(fechaStr.substring(4, 5));
        if (mes >= 1 && mes <= 12 && dia >= 1 && dia <= 31) {
          return DateTime(anio, mes, dia);
        }
      } catch (_) {}
      
      try {
        // Intentar YYMDD (año 2 dígitos, mes 1 dígito, día 2 dígitos)
        // Ejemplo: 18119 = año 18, mes 1, día 19
        final anio = 2000 + int.parse(fechaStr.substring(0, 2));
        final mes = int.parse(fechaStr.substring(2, 3));
        final dia = int.parse(fechaStr.substring(3, 5));
        if (mes >= 1 && mes <= 12 && dia >= 1 && dia <= 31) {
          return DateTime(anio, mes, dia);
        }
      } catch (_) {}
      
      try {
        // Intentar YMMDD (año 1 dígito, mes 2 dígitos, día 2 dígitos)
        final anio = 2000 + int.parse(fechaStr.substring(0, 1));
        final mes = int.parse(fechaStr.substring(1, 3));
        final dia = int.parse(fechaStr.substring(3, 5));
        if (mes >= 1 && mes <= 12 && dia >= 1 && dia <= 31) {
          return DateTime(anio, mes, dia);
        }
      } catch (_) {}
    }

    // Intentar formato numérico de 4 dígitos (MMDD o YYMM)
    if (fechaStr.length == 4 && fechaStr.contains(RegExp(r'^\d{4}$'))) {
      try {
        // Asumir MMDD con año actual
        final mes = int.parse(fechaStr.substring(0, 2));
        final dia = int.parse(fechaStr.substring(2, 4));
        if (mes >= 1 && mes <= 12 && dia >= 1 && dia <= 31) {
          final ahora = DateTime.now();
          return DateTime(ahora.year, mes, dia);
        }
      } catch (_) {}
    }

    // Si nada funciona, intentar usar la fecha actual como fallback
    // en lugar de lanzar excepción, para evitar que la app se rompa
    print('⚠️ No se pudo parsear la fecha: $fechaStr. Usando fecha actual como fallback.');
    return DateTime.now();
  }

  // Función auxiliar para parsear fechas con hora (TIMESTAMPTZ)
  static DateTime _parseDateTime(dynamic fechaValue) {
    if (fechaValue == null) {
      return DateTime.now();
    }

    // Si ya es un DateTime, retornarlo
    if (fechaValue is DateTime) {
      return fechaValue;
    }

    String fechaStr = fechaValue.toString().trim();

    // Intentar formato ISO estándar (YYYY-MM-DD o YYYY-MM-DDTHH:MM:SS)
    try {
      return DateTime.parse(fechaStr);
    } catch (_) {
      // Si falla, intentar solo la parte de fecha
      try {
        final fechaPart = fechaStr.split('T')[0].split(' ')[0];
        return _parseDate(fechaPart);
      } catch (_) {
        return DateTime.now();
      }
    }
  }
}

