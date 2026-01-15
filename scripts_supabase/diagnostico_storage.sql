-- ============================================
-- DIAGNÓSTICO DE STORAGE: evidencias-envios
-- ============================================
-- 
-- Este script verifica el estado del bucket y las políticas RLS
-- Úsalo para diagnosticar problemas con la subida de PDFs
-- ============================================

-- ============================================
-- 1. VERIFICAR QUE EL BUCKET EXISTE
-- ============================================
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'evidencias-envios')
    THEN '✅ El bucket "evidencias-envios" EXISTE'
    ELSE '❌ El bucket "evidencias-envios" NO EXISTE. Créalo desde el Dashboard.'
  END AS "Estado del Bucket";

-- ============================================
-- 2. VERIFICAR CONFIGURACIÓN DEL BUCKET
-- ============================================
SELECT 
  id AS "ID",
  name AS "Nombre",
  public AS "¿Es Público?",
  CASE 
    WHEN public THEN '✅ SÍ - Correcto'
    ELSE '❌ NO - Debe ser público. Ve a Storage > evidencias-envios > Settings'
  END AS "Estado",
  created_at AS "Creado en",
  updated_at AS "Actualizado en"
FROM storage.buckets
WHERE id = 'evidencias-envios';

-- ============================================
-- 3. VERIFICAR POLÍTICAS RLS EXISTENTES
-- ============================================
SELECT 
  policyname AS "Nombre de Política",
  cmd AS "Comando (INSERT/SELECT/UPDATE/DELETE)",
  CASE 
    WHEN roles::text[] @> ARRAY['anon'] THEN '✅ ANÓNIMO'
    WHEN roles::text[] @> ARRAY['authenticated'] THEN '🔐 AUTENTICADO'
    ELSE '❓ OTRO: ' || roles::text
  END AS "Tipo de Acceso",
  qual AS "Condición USING",
  with_check AS "Condición WITH CHECK"
FROM pg_policies
WHERE schemaname = 'storage' 
  AND tablename = 'objects'
  AND (
    policyname LIKE '%evidencias%' 
    OR policyname LIKE '%bitacoras%'
    OR policyname LIKE '%envios%'
  )
ORDER BY policyname;

-- ============================================
-- 4. CONTAR POLÍTICAS POR TIPO
-- ============================================
SELECT 
  CASE 
    WHEN roles::text[] @> ARRAY['anon'] THEN 'Anónimo'
    WHEN roles::text[] @> ARRAY['authenticated'] THEN 'Autenticado'
    ELSE 'Otro'
  END AS "Tipo",
  COUNT(*) AS "Cantidad",
  STRING_AGG(policyname, ', ') AS "Políticas"
FROM pg_policies
WHERE schemaname = 'storage' 
  AND tablename = 'objects'
  AND (
    policyname LIKE '%evidencias%' 
    OR policyname LIKE '%bitacoras%'
    OR policyname LIKE '%envios%'
  )
GROUP BY 
  CASE 
    WHEN roles::text[] @> ARRAY['anon'] THEN 'Anónimo'
    WHEN roles::text[] @> ARRAY['authenticated'] THEN 'Autenticado'
    ELSE 'Otro'
  END;

-- ============================================
-- 5. VERIFICAR POLÍTICAS REQUERIDAS
-- ============================================
SELECT 
  'INSERT' AS "Operación Requerida",
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_policies 
      WHERE schemaname = 'storage' 
        AND tablename = 'objects'
        AND cmd = 'INSERT'
        AND roles::text[] @> ARRAY['anon']
        AND policyname LIKE '%evidencias%'
    ) THEN '✅ Política anónima existe'
    ELSE '❌ Falta política anónima para INSERT'
  END AS "Estado"
UNION ALL
SELECT 
  'SELECT' AS "Operación Requerida",
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_policies 
      WHERE schemaname = 'storage' 
        AND tablename = 'objects'
        AND cmd = 'SELECT'
        AND roles::text[] @> ARRAY['anon']
        AND policyname LIKE '%evidencias%'
    ) THEN '✅ Política anónima existe'
    ELSE '❌ Falta política anónima para SELECT'
  END AS "Estado"
UNION ALL
SELECT 
  'UPDATE' AS "Operación Requerida",
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_policies 
      WHERE schemaname = 'storage' 
        AND tablename = 'objects'
        AND cmd = 'UPDATE'
        AND roles::text[] @> ARRAY['anon']
        AND policyname LIKE '%evidencias%'
    ) THEN '✅ Política anónima existe'
    ELSE '❌ Falta política anónima para UPDATE'
  END AS "Estado"
UNION ALL
SELECT 
  'DELETE' AS "Operación Requerida",
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_policies 
      WHERE schemaname = 'storage' 
        AND tablename = 'objects'
        AND cmd = 'DELETE'
        AND roles::text[] @> ARRAY['anon']
        AND policyname LIKE '%evidencias%'
    ) THEN '✅ Política anónima existe'
    ELSE '❌ Falta política anónima para DELETE'
  END AS "Estado";

-- ============================================
-- 6. RESUMEN Y RECOMENDACIONES
-- ============================================
SELECT 
  CASE 
    WHEN NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'evidencias-envios')
    THEN '❌ PROBLEMA: El bucket no existe. Créalo desde el Dashboard.'
    WHEN NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'evidencias-envios' AND public = true)
    THEN '❌ PROBLEMA: El bucket no es público. Ve a Settings y marca "Public bucket"'
    WHEN (
      SELECT COUNT(*) FROM pg_policies
      WHERE schemaname = 'storage' 
        AND tablename = 'objects'
        AND roles::text[] @> ARRAY['anon']
        AND policyname LIKE '%evidencias%'
    ) < 4
    THEN '❌ PROBLEMA: Faltan políticas anónimas. Ejecuta: politicas_rls_storage_anonimas_completo.sql'
    ELSE '✅ TODO CORRECTO: El bucket existe, es público y tiene las 4 políticas anónimas necesarias'
  END AS "Diagnóstico Final";

