import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import '../models/tracking_event_model.dart';
import '../../domain/entities/tracking_event.dart';

/// Servicio para consultar tracking de envíos DHL
/// 
/// Este servicio puede usar dos métodos:
/// 1. Proxy backend con Puppeteer (recomendado) - más legítimo y confiable
/// 2. Petición directa a DHL con headers optimizados
/// 
/// Para usar el proxy backend, configura la URL en [proxyUrl].
/// Si [proxyUrl] es null, usará el método directo.
class DHLTrackingService {
  // URL del proxy backend (Node.js con Puppeteer)
  // Ejemplo: 'http://localhost:3000' o 'https://tu-servidor.com'
  // Si es null, usará método directo/FastAPI
  final String? proxyUrl;

  // URL del microservicio FastAPI (scraping ligero)
  // Ejemplo: 'http://localhost:8000'
  final String? fastApiBaseUrl;
  
  // Endpoint público de DHL para México (página web de tracking)
  static const String _baseUrl = 'https://www.dhl.com/mx-es/home/tracking/tracking.html';
  static const String _dhlHomeUrl = 'https://www.dhl.com/mx-es/home.html';
  
  /// Constructor con opción de configurar URL del proxy y FastAPI
  DHLTrackingService({
    this.proxyUrl,
    this.fastApiBaseUrl,
  });
  
  // Cliente HTTP que mantiene cookies entre peticiones
  final http.Client _client = http.Client();
  
  // Cookies obtenidas de la sesión inicial
  String? _sessionCookies;

