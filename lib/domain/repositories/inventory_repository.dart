import '../entities/inventory_item.dart';

abstract class InventoryRepository {
  // Obtener todos los items
  Future<List<InventoryItem>> getAllItems();
  
  // Obtener items por categoría
  Future<List<InventoryItem>> getItemsByCategory(String category);
  
  // Obtener item por ID
  Future<InventoryItem?> getItemById(String id);
  
  // Obtener item por código QR
  Future<InventoryItem?> getItemByQrCode(String qrCode);
  
  // Crear nuevo item
  Future<InventoryItem> createItem(InventoryItem item);
  
  // Actualizar item existente
  Future<InventoryItem> updateItem(InventoryItem item);
  
  // Eliminar item
  Future<void> deleteItem(String id);
  
  // Buscar items por nombre
  Future<List<InventoryItem>> searchItems(String query);
  
  // Obtener estadísticas por categoría
  Future<Map<String, int>> getCategoryStats();
  
  // Exportar datos a diferentes formatos
  Future<String> exportToExcel();
  Future<String> exportToPdf();
  Future<Map<String, dynamic>> exportToJson();
}
