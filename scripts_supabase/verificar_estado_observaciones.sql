-- ============================================
-- VERIFICAR ESTADO: t_computo_observaciones
-- ============================================
-- 
-- Este script verifica el estado actual de la tabla
-- ============================================

-- Verificar el tipo de dato de id_equipo_computo
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 't_computo_observaciones'
  AND column_name IN ('id_equipo_computo', 'id_observacion')
ORDER BY column_name;

-- Verificar si existe la foreign key
SELECT 
    constraint_name,
    constraint_type
FROM information_schema.table_constraints
WHERE table_schema = 'public' 
  AND table_name = 't_computo_observaciones'
  AND constraint_name = 'fk_equipo_computo_observaciones';

-- Verificar si existe el índice único
SELECT 
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public' 
  AND tablename = 't_computo_observaciones'
  AND indexname = 'idx_computo_observaciones_equipo';










