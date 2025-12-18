import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/config/supabase_client.dart';
import 'app/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'core/di/injection_container.dart' as di;

/// Función de inicialización compartida para todos los entrypoints
Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSupabaseConfig.initialize();
  // Inicializar localización en español
  await initializeDateFormatting('es_ES', null);
  di.setupDependencies(); // Configurar dependencias
}

// Arranque por defecto (útil si ejecutas `flutter run` sin --target)
Future<void> main() async {
  await initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema Larga Distancia',
      theme: AppTheme.lightTheme,
      // Modo oscuro deshabilitado - siempre usar tema claro
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}
