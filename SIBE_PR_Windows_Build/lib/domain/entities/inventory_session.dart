enum InventorySessionStatus { pending, completed }

class InventorySession {
  final String id;
  final int categoryId;
  final String categoryName;
  final Map<int, int> quantities;
  final InventorySessionStatus status;
  final DateTime updatedAt;
  final String? ownerId;
  final String? ownerName;
  final String? ownerEmail;

  const InventorySession({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.quantities,
    required this.status,
    required this.updatedAt,
    this.ownerId,
    this.ownerName,
    this.ownerEmail,
  });

  InventorySession copyWith({
    String? id,
    int? categoryId,
    String? categoryName,
    Map<int, int>? quantities,
    InventorySessionStatus? status,
    DateTime? updatedAt,
    String? ownerId,
    String? ownerName,
    String? ownerEmail,
  }) {
    return InventorySession(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      quantities: quantities ?? this.quantities,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'quantities': quantities.map((key, value) => MapEntry(key.toString(), value)),
      'status': status.name,
      'updatedAt': updatedAt.toIso8601String(),
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerEmail': ownerEmail,
    };
  }

  factory InventorySession.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> rawQuantities = json['quantities'] as Map<String, dynamic>? ?? {};
    final quantities = rawQuantities.map(
      (key, value) => MapEntry(int.parse(key), value as int),
    );

    return InventorySession(
      id: json['id'] as String,
      categoryId: json['categoryId'] as int,
      categoryName: json['categoryName'] as String,
      quantities: quantities,
      status: InventorySessionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => InventorySessionStatus.pending,
      ),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      ownerId: json['ownerId'] as String?,
      ownerName: json['ownerName'] as String?,
      ownerEmail: json.containsKey('ownerEmail') ? json['ownerEmail'] as String? : null,
    );
  }
}

