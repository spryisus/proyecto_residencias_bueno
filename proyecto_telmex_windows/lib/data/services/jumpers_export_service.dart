import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../../app/config/excel_service_config.dart';
import '../../core/utils/file_saver_helper.dart';
import '../../core/utils/web_file_helper.dart' if (dart.library.io) '../../core/utils/web_file_helper_stub.dart';

/// Servicio para exportar datos de jumpers a Excel
class JumpersExportService {
  /// Obtiene la URL del servicio según la plataforma (web/móvil)
  static String get _excelServiceUrl => ExcelServiceConfig.getServiceUrl();
  
  /// Exporta datos de jumpers a Excel
  /// 
  /// [items] Lista de jumpers con los campos: tipo, tamano, cantidad, rack, contenedor
  /// 
  /// Retorna la ruta del archivo guardado o mensaje de descarga
  static Future<String?> exportJumpersToExcel(List<Map<String, dynamic>> items) async {
    try {
      if (items.isEmpty) {
        throw Exception('No hay datos para exportar');
      }

      // Preparar los datos para el endpoint según la plantilla
      // Columnas: B=TIPO, C=TAMAÑO, D=CANTIDAD, E=RACK, F=CONTENEDOR, UBICACION (nueva)
      final payload = {
        'items': items.map((item) {
          final contenedores = item['contenedores'] as List<dynamic>? ?? [];
          return {
            'tipo': item['tipo'] ?? item['categoryName'] ?? '',
            'tamano': item['tamano'] ?? item['size'] ?? '',
            'cantidad': item['cantidad'] ?? item['quantity'] ?? 0,
            'rack': item['rack'] ?? '', // Mantener para compatibilidad
            'contenedor': item['contenedor'] ?? item['container'] ?? '', // Mantener para compatibilidad
            'contenedores': contenedores, // Lista de contenedores múltiples
          };
        }).toList(),
      };

      // Llamar al endpoint del servicio Python
      final url = Uri.parse('$_excelServiceUrl/api/generate-jumpers-excel');
      
      http.Response response;
      try {
        response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 30));
      } on http.ClientException catch (e) {
        // Si el servidor de producción no está disponible, intentar con local como fallback
        if (_excelServiceUrl.contains('https://')) {
          print('⚠️ Servidor de producción no disponible, intentando con servidor local...');
          final localUrl = ExcelServiceConfig.localUrl;
          final localUri = Uri.parse('$localUrl/api/generate-jumpers-excel');
          print('🔗 Intentando con URL local: $localUrl');
          try {
            response = await http.post(
              localUri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            ).timeout(const Duration(seconds: 30));
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
          throw Exception(
            'Error al conectar con el servicio de Excel: ${e.toString()}\n\n'
            'Verifica que el servidor esté corriendo o tu conexión a internet.'
          );
        }
      } on Exception catch (e) {
        throw Exception('Error al generar Excel: ${e.toString()}');
      }

      if (response.statusCode != 200) {
        throw Exception('Error al generar Excel: ${response.statusCode} - ${response.body}');
      }

      // Generar nombre por defecto con fecha
      final now = DateTime.now();
      final dateStr = '${now.day.toString().padLeft(2, '0')}_${now.month.toString().padLeft(2, '0')}_${now.year}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final defaultFileName = 'Inventario_Jumpers_$dateStr.xlsx';

      // Para web, descargar directamente
      if (kIsWeb) {
        return downloadFileWeb(response.bodyBytes, defaultFileName);
      }

      // Para móvil/desktop, usar el helper
      return await FileSaverHelper.saveFile(
        fileBytes: response.bodyBytes,
        defaultFileName: defaultFileName,
        dialogTitle: 'Guardar inventario de jumpers como',
      );
    } catch (e) {
      rethrow;
    }
  }
}

