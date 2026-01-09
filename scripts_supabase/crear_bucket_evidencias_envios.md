# Configuración del Bucket de Storage para Evidencias de Envíos

Este documento explica cómo configurar el bucket de Supabase Storage para almacenar los archivos PDF de evidencia de envíos.

## Pasos para crear el bucket

1. **Accede al Dashboard de Supabase**
   - Ve a tu proyecto en [Supabase Dashboard](https://app.supabase.com)
   - Selecciona tu proyecto

2. **Crear el bucket**
   - Ve a la sección **Storage** en el menú lateral
   - Haz clic en **New bucket**
   - Configuración:
     - **Name**: `evidencias-envios`
     - **Public bucket**: ✅ **Activado** (marca esta opción para que los archivos sean accesibles públicamente)
   - Haz clic en **Create bucket**

3. **Configurar políticas de seguridad (RLS)**
   - Una vez creado el bucket, haz clic en él
   - Ve a la pestaña **Policies**
   - Crea las siguientes políticas:

### Política para INSERT (subir archivos)
```sql
CREATE POLICY "Usuarios autenticados pueden subir evidencias"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'evidencias-envios' AND
  (storage.foldername(name))[1] = 'bitacoras'
);
```

### Política para SELECT (descargar/ver archivos)
```sql
CREATE POLICY "Usuarios autenticados pueden ver evidencias"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'evidencias-envios' AND
  (storage.foldername(name))[1] = 'bitacoras'
);
```

### Política para UPDATE (actualizar archivos)
```sql
CREATE POLICY "Usuarios autenticados pueden actualizar evidencias"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'evidencias-envios' AND
  (storage.foldername(name))[1] = 'bitacoras'
);
```

### Política para DELETE (eliminar archivos)
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

## Estructura de archivos

Los archivos se organizarán de la siguiente manera:
```
evidencias-envios/
  └── bitacoras/
      └── {id_bitacora}/
          └── bitacora_{id_bitacora}_{timestamp}.pdf
```

## Límites del plan gratuito

- **Tamaño máximo por archivo**: 50 MB
- **Almacenamiento total**: 1 GB
- **Transferencia**: 2 GB/mes

## Notas importantes

- Los archivos PDF se suben automáticamente cuando se guarda o edita una bitácora
- Si el archivo es mayor a 50 MB, se mostrará un error
- Solo se permiten archivos con extensión `.pdf`
- La URL del archivo se guarda automáticamente en el campo `anexos` de la tabla `t_bitacora_envios`

