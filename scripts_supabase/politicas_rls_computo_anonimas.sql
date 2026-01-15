-- ============================================
-- POLÍTICAS RLS PARA TABLAS DE CÓMPUTO: ACCESO ANÓNIMO
-- ============================================
-- 
-- Este script configura las políticas de seguridad (RLS) para las tablas
-- de cómputo permitiendo acceso anónimo para eliminar equipos.
--
-- ⚠️ ADVERTENCIA: Esto es MENOS SEGURO que usar autenticación,
-- pero permite eliminar equipos sin necesidad de autenticación previa.
--
-- IMPORTANTE: Ejecuta este script en el SQL Editor de Supabase
-- Ruta: Dashboard > SQL Editor > New Query
-- ============================================

-- ============================================
-- ELIMINAR POLÍTICAS EXISTENTES (si las hay)
-- ============================================

-- Para t_computo_detalles_generales
DROP POLICY IF EXISTS "Acceso anónimo para eliminar detalles generales" ON public.t_computo_detalles_generales;
DROP POLICY IF EXISTS "Acceso anónimo para leer detalles generales" ON public.t_computo_detalles_generales;
DROP POLICY IF EXISTS "Acceso anónimo para insertar detalles generales" ON public.t_computo_detalles_generales;
DROP POLICY IF EXISTS "Acceso anónimo para actualizar detalles generales" ON public.t_computo_detalles_generales;

-- Para t_accesorios_equipos
DROP POLICY IF EXISTS "Acceso anónimo para eliminar accesorios" ON public.t_accesorios_equipos;
DROP POLICY IF EXISTS "Acceso anónimo para leer accesorios" ON public.t_accesorios_equipos;
DROP POLICY IF EXISTS "Acceso anónimo para insertar accesorios" ON public.t_accesorios_equipos;
DROP POLICY IF EXISTS "Acceso anónimo para actualizar accesorios" ON public.t_accesorios_equipos;

-- Para t_computo_observaciones
DROP POLICY IF EXISTS "Acceso anónimo para eliminar observaciones" ON public.t_computo_observaciones;
DROP POLICY IF EXISTS "Acceso anónimo para leer observaciones" ON public.t_computo_observaciones;
DROP POLICY IF EXISTS "Acceso anónimo para insertar observaciones" ON public.t_computo_observaciones;
DROP POLICY IF EXISTS "Acceso anónimo para actualizar observaciones" ON public.t_computo_observaciones;

-- Para t_computo_usuario_final
DROP POLICY IF EXISTS "Acceso anónimo para eliminar usuario final" ON public.t_computo_usuario_final;
DROP POLICY IF EXISTS "Acceso anónimo para leer usuario final" ON public.t_computo_usuario_final;
DROP POLICY IF EXISTS "Acceso anónimo para insertar usuario final" ON public.t_computo_usuario_final;
DROP POLICY IF EXISTS "Acceso anónimo para actualizar usuario final" ON public.t_computo_usuario_final;

-- Para t_computo_identificacion
DROP POLICY IF EXISTS "Acceso anónimo para eliminar identificacion" ON public.t_computo_identificacion;
DROP POLICY IF EXISTS "Acceso anónimo para leer identificacion" ON public.t_computo_identificacion;
DROP POLICY IF EXISTS "Acceso anónimo para insertar identificacion" ON public.t_computo_identificacion;
DROP POLICY IF EXISTS "Acceso anónimo para actualizar identificacion" ON public.t_computo_identificacion;

-- Para t_computo_software
DROP POLICY IF EXISTS "Acceso anónimo para eliminar software" ON public.t_computo_software;
DROP POLICY IF EXISTS "Acceso anónimo para leer software" ON public.t_computo_software;
DROP POLICY IF EXISTS "Acceso anónimo para insertar software" ON public.t_computo_software;
DROP POLICY IF EXISTS "Acceso anónimo para actualizar software" ON public.t_computo_software;

