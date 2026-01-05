-- ============================================
-- MIGRACIÓN: Cambiar consecutivo de INTEGER a TEXT
-- ============================================
-- 
-- Este script modifica la tabla t_bitacora_envios existente
-- para cambiar el tipo de dato del campo consecutivo de INTEGER a TEXT.
-- Esto permite valores como "17-01", "2024-001", etc.
--
-- IMPORTANTE: Ejecuta este script SOLO si ya creaste la tabla
-- con el campo consecutivo como INTEGER.
-- 
-- Si aún no has creado la tabla, usa el script t_bitacora_envios.sql
-- que ya tiene el campo como TEXT.
-- ============================================

-- Verificar si la tabla existe y tiene el campo consecutivo como INTEGER
DO $$
BEGIN
    -- Cambiar el tipo de dato de INTEGER a TEXT
    -- Primero convertir los valores existentes a texto
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 't_bitacora_envios' 
        AND column_name = 'consecutivo'
        AND data_type = 'integer'
    ) THEN
        -- Convertir los valores existentes a texto
        ALTER TABLE public.t_bitacora_envios 
        ALTER COLUMN consecutivo TYPE TEXT USING consecutivo::TEXT;
        
        RAISE NOTICE 'Campo consecutivo cambiado de INTEGER a TEXT exitosamente';
    ELSE
        RAISE NOTICE 'El campo consecutivo ya es TEXT o la tabla no existe';
    END IF;
END $$;

-- ============================================
-- VERIFICACIÓN
-- ============================================
-- Después de ejecutar, verifica el tipo de dato:
-- SELECT column_name, data_type 
-- FROM information_schema.columns 
-- WHERE table_name = 't_bitacora_envios' 
-- AND column_name = 'consecutivo';
--
-- Deberías ver: data_type = 'text'
-- ============================================

