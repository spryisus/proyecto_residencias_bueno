import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/entities/rutina.dart';

/// Almacenamiento local para las rutinas
class RutinaStorage {
  static const String _key = 'rutinas';

  /// Obtiene todas las rutinas guardadas
  Future<List<Rutina>> getAllRutinas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rutinasJson = prefs.getString(_key);
      
      if (rutinasJson == null) {
        // Si no hay rutinas guardadas, crear las 3 rutinas por defecto
        return _createDefaultRutinas();
      }

      final List<dynamic> decoded = json.decode(rutinasJson);
      return decoded.map((json) => Rutina.fromJson(json)).toList();
    } catch (e) {
      // Si hay error, retornar rutinas por defecto
      return _createDefaultRutinas();
    }
  }

  /// Guarda todas las rutinas
  Future<void> saveRutinas(List<Rutina> rutinas) async {
    final prefs = await SharedPreferences.getInstance();
    final rutinasJson = json.encode(rutinas.map((r) => r.toJson()).toList());
    await prefs.setString(_key, rutinasJson);
  }

  /// Actualiza una rutina específica
  Future<void> updateRutina(Rutina rutina) async {
    final rutinas = await getAllRutinas();
    final index = rutinas.indexWhere((r) => r.id == rutina.id);
    
    if (index != -1) {
      rutinas[index] = rutina;
    } else {
      rutinas.add(rutina);
    }
    
    await saveRutinas(rutinas);
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

