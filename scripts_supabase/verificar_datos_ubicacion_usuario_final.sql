-- Script para verificar si los datos de ubicación y usuario final están relacionados correctamente
-- ============================================

-- 1. Verificar cuántos equipos tienen ubicación relacionada
SELECT 
    COUNT(DISTINCT dg.id_equipo_computo) as total_equipos,
    COUNT(DISTINCT dg.id_ubicacion) as equipos_con_ubicacion,
    COUNT(DISTINCT CASE WHEN dg.id_ubicacion IS NULL THEN dg.id_equipo_computo END) as equipos_sin_ubicacion
FROM public.t_computo_detalles_generales dg;

-- 2. Verificar cuántos equipos tienen usuario final relacionado
SELECT 
    COUNT(DISTINCT dg.id_equipo_computo) as total_equipos,
    COUNT(DISTINCT uf.id_usuario_final) as equipos_con_usuario_final,
    COUNT(DISTINCT CASE WHEN uf.id_usuario_final IS NULL THEN dg.id_equipo_computo END) as equipos_sin_usuario_final
FROM public.t_computo_detalles_generales dg
LEFT JOIN public.t_computo_usuario_final uf ON dg.id_equipo_computo::TEXT = uf.id_equipo_computo::TEXT;

-- 3. Verificar datos de ubicación en la vista
SELECT 
    COUNT(*) as total_registros_vista,
    COUNT(direccion_fisica) as con_direccion_fisica,
    COUNT(estado_ubicacion) as con_estado,
    COUNT(ciudad) as con_ciudad,
    COUNT(tipo_edificio) as con_tipo_edificio,
    COUNT(nombre_edificio) as con_nombre_edificio
FROM public.v_equipos_computo_completo;

-- 4. Verificar datos de usuario final en la vista
SELECT 
    COUNT(*) as total_registros_vista,
    COUNT(nombre_final) as con_nombre_final,
    COUNT(apellido_paterno_final) as con_apellido_paterno,
    COUNT(apellido_materno_final) as con_apellido_materno,
    COUNT(expediente_final) as con_expediente,
    COUNT(empresa_final) as con_empresa,
    COUNT(puesto_final) as con_puesto,
    COUNT(empleado_asignado_nombre) as con_nombre_completo
FROM public.v_equipos_computo_completo
WHERE TRIM(empleado_asignado_nombre) != '';

-- 5. Mostrar algunos ejemplos de equipos con y sin datos
SELECT 
    dg.id_equipo_computo,
    dg.inventario,
    dg.id_ubicacion,
    ub.direccion_fisica,
    ub.estado,
    ub.ciudad,
    uf.nombre AS nombre_final,
    uf.apellido_paterno AS apellido_paterno_final,
    uf.empresa AS empresa_final,
    uf.puesto AS puesto_final,
    uf.expediente AS expediente_final
FROM public.t_computo_detalles_generales dg
LEFT JOIN public.t_computo_ubicacion ub ON dg.id_ubicacion = ub.id_ubicacion
LEFT JOIN public.t_computo_usuario_final uf ON dg.id_equipo_computo::TEXT = uf.id_equipo_computo::TEXT
ORDER BY dg.id_equipo_computo
LIMIT 10;