-- Para t_computo_equipos_principales
DROP POLICY IF EXISTS "Acceso anónimo para eliminar equipos principales" ON public.t_computo_equipos_principales;
DROP POLICY IF EXISTS "Acceso anónimo para leer equipos principales" ON public.t_computo_equipos_principales;
DROP POLICY IF EXISTS "Acceso anónimo para insertar equipos principales" ON public.t_computo_equipos_principales;
DROP POLICY IF EXISTS "Acceso anónimo para actualizar equipos principales" ON public.t_computo_equipos_principales;

-- ============================================
-- POLÍTICAS PARA t_computo_detalles_generales
-- ============================================

-- DELETE
CREATE POLICY "Acceso anónimo para eliminar detalles generales"
ON public.t_computo_detalles_generales
FOR DELETE
TO anon
USING (true);

-- SELECT (si no existe ya)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 't_computo_detalles_generales' 
    AND policyname LIKE '%leer%' 
    AND 'anon' = ANY(roles::text[])
  ) THEN
    CREATE POLICY "Acceso anónimo para leer detalles generales"
    ON public.t_computo_detalles_generales
    FOR SELECT
    TO anon
    USING (true);
  END IF;
END $$;

-- INSERT (si no existe ya)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 't_computo_detalles_generales' 
    AND policyname LIKE '%insertar%' 
    AND 'anon' = ANY(roles::text[])
  ) THEN
    CREATE POLICY "Acceso anónimo para insertar detalles generales"
    ON public.t_computo_detalles_generales
    FOR INSERT
    TO anon
    WITH CHECK (true);
  END IF;
END $$;

-- UPDATE (si no existe ya)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 't_computo_detalles_generales' 
    AND policyname LIKE '%actualizar%' 
    AND 'anon' = ANY(roles::text[])
  ) THEN
    CREATE POLICY "Acceso anónimo para actualizar detalles generales"
    ON public.t_computo_detalles_generales
    FOR UPDATE
    TO anon
    USING (true)
    WITH CHECK (true);
  END IF;
END $$;

-- ============================================
-- POLÍTICAS PARA t_accesorios_equipos
-- ============================================

-- DELETE
CREATE POLICY "Acceso anónimo para eliminar accesorios"
ON public.t_accesorios_equipos
FOR DELETE
TO anon
USING (true);

-- SELECT (si no existe ya)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 't_accesorios_equipos' 
    AND policyname LIKE '%leer%' 
    AND 'anon' = ANY(roles::text[])
  ) THEN
    CREATE POLICY "Acceso anónimo para leer accesorios"
    ON public.t_accesorios_equipos
    FOR SELECT
    TO anon
    USING (true);
  END IF;
END $$;

-- INSERT (si no existe ya)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 't_accesorios_equipos' 
    AND policyname LIKE '%insertar%' 
    AND 'anon' = ANY(roles::text[])
  ) THEN
    CREATE POLICY "Acceso anónimo para insertar accesorios"
    ON public.t_accesorios_equipos
    FOR INSERT
    TO anon
    WITH CHECK (true);
  END IF;
END $$;

-- UPDATE (si no existe ya)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 't_accesorios_equipos' 
    AND policyname LIKE '%actualizar%' 
    AND 'anon' = ANY(roles::text[])
  ) THEN
    CREATE POLICY "Acceso anónimo para actualizar accesorios"
    ON public.t_accesorios_equipos
    FOR UPDATE
    TO anon
    USING (true)
    WITH CHECK (true);
  END IF;
END $$;

-- ============================================
-- POLÍTICAS PARA t_computo_observaciones
-- ============================================

-- DELETE
CREATE POLICY "Acceso anónimo para eliminar observaciones"
ON public.t_computo_observaciones
FOR DELETE
TO anon
USING (true);