  /// Obtiene una sesión válida visitando primero la página principal
  /// Esto ayuda a que DHL reconozca las peticiones como legítimas
  Future<void> _establishSession() async {
    try {
      final response = await _client.get(
        Uri.parse(_dhlHomeUrl),
        headers: _getBaseHeaders(),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout al establecer sesión');
        },
      );
      
      // Extraer cookies de la respuesta
      final cookies = response.headers['set-cookie'];
      if (cookies != null && cookies.isNotEmpty) {
        _sessionCookies = cookies;
      }
    } catch (e) {
      // Si falla, continuamos sin sesión
      _sessionCookies = null;
    }
  }

  /// Headers base que simulan un navegador real completo
  /// Esto incluye todos los headers que un navegador moderno envía
  Map<String, String> _getBaseHeaders() {
    return {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
      'Accept-Language': 'es-MX,es;q=0.9,en-US;q=0.8,en;q=0.7',
      'Accept-Encoding': 'gzip, deflate, br',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
      'Sec-Fetch-Dest': 'document',
      'Sec-Fetch-Mode': 'navigate',
      'Sec-Fetch-Site': 'none',
      'Sec-Fetch-User': '?1',
      'Cache-Control': 'max-age=0',
      'sec-ch-ua': '"Not_A Brand";v="8", "Chromium";v="120", "Google Chrome";v="120"',
      'sec-ch-ua-mobile': '?0',
      'sec-ch-ua-platform': '"Windows"',
      'DNT': '1',
      'Referer': 'https://www.dhl.com/mx-es/home.html',
    };
  }

  /// Consulta el estado de un envío DHL usando el número de tracking
  /// 
  /// [trackingNumber] - Número de guía de DHL
  /// 
  /// Retorna un [ShipmentTracking] con la información del envío
  /// 
  /// Si [proxyUrl] está configurado, usa el proxy backend (más confiable).
  /// Si no, usa petición directa a DHL con headers optimizados.
  Future<ShipmentTracking> trackShipment(String trackingNumber) async {
    // Limpiar el número de tracking
    final cleanTrackingNumber = trackingNumber.trim().replaceAll(RegExp(r'[^\w]'), '');

    // 1) Intentar FastAPI (rápido)
    if (fastApiBaseUrl != null && fastApiBaseUrl!.isNotEmpty) {
      try {
        return await _trackViaFastApi(cleanTrackingNumber);
      } catch (e) {
        debugPrint('⚠️ FastAPI falló: $e');
      }
    }

    // 2) Intentar proxy Puppeteer (respaldo)
    if (proxyUrl != null && proxyUrl!.isNotEmpty) {
      try {
        return await _trackViaProxy(cleanTrackingNumber);
      } catch (e) {
        debugPrint('⚠️ Proxy Puppeteer falló: $e');
      }
    }
    
    // 3) Último recurso: método directo
    return _trackDirectly(cleanTrackingNumber);
  }

  /// Consulta tracking usando FastAPI (scraping ligero)
  Future<ShipmentTracking> _trackViaFastApi(String trackingNumber) async {
    final base = fastApiBaseUrl!.endsWith('/')
        ? fastApiBaseUrl!.substring(0, fastApiBaseUrl!.length - 1)
        : fastApiBaseUrl!;
    final url = Uri.parse('$base/tracking/$trackingNumber');

    final response = await http.get(url).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Timeout FastAPI');
      },
    );

    if (response.statusCode != 200) {
      throw Exception('FastAPI devolvió código ${response.statusCode}');
    }

    final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
    if (jsonData['success'] != true || jsonData['data'] == null) {
      throw Exception(jsonData['detail'] as String? ?? 'FastAPI sin datos');
    }

    final data = jsonData['data'] as Map<String, dynamic>;
    final events = (data['events'] as List<dynamic>?)
            ?.map((e) => TrackingEventModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final status = data['status'] as String? ?? 'Desconocido';

    DateTime? estimatedDelivery;
    final estimatedRaw = data['estimatedDelivery'];
    if (estimatedRaw is String) {
      estimatedDelivery = DateTime.tryParse(estimatedRaw);
    }

    return ShipmentTracking(
      trackingNumber: data['trackingNumber'] as String? ?? trackingNumber,
      status: status,
      events: events,
      origin: data['origin'] as String?,
      destination: data['destination'] as String?,
      currentLocation: data['currentLocation'] as String?,
      estimatedDelivery: estimatedDelivery,
    );
  }

  /// Consulta tracking usando el proxy backend (Node.js + Puppeteer)
  Future<ShipmentTracking> _trackViaProxy(String trackingNumber) async {
    try {
      // Construir URL del proxy
      final proxyUrlClean = proxyUrl!.endsWith('/') 
          ? proxyUrl!.substring(0, proxyUrl!.length - 1) 
          : proxyUrl!;
      
      // OPTIMIZACIÓN: Llamar a /warmup primero para precargar la página
      // Esto acelera significativamente la primera consulta
      try {
        final warmupUrl = Uri.parse('$proxyUrlClean/warmup');
        await http.get(warmupUrl).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            // Si el warmup falla, continuar de todas formas
            debugPrint('⚠️ Warmup timeout, continuando con consulta normal...');
            return http.Response('', 408); // Retornar respuesta vacía para evitar error
          },
        ).catchError((e) {
          // Si el warmup falla, continuar de todas formas
          debugPrint('⚠️ Error en warmup, continuando con consulta normal: $e');
          return http.Response('', 500); // Retornar respuesta vacía para evitar error
        });
      } catch (e) {
        // Si el warmup falla, continuar de todas formas
        debugPrint('⚠️ No se pudo hacer warmup, continuando: $e');
      }
      
      final url = Uri.parse('$proxyUrlClean/api/track/$trackingNumber');

      // Realizar petición al proxy
      // Timeout aumentado a 300 segundos (5 minutos) debido a los delays anti-detección
      // El proxy tiene delays de 70-80s + otros delays que pueden sumar hasta 3-4 minutos
      final response = await http.get(url).timeout(
        const Duration(seconds: 300), // 5 minutos para dar tiempo completo a los delays anti-detección
        onTimeout: () {
          throw Exception('Timeout: El servidor proxy está tardando mucho en responder. El proceso puede tardar hasta 3-4 minutos debido a medidas anti-detección. Verifica que el servidor esté corriendo.');
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return _parseProxyResponse(jsonData['data'] as Map<String, dynamic>, trackingNumber);
        } else {
          throw Exception(jsonData['error'] as String? ?? jsonData['message'] as String? ?? 'Error desconocido del proxy');
        }
      } else {
        throw Exception('Error al consultar el proxy. Código: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('Timeout')) {
        rethrow;
      }
      throw Exception('Error al consultar el tracking via proxy: ${e.toString()}');
    }
  }

  /// Consulta tracking directamente a DHL (método directo)
  Future<ShipmentTracking> _trackDirectly(String trackingNumber) async {
    try {
      // Primero establecemos una sesión visitando la página principal
      await _establishSession();
      
      // Esperar un poco para que la sesión se establezca
      await Future.delayed(const Duration(milliseconds: 500));

      // Construir la URL con el número de tracking
      final trackingUrl = Uri.parse(
        '$_baseUrl?submit=1&tracking-id=$trackingNumber'
      );

      // Headers específicos para la petición de tracking
      final headers = Map<String, String>.from(_getBaseHeaders());
      headers['Referer'] = _dhlHomeUrl;
      
      // Agregar cookies de sesión si las tenemos
      if (_sessionCookies != null) {
        headers['Cookie'] = _sessionCookies!;
      }

      // Realizar la petición HTTP con sesión establecida
      final response = await _client.get(
        trackingUrl,
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout: DHL está tardando mucho en responder. Considera usar un proxy backend para mejor confiabilidad.');
        },
      );

      if (response.statusCode == 200) {
        // Intentar parsear como JSON
        try {
          final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
          return _parseDHLResponse(jsonData, trackingNumber);
        } catch (e) {
          // Si no es JSON, puede ser HTML, intentar parsear HTML
          return _parseDHLHtmlResponse(response.body, trackingNumber);
        }
      } else if (response.statusCode == 404) {
        throw Exception('No se encontró información para el número de tracking: $trackingNumber');
      } else {
        throw Exception('Error al consultar DHL. Código: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('Tiempo de espera') || e.toString().contains('Timeout')) {
        rethrow;
      }
      throw Exception('Error al consultar el tracking: ${e.toString()}');
    }
  }

  /// Parsea la respuesta del proxy backend
  ShipmentTracking _parseProxyResponse(Map<String, dynamic> data, String trackingNumber) {
    try {
      final events = (data['events'] as List<dynamic>?)
              ?.map((e) => TrackingEventModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      // Determinar el estado basado en los eventos si el estado viene como "No encontrado" pero hay eventos
      String status = data['status'] as String? ?? 'Desconocido';
      
      // Si el estado es "No encontrado" pero hay eventos, verificar si son eventos válidos o mensajes de error
      if ((status.toLowerCase().contains('no encontrado') || 
           status.toLowerCase().contains('not found') ||
           status == 'Desconocido') && 
          events.isNotEmpty) {
        // Determinar estado basado en el evento más reciente
        final lastEvent = events.first; // Los eventos están ordenados del más reciente al más antiguo
        final description = lastEvent.description.toLowerCase();
        
        // Si el evento es un mensaje de error, mantener el estado como "No encontrado"
        if (description.contains('lo sentimos') || 
            description.contains('error') ||
            description.contains('no se pudo') ||
            description.contains('no se realizó') ||
            description.contains('intento')) {
          // Mantener el estado como "No encontrado" cuando es un mensaje de error
          status = 'No encontrado';
        } else if (description.contains('entregado') || description.contains('delivered')) {
          status = 'Entregado';
        } else if (description.contains('en tránsito') || 
                   description.contains('in transit') ||
                   description.contains('procesado') ||
                   description.contains('processed')) {
          status = 'En tránsito';
        } else if (description.contains('recolectado') || 
                   description.contains('picked up') ||
                   description.contains('retirado')) {
          status = 'Recolectado';
        } else if (description.contains('programado') || 
                   description.contains('scheduled')) {
          status = 'Programado';
        } else {
          // Si no podemos determinar, mantener el estado original
          status = status;
        }
      }

      // Extraer ubicación actual del evento más reciente si no viene en currentLocation
      String? currentLocation = data['currentLocation'] as String?;
      if ((currentLocation == null || currentLocation.isEmpty) && events.isNotEmpty) {
        final lastEvent = events.first;
        // Intentar extraer ubicación de la descripción si no viene en location
        if (lastEvent.location != null && lastEvent.location!.isNotEmpty) {
          currentLocation = lastEvent.location;
        } else if (lastEvent.description.contains(' - ')) {
          // Intentar extraer ubicación del formato "CIUDAD - ESTADO - PAÍS"
          final parts = lastEvent.description.split(' - ');
          if (parts.length >= 3) {
            currentLocation = '${parts[parts.length - 3]} - ${parts[parts.length - 2]} - ${parts[parts.length - 1]}';
          }
        }
      }

      return ShipmentTrackingModel(
        trackingNumber: trackingNumber,
        status: status,
        origin: data['origin'] as String?,
        destination: data['destination'] as String?,
        currentLocation: currentLocation,
        estimatedDelivery: data['estimatedDelivery'] != null
            ? DateTime.parse(data['estimatedDelivery'] as String)
            : null,
        events: events,
      );
    } catch (e) {
      throw Exception('Error al procesar la respuesta del proxy: ${e.toString()}');
    }
  }

  /// Parsea la respuesta JSON de DHL
  ShipmentTracking _parseDHLResponse(Map<String, dynamic> json, String trackingNumber) {
    try {
      final results = json['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) {
        throw Exception('No se encontraron resultados para este número de tracking');
      }

      final firstResult = results[0] as Map<String, dynamic>;
      final events = (firstResult['events'] as List<dynamic>?)
              ?.map((e) => TrackingEventModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      // Determinar el estado actual basado en los eventos
      String currentStatus = 'En tránsito';
      if (events.isNotEmpty) {
        final lastEvent = events.first;
        final description = lastEvent.description.toLowerCase();
        if (description.contains('entregado') || description.contains('delivered')) {
          currentStatus = 'Entregado';
        } else if (description.contains('en tránsito') || description.contains('in transit')) {
          currentStatus = 'En tránsito';
        } else if (description.contains('recolectado') || description.contains('picked up')) {
          currentStatus = 'Recolectado';
        }
      }

      return ShipmentTrackingModel(
        trackingNumber: trackingNumber,
        status: currentStatus,
        origin: firstResult['origin'] as String?,
        destination: firstResult['destination'] as String?,
        currentLocation: events.isNotEmpty ? events.first.location : null,
        estimatedDelivery: firstResult['estimatedDelivery'] != null
            ? DateTime.parse(firstResult['estimatedDelivery'] as String)
            : null,
        events: events,
      );
    } catch (e) {
      throw Exception('Error al procesar la respuesta de DHL: ${e.toString()}');
    }
  }

  /// Parsea la respuesta HTML de DHL (fallback)
  ShipmentTracking _parseDHLHtmlResponse(String html, String trackingNumber) {
    // Si DHL devuelve HTML en lugar de JSON, intentamos extraer información básica
    // Por ahora, retornamos un objeto con información mínima
    // En producción, podrías usar un parser HTML más sofisticado
    
    // Buscar patrones comunes en el HTML
    // Nota: DHL puede devolver HTML, por lo que este método es un fallback básico
    // En producción, considera usar un parser HTML como html o similar
    String status = 'En tránsito';
    
    // Intentar extraer estado básico del HTML
    if (html.toLowerCase().contains('entregado') || 
        html.toLowerCase().contains('delivered')) {
      status = 'Entregado';
    } else if (html.toLowerCase().contains('en tránsito') || 
               html.toLowerCase().contains('in transit')) {
      status = 'En tránsito';
    } else if (html.toLowerCase().contains('recolectado') || 
               html.toLowerCase().contains('picked up')) {
      status = 'Recolectado';
    }

    return ShipmentTrackingModel(
      trackingNumber: trackingNumber,
      status: status,
      events: [],
    );
  }

  /// Valida si un número de tracking tiene el formato correcto de DHL
  bool isValidTrackingNumber(String trackingNumber) {
    // DHL México generalmente usa números de 10-11 dígitos
    // o códigos alfanuméricos
    final cleaned = trackingNumber.trim().replaceAll(RegExp(r'[^\w]'), '');
    return cleaned.length >= 8 && cleaned.length <= 15;
  }

  /// Libera los recursos del cliente HTTP
  void dispose() {
    _client.close();
  }
}
