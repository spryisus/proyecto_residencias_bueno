-- ============================================
-- POLÍTICAS RLS PARA ACCESO ANÓNIMO
-- ============================================
-- 
-- Este script cambia las políticas RLS de t_bitacora_envios
-- para permitir acceso anónimo (sin autenticación en Supabase Auth).
--
-- ⚠️ ADVERTENCIA: Esto es MENOS SEGURO que usar autenticación,
-- pero es más simple si no quieres configurar Supabase Auth.
--
-- IMPORTANTE: Ejecuta este script en el SQL Editor de Supabase
-- Ruta: Dashboard > SQL Editor > New Query
-- ============================================

-- Eliminar políticas existentes para authenticated
DROP POLICY IF EXISTS "usuarios_autenticados_pueden_leer_bitacora" ON public.t_bitacora_envios;
DROP POLICY IF EXISTS "usuarios_autenticados_pueden_insertar_bitacora" ON public.t_bitacora_envios;
DROP POLICY IF EXISTS "usuarios_autenticados_pueden_actualizar_bitacora" ON public.t_bitacora_envios;
DROP POLICY IF EXISTS "usuarios_autenticados_pueden_eliminar_bitacora" ON public.t_bitacora_envios;

-- ============================================
-- POLÍTICAS PARA ACCESO ANÓNIMO
-- ============================================

-- Política para SELECT (lectura) - acceso anónimo
CREATE POLICY "anon_puede_leer_bitacora"
ON public.t_bitacora_envios
FOR SELECT
TO anon
USING (true);

-- Política para INSERT (crear registros) - acceso anónimo
CREATE POLICY "anon_puede_insertar_bitacora"
ON public.t_bitacora_envios
FOR INSERT
TO anon
WITH CHECK (true);

-- Política para UPDATE (actualizar registros) - acceso anónimo
CREATE POLICY "anon_puede_actualizar_bitacora"
ON public.t_bitacora_envios
FOR UPDATE
TO anon
USING (true)
WITH CHECK (true);

-- Política para DELETE (eliminar registros) - acceso anónimo
CREATE POLICY "anon_puede_eliminar_bitacora"
ON public.t_bitacora_envios
FOR DELETE
TO anon
USING (true);

-- ============================================
-- VERIFICACIÓN
-- ============================================
-- Después de ejecutar, verifica que las políticas se crearon:
-- SELECT schemaname, tablename, policyname, cmd, roles
-- FROM pg_policies 
-- WHERE tablename = 't_bitacora_envios'
-- ORDER BY cmd;
--
-- Deberías ver políticas para: SELECT, INSERT, UPDATE, DELETE
-- todas con rol 'anon' (anónimo)
-- ============================================

-- ============================================
-- NOTAS IMPORTANTES
-- ============================================
-- 1. Estas políticas permiten a CUALQUIER usuario (incluso sin autenticación)
--    realizar operaciones CRUD en t_bitacora_envios
-- 2. Tu aplicación Flutter ya valida que solo usuarios válidos puedan
--    acceder a través del login con t_empleados
-- 3. Si quieres mayor seguridad, usa el usuario de servicio en Supabase Auth
--    en lugar de estas políticas anónimas
-- ============================================



















