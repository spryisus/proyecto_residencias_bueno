-- Script para eliminar el rol de auditor de la base de datos
-- Ejecutar este script en el SQL Editor de Supabase

-- 1. Eliminar todas las asignaciones del rol auditor de la tabla t_empleado_rol
DELETE FROM public.t_empleado_rol
WHERE id_rol IN (
  SELECT id_rol FROM public.t_roles WHERE nombre = 'auditor'
);

-- 2. Eliminar el rol auditor de la tabla t_roles
DELETE FROM public.t_roles
WHERE nombre = 'auditor';

-- Verificar que se eliminó correctamente
SELECT * FROM public.t_roles WHERE nombre = 'auditor';
-- Debe retornar 0 filas

