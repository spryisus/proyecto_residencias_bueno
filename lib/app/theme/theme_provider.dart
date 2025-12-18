import 'package:flutter/material.dart';

/// Provider simplificado que siempre usa tema claro
/// El modo oscuro ha sido deshabilitado
class ThemeProvider extends ChangeNotifier {
  // Siempre usar tema claro
  ThemeMode get themeMode => ThemeMode.light;
  
  bool get isDarkMode => false;
  bool get isLightMode => true;
  bool get isSystemMode => false;
}


