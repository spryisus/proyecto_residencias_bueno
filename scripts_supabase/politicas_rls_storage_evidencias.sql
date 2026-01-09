-- ============================================
-- POLÍTICAS RLS PARA STORAGE: evidencias-envios
-- ============================================
-- 
-- Este script configura las políticas de seguridad (RLS) para el bucket
-- de storage que almacena los archivos PDF de evidencia de envíos.
--
-- IMPORTANTE: Ejecuta este script en el SQL Editor de Supabase
-- Ruta: Dashboard > SQL Editor > New Query
-- ============================================

-- Primero, asegúrate de que el bucket existe
-- Si no existe, créalo desde el Dashboard: Storage > New bucket > Name: evidencias-envios > Public: true

-- ============================================
-- HABILITAR RLS EN STORAGE (si no está habilitado)
-- ============================================
-- Nota: RLS en storage se habilita automáticamente, pero verificamos las políticas

-- ============================================
-- ELIMINAR POLÍTICAS EXISTENTES (si las hay)
-- ============================================
-- Esto es opcional, pero útil si quieres empezar desde cero
DROP POLICY IF EXISTS "Usuarios autenticados pueden subir evidencias" ON storage.objects;
DROP POLICY IF EXISTS "Usuarios autenticados pueden ver evidencias" ON storage.objects;
DROP POLICY IF EXISTS "Usuarios autenticados pueden actualizar evidencias" ON storage.objects;
DROP POLICY IF EXISTS "Usuarios autenticados pueden eliminar evidencias" ON storage.objects;

-- ============================================
-- POLÍTICA PARA INSERT (subir archivos)
-- ============================================
CREATE POLICY "Usuarios autenticados pueden subir evidencias"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'evidencias-envios' AND
  (storage.foldername(name))[1] = 'bitacoras'
);

-- ============================================
-- POLÍTICA PARA SELECT (descargar/ver archivos)
-- ============================================
CREATE POLICY "Usuarios autenticados pueden ver evidencias"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'evidencias-envios' AND
  (storage.foldername(name))[1] = 'bitacoras'
);

-- ============================================
-- POLÍTICA PARA UPDATE (actualizar archivos)
-- ============================================
CREATE POLICY "Usuarios autenticados pueden actualizar evidencias"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'evidencias-envios' AND
  (storage.foldername(name))[1] = 'bitacoras'
)
WITH CHECK (
  bucket_id = 'evidencias-envios' AND
  (storage.foldername(name))[1] = 'bitacoras'
);

-- ============================================
-- POLÍTICA PARA DELETE (eliminar archivos)
-- ============================================
CREATE POLICY "Usuarios autenticados pueden eliminar evidencias"
ON storage.objects
FOR DELETE
TO authenticated
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
-- 3. Solo usuarios autenticados pueden subir/ver/actualizar/eliminar archivos
-- 4. Si sigues teniendo problemas, verifica que el usuario esté autenticado en Supabase

