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
    try {
      // Verificar autenticación antes de subir
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        // Intentar autenticar con usuario de servicio
        try {
          const serviceEmail = 'service@telmex.local';
          const servicePassword = 'ServiceAuth2024!';
          
          await supabaseClient.auth.signInWithPassword(
            email: serviceEmail,
            password: servicePassword,
          );
        } catch (authError) {
          throw Exception(
            'No se pudo autenticar. Por favor, inicia sesión primero. '
            'Error: $authError'
          );
        }
      }

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

      // Subir el archivo a Supabase Storage
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
      if (e.message.contains('row-level security')) {
        throw Exception(
          'Error de permisos: Las políticas RLS no están configuradas correctamente. '
          'Por favor ejecuta el script SQL: scripts_supabase/politicas_rls_storage_evidencias.sql'
        );
      }
      throw Exception('Error al subir archivo: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  /// Elimina un archivo del storage
  /// 
  /// [fileUrl] - URL del archivo a eliminar
  Future<void> deleteFile(String fileUrl) async {
    try {
      // Verificar autenticación antes de eliminar
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        // Intentar autenticar con usuario de servicio
        try {
          const serviceEmail = 'service@telmex.local';
          const servicePassword = 'ServiceAuth2024!';
          
          await supabaseClient.auth.signInWithPassword(
            email: serviceEmail,
            password: servicePassword,
          );
        } catch (authError) {
          throw Exception(
            'No se pudo autenticar. Por favor, inicia sesión primero. '
            'Error: $authError'
          );
        }
      }

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
            await supabaseClient.storage.from(_bucketName).remove([filePath]);
            return;
          }
        }
        throw Exception('URL de archivo inválida: no se encontró la ruta "bitacoras"');
      }

      // Reconstruir la ruta: bitacoras/{bitacoraId}/{nombre_archivo}
      final filePath = pathSegments.sublist(bitacorasIndex).join('/');
      debugPrint('🔍 Ruta del archivo a eliminar: $filePath');

      // Verificar que el archivo existe antes de eliminarlo
      try {
        final files = await supabaseClient.storage
            .from(_bucketName)
            .list(path: filePath.substring(0, filePath.lastIndexOf('/')));
        
        final fileName = filePath.split('/').last;
        final fileExists = files.any((file) => file.name == fileName);
        
        if (!fileExists) {
          debugPrint('⚠️ El archivo no existe en el storage (puede que ya haya sido eliminado)');
          return; // No es un error si ya no existe
        }
        
        debugPrint('✅ Archivo encontrado, procediendo a eliminar...');
      } catch (e) {
        debugPrint('⚠️ No se pudo verificar si el archivo existe: $e');
        // Continuar con la eliminación de todas formas
      }

      // Eliminar el archivo usando el método remove
      // Nota: remove() retorna una lista vacía si tiene éxito
      try {
        debugPrint('🗑️ Llamando a remove() con ruta: $filePath');
        final result = await supabaseClient.storage.from(_bucketName).remove([filePath]);
        debugPrint('🔍 Resultado de eliminación (tipo: ${result.runtimeType}): $result');
        
        // Verificar el resultado (remove() retorna List<String>)
        if (result.isEmpty) {
          debugPrint('✅ remove() retornó lista vacía (éxito esperado)');
        } else {
          debugPrint('⚠️ remove() retornó datos inesperados: $result');
        }
      } catch (removeError) {
        debugPrint('❌ Error en remove(): $removeError');
        debugPrint('❌ Tipo de error: ${removeError.runtimeType}');
        rethrow; // Re-lanzar el error para que se maneje arriba
      }
      
      // Verificar que realmente se eliminó (esperar un poco para que se propague)
      debugPrint('⏳ Esperando 1 segundo para que se propague la eliminación...');
      await Future.delayed(const Duration(milliseconds: 1000));
      
      try {
        final folderPath = filePath.substring(0, filePath.lastIndexOf('/'));
        final fileName = filePath.split('/').last;
        
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('🔍 VERIFICANDO ELIMINACIÓN');
        debugPrint('🔍 Carpeta: $folderPath');
        debugPrint('🔍 Archivo buscado: $fileName');
        debugPrint('═══════════════════════════════════════════════════════');
        
        final files = await supabaseClient.storage
            .from(_bucketName)
            .list(path: folderPath);
        
        debugPrint('📋 Total de archivos en la carpeta: ${files.length}');
        debugPrint('📋 Archivos encontrados: ${files.map((f) => f.name).join(", ")}');
        
        final stillExists = files.any((file) => file.name == fileName);
        
        if (stillExists) {
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('❌ ERROR: El archivo SIGUE EXISTIENDO después de eliminarlo');
          debugPrint('❌ Ruta: $filePath');
          debugPrint('❌ Nombre: $fileName');
          debugPrint('═══════════════════════════════════════════════════════');
          throw Exception(
            'El archivo no se eliminó correctamente del storage. '
            'El método remove() no lanzó error, pero el archivo sigue existiendo. '
            'Esto puede indicar un problema con las políticas RLS de DELETE. '
            'Verifica en Supabase Dashboard > Storage > Policies que la política de DELETE esté activa.'
          );
        }
        
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('✅ VERIFICACIÓN EXITOSA: Archivo eliminado correctamente');
        debugPrint('✅ El archivo ya no existe en el storage');
        debugPrint('═══════════════════════════════════════════════════════');
      } catch (e) {
        // Si es el error que lanzamos nosotros, re-lanzarlo
        if (e.toString().contains('no se eliminó correctamente')) {
          rethrow;
        }
        debugPrint('⚠️ No se pudo verificar la eliminación: $e');
        // Aún así consideramos que se eliminó si no hubo excepción en remove()
        // pero advertimos al usuario
        debugPrint('⚠️ ADVERTENCIA: No se pudo verificar que el archivo se eliminó. '
            'Puede que el dashboard de Supabase tenga caché. '
            'Intenta refrescar el dashboard manualmente.');
      }
    } on StorageException catch (e) {
      if (e.message.contains('row-level security')) {
        throw Exception(
          'Error de permisos: Las políticas RLS no están configuradas correctamente. '
          'Por favor ejecuta el script SQL: scripts_supabase/politicas_rls_storage_evidencias.sql'
        );
      }
      throw Exception('Error al eliminar archivo: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al eliminar archivo: $e');
    }
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

