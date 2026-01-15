import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';

/// Helper para guardar archivos en diferentes plataformas
class FileSaverHelper {
  /// Guarda un archivo en la plataforma correspondiente
  /// 
  /// [fileBytes] Bytes del archivo a guardar
  /// [defaultFileName] Nombre por defecto del archivo
  /// [dialogTitle] Título del diálogo (solo para desktop)
  /// 
  /// Retorna la ruta del archivo guardado o mensaje de descarga
  static Future<String?> saveFile({
    required List<int> fileBytes,
    required String defaultFileName,
    String? dialogTitle,
  }) async {
    // Para web, lanzar error ya que este helper no soporta web
    // Los servicios de exportación deben manejar web directamente
    if (kIsWeb) {
      throw UnsupportedError(
        'FileSaverHelper.saveFile no soporta web. '
        'Los servicios de exportación deben manejar web directamente usando dart:html.'
      );
    }

    // Para móvil (Android/iOS), usar share_plus
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        // Obtener directorio temporal
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$defaultFileName');
        await file.writeAsBytes(fileBytes);
        
        // Compartir el archivo usando share_plus
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: defaultFileName,
        );
        
        // Retornar la ruta del archivo temporal
        // Nota: El archivo se guardará en la ubicación que el usuario elija
        return file.path;
      } catch (e) {
        // Si share falla, intentar guardar en Downloads (Android)
        if (Platform.isAndroid) {
          try {
            // Intentar obtener el directorio de descargas
            Directory? downloadsDir;
            // Para Android, intentar acceder a Downloads
            final externalDir = await getExternalStorageDirectory();
            if (externalDir != null) {
              downloadsDir = Directory('${externalDir.path}/../Download');
              if (!await downloadsDir.exists()) {
                downloadsDir = Directory('${externalDir.path}/Downloads');
              }
            }
            
            if (downloadsDir != null && await downloadsDir.exists()) {
              final file = File('${downloadsDir.path}/$defaultFileName');
              await file.writeAsBytes(fileBytes);
              return file.path;
            }
          } catch (_) {
            // Si falla, usar el directorio temporal
            final tempDir = await getTemporaryDirectory();
            final file = File('${tempDir.path}/$defaultFileName');
            await file.writeAsBytes(fileBytes);
            return file.path;
          }
        }
        
        // Para iOS o si todo falla, usar directorio temporal
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$defaultFileName');
        await file.writeAsBytes(fileBytes);
        return file.path;
      }
    }

    // Para desktop (Windows, Linux, macOS), usar FilePicker
    String? filePath = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle ?? 'Guardar archivo',
      fileName: defaultFileName,
      type: FileType.custom,
      allowedExtensions: [defaultFileName.split('.').last],
    );

    if (filePath == null) {
      return null; // Usuario canceló
    }

    // Asegurar que el archivo tenga la extensión correcta
    final extension = defaultFileName.split('.').last;
    if (!filePath.endsWith('.$extension')) {
      filePath = '$filePath.$extension';
    }

    // Guardar el archivo
    final file = File(filePath);
    await file.writeAsBytes(fileBytes);

    return filePath;
  }

  /// Abre un archivo usando la aplicación predeterminada
  /// 
  /// [filePath] Ruta del archivo a abrir
  static Future<void> openFile(String filePath) async {
    if (kIsWeb) {
      // En web no se puede abrir archivos directamente
      return;
    }

    if (Platform.isAndroid || Platform.isIOS) {
      // En móvil, usar open_filex
      await OpenFilex.open(filePath);
    } else {
      // En desktop, ya se maneja en el código que llama a esta función
      // (usando Process.run)
      return;
    }
  }
}

