-- ============================================
-- POLÍTICAS RLS COMPLETAS PARA t_empleados
-- ============================================
-- 
-- Este script crea todas las políticas necesarias para:
-- - SELECT (ya existe, pero se incluye por si acaso)
-- - INSERT (crear nuevos usuarios)
-- - UPDATE (actualizar usuarios, especialmente el campo activo)
-- - DELETE (eliminar usuarios)
--
-- IMPORTANTE: Ejecuta este script en el SQL Editor de Supabase
-- Ruta: Dashboard > SQL Editor > New Query
-- 
-- NOTA: Este script elimina políticas existentes con el mismo nombre
-- antes de crearlas, así que puedes ejecutarlo múltiples veces sin error
-- ============================================

-- ============================================
-- 1. POLÍTICA PARA INSERT (Crear usuarios)
-- ============================================
-- Eliminar política si existe
DROP POLICY IF EXISTS "usuarios_autenticados_pueden_insertar_empleados" ON public.t_empleados;

-- Crear política
CREATE POLICY "usuarios_autenticados_pueden_insertar_empleados"
ON public.t_empleados
FOR INSERT
TO authenticated
WITH CHECK (true);

-- ============================================
-- 2. POLÍTICA PARA UPDATE (Actualizar usuarios)
-- ============================================
-- Eliminar política si existe
DROP POLICY IF EXISTS "usuarios_autenticados_pueden_actualizar_empleados" ON public.t_empleados;

-- Crear política
CREATE POLICY "usuarios_autenticados_pueden_actualizar_empleados"
ON public.t_empleados
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- ============================================
-- 3. POLÍTICA PARA DELETE (Eliminar usuarios)
-- ============================================
-- Eliminar política si existe
DROP POLICY IF EXISTS "usuarios_autenticados_pueden_eliminar_empleados" ON public.t_empleados;

-- Crear política
CREATE POLICY "usuarios_autenticados_pueden_eliminar_empleados"
ON public.t_empleados
FOR DELETE
TO authenticated
USING (true);

-- ============================================
-- VERIFICACIÓN
-- ============================================
-- Después de ejecutar, verifica que todas las políticas se crearon:
-- SELECT schemaname, tablename, policyname, cmd 
-- FROM pg_policies 
-- WHERE tablename = 't_empleados'
-- ORDER BY cmd;
--
-- Deberías ver políticas para: SELECT, INSERT, UPDATE, DELETE
-- ============================================

-- ============================================
-- NOTAS IMPORTANTES
-- ============================================
-- 1. Estas políticas permiten a CUALQUIER usuario autenticado 
--    realizar operaciones CRUD en t_empleados
-- 2. Tu aplicación Flutter ya valida que solo admins pueden 
--    acceder a la pantalla de gestión de usuarios
-- 3. Si quieres mayor seguridad a nivel de BD, puedes crear 
--    políticas más restrictivas que verifiquen el rol del usuario
-- ============================================

