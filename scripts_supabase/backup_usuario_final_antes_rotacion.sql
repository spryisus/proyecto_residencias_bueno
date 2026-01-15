-- ============================================
-- BACKUP ANTES DE CORREGIR ROTACIÓN DE DATOS
-- ============================================
-- Este script crea una tabla de backup de t_computo_usuario_final
-- antes de ejecutar la corrección de rotación
--
-- ⚠️ IMPORTANTE: Ejecuta este script ANTES de corregir_rotacion_usuario_final.sql
-- ============================================

-- Crear tabla de backup con timestamp
CREATE TABLE IF NOT EXISTS public.t_computo_usuario_final_backup_pre_rotacion AS
SELECT 
    *,
    NOW() AS fecha_backup
FROM public.t_computo_usuario_final;

-- Verificar que el backup se creó correctamente
DO $$
DECLARE
    total_original INTEGER;
    total_backup INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_original
    FROM public.t_computo_usuario_final;
    
    SELECT COUNT(*) INTO total_backup
    FROM public.t_computo_usuario_final_backup_pre_rotacion;
    
    IF total_original = total_backup THEN
        RAISE NOTICE '✅ Backup creado correctamente. % registros respaldados.', total_backup;
    ELSE
        RAISE WARNING '⚠️  Advertencia: El número de registros no coincide. Original: %, Backup: %', total_original, total_backup;
    END IF;
END $$;

-- Mostrar algunos registros del backup para verificación
SELECT 
    'BACKUP CREADO' AS estado,
    COUNT(*) AS total_registros,
    MIN(fecha_backup) AS fecha_backup
FROM public.t_computo_usuario_final_backup_pre_rotacion;

-- Mostrar algunos ejemplos del backup
SELECT 
    id_usuario_final,
    expediente,
    apellido_paterno,
    apellido_materno,
    nombre,
    empresa,
    puesto
FROM public.t_computo_usuario_final_backup_pre_rotacion
ORDER BY id_usuario_final
LIMIT 10;

-- ============================================
-- INSTRUCCIONES PARA RESTAURAR (si es necesario)
-- ============================================
-- Si necesitas restaurar los datos desde el backup, ejecuta:
--
-- BEGIN;
-- TRUNCATE TABLE public.t_computo_usuario_final;
-- INSERT INTO public.t_computo_usuario_final 
--     (id_usuario_final, id_equipo_computo, expediente, apellido_paterno, apellido_materno, nombre, empresa, puesto, creado_en, actualizado_en)
-- SELECT 
--     id_usuario_final, id_equipo_computo, expediente, apellido_paterno, apellido_materno, nombre, empresa, puesto, creado_en, actualizado_en
-- FROM public.t_computo_usuario_final_backup_pre_rotacion;
-- COMMIT;
--
-- ============================================



