# Solución: Error RLS al Subir PDFs

## Error
```
Error al subir PDF: Exception: Error al subir archivo: new row violates row-level security policy
```

## Causa
Las políticas RLS (Row-Level Security) en Supabase Storage no están configuradas correctamente o el bucket no existe.

## Solución Paso a Paso

### Paso 1: Verificar/Crear el Bucket

1. Ve a tu proyecto en [Supabase Dashboard](https://app.supabase.com)
2. Navega a **Storage** en el menú lateral
3. Verifica si existe el bucket `evidencias-envios`
   - Si NO existe:
     - Haz clic en **New bucket**
     - **Name**: `evidencias-envios`
     - **Public bucket**: ✅ **Marca esta casilla** (MUY IMPORTANTE)
     - Haz clic en **Create bucket**

### Paso 2: Ejecutar el Script SQL de Políticas

1. En Supabase Dashboard, ve a **SQL Editor**
2. Haz clic en **New query**
3. Copia y pega el contenido completo del archivo:
   ```
   scripts_supabase/politicas_rls_storage_evidencias.sql
   ```
4. Haz clic en **Run** (o presiona Ctrl+Enter)
5. Verifica que no haya errores en la ejecución

### Paso 3: Verificar las Políticas

Ejecuta esta consulta para verificar que las políticas se crearon:

```sql
SELECT 
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'storage' 
  AND tablename = 'objects'
  AND policyname LIKE '%evidencias%';
```

Deberías ver 4 políticas:
- Usuarios autenticados pueden subir evidencias (INSERT)
- Usuarios autenticados pueden ver evidencias (SELECT)
- Usuarios autenticados pueden actualizar evidencias (UPDATE)
- Usuarios autenticados pueden eliminar evidencias (DELETE)

### Paso 4: Verificar Autenticación

El código intenta autenticarse automáticamente con un usuario de servicio. Si el error persiste:

1. Verifica que el usuario de servicio existe en la tabla `t_empleados`
2. El email debe ser: `service@telmex.local`
3. La contraseña debe ser: `ServiceAuth2024!`

Si el usuario no existe, créalo ejecutando:

```sql
INSERT INTO public.t_empleados (nombre_usuario, contrasena, activo)
VALUES (
  'service@telmex.local',
  '$2b$10$...', -- Hash bcrypt de 'ServiceAuth2024!'
  true
);
```

**Nota**: Necesitarás generar el hash bcrypt de la contraseña. Puedes usar un generador online o la función bcrypt de tu aplicación.

### Paso 5: Probar la Subida

1. Reinicia la aplicación Flutter
2. Intenta subir un PDF nuevamente
3. Si el error persiste, verifica los logs en la consola de Flutter

## Solución Alternativa: Políticas Más Permisivas (Solo para Desarrollo)

Si necesitas una solución rápida para desarrollo (NO recomendado para producción), puedes crear políticas más permisivas:

```sql
-- ELIMINAR POLÍTICAS EXISTENTES
DROP POLICY IF EXISTS "Usuarios autenticados pueden subir evidencias" ON storage.objects;
DROP POLICY IF EXISTS "Usuarios autenticados pueden ver evidencias" ON storage.objects;
DROP POLICY IF EXISTS "Usuarios autenticados pueden actualizar evidencias" ON storage.objects;
DROP POLICY IF EXISTS "Usuarios autenticados pueden eliminar evidencias" ON storage.objects;

-- POLÍTICAS PERMISIVAS (SOLO DESARROLLO)
CREATE POLICY "Permitir todo para evidencias-envios"
ON storage.objects
FOR ALL
TO authenticated
USING (bucket_id = 'evidencias-envios')
WITH CHECK (bucket_id = 'evidencias-envios');
```

## Verificación Final

Después de ejecutar los pasos anteriores:

1. El bucket `evidencias-envios` existe y es público
2. Las 4 políticas RLS están creadas
3. El usuario de servicio está autenticado
4. La aplicación puede subir archivos sin errores

## Contacto

Si el problema persiste después de seguir estos pasos, verifica:
- Los logs de Supabase Dashboard > Logs > Postgres Logs
- Los logs de la aplicación Flutter
- Que el bucket tenga el nombre exacto: `evidencias-envios` (sin espacios, con guión)

