-- ============================================
-- POLÍTICAS RLS PARA STORAGE: ANÓNIMO Y AUTENTICADO
-- ============================================
-- 
-- Este script configura las políticas de seguridad (RLS) para el bucket
-- de storage que almacena los archivos PDF de evidencia de envíos.
-- PERMITE ACCESO TANTO PARA USUARIOS ANÓNIMOS COMO AUTENTICADOS.
--
-- ⚠️ IMPORTANTE: Ejecuta este script en el SQL Editor de Supabase
-- Ruta: Dashboard > SQL Editor > New Query
-- ============================================

-- ============================================
-- PASO 1: VERIFICAR QUE EL BUCKET EXISTE Y ES PÚBLICO
-- ============================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM storage.buckets WHERE id = 'evidencias-envios'
  ) THEN
    RAISE EXCEPTION 'El bucket "evidencias-envios" no existe. Por favor créalo desde el Dashboard: Storage > New bucket > Name: evidencias-envios > Public: true';
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM storage.buckets 
    WHERE id = 'evidencias-envios' 
    AND public = true
  ) THEN
    RAISE WARNING 'El bucket "evidencias-envios" existe pero NO está marcado como público. Ve a Storage > evidencias-envios > Settings y marca "Public bucket"';
  END IF;
END $$;

-- ============================================
-- PASO 2: ELIMINAR TODAS LAS POLÍTICAS EXISTENTES
-- ============================================
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

-- ============================================
-- PASO 3: CREAR POLÍTICAS PARA ROL ANÓNIMO (anon)
-- ============================================

-- INSERT para anon
CREATE POLICY "Acceso anónimo para subir evidencias"
ON storage.objects
FOR INSERT
TO anon
WITH CHECK (
  bucket_id = 'evidencias-envios' AND
  (storage.foldername(name))[1] = 'bitacoras'
);

-- SELECT para anon
CREATE POLICY "Acceso anónimo para ver evidencias"
ON storage.objects
FOR SELECT
TO anon
USING (
  bucket_id = 'evidencias-envios' AND
  (storage.foldername(name))[1] = 'bitacoras'
);

-- UPDATE para anon
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

-- DELETE para anon
CREATE POLICY "Acceso anónimo para eliminar evidencias"
ON storage.objects
FOR DELETE
TO anon
USING (
  bucket_id = 'evidencias-envios' AND
  (storage.foldername(name))[1] = 'bitacoras'
);

-- ============================================
-- PASO 4: CREAR POLÍTICAS PARA ROL AUTENTICADO (authenticated)
-- ============================================

-- INSERT para authenticated
CREATE POLICY "Acceso autenticado para subir evidencias"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'evidencias-envios' AND
  (storage.foldername(name))[1] = 'bitacoras'
);

-- SELECT para authenticated
CREATE POLICY "Acceso autenticado para ver evidencias"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'evidencias-envios' AND
  (storage.foldername(name))[1] = 'bitacoras'
);

-- UPDATE para authenticated
CREATE POLICY "Acceso autenticado para actualizar evidencias"
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

-- DELETE para authenticated
CREATE POLICY "Acceso autenticado para eliminar evidencias"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'evidencias-envios' AND
  (storage.foldername(name))[1] = 'bitacoras'
);

-- ============================================
-- PASO 5: VERIFICACIÓN
-- ============================================
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
ORDER BY cmd, policyname;

-- Verificar que tenemos 8 políticas (4 para anon + 4 para authenticated)
SELECT 
  CASE 
    WHEN COUNT(*) = 8 THEN '✅ CORRECTO: 8 políticas creadas (4 anon + 4 authenticated)'
    ELSE '❌ ERROR: Se esperaban 8 políticas, pero se encontraron ' || COUNT(*)::text
  END AS "Verificación Final"
FROM pg_policies
WHERE schemaname = 'storage' 
  AND tablename = 'objects'
  AND policyname LIKE '%evidencias%';

-- ============================================
-- NOTAS IMPORTANTES
-- ============================================
-- 1. Este script crea políticas tanto para usuarios anónimos como autenticados
-- 2. Esto asegura que funcione sin importar si el usuario está autenticado o no
-- 3. Si el bucket no es público, ve a Storage > evidencias-envios > Settings > Public bucket: ON
-- 4. Después de ejecutar, prueba subir un PDF desde la aplicación

