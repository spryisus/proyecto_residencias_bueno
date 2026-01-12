-- Script para migrar datos de componentes a t_computo_detalles_generales
-- Este script asume que ya tienes los equipos principales importados en t_computo_equipos_principales
-- y que tienes una tabla temporal o un CSV con los datos de los componentes

-- IMPORTANTE: Antes de ejecutar este script, necesitas:
-- 1. Tener los equipos principales importados en t_computo_equipos_principales
-- 2. Crear una tabla temporal con tus datos del CSV o usar COPY FROM

-- Opción 1: Si tienes una tabla temporal con tus datos
-- Primero crea una tabla temporal con la estructura de tu CSV:

/*
CREATE TEMP TABLE temp_componentes_csv (
    inventario TEXT,
    equipo_pm TEXT,
    fecha_registro TEXT,  -- Puede venir como texto desde CSV
    tipo_equipo TEXT,
    marca TEXT,
    modelo TEXT,
    procesador TEXT,
    numero_serie TEXT,
    disco_duro TEXT,
    memoria_ram TEXT
);
*/

-- Opción 2: Insertar datos directamente usando INSERT con subquery para obtener id_equipo_principal
-- Ejemplo de cómo insertar un componente:

/*
INSERT INTO public.t_computo_detalles_generales (
    id_equipo_principal,
    inventario,
    fecha_registro,
    tipo_equipo,
    marca,
    modelo,
    procesador,
    numero_serie,
    disco_duro,
    memoria_ram
)
SELECT 
    ep.id_equipo_principal,  -- Obtener el ID del equipo principal basado en equipo_pm
    'RE053157',  -- inventario
    '2014-08-28'::DATE,  -- fecha_registro (convertir de texto a DATE)
    'ESCRITORIO',  -- tipo_equipo
    'HP',  -- marca
    'PRODESK 4 CORE I5',  -- modelo
    NULL,  -- procesador
    NULL,  -- numero_serie
    '500 GB',  -- disco_duro
    '4.0 GB'  -- memoria_ram
FROM public.t_computo_equipos_principales ep
WHERE ep.equipo_pm = 'COMPU 2';
*/

-- Función helper para insertar componentes desde valores individuales
CREATE OR REPLACE FUNCTION public.insertar_componente_computo(
    p_equipo_pm TEXT,
    p_inventario TEXT,
    p_fecha_registro TEXT DEFAULT NULL,
    p_tipo_equipo TEXT,
    p_marca TEXT DEFAULT NULL,
    p_modelo TEXT DEFAULT NULL,
    p_procesador TEXT DEFAULT NULL,
    p_numero_serie TEXT DEFAULT NULL,
    p_disco_duro TEXT DEFAULT NULL,
    p_memoria_ram TEXT DEFAULT NULL
)
RETURNS BIGINT AS $$
DECLARE
    v_id_equipo_principal BIGINT;
    v_id_equipo_computo BIGINT;
    v_fecha DATE;
BEGIN
    -- Buscar el id_equipo_principal basado en equipo_pm
    SELECT id_equipo_principal INTO v_id_equipo_principal
    FROM public.t_computo_equipos_principales
    WHERE equipo_pm = p_equipo_pm;
    
    -- Si no se encuentra el equipo principal, crear uno nuevo
    IF v_id_equipo_principal IS NULL THEN
        INSERT INTO public.t_computo_equipos_principales (equipo_pm)
        VALUES (p_equipo_pm)
        RETURNING id_equipo_principal INTO v_id_equipo_principal;
    END IF;
    
    -- Convertir fecha_registro de texto a DATE (formato DD/MM/YYYY)
    IF p_fecha_registro IS NOT NULL AND p_fecha_registro != '' THEN
        BEGIN
            v_fecha := TO_DATE(p_fecha_registro, 'DD/MM/YYYY');
        EXCEPTION WHEN OTHERS THEN
            -- Si falla, intentar otros formatos comunes
            BEGIN
                v_fecha := TO_DATE(p_fecha_registro, 'YYYY-MM-DD');
            EXCEPTION WHEN OTHERS THEN
                v_fecha := NULL;
            END;
        END;
    ELSE
        v_fecha := NULL;
    END IF;
    
    -- Insertar el componente
    INSERT INTO public.t_computo_detalles_generales (
        id_equipo_principal,
        inventario,
        fecha_registro,
        tipo_equipo,
        marca,
        modelo,
        procesador,
        numero_serie,
        disco_duro,
        memoria_ram
    )
    VALUES (
        v_id_equipo_principal,
        p_inventario,
        v_fecha,
        p_tipo_equipo,
        NULLIF(p_marca, ''),  -- Convertir strings vacíos a NULL
        NULLIF(p_modelo, ''),
        NULLIF(p_procesador, ''),
        NULLIF(p_numero_serie, ''),
        NULLIF(p_disco_duro, ''),
        NULLIF(p_memoria_ram, '')
    )
    ON CONFLICT (inventario) DO UPDATE SET
        fecha_registro = EXCLUDED.fecha_registro,
        tipo_equipo = EXCLUDED.tipo_equipo,
        marca = EXCLUDED.marca,
        modelo = EXCLUDED.modelo,
        procesador = EXCLUDED.procesador,
        numero_serie = EXCLUDED.numero_serie,
        disco_duro = EXCLUDED.disco_duro,
        memoria_ram = EXCLUDED.memoria_ram
    RETURNING id_equipo_computo INTO v_id_equipo_computo;
    
    RETURN v_id_equipo_computo;
END;
$$ LANGUAGE plpgsql;

-- Ejemplo de uso de la función:
/*
SELECT public.insertar_componente_computo(
    'COMPU 2',           -- equipo_pm
    'RE053157',          -- inventario
    '28/08/2014',        -- fecha_registro
    'ESCRITORIO',        -- tipo_equipo
    'HP',                -- marca
    'PRODESK 4 CORE I5', -- modelo
    NULL,                -- procesador
    NULL,                -- numero_serie
    '500 GB',            -- disco_duro
    '4.0 GB'             -- memoria_ram
);
*/

-- NOTA: Para importar desde CSV, puedes:
-- 1. Usar la función insertar_componente_computo() en un script que lea tu CSV
-- 2. O crear una tabla temporal, importar el CSV ahí, y luego ejecutar:

/*
INSERT INTO public.t_computo_detalles_generales (
    id_equipo_principal,
    inventario,
    fecha_registro,
    tipo_equipo,
    marca,
    modelo,
    procesador,
    numero_serie,
    disco_duro,
    memoria_ram
)
SELECT 
    ep.id_equipo_principal,
    temp.inventario,
    CASE 
        WHEN temp.fecha_registro IS NOT NULL AND temp.fecha_registro != '' THEN
            TO_DATE(temp.fecha_registro, 'DD/MM/YYYY')
        ELSE NULL
    END,
    temp.tipo_equipo,
    NULLIF(temp.marca, ''),
    NULLIF(temp.modelo, ''),
    NULLIF(temp.procesador, ''),
    NULLIF(temp.numero_serie, ''),
    NULLIF(temp.disco_duro, ''),
    NULLIF(temp.memoria_ram, '')
FROM temp_componentes_csv temp
LEFT JOIN public.t_computo_equipos_principales ep 
    ON temp.equipo_pm = ep.equipo_pm
WHERE temp.inventario IS NOT NULL 
    AND temp.inventario != ''
    AND temp.tipo_equipo IS NOT NULL
    AND temp.tipo_equipo != '';
*/

