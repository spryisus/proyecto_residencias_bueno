-- Script para crear la relación entre t_computo_ubicacion y t_computo_detalles_generales
-- y asignar la ubicación al equipo con id_equipo_computo = 15
-- ============================================

-- 1. Verificar si existe la columna id_ubicacion en t_computo_detalles_generales
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 't_computo_detalles_generales'
        AND column_name = 'id_ubicacion'
    ) THEN
        -- Agregar la columna si no existe
        ALTER TABLE public.t_computo_detalles_generales
        ADD COLUMN id_ubicacion BIGINT;
        
        RAISE NOTICE 'Columna id_ubicacion agregada a t_computo_detalles_generales';
    ELSE
        RAISE NOTICE 'La columna id_ubicacion ya existe en t_computo_detalles_generales';
    END IF;
END $$;

-- 2. Verificar si existe el constraint de foreign key
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_schema = 'public' 
        AND constraint_name = 'fk_equipo_ubicacion'
        AND table_name = 't_computo_detalles_generales'
    ) THEN
        -- Crear el constraint de foreign key
        ALTER TABLE public.t_computo_detalles_generales
        ADD CONSTRAINT fk_equipo_ubicacion 
            FOREIGN KEY (id_ubicacion) 
            REFERENCES public.t_computo_ubicacion(id_ubicacion) 
            ON DELETE SET NULL;
        
        RAISE NOTICE 'Constraint fk_equipo_ubicacion creado';
    ELSE
        RAISE NOTICE 'El constraint fk_equipo_ubicacion ya existe';
    END IF;
END $$;

-- 3. Verificar que existe el equipo con id_equipo_computo = 15
SELECT 
    id_equipo_computo,
    inventario,
    id_ubicacion as ubicacion_actual
FROM public.t_computo_detalles_generales
WHERE id_equipo_computo = 15;

-- 4. Verificar qué ubicaciones existen
SELECT 
    id_ubicacion,
    direccion_fisica,
    estado,
    ciudad,
    tipo_edificio,
    nombre_edificio
FROM public.t_computo_ubicacion
ORDER BY id_ubicacion;

-- 5. Verificar que existe la ubicación con id_ubicacion = 19
DO $$
DECLARE
    ubicacion_existe BOOLEAN;
BEGIN
    -- Verificar si existe id_ubicacion = 19
    SELECT EXISTS(
        SELECT 1 FROM public.t_computo_ubicacion WHERE id_ubicacion = 19
    ) INTO ubicacion_existe;
    
    IF NOT ubicacion_existe THEN
        RAISE NOTICE '⚠️ La ubicación con id_ubicacion = 19 NO existe';
        RAISE NOTICE 'Por favor, verifica qué ubicaciones existen y ajusta el script';
        RAISE NOTICE 'O crea la ubicación primero antes de asignarla';
    ELSE
        RAISE NOTICE '✅ La ubicación con id_ubicacion = 19 existe';
        
        -- Asignar la ubicación id_ubicacion = 19 al equipo con id_equipo_computo = 15
        UPDATE public.t_computo_detalles_generales
        SET id_ubicacion = 19
        WHERE id_equipo_computo = 15;
        
        RAISE NOTICE '✅ Ubicación asignada correctamente al equipo id_equipo_computo = 15';
    END IF;
END $$;

-- 6. Verificar que se asignó correctamente
SELECT 
    dg.id_equipo_computo,
    dg.inventario,
    dg.id_ubicacion,
    ub.direccion_fisica,
    ub.estado,
    ub.ciudad,
    ub.tipo_edificio,
    ub.nombre_edificio
FROM public.t_computo_detalles_generales dg
LEFT JOIN public.t_computo_ubicacion ub ON dg.id_ubicacion = ub.id_ubicacion
WHERE dg.id_equipo_computo = 15;

-- 7. Mostrar resumen de ubicaciones asignadas
SELECT 
    COUNT(*) as total_equipos,
    COUNT(id_ubicacion) as equipos_con_ubicacion,
    COUNT(*) - COUNT(id_ubicacion) as equipos_sin_ubicacion,
    COUNT(CASE WHEN id_ubicacion = 19 THEN 1 END) as equipos_en_ubicacion_19
FROM public.t_computo_detalles_generales;

