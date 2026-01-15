import '../../domain/entities/inventory_item.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_datasource.dart';
import '../models/inventory_model.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryDataSource dataSource;
  
  InventoryRepositoryImpl(this.dataSource);

  @override
  Future<List<InventoryItem>> getAllItems() async {
    final models = await dataSource.getAllItems();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<InventoryItem>> getItemsByCategory(String category) async {
    final models = await dataSource.getItemsByCategory(category);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<InventoryItem?> getItemById(String id) async {
    final model = await dataSource.getItemById(id);
    return model?.toEntity();
  }

  @override
  Future<InventoryItem?> getItemByQrCode(String qrCode) async {
    final model = await dataSource.getItemByQrCode(qrCode);
    return model?.toEntity();
  }

  @override
  Future<InventoryItem> createItem(InventoryItem item) async {
    final model = InventoryModel.fromEntity(item);
    final createdModel = await dataSource.createItem(model);
    return createdModel.toEntity();
  }

  @override
  Future<InventoryItem> updateItem(InventoryItem item) async {
    final model = InventoryModel.fromEntity(item);
    final updatedModel = await dataSource.updateItem(model);
    return updatedModel.toEntity();
  }

  @override
  Future<void> deleteItem(String id) async {
    await dataSource.deleteItem(id);
  }

  @override
  Future<List<InventoryItem>> searchItems(String query) async {
    final models = await dataSource.searchItems(query);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Map<String, int>> getCategoryStats() async {
    final items = await getAllItems();
    final stats = <String, int>{};
    
    for (final item in items) {
      stats[item.category] = (stats[item.category] ?? 0) + item.quantity;
    }
    
    return stats;
  }

  @override
  Future<String> exportToExcel() async {
    // Implementar exportación a Excel
    // Aquí usarías una librería como 'excel' para generar el archivo
    throw UnimplementedError('Exportación a Excel no implementada aún');
  }

  @override
  Future<String> exportToPdf() async {
    // Implementar exportación a PDF
    // Aquí usarías una librería como 'pdf' para generar el archivo
    throw UnimplementedError('Exportación a PDF no implementada aún');
  }

  @override
  Future<Map<String, dynamic>> exportToJson() async {
    final items = await getAllItems();
    return {
      'inventory': items.map((item) => item.toJson()).toList(),
      'exported_at': DateTime.now().toIso8601String(),
      'total_items': items.length,
    };
  }
}
