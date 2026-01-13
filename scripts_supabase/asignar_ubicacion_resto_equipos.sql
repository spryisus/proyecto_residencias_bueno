-- Script para asignar ubicación a los equipos que no tienen una asignada
-- ============================================

-- 1. Ver todas las ubicaciones disponibles
SELECT 
    id_ubicacion,
    direccion_fisica,
    estado,
    ciudad,
    tipo_edificio,
    nombre_edificio
FROM public.t_computo_ubicacion
ORDER BY id_ubicacion;

-- 2. Ver qué equipos no tienen ubicación asignada
SELECT 
    id_equipo_computo,
    inventario,
    id_ubicacion
FROM public.t_computo_detalles_generales
WHERE id_ubicacion IS NULL
ORDER BY id_equipo_computo;

-- 3. Ver qué equipos ya tienen ubicación asignada
SELECT 
    id_equipo_computo,
    inventario,
    id_ubicacion
FROM public.t_computo_detalles_generales
WHERE id_ubicacion IS NOT NULL
ORDER BY id_equipo_computo;

-- 4. Asignar ubicación id_ubicacion = 1 a todos los equipos que no tienen ubicación
-- (El equipo con id_equipo_computo = 15 ya tiene id_ubicacion = 19, así que no se afectará)

-- Verificar que existe la ubicación con id_ubicacion = 1
DO $$
DECLARE
    ubicacion_existe BOOLEAN;
BEGIN
    -- Verificar si existe id_ubicacion = 1
    SELECT EXISTS(
        SELECT 1 FROM public.t_computo_ubicacion WHERE id_ubicacion = 1
    ) INTO ubicacion_existe;
    
    IF NOT ubicacion_existe THEN
        RAISE NOTICE '⚠️ La ubicación con id_ubicacion = 1 NO existe';
        RAISE NOTICE 'Por favor, verifica qué ubicaciones existen';
    ELSE
        RAISE NOTICE '✅ La ubicación con id_ubicacion = 1 existe';
        
        -- Asignar la ubicación id_ubicacion = 1 a todos los equipos sin ubicación
        UPDATE public.t_computo_detalles_generales
        SET id_ubicacion = 1
        WHERE id_ubicacion IS NULL;
        
        RAISE NOTICE '✅ Ubicación id_ubicacion = 1 asignada a todos los equipos sin ubicación';
    END IF;
END $$;

-- OPCION 2: Si quieres asignar la ubicación más común (la que más equipos tienen)
-- Primero verifica cuál es:
SELECT 
    id_ubicacion,
    COUNT(*) as cantidad_equipos
FROM public.t_computo_detalles_generales
WHERE id_ubicacion IS NOT NULL
GROUP BY id_ubicacion
ORDER BY cantidad_equipos DESC
LIMIT 1;

-- 5. Verificar el resultado después de asignar
SELECT 
    COUNT(*) as total_equipos,
    COUNT(id_ubicacion) as equipos_con_ubicacion,
    COUNT(*) - COUNT(id_ubicacion) as equipos_sin_ubicacion,
    COUNT(CASE WHEN id_ubicacion = 19 THEN 1 END) as equipos_en_ubicacion_19,
    COUNT(CASE WHEN id_ubicacion != 19 AND id_ubicacion IS NOT NULL THEN 1 END) as equipos_en_otra_ubicacion
FROM public.t_computo_detalles_generales;

-- 6. Mostrar todos los equipos con su ubicación asignada
SELECT 
    dg.id_equipo_computo,
    dg.inventario,
    dg.id_ubicacion,
    ub.direccion_fisica,
    ub.estado,
    ub.ciudad
FROM public.t_computo_detalles_generales dg
LEFT JOIN public.t_computo_ubicacion ub ON dg.id_ubicacion = ub.id_ubicacion
ORDER BY dg.id_equipo_computo;

