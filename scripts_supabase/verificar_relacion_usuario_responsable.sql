-- Script para verificar por qué no se relacionan los datos de usuario responsable
-- ============================================

-- 1. Verificar si hay registros en t_computo_usuario_responsable
SELECT 
    COUNT(*) as total_usuarios_responsables,
    COUNT(DISTINCT id_usuario_responsable) as usuarios_unicos
FROM public.t_computo_usuario_responsable;

-- 2. Ver los registros de usuario responsable que existen
SELECT 
    id_usuario_responsable,
    nombre,
    apellido_paterno,
    apellido_materno,
    empresa,
    puesto,
    expediente
FROM public.t_computo_usuario_responsable
ORDER BY id_usuario_responsable;

-- 3. Verificar cuántos equipos tienen id_usuario_responsable relacionado
SELECT 
    COUNT(*) as total_equipos,
    COUNT(id_usuario_responsable) as equipos_con_responsable,
    COUNT(*) - COUNT(id_usuario_responsable) as equipos_sin_responsable
FROM public.t_computo_detalles_generales;

-- 4. Ver algunos equipos y su id_usuario_responsable
SELECT 
    dg.id_equipo_computo,
    dg.inventario,
    dg.id_usuario_responsable,
    ur.nombre as nombre_responsable_en_tabla,
    ur.apellido_paterno as apellido_responsable_en_tabla
FROM public.t_computo_detalles_generales dg
LEFT JOIN public.t_computo_usuario_responsable ur 
    ON dg.id_usuario_responsable = ur.id_usuario_responsable
ORDER BY dg.id_equipo_computo
LIMIT 10;

-- 5. Verificar si hay algún patrón en los datos (por ejemplo, si todos los equipos deberían tener el mismo responsable)
SELECT 
    dg.id_usuario_responsable,
    COUNT(*) as cantidad_equipos,
    STRING_AGG(DISTINCT dg.inventario, ', ') as inventarios
FROM public.t_computo_detalles_generales dg
GROUP BY dg.id_usuario_responsable
ORDER BY cantidad_equipos DESC;


