class TrackingEvent {
  final String description;
  final DateTime timestamp;
  final String? location;
  final String status;

  const TrackingEvent({
    required this.description,
    required this.timestamp,
    this.location,
    required this.status,
  });

  TrackingEvent copyWith({
    String? description,
    DateTime? timestamp,
    String? location,
    String? status,
  }) {
    return TrackingEvent(
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
      status: status ?? this.status,
    );
  }
}

class ShipmentTracking {
  final String trackingNumber;
  final String status;
  final String? origin;
  final String? destination;
  final String? currentLocation;
  final DateTime? estimatedDelivery;
  final List<TrackingEvent> events;

  const ShipmentTracking({
    required this.trackingNumber,
    required this.status,
    this.origin,
    this.destination,
    this.currentLocation,
    this.estimatedDelivery,
    required this.events,
  });

  ShipmentTracking copyWith({
    String? trackingNumber,
    String? status,
    String? origin,
    String? destination,
    String? currentLocation,
    DateTime? estimatedDelivery,
    List<TrackingEvent>? events,
  }) {
    return ShipmentTracking(
      trackingNumber: trackingNumber ?? this.trackingNumber,
      status: status ?? this.status,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      currentLocation: currentLocation ?? this.currentLocation,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      events: events ?? this.events,
    );
  }
}


