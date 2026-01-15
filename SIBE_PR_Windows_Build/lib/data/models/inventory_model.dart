import '../../domain/entities/inventory_item.dart';

class InventoryModel extends InventoryItem {
  const InventoryModel({
    required super.id,
    required super.name,
    required super.category,
    required super.quantity,
    required super.location,
    required super.createdAt,
    super.updatedAt,
    super.qrCode,
    super.description,
  });

  // Crear desde JSON (Supabase)
  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    return InventoryModel(
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

  // Convertir a JSON para Supabase
  @override
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

  // Crear desde entidad
  factory InventoryModel.fromEntity(InventoryItem entity) {
    return InventoryModel(
      id: entity.id,
      name: entity.name,
      category: entity.category,
      quantity: entity.quantity,
      location: entity.location,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      qrCode: entity.qrCode,
      description: entity.description,
    );
  }

  // Convertir a entidad
  InventoryItem toEntity() {
    return InventoryItem(
      id: id,
      name: name,
      category: category,
      quantity: quantity,
      location: location,
      createdAt: createdAt,
      updatedAt: updatedAt,
      qrCode: qrCode,
      description: description,
    );
  }
}
