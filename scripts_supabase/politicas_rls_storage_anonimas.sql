-- ============================================
-- POLÍTICAS RLS PARA STORAGE: ACCESO ANÓNIMO
-- ============================================
-- 
-- Este script configura las políticas de seguridad (RLS) para el bucket
-- de storage que almacena los archivos PDF de evidencia de envíos.
-- PERMITE ACCESO ANÓNIMO (sin autenticación en Supabase Auth).
--
-- ⚠️ ADVERTENCIA: Esto es MENOS SEGURO que usar autenticación,
-- pero es más simple y funciona sin necesidad de crear usuarios de servicio.
--
-- IMPORTANTE: Ejecuta este script en el SQL Editor de Supabase
-- Ruta: Dashboard > SQL Editor > New Query
-- ============================================

-- Primero, asegúrate de que el bucket existe
-- Si no existe, créalo desde el Dashboard: Storage > New bucket > Name: evidencias-envios > Public: true

-- ============================================
-- ELIMINAR POLÍTICAS EXISTENTES (si las hay)
-- ============================================
DROP POLICY IF EXISTS "Usuarios autenticados pueden subir evidencias" ON storage.objects;
DROP POLICY IF EXISTS "Usuarios autenticados pueden ver evidencias" ON storage.objects;
DROP POLICY IF EXISTS "Usuarios autenticados pueden actualizar evidencias" ON storage.objects;
DROP POLICY IF EXISTS "Usuarios autenticados pueden eliminar evidencias" ON storage.objects;
DROP POLICY IF EXISTS "Acceso anónimo para subir evidencias" ON storage.objects;
DROP POLICY IF EXISTS "Acceso anónimo para ver evidencias" ON storage.objects;
DROP POLICY IF EXISTS "Acceso anónimo para actualizar evidencias" ON storage.objects;
DROP POLICY IF EXISTS "Acceso anónimo para eliminar evidencias" ON storage.objects;

-- ============================================
-- POLÍTICA PARA INSERT (subir archivos) - ANÓNIMO
-- ============================================
CREATE POLICY "Acceso anónimo para subir evidencias"
ON storage.objects
FOR INSERT
TO anon
WITH CHECK (
  bucket_id = 'evidencias-envios' AND
  (storage.foldername(name))[1] = 'bitacoras'
);

-- ============================================
-- POLÍTICA PARA SELECT (descargar/ver archivos) - ANÓNIMO
-- ============================================
CREATE POLICY "Acceso anónimo para ver evidencias"
ON storage.objects
FOR SELECT
TO anon
USING (
  bucket_id = 'evidencias-envios' AND
  (storage.foldername(name))[1] = 'bitacoras'
);

-- ============================================
-- POLÍTICA PARA UPDATE (actualizar archivos) - ANÓNIMO
-- ============================================
CREATE POLICY "Acceso anónimo para actualizar evidencias"
ON storage.objects
FOR UPDATE
TO anon
USING (
  bucket_id = 'evidencias-envios' AND
  (storage.foldername(name))[1] = 'bitacoras'
)
WITH CHECK (
  bucket_id = 'evidencias-envios' AND
  (storage.foldername(name))[1] = 'bitacoras'
);

-- ============================================
-- POLÍTICA PARA DELETE (eliminar archivos) - ANÓNIMO
-- ============================================
CREATE POLICY "Acceso anónimo para eliminar evidencias"
ON storage.objects
FOR DELETE
TO anon
USING (
  bucket_id = 'evidencias-envios' AND
  (storage.foldername(name))[1] = 'bitacoras'
);

-- ============================================
-- VERIFICACIÓN
-- ============================================
-- Verifica que las políticas se crearon correctamente:
SELECT 
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'storage' 
  AND tablename = 'objects'
  AND policyname LIKE '%evidencias%';

-- ============================================
-- NOTAS IMPORTANTES
-- ============================================
-- 1. Asegúrate de que el bucket 'evidencias-envios' existe y está marcado como público
-- 2. Las políticas solo permiten acceso a archivos en la carpeta 'bitacoras/'
-- 3. Con estas políticas, NO se requiere autenticación en Supabase Auth
-- 4. Esto es menos seguro pero más simple de configurar
-- 5. Si prefieres mayor seguridad, usa el script: politicas_rls_storage_evidencias.sql

