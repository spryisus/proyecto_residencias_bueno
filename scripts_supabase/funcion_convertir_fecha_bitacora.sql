-- ============================================
-- FUNCIÓN: Convertir fecha numérica a DATE
-- ============================================
-- 
-- Esta función convierte valores numéricos de 6 dígitos (YYMMDD o YYDDMM)
-- a formato DATE válido para PostgreSQL.
--
-- Formato esperado: YYMMDD (ej: 180105 = 05/01/2018)
-- Si el formato es YYDDMM, ajusta la función según corresponda.
--
-- IMPORTANTE: Ejecuta este script ANTES de importar los datos
-- ============================================

-- Función para convertir fecha numérica a DATE
CREATE OR REPLACE FUNCTION convertir_fecha_numerica(fecha_numerica TEXT)
RETURNS DATE AS $$
DECLARE
    fecha_str TEXT;
    anio INTEGER;
    mes INTEGER;
    dia INTEGER;
BEGIN
    -- Si la fecha ya está en formato válido, retornarla directamente
    IF fecha_numerica ~ '^\d{4}-\d{2}-\d{2}$' THEN
        RETURN fecha_numerica::DATE;
    END IF;
    
    -- Si es un número de 6 dígitos, convertir a formato YYMMDD
    IF fecha_numerica ~ '^\d{6}$' THEN
        anio := 2000 + SUBSTRING(fecha_numerica, 1, 2)::INTEGER;
        mes := SUBSTRING(fecha_numerica, 3, 2)::INTEGER;
        dia := SUBSTRING(fecha_numerica, 5, 2)::INTEGER;
        
        -- Validar que mes y día sean válidos
        IF mes < 1 OR mes > 12 THEN
            RAISE EXCEPTION 'Mes inválido: %', mes;
        END IF;
        
        IF dia < 1 OR dia > 31 THEN
            RAISE EXCEPTION 'Día inválido: %', dia;
        END IF;
        
        -- Construir fecha en formato YYYY-MM-DD
        fecha_str := anio || '-' || LPAD(mes::TEXT, 2, '0') || '-' || LPAD(dia::TEXT, 2, '0');
        
        RETURN fecha_str::DATE;
    END IF;
    
    -- Si no coincide con ningún formato, intentar parsear como fecha estándar
    BEGIN
        RETURN fecha_numerica::DATE;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Formato de fecha no reconocido: %', fecha_numerica;
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================
-- COMENTARIOS
-- ============================================
COMMENT ON FUNCTION convertir_fecha_numerica(TEXT) IS 
'Convierte fechas numéricas de 6 dígitos (YYMMDD) a formato DATE. Ejemplo: 180105 -> 2018-01-05';

-- ============================================
-- VERIFICACIÓN
-- ============================================
-- Prueba la función:
-- SELECT convertir_fecha_numerica('180105'); -- Debería retornar: 2018-01-05
-- SELECT convertir_fecha_numerica('180115'); -- Debería retornar: 2018-01-15
-- ============================================








