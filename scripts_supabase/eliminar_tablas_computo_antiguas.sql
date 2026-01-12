-- Script para eliminar tablas antiguas de cómputo
-- EJECUTAR ESTE SCRIPT PRIMERO antes de crear las nuevas tablas

-- Eliminar vistas relacionadas si existen
DROP VIEW IF EXISTS public.v_equipos_computo_completo CASCADE;
DROP VIEW IF EXISTS public.v_componentes_computo_completo CASCADE;

-- Eliminar tablas relacionadas (en orden para evitar problemas de foreign keys)
DROP TABLE IF EXISTS public.t_equipos_computo CASCADE;
DROP TABLE IF EXISTS public.t_empleados_computo CASCADE;

-- Nota: t_empleados se mantiene porque puede ser usada por otras partes del sistema


