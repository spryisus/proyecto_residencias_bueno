-- =====================================================
-- Script de migración: Cambiar en_stock de BOOLEAN a TEXT
-- Para tablas t_tarjetas_red que ya fueron creadas
-- =====================================================

-- Este script convierte la columna en_stock de BOOLEAN a TEXT
-- para aceptar valores "SI" y "NO" en lugar de true/false

DO $$
BEGIN
  -- Verificar si la tabla existe
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 't_tarjetas_red'
  ) THEN
    RAISE EXCEPTION '❌ Error: La tabla t_tarjetas_red no existe. Ejecuta primero t_tarjetas_red.sql';
  END IF;

  -- Verificar si la columna en_stock es BOOLEAN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 't_tarjetas_red' 
    AND column_name = 'en_stock'
    AND data_type = 'boolean'
  ) THEN
    -- Convertir valores booleanos existentes a texto
    ALTER TABLE public.t_tarjetas_red 
    ALTER COLUMN en_stock TYPE TEXT USING 
      CASE 
        WHEN en_stock = true THEN 'SI'
        WHEN en_stock = false THEN 'NO'
        ELSE 'SI'
      END;
    
    -- Establecer valor por defecto
    ALTER TABLE public.t_tarjetas_red 
    ALTER COLUMN en_stock SET DEFAULT 'SI';
    
    RAISE NOTICE '✅ Columna en_stock convertida de BOOLEAN a TEXT exitosamente';
    RAISE NOTICE '✅ Valores existentes convertidos: true -> "SI", false -> "NO"';
  ELSIF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 't_tarjetas_red' 
    AND column_name = 'en_stock'
    AND data_type = 'text'
  ) THEN
    RAISE NOTICE 'ℹ️ La columna en_stock ya es de tipo TEXT. No se requiere migración.';
  ELSE
    RAISE EXCEPTION '❌ Error: La columna en_stock no existe en la tabla t_tarjetas_red';
  END IF;
END $$;

-- Verificar el resultado
SELECT 
  column_name,
  data_type,
  column_default,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 't_tarjetas_red'
  AND column_name = 'en_stock';





