import '../entities/inventory_item.dart';
import '../repositories/inventory_repository.dart';

// Caso de uso: Obtener inventario por categoría
class GetInventoryByCategory {
  final InventoryRepository repository;
  
  GetInventoryByCategory(this.repository);
  
  Future<List<InventoryItem>> call(String category) async {
    if (category.isEmpty) {
      throw ArgumentError('La categoría no puede estar vacía');
    }
    
    return await repository.getItemsByCategory(category);
  }
}

// Caso de uso: Crear nuevo item de inventario
class CreateInventoryItem {
  final InventoryRepository repository;
  
  CreateInventoryItem(this.repository);
  
  Future<InventoryItem> call(InventoryItem item) async {
    // Validaciones de negocio
    if (item.name.isEmpty) {
      throw ArgumentError('El nombre del item es requerido');
    }
    
    if (item.quantity < 0) {
      throw ArgumentError('La cantidad no puede ser negativa');
    }
    
    if (item.category.isEmpty) {
      throw ArgumentError('La categoría es requerida');
    }
    
    // Generar ID único si no existe
    final itemWithId = item.id.isEmpty 
        ? item.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString())
        : item;
    
    return await repository.createItem(itemWithId);
  }
}

// Caso de uso: Generar reporte de inventario
class GenerateInventoryReport {
  final InventoryRepository repository;
  
  GenerateInventoryReport(this.repository);
  
  Future<Map<String, dynamic>> call({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    List<InventoryItem> items;
    
    if (category != null) {
      items = await repository.getItemsByCategory(category);
    } else {
      items = await repository.getAllItems();
    }
    
    // Filtrar por fechas si se proporcionan
    if (startDate != null && endDate != null) {
      items = items.where((item) {
        return item.createdAt.isAfter(startDate) && 
               item.createdAt.isBefore(endDate);
      }).toList();
    }
    
    // Calcular estadísticas
    final totalItems = items.length;
    final totalQuantity = items.fold(0, (sum, item) => sum + item.quantity);
    final categoryStats = <String, int>{};
    
    for (final item in items) {
      categoryStats[item.category] = 
          (categoryStats[item.category] ?? 0) + item.quantity;
    }
    
    return {
      'total_items': totalItems,
      'total_quantity': totalQuantity,
      'category_stats': categoryStats,
      'items': items.map((item) => item.toJson()).toList(),
      'generated_at': DateTime.now().toIso8601String(),
    };
  }
}

// Caso de uso: Exportar inventario
class ExportInventory {
  final InventoryRepository repository;
  
  ExportInventory(this.repository);
  
  Future<String> call(String format, {String? category}) async {
    switch (format.toLowerCase()) {
      case 'excel':
        return await repository.exportToExcel();
      case 'pdf':
        return await repository.exportToPdf();
      case 'json':
        final data = await repository.exportToJson();
        return data.toString();
      default:
        throw ArgumentError('Formato no soportado: $format');
    }
  }
}
