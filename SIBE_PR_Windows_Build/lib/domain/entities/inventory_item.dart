class InventoryItem {
  final String id;
  final String name;
  final String category;
  final int quantity;
  final String location;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? qrCode;
  final String? description;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.location,
    required this.createdAt,
    this.updatedAt,
    this.qrCode,
    this.description,
  });

  // Método para crear copia con cambios
  InventoryItem copyWith({
    String? id,
    String? name,
    String? category,
    int? quantity,
    String? location,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? qrCode,
    String? description,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      qrCode: qrCode ?? this.qrCode,
      description: description ?? this.description,
    );
  }

  // Método para convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'quantity': quantity,
      'location': location,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'qr_code': qrCode,
      'description': description,
    };
  }

  // Método para crear desde JSON
  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      quantity: json['quantity'] as int,
      location: json['location'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      qrCode: json['qr_code'] as String?,
      description: json['description'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventoryItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'InventoryItem(id: $id, name: $name, category: $category, quantity: $quantity)';
  }
}
