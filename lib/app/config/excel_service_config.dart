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
  
  /// URL del servidor de Excel en producción (Render/Railway/etc)
  /// 
  /// ⚠️ URL DE RENDER GUARDADA PARA PRODUCCIÓN:
  /// 'https://generador-excel.onrender.com'
  /// 
  /// Ejemplos:
  /// - Render.com: 'https://excel-generator-service.onrender.com'
  /// - Railway.app: 'https://excel-generator-service.railway.app'
  /// - Fly.io: 'https://excel-generator-service.fly.dev'
  static const String productionUrl = 'https://generador-excel.onrender.com';
  
  /// URL local para desarrollo (IP de tu computadora en la red local)
  /// NOTA: Actualiza esta IP si cambias de red
  /// Para obtener tu IP local:
  /// - Linux/macOS: `ip addr show` o `ifconfig`
  /// - Windows: `ipconfig`
  static const String localUrl = 'http://192.168.1.67:8001';
  
  /// URL para emulador Android
  static const String androidEmulatorUrl = 'http://10.0.2.2:8001';
  
  // ============================================
  // CONFIGURACIÓN DE MODO (LOCAL vs PRODUCCIÓN)
  // ============================================
  
  /// Cambiar a `false` para usar URL local durante pruebas
  /// Cambiar a `true` para usar URL de producción (Render)
  /// 
  /// ⚠️ IMPORTANTE: Durante pruebas locales, mantener en `false`
  /// Para producción, cambiar a `true` y actualizar `productionUrl` arriba
  static const bool useProductionByDefault = true; // ✅ PRODUCCIÓN: Usando Render
  
  // ============================================
  // MÉTODOS PARA OBTENER LA URL CORRECTA
  // ============================================
  
  /// Obtiene la URL del servicio según la plataforma y ambiente
  /// 
  /// [useProduction] - Si es true, usa la URL de producción (cloud)
  ///                   Si es false, usa URL local
  ///                   Si es null, usa el valor de `useProductionByDefault`
  static String getServiceUrl({bool? useProduction}) {
    // Si se especifica explícitamente usar producción
    if (useProduction == true) {
      return productionUrl;
    }
    
    // Si se especifica explícitamente usar desarrollo local
    if (useProduction == false) {
      return _getLocalUrl();
    }
    
    // Usar el valor por defecto configurado (local o producción)
    if (useProductionByDefault) {
      return productionUrl;
    } else {
      return _getLocalUrl();
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

