-- ============================================
-- AGREGAR COLUMNA: cobo a t_bitacora_envios
-- ============================================
-- 
-- Este script agrega una nueva columna llamada "cobo" de tipo TEXT
-- a la tabla t_bitacora_envios.
--
-- IMPORTANTE: Ejecuta este script en el SQL Editor de Supabase
-- Ruta: Dashboard > SQL Editor > New Query
-- ============================================

-- Agregar la columna cobo
ALTER TABLE public.t_bitacora_envios
ADD COLUMN IF NOT EXISTS cobo TEXT;

-- Agregar comentario para documentación
COMMENT ON COLUMN public.t_bitacora_envios.cobo IS 'Campo COBO de la bitácora';

-- ============================================
-- VERIFICACIÓN
-- ============================================
-- Después de ejecutar, verifica que la columna se agregó correctamente:
-- SELECT column_name, data_type, is_nullable
-- FROM information_schema.columns
-- WHERE table_schema = 'public' 
--   AND table_name = 't_bitacora_envios'
--   AND column_name = 'cobo';
--
-- Deberías ver: column_name = 'cobo', data_type = 'text', is_nullable = 'YES'
-- ============================================

