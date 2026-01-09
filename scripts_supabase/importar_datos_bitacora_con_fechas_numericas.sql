-- ============================================
-- SCRIPT: Importar datos con fechas numéricas
-- ============================================
-- 
-- Este script te ayuda a importar datos donde las fechas están en formato
-- numérico (ej: 180105, 180115) y las convierte automáticamente a DATE.
--
-- PASOS:
-- 1. Primero ejecuta: funcion_convertir_fecha_bitacora.sql
-- 2. Importa tus datos desde Supabase Dashboard (puede fallar, pero no importa)
-- 3. Ejecuta este script para convertir las fechas
-- ============================================

-- Opción 1: Si importaste los datos y la columna fecha es TEXT o INTEGER
-- Primero necesitas cambiar temporalmente el tipo de dato de fecha a TEXT

-- Paso 1: Cambiar temporalmente fecha a TEXT (si no lo es ya)
-- ALTER TABLE public.t_bitacora_envios 
-- ALTER COLUMN fecha TYPE TEXT USING fecha::TEXT;

-- Paso 2: Convertir todas las fechas numéricas a DATE
UPDATE public.t_bitacora_envios
SET fecha = convertir_fecha_numerica(fecha::TEXT)::DATE
WHERE fecha::TEXT ~ '^\d{6}$'; -- Solo actualizar fechas de 6 dígitos

-- Paso 3: Si cambiaste el tipo a TEXT, volver a cambiarlo a DATE
-- ALTER TABLE public.t_bitacora_envios 
-- ALTER COLUMN fecha TYPE DATE USING fecha::DATE;

-- ============================================
-- ALTERNATIVA: Importar directamente con conversión
-- ============================================
-- Si prefieres importar directamente, puedes usar esta query como ejemplo:
-- 
-- INSERT INTO public.t_bitacora_envios (consecutivo, fecha, tecnico, ...)
-- VALUES 
--   ('18-01', convertir_fecha_numerica('180105'), 'RARE', ...),
--   ('18-02', convertir_fecha_numerica('180115'), 'CAHS', ...);
-- 
-- ============================================

-- ============================================
-- VERIFICACIÓN
-- ============================================
-- Después de ejecutar, verifica que las fechas se convirtieron correctamente:
-- SELECT consecutivo, fecha, tecnico 
-- FROM public.t_bitacora_envios 
-- WHERE fecha >= '2018-01-01' AND fecha < '2019-01-01'
-- ORDER BY fecha;
-- ============================================








