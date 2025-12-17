import 'package:flutter/material.dart';

class AppTheme {
  // Colores principales de Telmex (mejorados para mejor contraste)
  static const Color primaryBlue = Color(0xFF003366);
  static const Color secondaryBlue = Color(0xFF0066CC);
  static const Color accentBlue = Color(0xFF4A90E2);
  static const Color lightBlue = Color(0xFFE6F3FF);
  
  // Colores de estado
  static const Color successGreen = Color(0xFF28A745);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFDC3545);
  static const Color infoBlue = Color(0xFF17A2B8);
  
  // Grises para texto y superfícies
  static const Color grey100 = Color(0xFFF8F9FA);
  static const Color grey200 = Color(0xFFE9ECEF);
  static const Color grey300 = Color(0xFFDEE2E6);
  static const Color grey400 = Color(0xFFCED4DA);
  static const Color grey500 = Color(0xFFADB5BD);
  static const Color grey600 = Color(0xFF6C757D);
  static const Color grey700 = Color(0xFF495057);
  static const Color grey800 = Color(0xFF343A40);
  static const Color grey900 = Color(0xFF212529);

  // Tema claro profesional
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: secondaryBlue,
      tertiary: accentBlue,
      surface: Colors.white,
      surfaceVariant: grey100,
      background: grey100,
      error: errorRed,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: grey800,
      onBackground: grey800,
      onError: Colors.white,
      outline: grey300,
    ),
    
    // AppBar moderno
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: grey800,
      elevation: 1,
      shadowColor: Colors.black12,
      titleTextStyle: TextStyle(
        color: grey800,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      centerTitle: true,
    ),
    
    // Cards con elevación suave
    cardTheme: const CardThemeData(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      surfaceTintColor: Colors.transparent,
    ),
    
    // Botones elevados profesionales
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: primaryBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    ),
    
    // Botones de texto elegantes
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryBlue,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    // Input fields modernos
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: grey300, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: grey300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorRed, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorRed, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    
    // Tipografía profesional
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: grey800,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: grey800,
        letterSpacing: -0.25,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: grey800,
        letterSpacing: 0,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: grey800,
        letterSpacing: 0,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: grey800,
        letterSpacing: 0.15,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: grey800,
        letterSpacing: 0.15,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: grey800,
        letterSpacing: 0.15,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: grey800,
        letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: grey800,
        letterSpacing: 0.1,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: grey700,
        letterSpacing: 0.15,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: grey700,
        letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: grey600,
        letterSpacing: 0.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: grey700,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: grey700,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: grey600,
        letterSpacing: 0.5,
      ),
    ),
    
    // Iconos con tema consistente
    iconTheme: const IconThemeData(
      color: grey600,
      size: 24,
    ),
    
    // FAB con estilo moderno
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    
    // Divider más sutil
    dividerTheme: const DividerThemeData(
      color: grey200,
      thickness: 1,
      space: 1,
    ),
  );

  // Tema oscuro elegante
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: accentBlue,
      secondary: secondaryBlue,
      tertiary: primaryBlue,
      surface: grey900,
      surfaceVariant: grey800,
      background: Color(0xFF121212),
      error: Color(0xFFCF6679),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.black,
      outline: grey600,
    ),
    
    // AppBar oscuro elegante
    appBarTheme: const AppBarTheme(
      backgroundColor: grey900,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      centerTitle: true,
    ),
    
    // Cards oscuros con elevación sutil
    cardTheme: const CardThemeData(
      elevation: 2,
      shadowColor: Colors.black26,
      color: grey900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      surfaceTintColor: Colors.transparent,
    ),
    
    // Botones oscuros
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: accentBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    ),
    
    // Input fields oscuros
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: grey700, width: 1),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: grey700, width: 1),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: accentBlue, width: 2),
      ),
      filled: true,
      fillColor: grey800,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    
    // Divider oscuro
    dividerTheme: const DividerThemeData(
      color: grey700,
      thickness: 1,
      space: 1,
    ),
  );

  // Animaciones y transiciones suaves
  static Duration get fastAnimation => const Duration(milliseconds: 200);
  static Duration get mediumAnimation => const Duration(milliseconds: 300);
  static Duration get slowAnimation => const Duration(milliseconds: 500);
  
  // Curvas de animación profesionales
  static Curve get easeInOutCurve => Curves.easeInOut;
  static Curve get elasticCurve => Curves.elasticOut;
  static Curve get bounceCurve => Curves.bounceOut;
}

// Extensiones útiles para colores
extension ColorExtensions on Color {
  Color lighten(double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }
  
  Color darken(double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}