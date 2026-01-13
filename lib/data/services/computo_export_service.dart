import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../../app/config/excel_service_config.dart';
import '../../core/utils/file_saver_helper.dart';
import '../../core/utils/web_file_helper.dart' if (dart.library.io) '../../core/utils/web_file_helper_stub.dart';

/// Servicio para exportar datos de equipos de cómputo a Excel
class ComputoExportService {
  /// Obtiene la URL del servicio según la plataforma (web/móvil)
  static String get _excelServiceUrl => ExcelServiceConfig.getServiceUrl();
  
  /// Exporta datos de equipos de cómputo a Excel
  /// 
  /// [items] Lista de equipos de cómputo con todos los campos del esquema SQL
  /// 
  /// Retorna la ruta del archivo guardado o mensaje de descarga
  static Future<String?> exportComputoToExcel(List<Map<String, dynamic>> items) async {
    try {
      if (items.isEmpty) {
        throw Exception('No hay datos para exportar');
      }

      // Preparar los datos para el endpoint según la plantilla
      // Los items ya vienen con todos los campos necesarios (equipo principal + accesorios)
      final payload = {
        'items': items.map((item) => {
          'id': item['id'],
          'inventario': item['inventario'] ?? '',
          'equipo_pm': item['equipo_pm'] ?? '',
          'fecha_registro': item['fecha_registro'] ?? '',
          'tipo_equipo': item['tipo_equipo'] ?? '',
          'marca': item['marca'] ?? '',
          'modelo': item['modelo'] ?? '',
          'procesador': item['procesador'] ?? '',
          'numero_serie': item['numero_serie'] ?? '',
          'disco_duro': item['disco_duro'] ?? '',
          'memoria': item['memoria'] ?? '',
          'sistema_operativo_instalado': item['sistema_operativo_instalado'] ?? item['sistema_operativo'] ?? '',
          'etiqueta_sistema_operativo': item['etiqueta_sistema_operativo'] ?? '',
          'office_instalado': item['office_instalado'] ?? '',
          'direccion_fisica': item['direccion_fisica'] ?? item['ubicacion_fisica'] ?? '',
          'estado': item['estado'] ?? item['estado_ubicacion'] ?? '',
          'ciudad': item['ciudad'] ?? '',
          'tipo_edificio': item['tipo_edificio'] ?? '',
          'nombre_edificio': item['nombre_edificio'] ?? '',
          'tipo_uso': item['tipo_uso'] ?? '',
          'nombre_equipo_dominio': item['nombre_equipo_dominio'] ?? '',
          'status': item['status'] ?? '',
          'direccion_administrativa': item['direccion_administrativa'] ?? '',
          'subdireccion': item['subdireccion'] ?? '',
          'gerencia': item['gerencia'] ?? '',
          // Usuario Final
          'expediente_final': item['expediente_final'] ?? '',
          'nombre_completo_final': item['nombre_completo_final'] ?? item['empleado_asignado_nombre'] ?? '',
          'apellido_paterno_final': item['apellido_paterno_final'] ?? '',
          'apellido_materno_final': item['apellido_materno_final'] ?? '',
          'nombre_final': item['nombre_final'] ?? '',
          'empresa_final': item['empresa_final'] ?? '',
          'puesto_final': item['puesto_final'] ?? '',
          // Usuario Responsable
          'expediente_responsable': item['expediente_responsable'] ?? '',
          'nombre_completo_responsable': item['nombre_completo_responsable'] ?? '',
          'apellido_paterno_responsable': item['apellido_paterno_responsable'] ?? '',
          'apellido_materno_responsable': item['apellido_materno_responsable'] ?? '',
          'nombre_responsable': item['nombre_responsable'] ?? '',
          'empresa_responsable': item['empresa_responsable'] ?? '',
          'puesto_responsable': item['puesto_responsable'] ?? '',
          'observaciones': item['observaciones'] ?? '',
        }).toList(),
      };

      // Llamar al endpoint del servicio Python
      final url = Uri.parse('$_excelServiceUrl/api/generate-computo-excel');
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
      final defaultFileName = 'Inventario_Computo_$dateStr.xlsx';

      // Para web, descargar directamente
      if (kIsWeb) {
        return downloadFileWeb(response.bodyBytes, defaultFileName);
      }

      // Para móvil/desktop, usar el helper
      return await FileSaverHelper.saveFile(
        fileBytes: response.bodyBytes,
        defaultFileName: defaultFileName,
        dialogTitle: 'Guardar inventario de cómputo como',
      );
    } catch (e) {
      rethrow;
    }
  }
}

