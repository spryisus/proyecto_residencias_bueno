-- Script para verificar la diferencia entre usuario responsable y usuario final
-- ============================================

-- 1. Verificar cuántos registros hay en cada tabla
SELECT 
    't_computo_usuario_responsable' as tabla,
    COUNT(*) as total_registros
FROM public.t_computo_usuario_responsable
UNION ALL
SELECT 
    't_computo_usuario_final' as tabla,
    COUNT(*) as total_registros
FROM public.t_computo_usuario_final;

-- 2. Ver algunos ejemplos de usuario responsable
SELECT 
    ur.id_usuario_responsable,
    ur.nombre,
    ur.apellido_paterno,
    ur.apellido_materno,
    ur.empresa,
    ur.puesto,
    ur.expediente,
    COUNT(dg.id_equipo_computo) as equipos_asignados
FROM public.t_computo_usuario_responsable ur
LEFT JOIN public.t_computo_detalles_generales dg 
    ON dg.id_usuario_responsable = ur.id_usuario_responsable
GROUP BY ur.id_usuario_responsable, ur.nombre, ur.apellido_paterno, ur.apellido_materno, ur.empresa, ur.puesto, ur.expediente
ORDER BY ur.id_usuario_responsable
LIMIT 10;

-- 3. Ver algunos ejemplos de usuario final
SELECT 
    uf.id_usuario_final,
    uf.id_equipo_computo,
    uf.nombre,
    uf.apellido_paterno,
    uf.apellido_materno,
    uf.empresa,
    uf.puesto,
    uf.expediente,
    dg.inventario
FROM public.t_computo_usuario_final uf
LEFT JOIN public.t_computo_detalles_generales dg 
    ON dg.id_equipo_computo::TEXT = uf.id_equipo_computo::TEXT
ORDER BY uf.id_usuario_final
LIMIT 10;

-- 4. Verificar qué devuelve la vista para un equipo específico
SELECT 
    equipo_pm,
    inventario,
    nombre_responsable,
    apellido_paterno_responsable,
    empresa_responsable,
    puesto_responsable,
    nombre_final,
    apellido_paterno_final,
    empresa_final,
    puesto_final,
    empleado_asignado_nombre
FROM public.v_equipos_computo_completo
ORDER BY equipo_pm
LIMIT 5;

-- 5. Verificar si hay equipos donde usuario responsable y usuario final son iguales
SELECT 
    equipo_pm,
    inventario,
    nombre_responsable || ' ' || apellido_paterno_responsable as responsable_completo,
    nombre_final || ' ' || apellido_paterno_final as final_completo,
    CASE 
        WHEN nombre_responsable = nombre_final 
            AND apellido_paterno_responsable = apellido_paterno_final 
        THEN 'IGUALES'
        ELSE 'DIFERENTES'
    END as comparacion
FROM public.v_equipos_computo_completo
WHERE nombre_responsable IS NOT NULL 
    AND nombre_final IS NOT NULL
ORDER BY equipo_pm
LIMIT 10;


