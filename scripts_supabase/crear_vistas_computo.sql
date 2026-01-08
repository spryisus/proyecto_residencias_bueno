-- Script para crear las vistas de cómputo que faltan en la base de datos
-- Versión simplificada que solo crea vistas para tablas que existen

-- Vista completa de equipos de cómputo
-- Solo incluye columnas básicas de la tabla t_equipos_computo
CREATE OR REPLACE VIEW public.v_equipos_computo_completo AS
SELECT 
    id_equipo_computo,
    id_equipo_original,
    inventario,
    equipo_pm,
    fecha_registro,
    tipo_equipo,
    marca,
    modelo,
    procesador,
    numero_serie,
    disco_duro,
    memoria,
    sistema_operativo_instalado,
    etiqueta_sistema_operativo,
    office_instalado,
    tipo_uso,
    nombre_equipo_dominio,
    status,
    observaciones,
    creado_en,
    actualizado_en
FROM public.t_equipos_computo;

-- Vista completa de componentes de cómputo (solo si la tabla existe)
-- Esta vista se crea condicionalmente
DO $$
BEGIN
    -- Verificar si la tabla t_componentes_computo existe
    IF EXISTS (
        SELECT 1 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 't_componentes_computo'
    ) THEN
        -- Crear la vista de componentes
        EXECUTE '
        CREATE OR REPLACE VIEW public.v_componentes_computo_completo AS
        SELECT 
            cc.id_componente_computo,
            cc.id_equipo_computo,
            cc.tipo_componente,
            cc.inventario AS inventario_componente,
            cc.marca,
            cc.modelo,
            cc.numero_serie,
            cc.fecha_registro,
            cc.observaciones,
            cc.creado_en,
            cc.actualizado_en,
            ec.inventario AS inventario_equipo,
            ec.tipo_equipo,
            ec.marca AS marca_equipo,
            ec.modelo AS modelo_equipo
        FROM public.t_componentes_computo cc
        INNER JOIN public.t_equipos_computo ec 
            ON cc.id_equipo_computo = ec.id_equipo_computo';
    ELSE
        -- Si la tabla no existe, crear una vista vacía o simplemente no crearla
        -- En este caso, no creamos la vista si la tabla no existe
        RAISE NOTICE 'La tabla t_componentes_computo no existe. La vista v_componentes_computo_completo no se creará.';
    END IF;
END $$;

-- Comentarios para documentación
COMMENT ON VIEW public.v_equipos_computo_completo IS 
'Vista completa de equipos de cómputo con todas las columnas básicas de la tabla';
