-- ============================================
-- POLÍTICAS RLS COMPLETAS PARA t_bitacora_envios
-- ============================================
-- 
-- Este script crea políticas RLS que funcionan tanto para usuarios
-- autenticados (authenticated) como para usuarios anónimos (anon).
-- Esto asegura que la aplicación funcione tanto en escritorio como en móvil.
--
-- IMPORTANTE: Ejecuta este script en el SQL Editor de Supabase
-- Ruta: Dashboard > SQL Editor > New Query
-- ============================================

-- ============================================
-- ELIMINAR POLÍTICAS EXISTENTES
-- ============================================

-- Eliminar políticas para authenticated
DROP POLICY IF EXISTS "usuarios_autenticados_pueden_leer_bitacora" ON public.t_bitacora_envios;
DROP POLICY IF EXISTS "usuarios_autenticados_pueden_insertar_bitacora" ON public.t_bitacora_envios;
DROP POLICY IF EXISTS "usuarios_autenticados_pueden_actualizar_bitacora" ON public.t_bitacora_envios;
DROP POLICY IF EXISTS "usuarios_autenticados_pueden_eliminar_bitacora" ON public.t_bitacora_envios;

-- Eliminar políticas para anon
DROP POLICY IF EXISTS "anon_puede_leer_bitacora" ON public.t_bitacora_envios;
DROP POLICY IF EXISTS "anon_puede_insertar_bitacora" ON public.t_bitacora_envios;
DROP POLICY IF EXISTS "anon_puede_actualizar_bitacora" ON public.t_bitacora_envios;
DROP POLICY IF EXISTS "anon_puede_eliminar_bitacora" ON public.t_bitacora_envios;

-- ============================================
-- POLÍTICAS PARA USUARIOS AUTENTICADOS
-- ============================================

-- Política para SELECT (lectura) - usuarios autenticados
CREATE POLICY "authenticated_puede_leer_bitacora"
ON public.t_bitacora_envios
FOR SELECT
TO authenticated
USING (true);

-- Política para INSERT (crear registros) - usuarios autenticados
CREATE POLICY "authenticated_puede_insertar_bitacora"
ON public.t_bitacora_envios
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Política para UPDATE (actualizar registros) - usuarios autenticados
CREATE POLICY "authenticated_puede_actualizar_bitacora"
ON public.t_bitacora_envios
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Política para DELETE (eliminar registros) - usuarios autenticados
CREATE POLICY "authenticated_puede_eliminar_bitacora"
ON public.t_bitacora_envios
FOR DELETE
TO authenticated
USING (true);

-- ============================================
-- POLÍTICAS PARA USUARIOS ANÓNIMOS
-- ============================================

-- Política para SELECT (lectura) - usuarios anónimos
CREATE POLICY "anon_puede_leer_bitacora"
ON public.t_bitacora_envios
FOR SELECT
TO anon
USING (true);

-- Política para INSERT (crear registros) - usuarios anónimos
CREATE POLICY "anon_puede_insertar_bitacora"
ON public.t_bitacora_envios
FOR INSERT
TO anon
WITH CHECK (true);

-- Política para UPDATE (actualizar registros) - usuarios anónimos
CREATE POLICY "anon_puede_actualizar_bitacora"
ON public.t_bitacora_envios
FOR UPDATE
TO anon
USING (true)
WITH CHECK (true);

-- Política para DELETE (eliminar registros) - usuarios anónimos
CREATE POLICY "anon_puede_eliminar_bitacora"
ON public.t_bitacora_envios
FOR DELETE
TO anon
USING (true);

-- ============================================
-- VERIFICACIÓN
-- ============================================
-- Después de ejecutar, verifica que las políticas se crearon:
-- 
-- SELECT 
--   schemaname, 
--   tablename, 
--   policyname, 
--   cmd,
--   roles
-- FROM pg_policies 
-- WHERE tablename = 't_bitacora_envios'
-- ORDER BY cmd, roles;
--
-- Deberías ver 8 políticas en total:
-- - 4 para authenticated (SELECT, INSERT, UPDATE, DELETE)
-- - 4 para anon (SELECT, INSERT, UPDATE, DELETE)
-- ============================================

-- ============================================
-- NOTAS IMPORTANTES
-- ============================================
-- 1. Estas políticas permiten acceso completo a usuarios autenticados
--    y anónimos. Tu aplicación Flutter ya valida que solo usuarios
--    válidos puedan acceder a través del login con t_empleados.
-- 2. Si quieres mayor seguridad, puedes restringir las políticas
--    anónimas solo a SELECT, o eliminar las políticas anónimas
--    si todos los usuarios se autentican en Supabase Auth.
-- 3. Estas políticas funcionan tanto en escritorio como en móvil.
-- ============================================