-- SELECT (si no existe ya)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 't_computo_observaciones' 
    AND policyname LIKE '%leer%' 
    AND 'anon' = ANY(roles::text[])
  ) THEN
    CREATE POLICY "Acceso anónimo para leer observaciones"
    ON public.t_computo_observaciones
    FOR SELECT
    TO anon
    USING (true);
  END IF;
END $$;

-- INSERT (si no existe ya)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 't_computo_observaciones' 
    AND policyname LIKE '%insertar%' 
    AND 'anon' = ANY(roles::text[])
  ) THEN
    CREATE POLICY "Acceso anónimo para insertar observaciones"
    ON public.t_computo_observaciones
    FOR INSERT
    TO anon
    WITH CHECK (true);
  END IF;
END $$;

-- UPDATE (si no existe ya)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 't_computo_observaciones' 
    AND policyname LIKE '%actualizar%' 
    AND 'anon' = ANY(roles::text[])
  ) THEN
    CREATE POLICY "Acceso anónimo para actualizar observaciones"
    ON public.t_computo_observaciones
    FOR UPDATE
    TO anon
    USING (true)
    WITH CHECK (true);
  END IF;
END $$;

-- ============================================
-- POLÍTICAS PARA t_computo_usuario_final
-- ============================================

-- DELETE
CREATE POLICY "Acceso anónimo para eliminar usuario final"
ON public.t_computo_usuario_final
FOR DELETE
TO anon
USING (true);

-- SELECT (si no existe ya)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 't_computo_usuario_final' 
    AND policyname LIKE '%leer%' 
    AND 'anon' = ANY(roles::text[])
  ) THEN
    CREATE POLICY "Acceso anónimo para leer usuario final"
    ON public.t_computo_usuario_final
    FOR SELECT
    TO anon
    USING (true);
  END IF;
END $$;

-- INSERT (si no existe ya)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 't_computo_usuario_final' 
    AND policyname LIKE '%insertar%' 
    AND 'anon' = ANY(roles::text[])
  ) THEN
    CREATE POLICY "Acceso anónimo para insertar usuario final"
    ON public.t_computo_usuario_final
    FOR INSERT
    TO anon
    WITH CHECK (true);
  END IF;
END $$;

-- UPDATE (si no existe ya)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 't_computo_usuario_final' 
    AND policyname LIKE '%actualizar%' 
    AND 'anon' = ANY(roles::text[])
  ) THEN
    CREATE POLICY "Acceso anónimo para actualizar usuario final"
    ON public.t_computo_usuario_final
    FOR UPDATE
    TO anon
    USING (true)
    WITH CHECK (true);
  END IF;
END $$;

-- ============================================
-- POLÍTICAS PARA t_computo_identificacion
-- ============================================

-- DELETE
CREATE POLICY "Acceso anónimo para eliminar identificacion"
ON public.t_computo_identificacion
FOR DELETE
TO anon
USING (true);

-- SELECT (si no existe ya)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 't_computo_identificacion' 
    AND policyname LIKE '%leer%' 
    AND 'anon' = ANY(roles::text[])
  ) THEN
    CREATE POLICY "Acceso anónimo para leer identificacion"
    ON public.t_computo_identificacion
    FOR SELECT
    TO anon
    USING (true);
  END IF;
END $$;

-- INSERT (si no existe ya)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 't_computo_identificacion' 
    AND policyname LIKE '%insertar%' 
    AND 'anon' = ANY(roles::text[])
  ) THEN
    CREATE POLICY "Acceso anónimo para insertar identificacion"
    ON public.t_computo_identificacion
    FOR INSERT
    TO anon
    WITH CHECK (true);
  END IF;
END $$;

-- UPDATE (si no existe ya)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 't_computo_identificacion' 
    AND policyname LIKE '%actualizar%' 
    AND 'anon' = ANY(roles::text[])
  ) THEN
    CREATE POLICY "Acceso anónimo para actualizar identificacion"
    ON public.t_computo_identificacion
    FOR UPDATE
    TO anon
    USING (true)
    WITH CHECK (true);
  END IF;
