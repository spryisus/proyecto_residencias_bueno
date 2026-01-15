-- ============================================
-- POLÍTICAS RLS PARA STORAGE: ACCESO ANÓNIMO (VERSIÓN COMPLETA)
-- ============================================
-- 
-- Este script configura las políticas de seguridad (RLS) para el bucket
-- de storage que almacena los archivos PDF de evidencia de envíos.
-- PERMITE ACCESO ANÓNIMO (sin autenticación en Supabase Auth).
--
-- ⚠️ IMPORTANTE: Ejecuta este script en el SQL Editor de Supabase
-- Ruta: Dashboard > SQL Editor > New Query
-- ============================================

-- ============================================
-- PASO 1: VERIFICAR QUE EL BUCKET EXISTE
-- ============================================
-- Si el bucket no existe, créalo desde el Dashboard:
-- Storage > New bucket > Name: evidencias-envios > Public: true

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM storage.buckets WHERE id = 'evidencias-envios'
  ) THEN
    RAISE EXCEPTION 'El bucket "evidencias-envios" no existe. Por favor créalo desde el Dashboard: Storage > New bucket > Name: evidencias-envios > Public: true';
  END IF;
  
  -- Verificar que el bucket sea público
  IF NOT EXISTS (
    SELECT 1 FROM storage.buckets 
    WHERE id = 'evidencias-envios' 
    AND public = true
  ) THEN
    RAISE WARNING 'El bucket "evidencias-envios" existe pero NO está marcado como público. Esto puede causar problemas. Ve a Storage > evidencias-envios > Settings y marca "Public bucket"';
  END IF;
END $$;

-- ============================================
-- PASO 2: ELIMINAR TODAS LAS POLÍTICAS EXISTENTES
-- ============================================
-- Eliminar TODAS las políticas relacionadas con evidencias-envios
DO $$
DECLARE
  policy_record RECORD;
BEGIN
  FOR policy_record IN 
    SELECT policyname 
    FROM pg_policies 
    WHERE schemaname = 'storage' 
      AND tablename = 'objects'
      AND (
        policyname LIKE '%evidencias%' 
        OR policyname LIKE '%bitacoras%'
        OR policyname LIKE '%envios%'
      )
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', policy_record.policyname);
    RAISE NOTICE 'Política eliminada: %', policy_record.policyname;
  END LOOP;
END $$;

-- También eliminar políticas específicas por si acaso
DROP POLICY IF EXISTS "Usuarios autenticados pueden subir evidencias" ON storage.objects;
DROP POLICY IF EXISTS "Usuarios autenticados pueden ver evidencias" ON storage.objects;
DROP POLICY IF EXISTS "Usuarios autenticados pueden actualizar evidencias" ON storage.objects;
DROP POLICY IF EXISTS "Usuarios autenticados pueden eliminar evidencias" ON storage.objects;
DROP POLICY IF EXISTS "Acceso anónimo para subir evidencias" ON storage.objects;
DROP POLICY IF EXISTS "Acceso anónimo para ver evidencias" ON storage.objects;
DROP POLICY IF EXISTS "Acceso anónimo para actualizar evidencias" ON storage.objects;
DROP POLICY IF EXISTS "Acceso anónimo para eliminar evidencias" ON storage.objects;

-- ============================================
-- PASO 3: CREAR POLÍTICAS ANÓNIMAS
-- ============================================

-- POLÍTICA PARA INSERT (subir archivos) - ANÓNIMO
CREATE POLICY "Acceso anónimo para subir evidencias"
ON storage.objects
FOR INSERT
TO anon
WITH CHECK (
  bucket_id = 'evidencias-envios' AND
  (storage.foldername(name))[1] = 'bitacoras'
);

-- POLÍTICA PARA SELECT (descargar/ver archivos) - ANÓNIMO
CREATE POLICY "Acceso anónimo para ver evidencias"
ON storage.objects
FOR SELECT
TO anon
USING (
  bucket_id = 'evidencias-envios' AND
  (storage.foldername(name))[1] = 'bitacoras'
);

-- POLÍTICA PARA UPDATE (actualizar archivos) - ANÓNIMO
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

-- POLÍTICA PARA DELETE (eliminar archivos) - ANÓNIMO
CREATE POLICY "Acceso anónimo para eliminar evidencias"
ON storage.objects
FOR DELETE
TO anon
USING (
  bucket_id = 'evidencias-envios' AND
  (storage.foldername(name))[1] = 'bitacoras'
);

-- ============================================
-- PASO 4: VERIFICACIÓN
-- ============================================
-- Verificar que las políticas se crearon correctamente
SELECT 
  policyname AS "Nombre de Política",
  cmd AS "Comando",
  CASE 
    WHEN roles::text[] @> ARRAY['anon'] THEN '✅ ANÓNIMO'
    WHEN roles::text[] @> ARRAY['authenticated'] THEN '🔐 AUTENTICADO'
    ELSE '❓ OTRO'
  END AS "Tipo de Acceso"
FROM pg_policies
WHERE schemaname = 'storage' 
  AND tablename = 'objects'
  AND policyname LIKE '%evidencias%'
ORDER BY policyname;

-- Verificar el estado del bucket
SELECT 
  id AS "ID del Bucket",
  name AS "Nombre",
  public AS "¿Es Público?",
  CASE 
    WHEN public THEN '✅ SÍ'
    ELSE '❌ NO (debe ser público)'
  END AS "Estado"
FROM storage.buckets
WHERE id = 'evidencias-envios';

-- ============================================
-- NOTAS IMPORTANTES
-- ============================================
-- 1. Si el bucket no es público, ve a:
--    Storage > evidencias-envios > Settings > Public bucket: ON
-- 
-- 2. Si las políticas no aparecen en la verificación, ejecuta este script nuevamente
-- 
-- 3. Después de ejecutar este script, prueba subir un PDF desde la aplicación
-- 
-- 4. Si aún falla, ejecuta el script de diagnóstico:
--    scripts_supabase/diagnostico_storage.sql

