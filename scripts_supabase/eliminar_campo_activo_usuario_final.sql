-- ============================================
-- ELIMINAR CAMPO ACTIVO: t_computo_usuario_final
-- ============================================
-- 
-- Este script elimina el campo 'activo' y su índice asociado
-- de la tabla t_computo_usuario_final
-- ============================================

-- Eliminar el índice del campo activo si existe
DROP INDEX IF EXISTS public.idx_computo_usuario_final_activo;

-- Eliminar la columna activo si existe
ALTER TABLE public.t_computo_usuario_final
DROP COLUMN IF EXISTS activo;

-- Verificación
SELECT 
    column_name, 
    data_type
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 't_computo_usuario_final'
ORDER BY ordinal_position;


