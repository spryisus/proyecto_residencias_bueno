-- ============================================
-- IMPORTAR OBSERVACIONES: Usando tabla temporal
-- ============================================
-- 
-- Si Supabase Dashboard sigue fallando, usa este método:
-- 1. Crea una tabla temporal con todos los campos como TEXT
-- 2. Importa tu CSV a esa tabla temporal desde Dashboard
-- 3. Ejecuta este script para migrar los datos
-- ============================================

-- PASO 1: Crear tabla temporal (ejecuta esto primero)
CREATE TABLE IF NOT EXISTS public.temp_observaciones_import (
    id_observacion TEXT,
    id_equipo_computo TEXT,
    observaciones TEXT
);

-- ============================================
-- PASO 2: IMPORTA TU CSV A temp_observaciones_import
-- ============================================
-- Ve a Table Editor > temp_observaciones_import > Import data
-- Importa tu CSV aquí. Debería funcionar porque todos los campos son TEXT
-- ============================================

-- PASO 3: Después de importar, ejecuta esto para migrar los datos:
INSERT INTO public.t_computo_observaciones (
    id_equipo_computo,
    observaciones
)
SELECT 
    CASE 
        WHEN id_equipo_computo IS NULL OR id_equipo_computo = '' OR TRIM(id_equipo_computo) = '' THEN NULL
        WHEN id_equipo_computo ~ '^\d+$' THEN id_equipo_computo::TEXT
        ELSE NULL
    END as id_equipo_computo,
    NULLIF(TRIM(observaciones), '') as observaciones
FROM public.temp_observaciones_import
WHERE observaciones IS NOT NULL 
   OR (id_equipo_computo IS NOT NULL AND id_equipo_computo != '' AND TRIM(id_equipo_computo) != '');

-- PASO 4: Verificar datos migrados
SELECT 
    COUNT(*) as total_importado,
    COUNT(id_equipo_computo) as con_id_equipo,
    COUNT(*) - COUNT(id_equipo_computo) as sin_id_equipo
FROM public.t_computo_observaciones;

-- PASO 5: Limpiar tabla temporal (opcional, después de verificar)
-- DROP TABLE IF EXISTS public.temp_observaciones_import;










