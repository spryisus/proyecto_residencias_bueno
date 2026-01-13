-- Script para relacionar el usuario responsable con todos los equipos
-- ============================================
-- IMPORTANTE: Este script asigna el mismo usuario responsable a TODOS los equipos
-- Solo ejecuta esto si todos los equipos deberían tener el mismo responsable

-- 1. Verificar cuál es el usuario responsable que existe
SELECT 
    id_usuario_responsable,
    nombre,
    apellido_paterno,
    apellido_materno,
    empresa,
    puesto
FROM public.t_computo_usuario_responsable
ORDER BY id_usuario_responsable
LIMIT 1;

-- 2. OPCIONAL: Si quieres asignar el usuario responsable a todos los equipos que no tienen uno
-- Descomenta las siguientes líneas y reemplaza el ID con el id_usuario_responsable correcto


-- Primero, verifica cuántos equipos se actualizarán
SELECT 
    COUNT(*) as equipos_a_actualizar
FROM public.t_computo_detalles_generales
WHERE id_usuario_responsable IS NULL;

-- Luego, actualiza todos los equipos sin responsable
-- Reemplaza 1 con el id_usuario_responsable correcto
UPDATE public.t_computo_detalles_generales
SET id_usuario_responsable = 1  -- ⚠️ CAMBIA ESTE ID POR EL CORRECTO
WHERE id_usuario_responsable IS NULL;

-- Verificar que se actualizó correctamente
SELECT 
    COUNT(*) as total_equipos,
    COUNT(id_usuario_responsable) as equipos_con_responsable,
    COUNT(*) - COUNT(id_usuario_responsable) as equipos_sin_responsable
FROM public.t_computo_detalles_generales;

-- 3. Si prefieres crear un usuario responsable diferente para cada equipo basado en algún criterio
-- (por ejemplo, basado en el usuario final), puedes usar esto:

/*
-- Crear usuario responsable basado en el usuario final (si no existe ya)
INSERT INTO public.t_computo_usuario_responsable (nombre, apellido_paterno, apellido_materno, empresa, puesto, expediente)
SELECT DISTINCT
    uf.nombre,
    uf.apellido_paterno,
    uf.apellido_materno,
    uf.empresa,
    uf.puesto,
    uf.expediente
FROM public.t_computo_usuario_final uf
WHERE NOT EXISTS (
    SELECT 1 FROM public.t_computo_usuario_responsable ur
    WHERE ur.nombre = uf.nombre
        AND ur.apellido_paterno = uf.apellido_paterno
        AND ur.apellido_materno = uf.apellido_materno
        AND ur.empresa = uf.empresa
        AND ur.puesto = uf.puesto
);

-- Luego relacionar los equipos con estos usuarios responsables
UPDATE public.t_computo_detalles_generales dg
SET id_usuario_responsable = ur.id_usuario_responsable
FROM public.t_computo_usuario_final uf
INNER JOIN public.t_computo_usuario_responsable ur
    ON ur.nombre = uf.nombre
    AND ur.apellido_paterno = uf.apellido_paterno
    AND ur.apellido_materno = uf.apellido_materno
    AND ur.empresa = uf.empresa
    AND ur.puesto = uf.puesto
WHERE dg.id_equipo_computo::TEXT = uf.id_equipo_computo::TEXT
    AND dg.id_usuario_responsable IS NULL;
*/


