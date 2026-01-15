import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/entities/rutina.dart';
import '../datasources/rutina_datasource.dart';

/// Almacenamiento para las rutinas (Supabase + caché local)
class RutinaStorage {
  static const String _key = 'rutinas';
  final RutinaDataSource _supabaseDataSource = SupabaseRutinaDataSource();

  /// Obtiene todas las rutinas guardadas
  /// Siempre prioriza Supabase sobre el caché local para mantener sincronización
  Future<List<Rutina>> getAllRutinas() async {
    try {
      // SIEMPRE intentar obtener desde Supabase primero (prioridad absoluta)
      final supabaseRutinas = await _supabaseDataSource.getAllRutinas();
      
      // Si hay rutinas en Supabase, actualizar caché local y retornar
      if (supabaseRutinas.isNotEmpty) {
        debugPrint('✅ Rutinas obtenidas desde Supabase: ${supabaseRutinas.length}');
        // Limpiar caché local y guardar las de Supabase (sincronización)
        await _saveToLocalCache(supabaseRutinas);
        // Filtrar rutinas vencidas (fecha pasada) y eliminar su fecha
        return await _processExpiredRutinas(supabaseRutinas);
      }
      
      // Si no hay rutinas en Supabase, crear las por defecto
      debugPrint('⚠️ No hay rutinas en Supabase, creando por defecto...');
      final defaultRutinas = _createDefaultRutinas();
      
      // Intentar guardar las rutinas por defecto en Supabase
      for (final rutina in defaultRutinas) {
        try {
          await _supabaseDataSource.saveRutina(rutina);
        } catch (e) {
          debugPrint('Error al guardar rutina por defecto en Supabase: $e');
        }
      }
      
      // Recargar desde Supabase para obtener los IDs reales generados
      try {
        final rutinasConIds = await _supabaseDataSource.getAllRutinas();
        if (rutinasConIds.isNotEmpty) {
          debugPrint('✅ Rutinas por defecto guardadas en Supabase: ${rutinasConIds.length}');
          await _saveToLocalCache(rutinasConIds);
          return await _processExpiredRutinas(rutinasConIds);
        }
      } catch (e) {
        debugPrint('Error al recargar rutinas después de crear por defecto: $e');
      }
      
      // Si Supabase falla completamente, usar caché local como último recurso
      debugPrint('⚠️ Supabase no disponible, usando caché local como fallback');
      await _saveToLocalCache(defaultRutinas);
      return defaultRutinas;
    } catch (e) {
      // Si hay error con Supabase, usar caché local SOLO como fallback
      debugPrint('❌ Error al obtener rutinas de Supabase: $e');
      debugPrint('⚠️ Usando caché local como fallback (puede estar desactualizado)');
      final cachedRutinas = await _getFromLocalCache();
      if (cachedRutinas.isNotEmpty) {
        debugPrint('✅ Rutinas obtenidas desde caché local: ${cachedRutinas.length}');
        return cachedRutinas;
      }
      // Si no hay nada, crear por defecto
      return _createDefaultRutinas();
    }
  }

  /// Procesa rutinas vencidas: elimina la fecha si ya pasó el día
  Future<List<Rutina>> _processExpiredRutinas(List<Rutina> rutinas) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final updatedRutinas = <Rutina>[];
    bool hasChanges = false;

    for (final rutina in rutinas) {
      if (rutina.fechaEstimada != null) {
        final rutinaDate = DateTime(
          rutina.fechaEstimada!.year,
          rutina.fechaEstimada!.month,
          rutina.fechaEstimada!.day,
        );
        
        // Si la fecha ya pasó, eliminar la fecha
        if (rutinaDate.isBefore(today)) {
          final rutinaSinFecha = rutina.copyWith(fechaEstimada: null);
          updatedRutinas.add(rutinaSinFecha);
          hasChanges = true;
          // Actualizar en Supabase
          try {
            await _supabaseDataSource.updateRutinaFecha(rutina.id, null);
          } catch (e) {
            debugPrint('Error al eliminar fecha de rutina vencida: $e');
          }
        } else {
          updatedRutinas.add(rutina);
        }
      } else {
        updatedRutinas.add(rutina);
      }
    }

