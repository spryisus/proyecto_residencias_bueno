import '../../domain/entities/rutina.dart';
import '../../app/config/supabase_client.dart';
import 'package:flutter/material.dart';

abstract class RutinaDataSource {
  Future<List<Rutina>> getAllRutinas();
  Future<Rutina?> getRutinaById(String id);
  Future<void> saveRutina(Rutina rutina);
  Future<void> deleteRutina(String id);
  Future<void> updateRutinaFecha(String id, DateTime? fecha);
}

class SupabaseRutinaDataSource implements RutinaDataSource {
  static const String _tableName = 't_rutinas';

  @override
  Future<List<Rutina>> getAllRutinas() async {
    try {
      final response = await supabaseClient
          .from(_tableName)
          .select('*')
          .order('nombre', ascending: true);
      
      return response.map((json) => _fromSupabaseJson(json)).toList();
    } catch (e) {
      // Si la tabla no existe, devolver lista vacía
      if (e.toString().contains('does not exist') || 
          e.toString().contains('relation') ||
          e.toString().contains('42P01')) {
        return [];
      }
      throw Exception('Error al obtener rutinas: $e');
    }
  }

  @override
  Future<Rutina?> getRutinaById(String id) async {
    try {
      final response = await supabaseClient
          .from(_tableName)
          .select('*')
          .eq('id_rutina', id)
          .maybeSingle();
      
      if (response == null) return null;
      return _fromSupabaseJson(response);
    } catch (e) {
      if (e.toString().contains('does not exist') || 
          e.toString().contains('relation') ||
          e.toString().contains('42P01')) {
        return null;
      }
      throw Exception('Error al obtener rutina: $e');
    }
  }

  @override
  Future<void> saveRutina(Rutina rutina) async {
    try {
      final json = _toSupabaseJson(rutina);
      
      // Si el ID no es un UUID válido, buscar por nombre
      bool isUuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false).hasMatch(rutina.id);
      
      Map<String, dynamic>? existing;
      
      if (isUuid) {
        // Buscar por ID si es UUID
        existing = await supabaseClient
            .from(_tableName)
            .select('id_rutina')
            .eq('id_rutina', rutina.id)
            .maybeSingle();
      } else {
        // Si no es UUID, buscar por nombre (para rutinas por defecto)
        existing = await supabaseClient
            .from(_tableName)
            .select('id_rutina')
            .eq('nombre', rutina.nombre)
            .maybeSingle();
      }
      
      if (existing != null) {
        // Actualizar usando el ID encontrado
        await supabaseClient
            .from(_tableName)
            .update(json)
            .eq('id_rutina', existing['id_rutina'] as String);
      } else {
        // Insertar (Supabase generará el UUID automáticamente)
        // Si el ID no es UUID, no incluirlo en el insert
        if (!isUuid) {
          json.remove('id_rutina');
        }
        await supabaseClient
            .from(_tableName)
            .insert(json);
      }
    } catch (e) {
      // Si la tabla no existe, crear un mensaje más claro
      if (e.toString().contains('does not exist') || 
          e.toString().contains('relation') ||
          e.toString().contains('42P01')) {
        throw Exception('La tabla de rutinas no existe en la base de datos. Por favor, crea la tabla primero.');
      }
      throw Exception('Error al guardar rutina: $e');
    }
  }

  @override
  Future<void> deleteRutina(String id) async {
    try {
      await supabaseClient
          .from(_tableName)
          .delete()
          .eq('id_rutina', id);
    } catch (e) {
      if (e.toString().contains('does not exist') || 
          e.toString().contains('relation') ||
          e.toString().contains('42P01')) {
        // Si la tabla no existe, no hay nada que eliminar
        return;
      }
      throw Exception('Error al eliminar rutina: $e');
    }
  }

  @override
  Future<void> updateRutinaFecha(String id, DateTime? fecha) async {
    try {
      await supabaseClient
          .from(_tableName)
          .update({'fecha': fecha?.toIso8601String().split('T')[0]})
          .eq('id_rutina', id);
    } catch (e) {
      if (e.toString().contains('does not exist') || 
          e.toString().contains('relation') ||
          e.toString().contains('42P01')) {
        throw Exception('La tabla de rutinas no existe en la base de datos.');
      }
      throw Exception('Error al actualizar fecha de rutina: $e');
    }
  }

  // Convertir de JSON de Supabase a Rutina
  Rutina _fromSupabaseJson(Map<String, dynamic> json) {
    return Rutina(
      id: json['id_rutina'] as String,
      nombre: json['nombre'] as String,
      fechaEstimada: json['fecha'] != null
          ? DateTime.parse(json['fecha'] as String)
          : null,
      color: Color(json['color_value'] as int),
    );
  }

  // Convertir Rutina a JSON para Supabase
  Map<String, dynamic> _toSupabaseJson(Rutina rutina) {
    return {
      'id_rutina': rutina.id,
      'nombre': rutina.nombre,
      'fecha': rutina.fechaEstimada?.toIso8601String().split('T')[0],
      'color_value': rutina.color.value,
    };
  }
}

