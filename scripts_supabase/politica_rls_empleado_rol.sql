-- ============================================
-- POLÍTICAS RLS PARA t_empleado_rol
-- ============================================
-- 
-- Esta tabla relaciona empleados con sus roles.
-- Necesita políticas para INSERT y DELETE cuando se crean/eliminan usuarios.
--
-- IMPORTANTE: Ejecuta este script en el SQL Editor de Supabase
-- Ruta: Dashboard > SQL Editor > New Query
-- 
-- NOTA: Este script elimina políticas existentes con el mismo nombre
-- antes de crearlas, así que puedes ejecutarlo múltiples veces sin error
-- ============================================

-- ============================================
-- 1. POLÍTICA PARA INSERT (Asignar roles)
-- ============================================
-- Eliminar política si existe
DROP POLICY IF EXISTS "usuarios_autenticados_pueden_insertar_empleado_rol" ON public.t_empleado_rol;

-- Crear política
CREATE POLICY "usuarios_autenticados_pueden_insertar_empleado_rol"
ON public.t_empleado_rol
FOR INSERT
TO authenticated
WITH CHECK (true);

-- ============================================
-- 2. POLÍTICA PARA DELETE (Eliminar asignaciones de roles)
-- ============================================
-- Eliminar política si existe
DROP POLICY IF EXISTS "usuarios_autenticados_pueden_eliminar_empleado_rol" ON public.t_empleado_rol;

-- Crear política
CREATE POLICY "usuarios_autenticados_pueden_eliminar_empleado_rol"
ON public.t_empleado_rol
FOR DELETE
TO authenticated
USING (true);

-- ============================================
-- VERIFICACIÓN
-- ============================================
-- Después de ejecutar, verifica que las políticas se crearon:
-- SELECT schemaname, tablename, policyname, cmd 
-- FROM pg_policies 
-- WHERE tablename = 't_empleado_rol'
-- ORDER BY cmd;
-- ============================================

