import 'dart:convert';

import '../../domain/entities/inventory_session.dart';
import '../../app/config/supabase_client.dart';

abstract class InventorySessionDataSource {
  Future<List<InventorySession>> getAllSessions();
  Future<InventorySession?> getSessionById(String id);
  Future<void> saveSession(InventorySession session);
  Future<void> deleteSession(String id);
  Future<List<InventorySession>> getSessionsByOwnerId(String ownerId);
}

class SupabaseInventorySessionDataSource implements InventorySessionDataSource {
  static const String _tableName = 'inventory_sessions';

  @override
  Future<List<InventorySession>> getAllSessions() async {
    try {
      final response = await supabaseClient
          .from(_tableName)
          .select('*')
          .order('updated_at', ascending: false);
      
      return response.map((json) => _fromSupabaseJson(json)).toList();
    } catch (e) {
      // Si la tabla no existe, devolver lista vacía
      if (e.toString().contains('does not exist') || 
          e.toString().contains('relation') ||
          e.toString().contains('42P01')) {
        return [];
      }
      throw Exception('Error al obtener sesiones: $e');
    }
  }

  @override
  Future<InventorySession?> getSessionById(String id) async {
    try {
      final response = await supabaseClient
          .from(_tableName)
          .select('*')
          .eq('id', id)
          .maybeSingle();
      
      if (response == null) return null;
      return _fromSupabaseJson(response);
    } catch (e) {
      if (e.toString().contains('does not exist') || 
          e.toString().contains('relation') ||
          e.toString().contains('42P01')) {
        return null;
      }
      throw Exception('Error al obtener sesión: $e');
    }
  }

  @override
  Future<void> saveSession(InventorySession session) async {
    try {
      final json = _toSupabaseJson(session);
      
      // Intentar actualizar primero
      final existing = await supabaseClient
          .from(_tableName)
          .select('id')
          .eq('id', session.id)
          .maybeSingle();
      
      if (existing != null) {
        // Actualizar
        await supabaseClient
            .from(_tableName)
            .update(json)
            .eq('id', session.id);
      } else {
        // Insertar
        await supabaseClient
            .from(_tableName)
            .insert(json);
      }
    } catch (e) {
      // Si la tabla no existe, crear un mensaje más claro
      if (e.toString().contains('does not exist') || 
          e.toString().contains('relation') ||
          e.toString().contains('42P01')) {
        throw Exception('La tabla de sesiones de inventario no existe en la base de datos. Por favor, crea la tabla primero.');
      }
      throw Exception('Error al guardar sesión: $e');
    }
  }

  @override
  Future<void> deleteSession(String id) async {
    try {
      await supabaseClient
          .from(_tableName)
          .delete()
          .eq('id', id);
    } catch (e) {
      if (e.toString().contains('does not exist') || 
          e.toString().contains('relation') ||
          e.toString().contains('42P01')) {
        // Si la tabla no existe, no hay nada que eliminar
        return;
      }
      throw Exception('Error al eliminar sesión: $e');
    }
  }

  @override
  Future<List<InventorySession>> getSessionsByOwnerId(String ownerId) async {
    try {
      final response = await supabaseClient
          .from(_tableName)
          .select('*')
          .eq('owner_id', ownerId)
          .order('updated_at', ascending: false);
      
      return response.map((json) => _fromSupabaseJson(json)).toList();
    } catch (e) {
      if (e.toString().contains('does not exist') || 
          e.toString().contains('relation') ||
          e.toString().contains('42P01')) {
        return [];
      }
      throw Exception('Error al obtener sesiones por usuario: $e');
    }
  }

  // Convertir de JSON de Supabase a InventorySession
  InventorySession _fromSupabaseJson(Map<String, dynamic> json) {
    // Parsear quantities desde JSON string o Map
    Map<int, int> quantities = {};
    if (json['quantities'] != null) {
      if (json['quantities'] is String) {
        // Si es string, parsearlo
        final decoded = jsonDecode(json['quantities'] as String);
        if (decoded is Map) {
          quantities = decoded.map(
            (key, value) => MapEntry(int.parse(key.toString()), value as int),
          );
        }
      } else if (json['quantities'] is Map) {
        // Si ya es Map
        quantities = (json['quantities'] as Map).map(
          (key, value) => MapEntry(int.parse(key.toString()), value as int),
        );
      }
    }

    return InventorySession(
      id: json['id'] as String,
      categoryId: json['category_id'] as int,
      categoryName: json['category_name'] as String,
      quantities: quantities,
      status: InventorySessionStatus.values.firstWhere(
        (s) => s.name == json['status'] as String,
        orElse: () => InventorySessionStatus.pending,
      ),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      ownerId: json['owner_id'] as String?,
      ownerName: json['owner_name'] as String?,
      ownerEmail: json['owner_email'] as String?,
    );
  }

  // Convertir InventorySession a JSON para Supabase
  Map<String, dynamic> _toSupabaseJson(InventorySession session) {
    return {
      'id': session.id,
      'category_id': session.categoryId,
      'category_name': session.categoryName,
      'quantities': jsonEncode(session.quantities.map(
        (key, value) => MapEntry(key.toString(), value),
      )),
      'status': session.status.name,
      'updated_at': session.updatedAt.toIso8601String(),
      'owner_id': session.ownerId,
      'owner_name': session.ownerName,
      'owner_email': session.ownerEmail,
    };
  }
}

