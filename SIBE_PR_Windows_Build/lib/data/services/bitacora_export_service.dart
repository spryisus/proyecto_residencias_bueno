import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../../app/config/excel_service_config.dart';
import '../../core/utils/file_saver_helper.dart';
import '../../core/utils/web_file_helper.dart' if (dart.library.io) '../../core/utils/web_file_helper_stub.dart';
import '../../domain/entities/bitacora_envio.dart';

/// Servicio para exportar datos de bitácora de envíos a Excel
class BitacoraExportService {
  /// Obtiene la URL del servicio según la plataforma (web/móvil)
  static String get _excelServiceUrl => ExcelServiceConfig.getServiceUrl();
  
  /// Exporta datos de bitácora a Excel con múltiples hojas (una por año)
  /// 
  /// [bitacorasPorAnio] Mapa donde la clave es el año y el valor es la lista de bitácoras de ese año
  /// 
  /// Retorna la ruta del archivo guardado o mensaje de descarga
  static Future<String?> exportBitacoraToExcel(
    Map<int, List<BitacoraEnvio>> bitacorasPorAnio,
  ) async {
    try {
      if (bitacorasPorAnio.isEmpty) {
        throw Exception('No hay datos para exportar');
      }

      // Preparar los datos para el endpoint según la plantilla
      // Convertir el mapa a una lista de objetos con año e items
      final yearsData = bitacorasPorAnio.entries.map((entry) {
        final year = entry.key;
        final items = entry.value;
        return {
          'year': year,
          'items': items.map((item) {
            return {
              'consecutivo': item.consecutivo,
              'fecha': item.fecha.toIso8601String().split('T')[0], // Solo fecha YYYY-MM-DD
              'tecnico': item.tecnico ?? '',
              'tarjeta': item.tarjeta ?? '',
              'codigo': item.codigo ?? '',
              'serie': item.serie ?? '',
              'folio': item.folio ?? '',
              'envia': item.envia ?? '',
              'recibe': item.recibe ?? '',
              'guia': item.guia ?? '',
              'anexos': item.anexos ?? '',
              'observaciones': item.observaciones ?? '',
              'cobo': item.cobo ?? '',
            };
          }).toList(),
        };
      }).toList();

      final payload = {
        'years_data': yearsData, // Lista de objetos con año e items
      };

      // Llamar al endpoint del servicio Python
      final url = Uri.parse('$_excelServiceUrl/api/generate-bitacora-excel');
      
      // Timeout aumentado para archivos grandes con múltiples hojas
      // 180 segundos (3 minutos) debería ser suficiente incluso para 9 hojas con muchos registros
      final numYears = bitacorasPorAnio.length;
      final timeoutSeconds = numYears > 5 ? 180 : (numYears > 2 ? 120 : 60);
      
      http.Response response;
      try {
        response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        ).timeout(
          Duration(seconds: timeoutSeconds),
          onTimeout: () {
            throw Exception(
              'Tiempo de espera agotado después de ${timeoutSeconds} segundos.\n\n'
              'El servicio está procesando un archivo grande con $numYears hoja(s).\n'
              'Esto es normal para exportaciones grandes. El archivo puede haberse generado correctamente.\n\n'
              'Verifica si el archivo se descargó antes de intentar nuevamente.'
            );
          },
        );
      } catch (e) {
        // Si el servidor de producción no está disponible, intentar con local como fallback
        if (_excelServiceUrl.contains('https://') && 
            (e.toString().contains('Connection refused') || 
             e.toString().contains('Conexión rehusada') ||
             e.toString().contains('SocketException') ||
             e.toString().contains('Failed host lookup'))) {
          print('⚠️ Servidor de producción no disponible, intentando con servidor local...');
          final localUrl = ExcelServiceConfig.localUrl;
          final localUri = Uri.parse('$localUrl/api/generate-bitacora-excel');
          print('🔗 Intentando con URL local: $localUrl');
          try {
            response = await http.post(
              localUri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            ).timeout(
              Duration(seconds: timeoutSeconds),
              onTimeout: () {
                throw Exception(
                  'Tiempo de espera agotado después de ${timeoutSeconds} segundos.\n\n'
                  'El servicio está procesando un archivo grande con $numYears hoja(s).\n'
                  'Esto es normal para exportaciones grandes. El archivo puede haberse generado correctamente.\n\n'
                  'Verifica si el archivo se descargó antes de intentar nuevamente.'
                );
              },
            );
          } catch (e2) {
            throw Exception(
              'Error al conectar con el servicio de Excel.\n\n'
              'El servidor de producción no está disponible y el servidor local tampoco responde.\n\n'
              'Solución:\n'
              '1. Verifica tu conexión a internet para usar el servidor de producción.\n'
              '2. O inicia el servidor local ejecutando: cd excel_generator_service && ./start_server.sh\n\n'
              'Error: ${e.toString()}'
            );
          }
        } else {
          // Mejorar mensaje de error para conexión rechazada
          if (e.toString().contains('Connection refused') || 
              e.toString().contains('Conexión rehusada') ||
              e.toString().contains('SocketException')) {
            throw Exception(
              'No se pudo conectar al servicio de Excel.\n\n'
              'El servicio Python no está corriendo en $_excelServiceUrl\n\n'
              'Para iniciarlo, ejecuta:\n'
              'cd excel_generator_service\n'
              'python -m uvicorn main:app --host 0.0.0.0 --port 8001 --reload\n\n'
              'O usa el script: ./start_server.sh'
            );
          }
          rethrow;
        }
      }

      if (response.statusCode != 200) {
        throw Exception('Error al generar Excel: ${response.statusCode} - ${response.body}');
      }

      // Generar nombre por defecto con años
      final now = DateTime.now();
      final dateStr = '${now.day.toString().padLeft(2, '0')}_${now.month.toString().padLeft(2, '0')}_${now.year}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final yearsList = bitacorasPorAnio.keys.toList()..sort();
      final yearsStr = yearsList.join('_');
      final defaultFileName = 'Bitacora_Envio_$yearsStr\_$dateStr.xlsx';

      // Para web, descargar directamente
      if (kIsWeb) {
        return downloadFileWeb(response.bodyBytes, defaultFileName);
      }

      // Para móvil/desktop, usar el helper
      return await FileSaverHelper.saveFile(
        fileBytes: response.bodyBytes,
        defaultFileName: defaultFileName,
        dialogTitle: 'Guardar bitácora de envíos como',
      );
    } catch (e) {
      rethrow;
    }
  }
}

