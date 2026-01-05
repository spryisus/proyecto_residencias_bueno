import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../../app/config/excel_service_config.dart';
import '../../core/utils/file_saver_helper.dart';
import '../../core/utils/web_file_helper.dart' if (dart.library.io) '../../core/utils/web_file_helper_stub.dart';

/// Servicio para exportar datos de tarjetas de red (SICOR) a Excel
class SicorExportService {
  /// Obtiene la URL del servicio según la plataforma (web/móvil)
  static String get _excelServiceUrl => ExcelServiceConfig.getServiceUrl();
  
  /// Exporta datos de tarjetas de red a Excel
  /// 
  /// [items] Lista de tarjetas de red con los campos: en_stock, numero, codigo, serie, marca, posicion, comentarios
  /// 
  /// Retorna la ruta del archivo guardado o mensaje de descarga
  static Future<String?> exportSicorToExcel(List<Map<String, dynamic>> items) async {
    try {
      if (items.isEmpty) {
        throw Exception('No hay datos para exportar');
      }

      // Preparar los datos para el endpoint según la plantilla
      // Los datos empiezan en B5 (columna B, fila 5)
      final payload = {
        'items': items.map((item) => {
          'en_stock': item['en_stock'] ?? 'SI',
          'numero': item['numero'] ?? '',
          'codigo': item['codigo'] ?? '',
          'serie': item['serie'] ?? '',
          'marca': item['marca'] ?? '',
          'posicion': item['posicion'] ?? '',
          'comentarios': item['comentarios'] ?? '',
        }).toList(),
      };

      // Llamar al endpoint del servicio Python
      final url = Uri.parse('$_excelServiceUrl/api/generate-sicor-excel');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al generar Excel: ${response.statusCode} - ${response.body}');
      }

      // Generar nombre por defecto con fecha
      final now = DateTime.now();
      final dateStr = '${now.day.toString().padLeft(2, '0')}_${now.month.toString().padLeft(2, '0')}_${now.year}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final defaultFileName = 'Inventario_SICOR_$dateStr.xlsx';

      // Para web, descargar directamente
      if (kIsWeb) {
        return downloadFileWeb(response.bodyBytes, defaultFileName);
      }

      // Para móvil/desktop, usar el helper
      return await FileSaverHelper.saveFile(
        fileBytes: response.bodyBytes,
        defaultFileName: defaultFileName,
        dialogTitle: 'Guardar inventario de SICOR como',
      );
    } catch (e) {
      rethrow;
    }
  }
}





