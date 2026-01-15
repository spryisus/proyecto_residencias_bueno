import '../../domain/entities/tracking_event.dart';

class TrackingEventModel extends TrackingEvent {
  const TrackingEventModel({
    required super.description,
    required super.timestamp,
    super.location,
    required super.status,
  });

  factory TrackingEventModel.fromJson(Map<String, dynamic> json) {
    // Limpiar la descripción: remover espacios en blanco, saltos de línea y tabs
    String? rawDescription = json['description'] as String? ?? json['event'] as String?;
    String cleanDescription = _cleanDescription(rawDescription ?? 'Sin descripción');
    
    // Extraer ubicación si viene en la descripción
    String? location = json['location'] as String?;
    if (location == null || location.isEmpty) {
      location = _extractLocationFromDescription(cleanDescription);
    }
    
    // Limpiar y determinar el estado
    String cleanStatus = json['status'] as String? ?? 
                        _extractStatusFromDescription(cleanDescription) ?? 
                        'Desconocido';
    
    return TrackingEventModel(
      description: cleanDescription,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : json['date'] != null && json['time'] != null
              ? _parseDateTime(json['date'] as String, json['time'] as String)
              : DateTime.now(),
      location: location,
      status: cleanStatus,
    );
  }

  /// Limpia una descripción removiendo espacios en blanco, saltos de línea y tabs
  static String _cleanDescription(String description) {
    if (description.isEmpty) return 'Sin descripción';
    
    // Remover tabs, saltos de línea múltiples, y espacios en blanco excesivos
    return description
        .replaceAll(RegExp(r'\t+'), ' ')  // Reemplazar tabs con espacios
        .replaceAll(RegExp(r'\n+'), ' ')  // Reemplazar saltos de línea con espacios
        .replaceAll(RegExp(r'\s+'), ' ')  // Reemplazar múltiples espacios con uno solo
        .trim();  // Remover espacios al inicio y final
  }

  /// Intenta extraer la ubicación de la descripción
  /// Busca patrones como "CIUDAD - ESTADO - PAÍS" o "CIUDAD, ESTADO"
  static String? _extractLocationFromDescription(String description) {
    // Buscar patrón "CIUDAD - ESTADO - PAÍS"
    final match = RegExp(r'([A-ZÁÉÍÓÚÑ][A-ZÁÉÍÓÚÑ\s-]+)\s*-\s*([A-ZÁÉÍÓÚÑ][A-ZÁÉÍÓÚÑ\s-]+)\s*-\s*([A-ZÁÉÍÓÚÑ][A-ZÁÉÍÓÚÑ\s]+)')
        .firstMatch(description);
    if (match != null) {
      return '${match.group(1)!.trim()} - ${match.group(2)!.trim()} - ${match.group(3)!.trim()}';
    }
    
    // Buscar patrón "CIUDAD, ESTADO"
    final match2 = RegExp(r'([A-ZÁÉÍÓÚÑ][A-ZÁÉÍÓÚÑ\s]+),\s*([A-ZÁÉÍÓÚÑ][A-ZÁÉÍÓÚÑ\s]+)')
        .firstMatch(description);
    if (match2 != null) {
      return '${match2.group(1)!.trim()}, ${match2.group(2)!.trim()}';
    }
    
    return null;
  }

  /// Intenta extraer el estado/estatus de la descripción
  static String? _extractStatusFromDescription(String description) {
    final descLower = description.toLowerCase();
    
    if (descLower.contains('entregado') || descLower.contains('delivered')) {
      return 'Entregado';
    } else if (descLower.contains('en tránsito') || descLower.contains('in transit')) {
      return 'En tránsito';
    } else if (descLower.contains('recolectado') || 
               descLower.contains('picked up') ||
               descLower.contains('retirado')) {
      return 'Recolectado';
    } else if (descLower.contains('programado') || descLower.contains('scheduled')) {
      return 'Programado';
    } else if (descLower.contains('procesado') || descLower.contains('processed')) {
      return 'En proceso';
    }
    
    return null;
  }

  static DateTime _parseDateTime(String date, String time) {
    try {
      // Formato: "2024-01-10" y "08:30"
      final dateParts = date.split('-');
      final timeParts = time.split(':');
      return DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    } catch (e) {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'location': location,
      'status': status,
    };
  }
}

class ShipmentTrackingModel extends ShipmentTracking {
  const ShipmentTrackingModel({
    required super.trackingNumber,
    required super.status,
    super.origin,
    super.destination,
    super.currentLocation,
    super.estimatedDelivery,
    required super.events,
  });

  factory ShipmentTrackingModel.fromJson(Map<String, dynamic> json) {
    final events = (json['events'] as List<dynamic>?)
            ?.map((e) => TrackingEventModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return ShipmentTrackingModel(
      trackingNumber: json['trackingNumber'] as String? ?? json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'Desconocido',
      origin: json['origin'] as String?,
      destination: json['destination'] as String?,
      currentLocation: json['currentLocation'] as String?,
      estimatedDelivery: json['estimatedDelivery'] != null
          ? DateTime.parse(json['estimatedDelivery'] as String)
          : null,
      events: events,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trackingNumber': trackingNumber,
      'status': status,
      'origin': origin,
      'destination': destination,
      'currentLocation': currentLocation,
      'estimatedDelivery': estimatedDelivery?.toIso8601String(),
      'events': events.map((e) => (e as TrackingEventModel).toJson()).toList(),
    };
  }
}