    if (hasChanges) {
      await _saveToLocalCache(updatedRutinas);
    }

    return updatedRutinas;
  }

  /// Guarda todas las rutinas
  Future<void> saveRutinas(List<Rutina> rutinas) async {
    try {
      // Guardar en Supabase primero
      for (final rutina in rutinas) {
        await _supabaseDataSource.saveRutina(rutina);
      }
      // También guardar en caché local
      await _saveToLocalCache(rutinas);
    } catch (e) {
      // Si falla Supabase, guardar solo localmente
      debugPrint('Error al guardar rutinas en Supabase: $e');
      await _saveToLocalCache(rutinas);
    }
  }

  /// Actualiza una rutina específica
  Future<void> updateRutina(Rutina rutina) async {
    try {
      // Actualizar en Supabase primero
      await _supabaseDataSource.saveRutina(rutina);
      // También actualizar en caché local
      final rutinas = await getAllRutinas();
      final index = rutinas.indexWhere((r) => r.id == rutina.id);
      
      if (index != -1) {
        rutinas[index] = rutina;
      } else {
        rutinas.add(rutina);
      }
      
      await _saveToLocalCache(rutinas);
    } catch (e) {
      // Si falla Supabase, actualizar solo localmente
      debugPrint('Error al actualizar rutina en Supabase: $e');
      final rutinas = await _getFromLocalCache();
      final index = rutinas.indexWhere((r) => r.id == rutina.id);
      
      if (index != -1) {
        rutinas[index] = rutina;
      } else {
        rutinas.add(rutina);
      }
      
      await _saveToLocalCache(rutinas);
    }
  }

  /// Elimina la fecha de una rutina
  Future<void> deleteRutinaFecha(String id) async {
    try {
      // Eliminar fecha en Supabase
      await _supabaseDataSource.updateRutinaFecha(id, null);
      // Actualizar en caché local
      final rutinas = await getAllRutinas();
      final index = rutinas.indexWhere((r) => r.id == id);
      
      if (index != -1) {
        rutinas[index] = rutinas[index].copyWith(fechaEstimada: null);
        await _saveToLocalCache(rutinas);
      }
    } catch (e) {
      debugPrint('Error al eliminar fecha de rutina: $e');
      // Si falla Supabase, actualizar solo localmente
      final rutinas = await _getFromLocalCache();
      final index = rutinas.indexWhere((r) => r.id == id);
      
      if (index != -1) {
        rutinas[index] = rutinas[index].copyWith(fechaEstimada: null);
        await _saveToLocalCache(rutinas);
      }
    }
  }

  /// Guarda rutinas en caché local
  Future<void> _saveToLocalCache(List<Rutina> rutinas) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rutinasJson = json.encode(rutinas.map((r) => r.toJson()).toList());
      await prefs.setString(_key, rutinasJson);
    } catch (e) {
      debugPrint('Error al guardar rutinas en caché local: $e');
    }
  }

  /// Obtiene rutinas desde caché local
  Future<List<Rutina>> _getFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rutinasJson = prefs.getString(_key);
      
      if (rutinasJson == null) {
        return _createDefaultRutinas();
      }

      final List<dynamic> decoded = json.decode(rutinasJson);
      return decoded.map((json) => Rutina.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error al obtener rutinas desde caché local: $e');
      return _createDefaultRutinas();
    }
  }

  /// Crea las 3 rutinas por defecto
  List<Rutina> _createDefaultRutinas() {
    return [
      Rutina(
        id: 'rutina_1',
        nombre: 'Rutina 1',
        color: Colors.blue,
      ),
      Rutina(
        id: 'rutina_2',
        nombre: 'Rutina 2',
        color: Colors.purple,
      ),
      Rutina(
        id: 'rutina_3',
        nombre: 'Rutina 3',
        color: Colors.teal,
      ),
    ];
  }
}

