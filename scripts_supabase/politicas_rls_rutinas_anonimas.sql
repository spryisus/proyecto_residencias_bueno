-- ============================================
-- POLÍTICAS RLS PARA RUTINAS: ACCESO ANÓNIMO
-- ============================================
-- 
-- Este script configura las políticas de seguridad (RLS) para la tabla
-- t_rutinas permitiendo acceso anónimo (sin autenticación en Supabase Auth).
--
-- ⚠️ ADVERTENCIA: Esto es MENOS SEGURO que usar autenticación,
-- pero es más simple y permite que las rutinas se sincronicen entre equipos
-- sin necesidad de crear usuarios de servicio.
--
-- IMPORTANTE: Ejecuta este script en el SQL Editor de Supabase
-- Ruta: Dashboard > SQL Editor > New Query
-- ============================================

-- ============================================
-- ELIMINAR POLÍTICAS EXISTENTES (si las hay)
-- ============================================
DROP POLICY IF EXISTS "Permitir lectura a usuarios autenticados" ON public.t_rutinas;
DROP POLICY IF EXISTS "Permitir inserción a usuarios autenticados" ON public.t_rutinas;
DROP POLICY IF EXISTS "Permitir actualización a usuarios autenticados" ON public.t_rutinas;
DROP POLICY IF EXISTS "Permitir eliminación a usuarios autenticados" ON public.t_rutinas;
DROP POLICY IF EXISTS "Acceso anónimo para leer rutinas" ON public.t_rutinas;
DROP POLICY IF EXISTS "Acceso anónimo para insertar rutinas" ON public.t_rutinas;
DROP POLICY IF EXISTS "Acceso anónimo para actualizar rutinas" ON public.t_rutinas;
DROP POLICY IF EXISTS "Acceso anónimo para eliminar rutinas" ON public.t_rutinas;

-- ============================================
-- POLÍTICA PARA SELECT (lectura) - ANÓNIMO
-- ============================================
CREATE POLICY "Acceso anónimo para leer rutinas"
ON public.t_rutinas
FOR SELECT
TO anon
USING (true);

-- ============================================
-- POLÍTICA PARA INSERT (crear rutinas) - ANÓNIMO
-- ============================================
CREATE POLICY "Acceso anónimo para insertar rutinas"
ON public.t_rutinas
FOR INSERT
TO anon
WITH CHECK (true);

-- ============================================
-- POLÍTICA PARA UPDATE (actualizar rutinas) - ANÓNIMO
-- ============================================
CREATE POLICY "Acceso anónimo para actualizar rutinas"
ON public.t_rutinas
FOR UPDATE
TO anon
USING (true)
WITH CHECK (true);

-- ============================================
-- POLÍTICA PARA DELETE (eliminar rutinas) - ANÓNIMO
-- ============================================
CREATE POLICY "Acceso anónimo para eliminar rutinas"
ON public.t_rutinas
FOR DELETE
TO anon
USING (true);

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
WHERE schemaname = 'public' 
  AND tablename = 't_rutinas'
  AND policyname LIKE '%anónimo%';

-- ============================================
-- NOTAS IMPORTANTES
-- ============================================
-- 1. Asegúrate de que la tabla t_rutinas existe (ejecuta crear_tabla_rutinas.sql primero)
-- 2. Con estas políticas, NO se requiere autenticación en Supabase Auth
-- 3. Esto permite que las rutinas se sincronicen entre todos los equipos
-- 4. Si prefieres mayor seguridad, puedes mantener las políticas de authenticated
--    y crear un usuario de servicio en Supabase Auth

