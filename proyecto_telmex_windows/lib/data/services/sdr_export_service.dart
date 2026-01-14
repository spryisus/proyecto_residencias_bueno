import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:excel/excel.dart';
import '../../app/config/excel_service_config.dart';
import '../../core/utils/file_saver_helper.dart';
import '../../core/utils/web_file_helper.dart' if (dart.library.io) '../../core/utils/web_file_helper_stub.dart';

/// Servicio para exportar datos SDR a Excel usando la plantilla
class SdrExportService {
  /// Obtiene la URL del servicio según la plataforma (web/móvil)
  static String get _excelServiceUrl => ExcelServiceConfig.getServiceUrl();
  
  /// Exporta datos SDR a Excel usando la plantilla
  /// 
  /// [items] Lista de items SDR con los siguientes campos:
  /// - codigo: Código del item
  /// - descripcion: Descripción del item
  /// - cantidad: Cantidad
  /// - ubicacion: Ubicación
  /// - fecha: Fecha (formato string)
  /// - observaciones: Observaciones adicionales
  /// 
  /// Retorna la ruta del archivo guardado o null si se canceló
  static Future<String?> exportSdrToExcel(List<Map<String, dynamic>> items) async {
    try {
      if (items.isEmpty) {
        throw Exception('No hay datos para exportar');
      }

      // Preparar los datos para el endpoint
      // La plantilla SDR espera un solo formulario con todos los campos
      final payload = {
        'items': items.map((item) => {
          // Datos de Falla de aviso
          'fecha': item['fecha'] ?? item['date'] ?? '',
          'descripcion_aviso': item['descripcion_aviso'] ?? item['descripcion_del_aviso'] ?? '',
          'grupo_planificador': item['grupo_planificador'] ?? '',
          'puesto_trabajo_responsable': item['puesto_trabajo_responsable'] ?? '',
          'autor_aviso': item['autor_aviso'] ?? '',
          'motivo_intervencion': item['motivo_intervencion'] ?? '',
          'modelo_dano': item['modelo_dano'] ?? item['modelo_del_dano'] ?? '',
          'causa_averia': item['causa_averia'] ?? '',
          'repercusion_funcionamiento': item['repercusion_funcionamiento'] ?? '',
          'estado_instalacion': item['estado_instalacion'] ?? '',
          'motivo_intervencion_afectacion': item['motivo_intervencion_afectacion'] ?? '',
          'atencion_dano': item['atencion_dano'] ?? '',
          'prioridad': item['prioridad'] ?? '',
          
          // Lugar del Daño
          'centro_emplazamiento': item['centro_emplazamiento'] ?? '',
          'area_empresa': item['area_empresa'] ?? '',
          'puesto_trabajo_emplazamiento': item['puesto_trabajo_emplazamiento'] ?? '',
          'division': item['division'] ?? '',
          'estado_instalacion_lugar': item['estado_instalacion_lugar'] ?? '',
          'datos_disponibles': item['datos_disponibles'] ?? '',
          'emplazamiento_1': item['emplazamiento_1'] ?? item['emplazamiento'] ?? '',
          'emplazamiento_2': item['emplazamiento_2'] ?? item['emplazamiento'] ?? '',
          'local': item['local'] ?? '',
          'campo_clasificacion': item['campo_clasificacion'] ?? '',
          
          // Datos de la unidad Dañada
          'tipo_unidad_danada': item['tipo_unidad_danada'] ?? '',
          'no_serie_unidad_danada': item['no_serie_unidad_danada'] ?? '',
          
          // Datos de la unidad que se montó
          'tipo_unidad_montada': item['tipo_unidad_montada'] ?? '',
          'no_serie_unidad_montada': item['no_serie_unidad_montada'] ?? '',
        }).toList(),
      };

      // Llamar al endpoint del servicio Python
      final url = Uri.parse('$_excelServiceUrl/api/generate-sdr-excel');
      
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
          final localUri = Uri.parse('$localUrl/api/generate-sdr-excel');
          print('🔗 Intentando con URL local: $localUrl');
          try {
            response = await http.post(
              localUri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            ).timeout(const Duration(seconds: 30));
          } catch (e2) {
            // Si ambos fallan, usar método local con plantilla
            if (e2.toString().contains('Connection refused') || 
                e2.toString().contains('Failed host lookup')) {
              return await _exportSdrToExcelLocal(items);
            }
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
          // Si es local y falla, intentar método local con plantilla
          if (e.toString().contains('Connection refused') || 
              e.toString().contains('Failed host lookup')) {
            return await _exportSdrToExcelLocal(items);
          }
          throw Exception(
            'Error al conectar con el servicio de Excel: ${e.toString()}\n\n'
            'Verifica que el servidor esté corriendo o tu conexión a internet.'
          );
        }
      } on Exception catch (e) {
        // Si es error de conexión, intentar método local
        if (e.toString().contains('Connection refused') || 
            e.toString().contains('Failed host lookup')) {
          return await _exportSdrToExcelLocal(items);
        }
        throw Exception('Error al generar Excel: ${e.toString()}');
      }

      if (response.statusCode != 200) {
        throw Exception('Error al generar Excel: ${response.statusCode} - ${response.body}');
      }

      // Generar nombre por defecto con fecha
      final now = DateTime.now();
      final dateStr = '${now.day.toString().padLeft(2, '0')}_${now.month.toString().padLeft(2, '0')}_${now.year}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final defaultFileName = 'Solicitud_SDR_$dateStr.xlsx';

      // Para web, descargar directamente
      if (kIsWeb) {
        return downloadFileWeb(response.bodyBytes, defaultFileName);
      }

      // Para móvil/desktop, usar el helper
      return await FileSaverHelper.saveFile(
        fileBytes: response.bodyBytes,
        defaultFileName: defaultFileName,
        dialogTitle: 'Guardar solicitud SDR como',
      );
    } catch (e) {
      // Si el servicio Python no está disponible, usar método alternativo con plantilla local
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('Failed host lookup')) {
        return await _exportSdrToExcelLocal(items);
      }
      rethrow;
    }
  }

  /// Método alternativo que carga la plantilla desde assets y genera el Excel localmente
  static Future<String?> _exportSdrToExcelLocal(List<Map<String, dynamic>> items) async {
    try {
      // Cargar la plantilla desde assets
      final ByteData data = await rootBundle.load('assets/plantilla_SDR.xlsx');
      final bytes = data.buffer.asUint8List();
      
      // Crear Excel desde los bytes de la plantilla
      var excel = Excel.decodeBytes(bytes);
      
      // Obtener la primera hoja (o la hoja activa)
      final sheetName = excel.tables.keys.first;
      final sheet = excel[sheetName];
      
      // Mapear campos a las filas correspondientes de la plantilla
      // Tomar el primer item (ya que es un formulario único)
      final item = items.isNotEmpty ? items[0] : <String, dynamic>{};
      
      // Datos de Falla de aviso (columna B, filas 9-22)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 8))
          .value = TextCellValue(item['fecha'] ?? item['date'] ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 9))
          .value = TextCellValue(item['descripcion_aviso'] ?? item['descripcion_del_aviso'] ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 10))
          .value = TextCellValue(item['grupo_planificador'] ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 11))
          .value = TextCellValue(item['puesto_trabajo_responsable'] ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 12))
          .value = TextCellValue(item['autor_aviso'] ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 13))
          .value = TextCellValue(item['motivo_intervencion'] ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 14))
          .value = TextCellValue(item['modelo_dano'] ?? item['modelo_del_dano'] ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 15))
          .value = TextCellValue(item['causa_averia'] ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 16))
          .value = TextCellValue(item['repercusion_funcionamiento'] ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 17))
          .value = TextCellValue(item['estado_instalacion'] ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 18))
          .value = TextCellValue(item['motivo_intervencion_afectacion'] ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 20))
          .value = TextCellValue(item['atencion_dano'] ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 21))
          .value = TextCellValue(item['prioridad'] ?? '');
      
      // Lugar del Daño (columna B, filas 25-35)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 24))
          .value = TextCellValue(item['centro_emplazamiento'] ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 25))
          .value = TextCellValue(item['area_empresa'] ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 26))
          .value = TextCellValue(item['puesto_trabajo_emplazamiento'] ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 27))
          .value = TextCellValue(item['division'] ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 28))
          .value = TextCellValue(item['estado_instalacion_lugar'] ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 29))
          .value = TextCellValue(item['datos_disponibles'] ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 31))
          .value = TextCellValue(item['emplazamiento_1'] ?? item['emplazamiento'] ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 32))
          .value = TextCellValue(item['emplazamiento_2'] ?? item['emplazamiento'] ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 33))
          .value = TextCellValue(item['local'] ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 34))
          .value = TextCellValue(item['campo_clasificacion'] ?? '');
      
      // Datos de la unidad Dañada (columna B, filas 38-39)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 37))
          .value = TextCellValue(item['tipo_unidad_danada'] ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 38))
          .value = TextCellValue(item['no_serie_unidad_danada'] ?? '');
      
      // Datos de la unidad que se montó (columna B, filas 42-43)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 41))
          .value = TextCellValue(item['tipo_unidad_montada'] ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 42))
          .value = TextCellValue(item['no_serie_unidad_montada'] ?? '');

      // Generar nombre por defecto
      final now = DateTime.now();
      final dateStr = '${now.day.toString().padLeft(2, '0')}_${now.month.toString().padLeft(2, '0')}_${now.year}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final defaultFileName = 'Solicitud_SDR_$dateStr.xlsx';

      final fileBytes = excel.save();
      if (fileBytes == null) {
        throw Exception('Error al generar el archivo Excel');
      }

      // Para web, descargar directamente
      if (kIsWeb) {
        return downloadFileWeb(fileBytes, defaultFileName);
      }

      // Para móvil/desktop, usar el helper
      return await FileSaverHelper.saveFile(
        fileBytes: fileBytes,
        defaultFileName: defaultFileName,
        dialogTitle: 'Guardar solicitud SDR como',
      );
    } catch (e) {
      throw Exception('Error al exportar SDR a Excel: $e');
    }
  }

  /// Obtiene información sobre la configuración del servicio
  static Map<String, dynamic> getServiceInfo() {
    return ExcelServiceConfig.getConfigInfo();
  }
}

