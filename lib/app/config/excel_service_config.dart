import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

/// Configuración centralizada para el servicio de generación de Excel
/// 
/// Esta clase permite cambiar fácilmente entre ambientes:
/// - Desarrollo local (localhost o IP local)
/// - Producción (servidor en la nube)
class ExcelServiceConfig {
  // ============================================
  // CONFIGURACIÓN DE AMBIENTES
  // ============================================
  
  /// URL del servidor de Excel en producción (actualizar con tu URL de Render/Railway/etc)
  /// 
  /// Ejemplos:
  /// - Render.com: 'https://excel-generator-service.onrender.com'
  /// - Railway.app: 'https://excel-generator-service.railway.app'
  /// - Fly.io: 'https://excel-generator-service.fly.dev'
  static const String productionUrl = 'https://excel-generator-service.onrender.com';
  
  /// URL local para desarrollo (IP de tu computadora en la red local)
  /// NOTA: Actualiza esta IP si cambias de red
  /// Para obtener tu IP local:
  /// - Linux/macOS: `ip addr show` o `ifconfig`
  /// - Windows: `ipconfig`
  static const String localUrl = 'http://192.168.1.67:8001';
  
  /// URL para emulador Android
  static const String androidEmulatorUrl = 'http://10.0.2.2:8001';
  
  // ============================================
  // MÉTODOS PARA OBTENER LA URL CORRECTA
  // ============================================
  
  /// Obtiene la URL del servicio según la plataforma y ambiente
  /// 
  /// [useProduction] - Si es true, usa la URL de producción (cloud)
  ///                   Si es false o null, detecta automáticamente
  static String getServiceUrl({bool? useProduction}) {
    // Si se especifica explícitamente usar producción
    if (useProduction == true) {
      return productionUrl;
    }
    
    // Si se especifica explícitamente usar desarrollo local
    if (useProduction == false) {
      return _getLocalUrl();
    }
    
    // Detección automática según la plataforma
    if (kIsWeb) {
      // Web: usar localhost o producción según configuración
      return const String.fromEnvironment(
        'EXCEL_SERVICE_URL',
        defaultValue: 'http://localhost:8001',
      );
    } else {
      // Móvil o desktop
      try {
        if (Platform.isAndroid) {
          // Verificar si es emulador
          if (_isAndroidEmulator()) {
            return androidEmulatorUrl;
          }
          // Dispositivo físico: usar URL local o producción
          return const String.fromEnvironment(
            'EXCEL_SERVICE_URL',
            defaultValue: localUrl,
          );
        } else if (Platform.isIOS) {
          // iOS: usar URL local o producción
          return const String.fromEnvironment(
            'EXCEL_SERVICE_URL',
            defaultValue: localUrl,
          );
        } else {
          // Desktop (Windows, Linux, macOS): usar localhost
          return 'http://localhost:8001';
        }
      } catch (e) {
        // Si hay error, usar localhost como fallback
        return 'http://localhost:8001';
      }
    }
  }
  
  /// Obtiene la URL local según la plataforma
  static String _getLocalUrl() {
    if (kIsWeb) {
      return 'http://localhost:8001';
    }
    
    try {
      if (Platform.isAndroid) {
        if (_isAndroidEmulator()) {
          return androidEmulatorUrl;
        }
        return localUrl;
      } else if (Platform.isIOS) {
        return localUrl;
      } else {
        return 'http://localhost:8001';
      }
    } catch (e) {
      return 'http://localhost:8001';
    }
  }
  
  /// Detecta si está corriendo en un emulador Android
  static bool _isAndroidEmulator() {
    // Verificar a través de variables de entorno o características del sistema
    // Por ahora, retorna false. Puedes mejorarlo detectando características del emulador
    return false;
  }
  
  // ============================================
  // UTILIDADES
  // ============================================
  
  /// Verifica si la URL es de producción (HTTPS)
  static bool isProductionUrl(String url) {
    return url.startsWith('https://');
  }
  
  /// Obtiene información sobre la configuración actual
  static Map<String, dynamic> getConfigInfo() {
    final currentUrl = getServiceUrl();
    return {
      'currentUrl': currentUrl,
      'isProduction': isProductionUrl(currentUrl),
      'platform': kIsWeb 
          ? 'web' 
          : (Platform.isAndroid 
              ? 'android' 
              : (Platform.isIOS 
                  ? 'ios' 
                  : 'desktop')),
      'productionUrl': productionUrl,
      'localUrl': localUrl,
    };
  }
}

