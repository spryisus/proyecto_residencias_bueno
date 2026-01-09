-- Script para crear las vistas de cómputo que faltan en la base de datos
-- Versión que verifica la existencia de tablas y columnas antes de crear las vistas

-- Vista completa de equipos de cómputo
-- Incluye JOINs con empleados y ubicaciones para obtener nombres y direcciones
-- Solo hace JOINs si las tablas relacionadas existen y las columnas están presentes
DO $$
DECLARE
    tiene_empleados_computo BOOLEAN;
    tiene_ubicaciones_computo BOOLEAN;
    tiene_id_ubicacion_fisica BOOLEAN;
    tiene_id_ubicacion_admin BOOLEAN;
    tiene_id_empleado_asignado BOOLEAN;
    tiene_id_empleado_responsable BOOLEAN;
    query_sql TEXT;
BEGIN
    -- Verificar si la tabla t_equipos_computo existe
    IF EXISTS (
        SELECT 1 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 't_equipos_computo'
    ) THEN
        -- Verificar existencia de tablas relacionadas
        SELECT EXISTS (
            SELECT 1 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = 't_empleados_computo'
        ) INTO tiene_empleados_computo;
        
        SELECT EXISTS (
            SELECT 1 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = 't_ubicaciones_computo'
        ) INTO tiene_ubicaciones_computo;
        
        -- Verificar existencia de columnas en t_equipos_computo
        SELECT EXISTS (
            SELECT 1 
            FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 't_equipos_computo'
            AND column_name = 'id_ubicacion_fisica'
        ) INTO tiene_id_ubicacion_fisica;
        
        SELECT EXISTS (
            SELECT 1 
            FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 't_equipos_computo'
            AND column_name = 'id_ubicacion_admin'
        ) INTO tiene_id_ubicacion_admin;
        
        SELECT EXISTS (
            SELECT 1 
            FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 't_equipos_computo'
            AND column_name = 'id_empleado_asignado'
        ) INTO tiene_id_empleado_asignado;
        
        SELECT EXISTS (
            SELECT 1 
            FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 't_equipos_computo'
            AND column_name = 'id_empleado_responsable'
        ) INTO tiene_id_empleado_responsable;
        
        -- Construir la vista dinámicamente según las tablas y columnas disponibles
        query_sql := 'CREATE OR REPLACE VIEW public.v_equipos_computo_completo AS SELECT ';
        
        -- Columnas básicas (siempre presentes)
        query_sql := query_sql || 'ec.id_equipo_computo, ec.id_equipo_original, ec.inventario, ec.equipo_pm, ec.fecha_registro, ';
        query_sql := query_sql || 'ec.tipo_equipo, ec.marca, ec.modelo, ec.procesador, ec.numero_serie, ';
        query_sql := query_sql || 'ec.disco_duro, ec.memoria, ec.sistema_operativo_instalado, ec.etiqueta_sistema_operativo, ';
        query_sql := query_sql || 'ec.office_instalado, ec.tipo_uso, ec.nombre_equipo_dominio, ec.status, ';
        query_sql := query_sql || 'ec.observaciones, ec.creado_en, ec.actualizado_en';
        
        -- Agregar columnas de FK si existen
        IF tiene_id_ubicacion_fisica THEN
            query_sql := query_sql || ', ec.id_ubicacion_fisica';
        END IF;
        IF tiene_id_ubicacion_admin THEN
            query_sql := query_sql || ', ec.id_ubicacion_admin';
        END IF;
        IF tiene_id_empleado_asignado THEN
            query_sql := query_sql || ', ec.id_empleado_asignado';
        END IF;
        IF tiene_id_empleado_responsable THEN
            query_sql := query_sql || ', ec.id_empleado_responsable';
        END IF;
        
        -- Agregar JOINs y campos calculados
        IF tiene_empleados_computo AND tiene_id_empleado_asignado THEN
            query_sql := query_sql || ', emp_asignado.nombre_completo AS empleado_asignado_nombre';
        ELSE
            query_sql := query_sql || ', NULL::text AS empleado_asignado_nombre';
        END IF;
        
        IF tiene_empleados_computo AND tiene_id_empleado_responsable THEN
            query_sql := query_sql || ', emp_responsable.nombre_completo AS empleado_responsable_nombre';
        ELSE
            query_sql := query_sql || ', NULL::text AS empleado_responsable_nombre';
        END IF;
        
        IF tiene_ubicaciones_computo AND tiene_id_ubicacion_fisica THEN
            query_sql := query_sql || ', ubic.direccion_fisica AS direccion_fisica, ubic.estado AS estado_ubicacion, ';
            query_sql := query_sql || 'ubic.ciudad AS ciudad_ubicacion, ubic.tipo_edificio, ubic.nombre_edificio, ';
            query_sql := query_sql || 'ubic.codigo_postal, ubic.direccion_fisica AS ubicacion_fisica';
        ELSE
            query_sql := query_sql || ', NULL::text AS direccion_fisica, NULL::text AS estado_ubicacion, ';
            query_sql := query_sql || 'NULL::text AS ciudad_ubicacion, NULL::text AS tipo_edificio, ';
            query_sql := query_sql || 'NULL::text AS nombre_edificio, NULL::text AS codigo_postal, ';
            query_sql := query_sql || 'NULL::text AS ubicacion_fisica';
        END IF;
        
        query_sql := query_sql || ' FROM public.t_equipos_computo ec';
        
        -- Agregar JOINs si las tablas y columnas existen
        IF tiene_empleados_computo AND tiene_id_empleado_asignado THEN
            query_sql := query_sql || ' LEFT JOIN public.t_empleados_computo emp_asignado ON ec.id_empleado_asignado = emp_asignado.id_empleado_computo';
        END IF;
        
        IF tiene_empleados_computo AND tiene_id_empleado_responsable THEN
            query_sql := query_sql || ' LEFT JOIN public.t_empleados_computo emp_responsable ON ec.id_empleado_responsable = emp_responsable.id_empleado_computo';
        END IF;
        
        IF tiene_ubicaciones_computo AND tiene_id_ubicacion_fisica THEN
            query_sql := query_sql || ' LEFT JOIN public.t_ubicaciones_computo ubic ON ec.id_ubicacion_fisica = ubic.id_ubicacion_computo';
        END IF;
        
        -- Ejecutar la consulta construida
        EXECUTE query_sql;
    ELSE
        RAISE NOTICE 'La tabla t_equipos_computo no existe. La vista v_equipos_computo_completo no se creará.';
    END IF;
END $$;

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
