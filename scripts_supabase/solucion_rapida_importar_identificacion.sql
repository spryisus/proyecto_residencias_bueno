-- ============================================
-- SOLUCIÓN RÁPIDA: Importar datos en t_computo_identificacion
-- ============================================
-- 
-- Este script resuelve el error: "invalid input syntax for type bigint: """
-- que ocurre cuando importas datos con celdas vacías desde Supabase Dashboard
-- 
-- IMPORTANTE: Si este script no funciona, usa: solucion_definitiva_importar_identificacion.sql
-- ============================================

-- PASO 1: Eliminar el índice único y la foreign key temporalmente
DROP INDEX IF EXISTS public.idx_computo_identificacion_equipo;
ALTER TABLE public.t_computo_identificacion 
DROP CONSTRAINT IF EXISTS fk_equipo_computo_identificacion;

-- PASO 2: Cambiar temporalmente id_equipo_computo a TEXT para permitir importar cadenas vacías
ALTER TABLE public.t_computo_identificacion 
ALTER COLUMN id_equipo_computo TYPE TEXT USING id_equipo_computo::TEXT;

-- PASO 3: Permitir NULL
ALTER TABLE public.t_computo_identificacion 
ALTER COLUMN id_equipo_computo DROP NOT NULL;

-- ============================================
-- AHORA IMPORTA TUS DATOS DESDE SUPABASE DASHBOARD
-- ============================================
-- Ve a Table Editor > t_computo_identificacion > Import data
-- Selecciona tu archivo y importa. Ahora debería funcionar sin errores.
-- ============================================

-- PASO 4: Después de importar, ejecuta estas líneas para convertir y restaurar:

-- Convertir cadenas vacías y valores inválidos a NULL
UPDATE public.t_computo_identificacion
SET id_equipo_computo = NULL
WHERE id_equipo_computo = '' 
   OR id_equipo_computo IS NULL
   OR TRIM(id_equipo_computo) = '';

-- Eliminar registros con valores que no se pueden convertir a BIGINT
DELETE FROM public.t_computo_identificacion
WHERE id_equipo_computo IS NOT NULL
  AND id_equipo_computo !~ '^\d+$'; -- Solo números enteros

-- Convertir la columna de vuelta a BIGINT
ALTER TABLE public.t_computo_identificacion 
ALTER COLUMN id_equipo_computo TYPE BIGINT 
USING CASE 
    WHEN id_equipo_computo IS NULL OR id_equipo_computo = '' THEN NULL
    WHEN id_equipo_computo ~ '^\d+$' THEN id_equipo_computo::BIGINT
    ELSE NULL
END;

-- Restaurar la foreign key
ALTER TABLE public.t_computo_identificacion
ADD CONSTRAINT fk_equipo_computo_identificacion 
    FOREIGN KEY (id_equipo_computo) 
    REFERENCES public.t_computo_detalles_generales(id_equipo_computo) 
    ON DELETE CASCADE;

-- Opción A: Si quieres eliminar registros sin id_equipo_computo (descomenta)
-- DELETE FROM public.t_computo_identificacion 
-- WHERE id_equipo_computo IS NULL;

-- Opción B: Si quieres mantenerlos pero asignarles un valor por defecto (descomenta)
-- UPDATE public.t_computo_identificacion
-- SET id_equipo_computo = (
--     SELECT MIN(id_equipo_computo) 
--     FROM public.t_computo_detalles_generales
-- )
-- WHERE id_equipo_computo IS NULL;

-- PASO 5: Restaurar NOT NULL solo si no hay valores NULL
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.t_computo_identificacion 
        WHERE id_equipo_computo IS NULL
    ) THEN
        ALTER TABLE public.t_computo_identificacion 
        ALTER COLUMN id_equipo_computo SET NOT NULL;
        
        -- Recrear índice único
        CREATE UNIQUE INDEX IF NOT EXISTS idx_computo_identificacion_equipo 
        ON public.t_computo_identificacion(id_equipo_computo);
    ELSE
        -- Si hay NULL, crear índice parcial (permite múltiples NULL)
        CREATE UNIQUE INDEX IF NOT EXISTS idx_computo_identificacion_equipo 
        ON public.t_computo_identificacion(id_equipo_computo)
        WHERE id_equipo_computo IS NOT NULL;
        
        RAISE NOTICE 'Hay registros con id_equipo_computo NULL. El índice único parcial permite múltiples NULL.';
    END IF;
END $$;

-- ============================================
-- VERIFICACIÓN
-- ============================================
-- Verifica tus datos importados:
SELECT 
    COUNT(*) as total_registros,
    COUNT(id_equipo_computo) as con_id_equipo,
    COUNT(*) - COUNT(id_equipo_computo) as sin_id_equipo
FROM public.t_computo_identificacion;

