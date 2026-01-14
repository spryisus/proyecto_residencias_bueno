-- Script para corregir la rotación de datos en t_computo_usuario_final
-- Los datos están rotados: Apellido Paterno → Apellido Materno → Nombre → Apellido Paterno
-- 
-- Este script rota los datos correctamente:
-- - Apellido Paterno actual → se mueve a Apellido Materno
-- - Apellido Materno actual → se mueve a Nombre
-- - Nombre actual → se mueve a Apellido Paterno
--
-- ⚠️ IMPORTANTE: Hacer backup antes de ejecutar este script
-- ⚠️ Este script actualiza TODOS los registros de la tabla

BEGIN;

-- Crear tabla temporal para almacenar los valores actuales
CREATE TEMP TABLE temp_usuario_final_rotacion AS
SELECT 
    id_usuario_final,
    apellido_paterno AS apellido_paterno_actual,
    apellido_materno AS apellido_materno_actual,
    nombre AS nombre_actual
FROM public.t_computo_usuario_final;

-- Verificar cuántos registros se van a actualizar
DO $$
DECLARE
    total_registros INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_registros
    FROM public.t_computo_usuario_final;
    
    RAISE NOTICE 'Se actualizarán % registros en t_computo_usuario_final', total_registros;
END $$;

-- Actualizar los datos rotando las columnas
UPDATE public.t_computo_usuario_final uf
SET 
    -- Nombre actual → Apellido Paterno (rotación)
    apellido_paterno = temp.nombre_actual,
    -- Apellido Paterno actual → Apellido Materno (rotación)
    apellido_materno = temp.apellido_paterno_actual,
    -- Apellido Materno actual → Nombre (rotación)
    nombre = temp.apellido_materno_actual,
    -- Actualizar timestamp
    actualizado_en = NOW()
FROM temp_usuario_final_rotacion temp
WHERE uf.id_usuario_final = temp.id_usuario_final;

-- Verificar los cambios (muestra algunos ejemplos)
SELECT 
    id_usuario_final,
    expediente,
    apellido_paterno AS nuevo_apellido_paterno,
    apellido_materno AS nuevo_apellido_materno,
    nombre AS nuevo_nombre,
    empresa,
    puesto,
    actualizado_en
FROM public.t_computo_usuario_final
ORDER BY id_usuario_final
LIMIT 10;

-- Mostrar resumen
DO $$
DECLARE
    total_actualizados INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_actualizados
    FROM public.t_computo_usuario_final
    WHERE actualizado_en >= NOW() - INTERVAL '1 minute';
    
    RAISE NOTICE '✅ Actualización completada. % registros actualizados.', total_actualizados;
END $$;

-- La tabla temporal se elimina automáticamente al final de la sesión
-- DROP TABLE IF EXISTS temp_usuario_final_rotacion;

COMMIT;

-- ============================================
-- VERIFICACIÓN POST-ACTUALIZACIÓN
-- ============================================
-- Ejecuta estas consultas para verificar que los datos se rotaron correctamente:

-- Ver algunos ejemplos de los datos corregidos
-- SELECT 
--     id_usuario_final,
--     expediente,
--     apellido_paterno,
--     apellido_materno,
--     nombre,
--     empresa,
--     puesto
-- FROM public.t_computo_usuario_final
-- ORDER BY id_usuario_final
-- LIMIT 20;

