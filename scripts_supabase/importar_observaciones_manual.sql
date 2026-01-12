-- ============================================
-- IMPORTACIÓN MANUAL: t_computo_observaciones
-- ============================================
-- 
-- Si la importación desde Dashboard sigue fallando,
-- usa este script para importar manualmente desde SQL Editor
-- 
-- INSTRUCCIONES:
-- 1. Copia tus datos del CSV
-- 2. Reemplaza los valores en el INSERT de abajo
-- 3. Ejecuta el script
-- ============================================

-- Ejemplo de cómo insertar datos manualmente
-- Reemplaza los valores con tus datos reales

INSERT INTO public.t_computo_observaciones (
    id_equipo_computo,
    observaciones
) VALUES
    (4, 'EN OPTIMAS CONDICIONES,'),
    (5, 'SE CAMBIO EL DIA 24 ENERO'),
    (5, 'NUEVO LLEGO AGOSTO 2018'),
    (6, 'MONITOR DAÑADO, SE SOLI'),
    (7, 'TECLADO EN BUEN ESTADO,'),
    (7, 'EN BUEN ESTADO. PERTENEC'),
    (7, 'EN USO, FUNCIONA CORREC'),
    (8, 'OTRA OBSERVACION'),
    -- Si id_equipo_computo está vacío, usa NULL:
    (NULL, 'OBSERVACION SIN EQUIPO ASIGNADO'),
    -- Continúa con el resto de tus datos...
    (NULL, NULL); -- Ejemplo de ambos campos vacíos

-- ============================================
-- ALTERNATIVA: Importar desde una tabla temporal
-- ============================================
-- Si tienes muchos datos, puedes crear una tabla temporal:

-- 1. Crear tabla temporal
CREATE TEMP TABLE temp_observaciones_import (
    id_equipo_computo TEXT,
    observaciones TEXT
);

-- 2. Insertar datos en la tabla temporal (puedes usar COPY o INSERT)
-- INSERT INTO temp_observaciones_import VALUES
--     ('4', 'EN OPTIMAS CONDICIONES,'),
--     ('5', 'SE CAMBIO EL DIA 24 ENERO'),
--     ('', 'OBSERVACION SIN EQUIPO'), -- Cadena vacía
--     (NULL, 'OBSERVACION CON NULL');

-- 3. Insertar desde la tabla temporal a la tabla real
-- INSERT INTO public.t_computo_observaciones (id_equipo_computo, observaciones)
-- SELECT 
--     CASE 
--         WHEN id_equipo_computo = '' OR id_equipo_computo IS NULL THEN NULL
--         WHEN id_equipo_computo ~ '^\d+$' THEN id_equipo_computo::BIGINT
--         ELSE NULL
--     END as id_equipo_computo,
--     NULLIF(observaciones, '') as observaciones
-- FROM temp_observaciones_import;

-- 4. Limpiar tabla temporal
-- DROP TABLE IF EXISTS temp_observaciones_import;

