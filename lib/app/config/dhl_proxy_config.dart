import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

/// Configuración centralizada para el servidor proxy DHL
/// 
/// Esta clase permite cambiar fácilmente entre ambientes:
/// - Desarrollo local (localhost o IP local)
/// - Producción (servidor en la nube)
class DHLProxyConfig {
  // ============================================
  // CONFIGURACIÓN DE AMBIENTES
  // ============================================
  
  /// URL del servidor proxy en producción (Puppeteer, Render/Railway/etc)
  /// 
  /// Ejemplos:
  /// - Render.com: 'https://dhl-tracking-proxy.onrender.com'
  /// - Railway.app: 'https://dhl-tracking-proxy.railway.app'
  /// - Fly.io: 'https://dhl-tracking-proxy.fly.dev'
  static const String productionUrl = 'https://dhl-tracking-proxy.onrender.com';
  
  /// URL local para desarrollo (Puppeteer local)
  static const String localUrl = 'http://10.12.18.188:3000';
  
  /// URL para emulador Android (Puppeteer)
  static const String androidEmulatorUrl = 'http://10.0.2.2:3000';

  /// ===========================
  /// FastAPI (scraping ligero)
  /// ===========================
  static const String fastApiWebDesktop = 'http://localhost:8000';
  static const String fastApiAndroidEmu = 'http://10.0.2.2:8000';
  /// Para dispositivo físico, actualiza con la IP LAN de tu PC corriendo FastAPI
  static const String fastApiLanDevice = 'http://10.12.18.188:8000';
  
  // ============================================
  // MÉTODOS PARA OBTENER LA URL CORRECTA
  // ============================================
  
  /// Obtiene la URL base de FastAPI según plataforma
  static String getFastApiBase() {
    if (kIsWeb) {
      return fastApiWebDesktop;
    }
    try {
      if (Platform.isAndroid) {
        // Emulador Android usa 10.0.2.2, físico usa LAN
        return _isAndroidEmulator() ? fastApiAndroidEmu : fastApiLanDevice;
      } else if (Platform.isIOS) {
        return fastApiLanDevice;
      } else {
        // Desktop
        return fastApiWebDesktop;
      }
    } catch (_) {
      return fastApiWebDesktop;
    }
  }

  /// Obtiene la URL del proxy según la plataforma y ambiente
  /// 
  /// [useProduction] - Si es true, usa la URL de producción (cloud)
  ///                   Si es false o null, detecta automáticamente
  static String getProxyUrl({bool? useProduction}) {
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
        'DHL_PROXY_URL',
        defaultValue: 'http://localhost:8000',
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
            'DHL_PROXY_URL',
            defaultValue: localUrl,
          );
        } else if (Platform.isIOS) {
          // iOS: usar URL local o producción
          return const String.fromEnvironment(
            'DHL_PROXY_URL',
            defaultValue: localUrl,
          );
        } else {
          // Desktop (Windows, Linux, macOS): usar localhost
          return 'http://localhost:3000';
        }
      } catch (e) {
        // Si hay error, usar localhost como fallback
        return 'http://localhost:3000';
      }
    }
  }
  
  /// Obtiene la URL local según la plataforma
  static String _getLocalUrl() {
    if (kIsWeb) {
      return 'http://localhost:3000';
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
        return 'http://localhost:3000';
      }
    } catch (e) {
      return 'http://localhost:3000';
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
    final currentUrl = getProxyUrl();
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


