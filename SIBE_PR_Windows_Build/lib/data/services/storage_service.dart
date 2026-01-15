import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/config/supabase_client.dart';

/// Servicio para manejar la subida de archivos a Supabase Storage
class StorageService {
  static const String _bucketName = 'evidencias-envios';
  
  /// Sube un archivo PDF a Supabase Storage
  /// 
  /// [file] - El archivo a subir
  /// [bitacoraId] - ID de la bitácora para organizar los archivos
  /// 
  /// Retorna la URL pública del archivo subido
  /// Lanza una excepción si hay algún error
  Future<String> uploadPdfFile(File file, int bitacoraId) async {
    // Validar que el archivo sea PDF
    final fileName = file.path.split('/').last;
    if (!fileName.toLowerCase().endsWith('.pdf')) {
      throw Exception('Solo se permiten archivos PDF');
    }

    // Validar tamaño del archivo (50 MB máximo)
    final fileSize = await file.length();
    const maxSize = 50 * 1024 * 1024; // 50 MB en bytes
    if (fileSize > maxSize) {
      throw Exception('El archivo es demasiado grande. Máximo 50 MB');
    }

    // Usar el nombre original del archivo, pero asegurar que sea único
    final originalFileName = file.path.split('/').last;
    final baseFileName = originalFileName.toLowerCase().endsWith('.pdf')
        ? originalFileName.substring(0, originalFileName.length - 4)
        : originalFileName;
    
    // Limpiar el nombre del archivo (remover caracteres especiales que puedan causar problemas)
    final cleanFileName = baseFileName
        .replaceAll(RegExp(r'[^\w\-_\.]'), '_')
        .substring(0, baseFileName.length > 50 ? 50 : baseFileName.length);
    
    // Agregar timestamp para hacerlo único y mantener la extensión .pdf
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uniqueFileName = '${cleanFileName}_$timestamp.pdf';

    // Ruta en el bucket: bitacoras/{bitacoraId}/{nombre_archivo}
    final filePath = 'bitacoras/$bitacoraId/$uniqueFileName';

    // Leer el archivo como bytes
    final fileBytes = await file.readAsBytes();

    try {
      // Intentar subir sin autenticación primero (si las políticas RLS permiten acceso anónimo)
      await supabaseClient.storage.from(_bucketName).uploadBinary(
        filePath,
        fileBytes,
        fileOptions: const FileOptions(
          contentType: 'application/pdf',
          upsert: false, // No sobrescribir si existe
        ),
      );

      // Obtener la URL pública del archivo
      final publicUrl = supabaseClient.storage
          .from(_bucketName)
          .getPublicUrl(filePath);

      return publicUrl;
    } on StorageException catch (e) {
      // Si falla por RLS, intentar autenticarse y volver a intentar
      if (e.message.contains('row-level security') || 
          e.message.contains('permission denied') ||
          e.message.contains('JWT') ||
          e.message.contains('Unauthorized')) {
        debugPrint('⚠️ Error de permisos, intentando autenticarse...');
        
        try {
          // Intentar autenticar con usuario de servicio
          final currentUser = supabaseClient.auth.currentUser;
          if (currentUser == null) {
            const serviceEmail = 'service@telmex.local';
            const servicePassword = 'ServiceAuth2024!';
            
            try {
              await supabaseClient.auth.signInWithPassword(
                email: serviceEmail,
                password: servicePassword,
              );
              debugPrint('✅ Autenticación exitosa con usuario de servicio');
            } catch (authError) {
              debugPrint('❌ Error al autenticar: $authError');
              // Si falla la autenticación, sugerir usar políticas anónimas
              throw Exception(
                'Error de permisos al subir PDF.\n\n'
                'Solución 1 (Recomendada): Ejecuta el script SQL para permitir acceso anónimo:\n'
                'scripts_supabase/politicas_rls_storage_anonimas.sql\n\n'
                'Solución 2: Crea el usuario de servicio en Supabase Auth:\n'
                'Email: service@telmex.local\n'
                'Password: ServiceAuth2024!\n\n'
                'Error de autenticación: $authError'
              );
            }
          }

          // Intentar subir nuevamente después de autenticarse
          await supabaseClient.storage.from(_bucketName).uploadBinary(
            filePath,
            fileBytes,
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              upsert: false,
            ),
          );

          // Obtener la URL pública del archivo
          final publicUrl = supabaseClient.storage
              .from(_bucketName)
              .getPublicUrl(filePath);

          return publicUrl;
        } catch (retryError) {
          throw Exception(
            'Error al subir archivo después de autenticarse: $retryError\n\n'
            'Por favor ejecuta el script SQL: scripts_supabase/politicas_rls_storage_anonimas.sql'
          );
        }
      }
      throw Exception('Error al subir archivo: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al subir PDF: $e');
    }
  }

  /// Elimina un archivo del storage
  /// 
  /// [fileUrl] - URL del archivo a eliminar
  Future<void> deleteFile(String fileUrl) async {
    // Extraer la ruta del archivo de la URL
    final uri = Uri.parse(fileUrl);
    final pathSegments = uri.pathSegments;
    
    debugPrint('🔍 URL completa: $fileUrl');
    debugPrint('🔍 Path segments: $pathSegments');
    
    // Buscar el índice de 'bitacoras' en la ruta
    final bitacorasIndex = pathSegments.indexWhere((s) => s == 'bitacoras');
    if (bitacorasIndex == -1) {
      // Si no encuentra 'bitacoras', intentar buscar desde 'evidencias-envios' o directamente el archivo
      // La estructura puede ser: storage/v1/object/public/evidencias-envios/bitacoras/...
      final evidenciasIndex = pathSegments.indexWhere((s) => s == 'evidencias-envios');
      if (evidenciasIndex != -1 && evidenciasIndex + 1 < pathSegments.length) {
        // Buscar 'bitacoras' después de 'evidencias-envios'
        final searchStart = evidenciasIndex + 1;
        final bitacorasIdx = pathSegments.indexWhere(
          (s) => s == 'bitacoras',
          searchStart,
        );
        if (bitacorasIdx != -1) {
          final filePath = pathSegments.sublist(bitacorasIdx).join('/');
          debugPrint('🔍 Ruta del archivo a eliminar: $filePath');
          try {
            await supabaseClient.storage.from(_bucketName).remove([filePath]);
            return;
          } on StorageException catch (e) {
            if (e.message.contains('row-level security') || 
                e.message.contains('permission denied') ||
                e.message.contains('JWT') ||
                e.message.contains('Unauthorized')) {
              await _tryAuthenticateAndRetry(() => 
                supabaseClient.storage.from(_bucketName).remove([filePath]));
              return;
            }
            rethrow;
          }
        }
      }
      throw Exception('URL de archivo inválida: no se encontró la ruta "bitacoras"');
    }

    // Reconstruir la ruta: bitacoras/{bitacoraId}/{nombre_archivo}
    final filePath = pathSegments.sublist(bitacorasIndex).join('/');
    debugPrint('🔍 Ruta del archivo a eliminar: $filePath');

    try {
      // Intentar eliminar sin autenticación primero
      await supabaseClient.storage.from(_bucketName).remove([filePath]);
      debugPrint('✅ Archivo eliminado exitosamente');
      return;
    } on StorageException catch (e) {
      // Si falla por RLS, intentar autenticarse y volver a intentar
      if (e.message.contains('row-level security') || 
          e.message.contains('permission denied') ||
          e.message.contains('JWT') ||
          e.message.contains('Unauthorized')) {
        debugPrint('⚠️ Error de permisos, intentando autenticarse...');
        
        try {
          await _tryAuthenticateAndRetry(() => 
            supabaseClient.storage.from(_bucketName).remove([filePath]));
          debugPrint('✅ Archivo eliminado exitosamente después de autenticarse');
          return;
        } catch (retryError) {
          throw Exception(
            'Error al eliminar archivo después de autenticarse: $retryError\n\n'
            'Por favor ejecuta el script SQL: scripts_supabase/politicas_rls_storage_anonimas.sql'
          );
        }
      }
      throw Exception('Error al eliminar archivo: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al eliminar archivo: $e');
    }
  }

  /// Intenta autenticarse y ejecutar una operación de storage
  Future<void> _tryAuthenticateAndRetry(Future<void> Function() operation) async {
    final currentUser = supabaseClient.auth.currentUser;
    if (currentUser == null) {
      const serviceEmail = 'service@telmex.local';
      const servicePassword = 'ServiceAuth2024!';
      
      try {
        await supabaseClient.auth.signInWithPassword(
          email: serviceEmail,
          password: servicePassword,
        );
        debugPrint('✅ Autenticación exitosa con usuario de servicio');
      } catch (authError) {
        debugPrint('❌ Error al autenticar: $authError');
        throw Exception(
          'Error de permisos.\n\n'
          'Solución 1 (Recomendada): Ejecuta el script SQL para permitir acceso anónimo:\n'
          'scripts_supabase/politicas_rls_storage_anonimas.sql\n\n'
          'Solución 2: Crea el usuario de servicio en Supabase Auth:\n'
          'Email: service@telmex.local\n'
          'Password: ServiceAuth2024!\n\n'
          'Error de autenticación: $authError'
        );
      }
    }
    
    // Ejecutar la operación después de autenticarse
    await operation();
  }

  /// Verifica si el bucket existe, si no, lo crea
  /// 
  /// NOTA: Esto debe ejecutarse manualmente en Supabase Dashboard
  /// Storage > New bucket > Name: evidencias-envios > Public: true
  static Future<void> ensureBucketExists() async {
    try {
      // Intentar listar archivos del bucket para verificar que existe
      await supabaseClient.storage.from(_bucketName).list();
    } catch (e) {
      throw Exception(
        'El bucket "$_bucketName" no existe. '
        'Por favor créalo en Supabase Dashboard: '
        'Storage > New bucket > Name: $_bucketName > Public: true'
      );
    }
  }
}
