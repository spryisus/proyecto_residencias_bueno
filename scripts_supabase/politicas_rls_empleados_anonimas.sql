-- ============================================
-- POLÍTICAS RLS PARA EMPLEADOS: ACCESO ANÓNIMO
-- ============================================
-- 
-- Este script configura las políticas de seguridad (RLS) para las tablas
-- t_empleados y t_empleado_rol permitiendo acceso anónimo para crear usuarios.
--
-- ⚠️ ADVERTENCIA: Esto es MENOS SEGURO que usar autenticación,
-- pero permite crear usuarios sin necesidad de autenticación previa.
--
-- IMPORTANTE: Ejecuta este script en el SQL Editor de Supabase
-- Ruta: Dashboard > SQL Editor > New Query
-- ============================================

-- ============================================
-- ELIMINAR POLÍTICAS EXISTENTES (si las hay)
-- ============================================
-- Para t_empleados
DROP POLICY IF EXISTS "usuarios_autenticados_pueden_insertar_empleados" ON public.t_empleados;
DROP POLICY IF EXISTS "Acceso anónimo para insertar empleados" ON public.t_empleados;
DROP POLICY IF EXISTS "Acceso anónimo para leer empleados" ON public.t_empleados;
DROP POLICY IF EXISTS "Acceso anónimo para actualizar empleados" ON public.t_empleados;

-- Para t_empleado_rol
DROP POLICY IF EXISTS "usuarios_autenticados_pueden_insertar_empleado_rol" ON public.t_empleado_rol;
DROP POLICY IF EXISTS "Acceso anónimo para insertar empleado_rol" ON public.t_empleado_rol;

-- ============================================
-- POLÍTICAS PARA t_empleados
-- ============================================

-- Política para INSERT (crear empleados) - ANÓNIMO
CREATE POLICY "Acceso anónimo para insertar empleados"
ON public.t_empleados
FOR INSERT
TO anon
WITH CHECK (true);

-- Política para SELECT (leer empleados) - ANÓNIMO (si no existe ya)
-- Esta es necesaria para verificar si un usuario ya existe
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 't_empleados' 
    AND policyname LIKE '%leer%' 
    AND 'anon' = ANY(roles::text[])
  ) THEN
    CREATE POLICY "Acceso anónimo para leer empleados"
    ON public.t_empleados
    FOR SELECT
    TO anon
    USING (true);
  END IF;
END $$;

-- Política para UPDATE (actualizar empleados) - ANÓNIMO
CREATE POLICY "Acceso anónimo para actualizar empleados"
ON public.t_empleados
FOR UPDATE
TO anon
USING (true)
WITH CHECK (true);

-- ============================================
-- POLÍTICAS PARA t_empleado_rol
-- ============================================

-- Política para INSERT (asignar roles) - ANÓNIMO
CREATE POLICY "Acceso anónimo para insertar empleado_rol"
ON public.t_empleado_rol
FOR INSERT
TO anon
WITH CHECK (true);

-- Política para SELECT (leer roles de empleados) - ANÓNIMO (si no existe ya)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 't_empleado_rol' 
    AND policyname LIKE '%leer%' 
    AND 'anon' = ANY(roles::text[])
  ) THEN
    CREATE POLICY "Acceso anónimo para leer empleado_rol"
    ON public.t_empleado_rol
    FOR SELECT
    TO anon
    USING (true);
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
  AND (tablename = 't_empleados' OR tablename = 't_empleado_rol')
  AND policyname LIKE '%anónimo%'
ORDER BY tablename, cmd;

-- ============================================
-- NOTAS IMPORTANTES
-- ============================================
-- 1. Con estas políticas, NO se requiere autenticación para crear usuarios
-- 2. Esto permite que cualquier usuario de la app pueda crear nuevos usuarios
-- 3. Si prefieres mayor seguridad, mantén las políticas de authenticated
--    y crea un usuario de servicio en Supabase Auth