END $$;

-- ============================================
-- POLÍTICAS PARA t_computo_software
-- ============================================

-- DELETE
CREATE POLICY "Acceso anónimo para eliminar software"
ON public.t_computo_software
FOR DELETE
TO anon
USING (true);

-- SELECT (si no existe ya)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 't_computo_software' 
    AND policyname LIKE '%leer%' 
    AND 'anon' = ANY(roles::text[])
  ) THEN
    CREATE POLICY "Acceso anónimo para leer software"
    ON public.t_computo_software
    FOR SELECT
    TO anon
    USING (true);
  END IF;
END $$;

-- INSERT (si no existe ya)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 't_computo_software' 
    AND policyname LIKE '%insertar%' 
    AND 'anon' = ANY(roles::text[])
  ) THEN
    CREATE POLICY "Acceso anónimo para insertar software"
    ON public.t_computo_software
    FOR INSERT
    TO anon
    WITH CHECK (true);
  END IF;
END $$;

-- UPDATE (si no existe ya)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 't_computo_software' 
    AND policyname LIKE '%actualizar%' 
    AND 'anon' = ANY(roles::text[])
  ) THEN
    CREATE POLICY "Acceso anónimo para actualizar software"
    ON public.t_computo_software
    FOR UPDATE
    TO anon
    USING (true)
    WITH CHECK (true);
  END IF;
END $$;

-- ============================================
-- POLÍTICAS PARA t_computo_equipos_principales
-- ============================================

-- DELETE
CREATE POLICY "Acceso anónimo para eliminar equipos principales"
ON public.t_computo_equipos_principales
FOR DELETE
TO anon
USING (true);

-- SELECT (si no existe ya)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 't_computo_equipos_principales' 
    AND policyname LIKE '%leer%' 
    AND 'anon' = ANY(roles::text[])
  ) THEN
    CREATE POLICY "Acceso anónimo para leer equipos principales"
    ON public.t_computo_equipos_principales
    FOR SELECT
    TO anon
    USING (true);
  END IF;
END $$;

-- INSERT (si no existe ya)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 't_computo_equipos_principales' 
    AND policyname LIKE '%insertar%' 
    AND 'anon' = ANY(roles::text[])
  ) THEN
    CREATE POLICY "Acceso anónimo para insertar equipos principales"
    ON public.t_computo_equipos_principales
    FOR INSERT
    TO anon
    WITH CHECK (true);
  END IF;
END $$;

-- UPDATE (si no existe ya)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 't_computo_equipos_principales' 
    AND policyname LIKE '%actualizar%' 
    AND 'anon' = ANY(roles::text[])
  ) THEN
    CREATE POLICY "Acceso anónimo para actualizar equipos principales"
    ON public.t_computo_equipos_principales
    FOR UPDATE
    TO anon
    USING (true)
    WITH CHECK (true);
  END IF;
END $$;

-- ============================================
-- VERIFICACIÓN
-- ============================================
-- Verifica que las políticas se crearon correctamente:
SELECT 
  tablename,
  policyname,
  cmd,
  roles
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename IN (
    't_computo_detalles_generales',
    't_accesorios_equipos',
    't_computo_observaciones',
    't_computo_usuario_final',
    't_computo_identificacion',
    't_computo_software',
    't_computo_equipos_principales'
  )
  AND policyname LIKE '%anónimo%'
ORDER BY tablename, cmd;

-- ============================================
-- NOTAS IMPORTANTES
-- ============================================
-- 1. Con estas políticas, NO se requiere autenticación para eliminar equipos
-- 2. Esto permite que cualquier usuario de la app pueda eliminar equipos
-- 3. Si prefieres mayor seguridad, mantén las políticas de authenticated
--    y crea un usuario de servicio en Supabase Auth

