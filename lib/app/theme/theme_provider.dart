import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;
  
  ThemeProvider() {
    _loadThemeMode();
  }
  
  // Cargar el modo de tema guardado
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeMode = prefs.getString(_themeModeKey);
      
      if (savedThemeMode != null) {
        switch (savedThemeMode) {
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          case 'system':
          default:
            _themeMode = ThemeMode.system;
            break;
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error loading theme mode: $e');
    }
  }
  
  // Cambiar a tema claro
  Future<void> setLightTheme() async {
    _themeMode = ThemeMode.light;
    await _saveThemeMode('light');
    notifyListeners();
  }
  
  // Cambiar a tema oscuro
  Future<void> setDarkTheme() async {
    _themeMode = ThemeMode.dark;
    await _saveThemeMode('dark');
    notifyListeners();
  }
  
  // Cambiar a tema del sistema
  Future<void> setSystemTheme() async {
    _themeMode = ThemeMode.system;
    await _saveThemeMode('system');
    notifyListeners();
  }
  
  // Alternar entre tema claro y oscuro
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setDarkTheme();
    } else {
      await setLightTheme();
    }
  }
  
  // Guardar el modo de tema
  Future<void> _saveThemeMode(String mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode);
    } catch (e) {
      print('Error saving theme mode: $e');
    }
  }
  
  // Obtener el nombre del tema para mostrar en UI
  String get themeModeName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Oscuro';
      case ThemeMode.system:
        return 'Sistema';
    }
  }
  
  // Obtener icono del tema
  IconData get themeIcon {
    switch (_themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_6;
    }
  }
}


