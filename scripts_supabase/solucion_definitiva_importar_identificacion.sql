-- ============================================
-- SOLUCIÓN DEFINITIVA: Importar datos en t_computo_identificacion
-- ============================================
-- 
-- Este script resuelve el error: "invalid input syntax for type bigint: """
-- cambiando temporalmente el tipo de columna a TEXT para importar,
-- y luego convirtiendo los valores correctamente
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

-- Convertir valores válidos de TEXT a BIGINT
-- Primero, eliminar registros con valores que no se pueden convertir a BIGINT
DELETE FROM public.t_computo_identificacion
WHERE id_equipo_computo IS NOT NULL
  AND id_equipo_computo !~ '^\d+$'; -- Solo números enteros

-- Ahora convertir la columna de vuelta a BIGINT
ALTER TABLE public.t_computo_identificacion 
ALTER COLUMN id_equipo_computo TYPE BIGINT 
USING CASE 
    WHEN id_equipo_computo IS NULL OR id_equipo_computo = '' THEN NULL
    WHEN id_equipo_computo ~ '^\d+$' THEN id_equipo_computo::BIGINT
    ELSE NULL
END;

-- PASO 5: Restaurar la foreign key
ALTER TABLE public.t_computo_identificacion
ADD CONSTRAINT fk_equipo_computo_identificacion 
    FOREIGN KEY (id_equipo_computo) 
    REFERENCES public.t_computo_detalles_generales(id_equipo_computo) 
    ON DELETE CASCADE;

-- PASO 6: Decidir qué hacer con los registros NULL
-- Opción A: Eliminar registros sin id_equipo_computo (descomenta si quieres)
-- DELETE FROM public.t_computo_identificacion 
-- WHERE id_equipo_computo IS NULL;

-- Opción B: Mantener NULL permitido (si algunos registros pueden no tener equipo)
-- En este caso, no hacemos nada y mantenemos NULL permitido

-- PASO 7: Restaurar NOT NULL solo si no hay valores NULL
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

-- Ver algunos registros para verificar:
SELECT 
    id_identificacion,
    id_equipo_computo,
    tipo_uso,
    nombre_equipo_dominio,
    status
FROM public.t_computo_identificacion
ORDER BY id_identificacion
LIMIT 10;


