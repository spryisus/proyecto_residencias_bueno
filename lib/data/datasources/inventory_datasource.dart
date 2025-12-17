import '../models/inventory_model.dart';
import '../../app/config/supabase_client.dart';

abstract class InventoryDataSource {
  Future<List<InventoryModel>> getAllItems();
  Future<List<InventoryModel>> getItemsByCategory(String category);
  Future<InventoryModel?> getItemById(String id);
  Future<InventoryModel?> getItemByQrCode(String qrCode);
  Future<InventoryModel> createItem(InventoryModel item);
  Future<InventoryModel> updateItem(InventoryModel item);
  Future<void> deleteItem(String id);
  Future<List<InventoryModel>> searchItems(String query);
}

class SupabaseInventoryDataSource implements InventoryDataSource {
  @override
  Future<List<InventoryModel>> getAllItems() async {
    try {
      final response = await supabaseClient
          .from('inventory')
          .select('*')
          .order('created_at', ascending: false);
      
      return response.map((json) => InventoryModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener items: $e');
    }
  }

  @override
  Future<List<InventoryModel>> getItemsByCategory(String category) async {
    try {
      final response = await supabaseClient
          .from('inventory')
          .select('*')
          .eq('category', category)
          .order('created_at', ascending: false);
      
      return response.map((json) => InventoryModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener items por categoría: $e');
    }
  }

  @override
  Future<InventoryModel?> getItemById(String id) async {
    try {
      final response = await supabaseClient
          .from('inventory')
          .select('*')
          .eq('id', id)
          .single();
      
      return InventoryModel.fromJson(response);
    } catch (e) {
      return null; // Item no encontrado
    }
  }

  @override
  Future<InventoryModel?> getItemByQrCode(String qrCode) async {
    try {
      final response = await supabaseClient
          .from('inventory')
          .select('*')
          .eq('qr_code', qrCode)
          .single();
      
      return InventoryModel.fromJson(response);
    } catch (e) {
      return null; // Item no encontrado
    }
  }

  @override
  Future<InventoryModel> createItem(InventoryModel item) async {
    try {
      final response = await supabaseClient
          .from('inventory')
          .insert(item.toJson())
          .select()
          .single();
      
      return InventoryModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear item: $e');
    }
  }

  @override
  Future<InventoryModel> updateItem(InventoryModel item) async {
    try {
      final updatedItem = item.copyWith(updatedAt: DateTime.now());
      
      final response = await supabaseClient
          .from('inventory')
          .update(updatedItem.toJson())
          .eq('id', item.id)
          .select()
          .single();
      
      return InventoryModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar item: $e');
    }
  }

  @override
  Future<void> deleteItem(String id) async {
    try {
      await supabaseClient
          .from('inventory')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar item: $e');
    }
  }

  @override
  Future<List<InventoryModel>> searchItems(String query) async {
    try {
      final response = await supabaseClient
          .from('inventory')
          .select('*')
          .or('name.ilike.%$query%,description.ilike.%$query%')
          .order('created_at', ascending: false);
      
      return response.map((json) => InventoryModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al buscar items: $e');
    }
  }
}
