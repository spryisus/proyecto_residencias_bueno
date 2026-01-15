import 'package:flutter/material.dart';

/// Entidad que representa una rutina
class Rutina {
  final String id;
  final String nombre;
  final DateTime? fechaEstimada;
  final Color color;

  Rutina({
    required this.id,
    required this.nombre,
    this.fechaEstimada,
    required this.color,
  });

  /// Crea una copia de la rutina con campos modificados
  Rutina copyWith({
    String? id,
    String? nombre,
    DateTime? fechaEstimada,
    Color? color,
  }) {
    return Rutina(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      fechaEstimada: fechaEstimada ?? this.fechaEstimada,
      color: color ?? this.color,
    );
  }

  /// Convierte la rutina a JSON para almacenamiento
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'fechaEstimada': fechaEstimada?.toIso8601String(),
      'colorValue': color.value,
    };
  }

  /// Crea una rutina desde JSON
  factory Rutina.fromJson(Map<String, dynamic> json) {
    return Rutina(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      fechaEstimada: json['fechaEstimada'] != null
          ? DateTime.parse(json['fechaEstimada'] as String)
          : null,
      color: Color(json['colorValue'] as int),
    );
  }

  /// Calcula los días restantes hasta la fecha estimada
  int? get diasRestantes {
    if (fechaEstimada == null) return null;
    final ahora = DateTime.now();
    final diferencia = fechaEstimada!.difference(ahora);
    return diferencia.inDays;
  }

  /// Obtiene el estado de la rutina según los días restantes
  EstadoRutina get estado {
    if (fechaEstimada == null) return EstadoRutina.sinFecha;
    
    final dias = diasRestantes!;
    if (dias < 0) return EstadoRutina.vencida;
    if (dias == 0 || dias == 1) return EstadoRutina.urgente;
    if (dias < 3) return EstadoRutina.proxima;
    if (dias >= 5) return EstadoRutina.normal;
    return EstadoRutina.proxima;
  }

  /// Obtiene el color según el estado
  Color get colorEstado {
    switch (estado) {
      case EstadoRutina.sinFecha:
        return color;
      case EstadoRutina.normal:
        return Colors.green.shade300; // Verde claro para 5+ días
      case EstadoRutina.proxima:
        return Colors.amber.shade400; // Ámbar para <3 días
      case EstadoRutina.urgente:
        return Colors.red.shade400; // Rojo para 1 día o actual
      case EstadoRutina.vencida:
        return Colors.red.shade700;
    }
  }
}

/// Enum para los estados de una rutina
enum EstadoRutina {
  sinFecha,
  normal,    // 5+ días
  proxima,   // <3 días
  urgente,   // 1 día o actual
  vencida,
}















