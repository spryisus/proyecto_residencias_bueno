-- ============================================
-- SOLUCIÓN COMPLETA: Importar datos con fechas numéricas
-- ============================================
-- 
-- Este script hace TODO en un solo paso:
-- 1. Crea la función de conversión
-- 2. Convierte todas las fechas numéricas a DATE
--
-- IMPORTANTE: Ejecuta este script DESPUÉS de haber importado
-- los datos con la columna fecha como TEXT
-- ============================================

-- ============================================
-- PASO 1: Crear la función de conversión
-- ============================================
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
-- PASO 2: Verificar que la función se creó
-- ============================================
-- Prueba la función (esto debería funcionar sin errores):
SELECT convertir_fecha_numerica('180105') as fecha_ejemplo;
-- Debería retornar: 2018-01-05

-- ============================================
-- PASO 3: Convertir todas las fechas numéricas
-- ============================================
-- IMPORTANTE: Solo ejecuta esto si la columna fecha es TEXT
-- Si la columna fecha ya es DATE, primero cámbiala a TEXT:
-- ALTER TABLE public.t_bitacora_envios ALTER COLUMN fecha TYPE TEXT USING fecha::TEXT;

UPDATE public.t_bitacora_envios
SET fecha = convertir_fecha_numerica(fecha::TEXT)::DATE
WHERE fecha::TEXT ~ '^\d{6}$'; -- Solo actualizar fechas de 6 dígitos

-- ============================================
-- PASO 4: Cambiar el tipo de dato de vuelta a DATE
-- ============================================
-- Si cambiaste el tipo a TEXT, vuelve a cambiarlo a DATE:
ALTER TABLE public.t_bitacora_envios 
ALTER COLUMN fecha TYPE DATE USING fecha::DATE;

-- ============================================
-- VERIFICACIÓN
-- ============================================
-- Verifica que las fechas se convirtieron correctamente:
SELECT 
    consecutivo, 
    fecha, 
    tecnico,
    CASE 
        WHEN fecha::TEXT ~ '^\d{6}$' THEN '⚠️ NO CONVERTIDA'
        ELSE '✅ CONVERTIDA'
    END as estado
FROM public.t_bitacora_envios 
WHERE fecha >= '2018-01-01' AND fecha < '2019-01-01'
ORDER BY fecha
LIMIT 20;

-- ============================================
-- NOTAS
-- ============================================
-- Si ves fechas que no se convirtieron (marcadas como "NO CONVERTIDA"),
-- puede ser que tengan un formato diferente. Revisa esos registros y
-- ajusta la función según sea necesario.
-- ============================================











