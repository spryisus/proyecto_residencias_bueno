# Solución: PDFs no se eliminan del Storage

## Problema
Los logs muestran que el archivo se elimina exitosamente (`✅ Archivo eliminado exitosamente`), pero en el dashboard de Supabase el archivo sigue apareciendo.

## Posibles Causas

### 1. Caché del Dashboard de Supabase
El dashboard de Supabase puede tener caché y mostrar archivos que ya fueron eliminados.

**Solución:**
- Refresca el dashboard con `Ctrl+F5` o `Cmd+Shift+R` (forzar recarga)
- Espera unos segundos y vuelve a refrescar
- Cierra y vuelve a abrir el dashboard

### 2. Políticas RLS no configuradas correctamente
Las políticas de seguridad pueden estar bloqueando la eliminación silenciosamente.

**Solución:**
1. Ve a Supabase Dashboard > Storage > Policies
2. Verifica que existe la política de DELETE:
   ```sql
   CREATE POLICY "Usuarios autenticados pueden eliminar evidencias"
   ON storage.objects
   FOR DELETE
   TO authenticated
   USING (
     bucket_id = 'evidencias-envios' AND
     (storage.foldername(name))[1] = 'bitacoras'
   );
   ```

3. Si no existe, ejecuta el script completo:
   ```
   scripts_supabase/politicas_rls_storage_evidencias.sql
   ```

### 3. Verificar que el archivo realmente se eliminó

Ejecuta esta consulta en el SQL Editor de Supabase para verificar:

```sql
SELECT 
  name,
  bucket_id,
  created_at,
  updated_at
FROM storage.objects
WHERE bucket_id = 'evidencias-envios'
  AND name LIKE 'bitacoras/%'
ORDER BY updated_at DESC
LIMIT 20;
```

Si el archivo aparece aquí pero no en el dashboard, es un problema de caché del dashboard.

### 4. Eliminar manualmente desde el Dashboard

Si el archivo realmente no se eliminó:

1. Ve a Storage > evidencias-envios
2. Navega a la carpeta del archivo (ej: `bitacoras/691/`)
3. Haz clic en el archivo
4. Haz clic en "Delete" o el icono de basura
5. Confirma la eliminación

### 5. Verificar autenticación

El código intenta autenticarse automáticamente, pero si falla, la eliminación puede no funcionar.

**Verifica en los logs:**
- Debe aparecer: `🔐 Usuario autenticado: [ID]`
- Si aparece: `⚠️ No se pudo autenticar`, necesitas crear el usuario de servicio

## Verificación en el Código

El código ahora:
1. ✅ Verifica que el archivo existe antes de eliminarlo
2. ✅ Intenta eliminarlo con `remove()`
3. ✅ Espera 1 segundo para que se propague
4. ✅ Verifica que realmente se eliminó
5. ✅ Muestra un error si no se eliminó

## Logs a Revisar

Busca en los logs de Flutter:

```
🗑️ Intentando eliminar PDF: [URL]
🔍 Ruta del archivo a eliminar: [ruta]
✅ Archivo encontrado, procediendo a eliminar...
🔍 Resultado de eliminación: [resultado]
✅ remove() retornó lista vacía (éxito)
🔍 Verificando eliminación en carpeta: [carpeta]
🔍 Archivos encontrados en la carpeta: [lista]
✅ Archivo eliminado y verificado exitosamente
```

Si ves `❌ El archivo sigue existiendo después de intentar eliminarlo`, entonces:
- Las políticas RLS pueden estar bloqueando
- O hay un problema con los permisos del usuario

## Solución Rápida

Si el problema persiste:

1. **Refresca el dashboard** (Ctrl+F5)
2. **Verifica las políticas RLS** en Storage > Policies
3. **Elimina manualmente** desde el dashboard si es necesario
4. **Revisa los logs** de Flutter para ver errores específicos

## Nota sobre Caché

El dashboard de Supabase puede tardar varios segundos o incluso minutos en actualizarse después de eliminar archivos. Esto es normal y no indica que el archivo no se eliminó.

Para verificar realmente, usa la consulta SQL mencionada arriba.

