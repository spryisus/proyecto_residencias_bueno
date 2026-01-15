import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/inventory_session.dart';
import '../datasources/inventory_session_datasource.dart';

class InventorySessionStorage {
  static const String _storageKey = 'inventory_sessions';
  final InventorySessionDataSource _supabaseDataSource = SupabaseInventorySessionDataSource();

  Future<List<InventorySession>> getAllSessions() async {
    try {
      // Intentar obtener desde Supabase primero
      final supabaseSessions = await _supabaseDataSource.getAllSessions();
      
      // Guardar en caché local para uso offline
      await _saveToLocalCache(supabaseSessions);
      
      return supabaseSessions;
    } catch (e) {
      // Si falla Supabase, usar caché local
      print('Error al obtener sesiones de Supabase, usando caché local: $e');
      return await _getFromLocalCache();
    }
  }

  Future<void> saveSession(InventorySession session) async {
    try {
      // Guardar en Supabase primero
      await _supabaseDataSource.saveSession(session);
      
      // También guardar en caché local
      await _saveSessionToLocalCache(session);
    } catch (e) {
      // Si falla Supabase, guardar solo localmente
      print('Error al guardar sesión en Supabase, guardando solo localmente: $e');
      await _saveSessionToLocalCache(session);
      
      // Re-lanzar el error para que el usuario sepa que no se sincronizó
      // pero los datos están guardados localmente
    }
  }

  Future<void> deleteSession(String id) async {
    try {
      // Eliminar de Supabase primero
      await _supabaseDataSource.deleteSession(id);
      
      // También eliminar del caché local
      await _deleteFromLocalCache(id);
    } catch (e) {
      // Si falla Supabase, eliminar solo localmente
      print('Error al eliminar sesión de Supabase, eliminando solo localmente: $e');
      await _deleteFromLocalCache(id);
    }
  }

  Future<InventorySession?> getSessionById(String id) async {
    try {
      // Intentar obtener desde Supabase
      final session = await _supabaseDataSource.getSessionById(id);
      if (session != null) {
        // Guardar en caché local
        await _saveSessionToLocalCache(session);
        return session;
      }
    } catch (e) {
      print('Error al obtener sesión de Supabase, usando caché local: $e');
    }
    
    // Si no se encuentra en Supabase o hay error, buscar en caché local
    final sessions = await _getFromLocalCache();
    for (final session in sessions) {
      if (session.id == id) {
        return session;
      }
    }
    return null;
  }

  Future<InventorySession?> getSessionByCategory(
    int categoryId, {
    InventorySessionStatus? status,
  }) async {
    final sessions = await getAllSessions();
    for (final session in sessions) {
      if (session.categoryId == categoryId &&
          (status == null || session.status == status)) {
        return session;
      }
    }
    return null;
  }

  Future<InventorySession?> getSessionByCategoryName(
    String categoryName, {
    InventorySessionStatus? status,
  }) async {
    final sessions = await getAllSessions();
    for (final session in sessions) {
      if (session.categoryName == categoryName &&
          (status == null || session.status == status)) {
        return session;
      }
    }
    return null;
  }

  Future<List<InventorySession>> getSessionsByCategoryName(
    String categoryName, {
    InventorySessionStatus? status,
  }) async {
    final sessions = await getAllSessions();
    return sessions.where((session) {
      return session.categoryName == categoryName &&
          (status == null || session.status == status);
    }).toList();
  }

  // Métodos privados para manejar el caché local
  Future<List<InventorySession>> _getFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) {
        return [];
      }

      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      final List<InventorySession> sessions = [];
      
      for (final entry in decoded) {
        try {
          final session = InventorySession.fromJson(entry as Map<String, dynamic>);
          sessions.add(session);
        } catch (e) {
          print('Error al deserializar sesión del caché: $e');
        }
      }
      
      sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return sessions;
    } catch (e) {
      print('Error al cargar sesiones del caché: $e');
      return [];
    }
  }

  Future<void> _saveToLocalCache(List<InventorySession> sessions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(sessions.map((s) => s.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      print('Error al guardar sesiones en caché: $e');
    }
  }

  Future<void> _saveSessionToLocalCache(InventorySession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessions = await _getFromLocalCache();
      final index = sessions.indexWhere((s) => s.id == session.id);

      if (index >= 0) {
        sessions[index] = session;
      } else {
        sessions.add(session);
      }

      final encoded = jsonEncode(sessions.map((s) => s.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      print('Error al guardar sesión en caché: $e');
    }
  }

  Future<void> _deleteFromLocalCache(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessions = await _getFromLocalCache();
      sessions.removeWhere((s) => s.id == id);
      final encoded = jsonEncode(sessions.map((s) => s.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      print('Error al eliminar sesión del caché: $e');
    }
  }
}

