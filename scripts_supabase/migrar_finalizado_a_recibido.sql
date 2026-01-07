-- ============================================
-- MIGRAR ESTADO: FINALIZADO → RECIBIDO
-- ============================================
-- 
-- Este script migra todos los registros que tienen estado 'FINALIZADO'
-- al nuevo estado 'RECIBIDO' para mantener consistencia con la nueva nomenclatura.
--
-- IMPORTANTE: Ejecuta este script en el SQL Editor de Supabase
-- Ruta: Dashboard > SQL Editor > New Query
-- ============================================

-- Paso 1: Verificar cuántos registros tienen estado FINALIZADO
SELECT 
    'Registros con estado FINALIZADO' as descripcion,
    COUNT(*) as total
FROM public.t_bitacora_envios
WHERE estado = 'FINALIZADO';

-- Paso 2: Verificar el estado actual de la columna
SELECT 
    estado,
    COUNT(*) as total
FROM public.t_bitacora_envios
GROUP BY estado
ORDER BY estado;

-- Paso 3: Verificar si hay registros con valores NULL o inválidos
SELECT 
    'Registros con estado NULL o inválido' as descripcion,
    COUNT(*) as total
FROM public.t_bitacora_envios
WHERE estado IS NULL 
   OR estado NOT IN ('ENVIADO', 'EN_TRANSITO', 'FINALIZADO', 'RECIBIDO');

-- Paso 4: Eliminar el constraint CHECK antiguo (si existe)
-- Esto es necesario para poder actualizar los datos
ALTER TABLE public.t_bitacora_envios
DROP CONSTRAINT IF EXISTS t_bitacora_envios_estado_check;

-- Paso 5: Actualizar todos los registros de FINALIZADO a RECIBIDO
-- Ahora podemos hacerlo porque eliminamos el constraint
UPDATE public.t_bitacora_envios
SET 
    estado = 'RECIBIDO',
    actualizado_en = NOW(),
    actualizado_por = COALESCE(actualizado_por, 'Sistema - Migración')
WHERE estado = 'FINALIZADO';

-- Paso 6: Actualizar registros NULL a RECIBIDO (por si acaso)
UPDATE public.t_bitacora_envios
SET 
    estado = 'RECIBIDO',
    actualizado_en = NOW(),
    actualizado_por = COALESCE(actualizado_por, 'Sistema - Migración')
WHERE estado IS NULL;

-- Paso 7: Verificar que todos los registros tienen valores válidos antes de crear el constraint
SELECT 
    'Registros con valores inválidos (debería ser 0)' as descripcion,
    COUNT(*) as total
FROM public.t_bitacora_envios
WHERE estado IS NULL 
   OR estado NOT IN ('ENVIADO', 'EN_TRANSITO', 'RECIBIDO');

-- Paso 8: Crear el nuevo constraint CHECK con RECIBIDO en lugar de FINALIZADO
-- Solo se crea si todos los datos son válidos
ALTER TABLE public.t_bitacora_envios
ADD CONSTRAINT t_bitacora_envios_estado_check 
CHECK (estado IN ('ENVIADO', 'EN_TRANSITO', 'RECIBIDO'));

-- Paso 9: Verificar que la migración fue exitosa
SELECT 
    'Registros migrados exitosamente' as descripcion,
    COUNT(*) as total
FROM public.t_bitacora_envios
WHERE estado = 'RECIBIDO';

-- Paso 10: Verificar que no quedan registros con FINALIZADO
SELECT 
    'Registros que aún tienen FINALIZADO (debería ser 0)' as descripcion,
    COUNT(*) as total
FROM public.t_bitacora_envios
WHERE estado = 'FINALIZADO';

-- Paso 11: Mostrar resumen final por estado
SELECT 
    estado,
    COUNT(*) as total,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM public.t_bitacora_envios), 2) as porcentaje
FROM public.t_bitacora_envios
GROUP BY estado
ORDER BY estado;

-- ============================================
-- NOTAS
-- ============================================
-- 1. Este script actualiza el campo 'actualizado_en' y 'actualizado_por' 
--    para mantener un registro de la migración
-- 2. Si no hay registros con FINALIZADO, el UPDATE no afectará ninguna fila
-- 3. Después de ejecutar este script, todos los registros deberían tener:
--    - ENVIADO
--    - EN_TRANSITO
--    - RECIBIDO
-- 4. Si necesitas revertir el cambio, puedes ejecutar:
--    UPDATE public.t_bitacora_envios SET estado = 'FINALIZADO' WHERE estado = 'RECIBIDO';
--    (Aunque no se recomienda revertir después de usar RECIBIDO en producción)

