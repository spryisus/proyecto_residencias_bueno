-- ============================================
-- RECREAR VISTA COMPUTO COMPLETO
-- ============================================
-- Este script recrea la vista v_equipos_computo_completo
-- para asegurar que refleje los datos corregidos de t_computo_usuario_final
--
-- ⚠️ IMPORTANTE: Ejecuta este script después de corregir los datos en t_computo_usuario_final
-- ============================================

-- Eliminar la vista existente
DROP VIEW IF EXISTS public.v_equipos_computo_completo CASCADE;

-- Recrear la vista con los datos corregidos
CREATE VIEW public.v_equipos_computo_completo AS
WITH equipos_base AS (
    SELECT DISTINCT ON (ep.id_equipo_principal)
        -- Equipo Principal
        ep.id_equipo_principal,
        ep.equipo_pm,
        
        -- Detalles Generales (Componentes) - Solo el primer componente del equipo principal
        dg.id_equipo_computo,
        dg.inventario,
        dg.fecha_registro,
        dg.tipo_equipo,
        dg.marca,
        dg.modelo,
        dg.procesador,
        dg.numero_serie,
        dg.disco_duro,
        dg.memoria_ram,
        dg.creado_en AS detalles_creado_en,
        dg.actualizado_en AS detalles_actualizado_en,
        dg.id_ubicacion AS id_ubicacion_dg,
        dg.id_usuario_responsable AS id_usuario_responsable_dg,
        
        -- Software
        sw.sistema_operativo_instalado,
        sw.etiqueta_sistema_operativo,
        sw.office_instalado,
        
        -- Identificación
        id.tipo_uso,
        id.nombre_equipo_dominio,
        id.status,
        id.direccion_administrativa,
        id.subdireccion,
        id.gerencia,
        
        -- Observaciones
        obs.observaciones
        
    FROM public.t_computo_equipos_principales ep
    LEFT JOIN public.t_computo_detalles_generales dg 
        ON dg.equipo_pm = ep.id_equipo_principal
    LEFT JOIN public.t_computo_software sw 
        ON dg.id_equipo_computo = sw.id_equipo_computo
    LEFT JOIN public.t_computo_identificacion id 
        ON dg.id_equipo_computo::TEXT = id.id_equipo_computo::TEXT
    LEFT JOIN public.t_computo_observaciones obs 
        ON dg.id_equipo_computo::TEXT = obs.id_equipo_computo
    ORDER BY 
        ep.id_equipo_principal, 
        dg.id_equipo_computo
)
SELECT 
    eb.id_equipo_principal,
    eb.equipo_pm,
    eb.id_equipo_computo,
    eb.inventario,
    eb.fecha_registro,
    eb.tipo_equipo,
    eb.marca,
    eb.modelo,
    eb.procesador,
    eb.numero_serie,
    eb.disco_duro,
    eb.memoria_ram,
    eb.detalles_creado_en,
    eb.detalles_actualizado_en,
    eb.sistema_operativo_instalado,
    eb.etiqueta_sistema_operativo,
    eb.office_instalado,
    eb.tipo_uso,
    eb.nombre_equipo_dominio,
    eb.status,
    eb.direccion_administrativa,
    eb.subdireccion,
    eb.gerencia,
    eb.observaciones,
    
    -- Ubicación (obtener de cualquier registro relacionado con el equipo_pm)
    ub.id_ubicacion,
    ub.direccion_fisica,
    ub.estado AS estado_ubicacion,
    ub.ciudad,
    ub.tipo_edificio,
    ub.nombre_edificio,
    
    -- Usuario Responsable
    ur.id_usuario_responsable,
    ur.expediente AS expediente_responsable,
    ur.apellido_paterno AS apellido_paterno_responsable,
    ur.apellido_materno AS apellido_materno_responsable,
    ur.nombre AS nombre_responsable,
    ur.empresa AS empresa_responsable,
    ur.puesto AS puesto_responsable,
    
    -- Usuario Final (obtener de cualquier registro relacionado con cualquier id_equipo_computo del mismo equipo_pm)
    -- NOTA: Los datos ya están corregidos en t_computo_usuario_final, así que los obtenemos directamente
    uf.id_usuario_final,
    uf.expediente AS expediente_final,
    uf.apellido_paterno AS apellido_paterno_final,
    uf.apellido_materno AS apellido_materno_final,
    uf.nombre AS nombre_final,
    uf.empresa AS empresa_final,
    uf.puesto AS puesto_final,
    -- Campo combinado para mostrar nombre completo del usuario final
    -- Orden correcto: Nombre + Apellido Paterno + Apellido Materno
    TRIM(
      CONCAT(
        COALESCE(uf.nombre, ''),
        ' ',
        COALESCE(uf.apellido_paterno, ''),
        ' ',
        COALESCE(uf.apellido_materno, '')
      )
    ) AS empleado_asignado_nombre
    
FROM equipos_base eb
LEFT JOIN public.t_computo_ubicacion ub 
    ON eb.id_ubicacion_dg = ub.id_ubicacion
LEFT JOIN public.t_computo_usuario_responsable ur 
    ON eb.id_usuario_responsable_dg = ur.id_usuario_responsable
-- Obtener usuario final de cualquier registro relacionado con el mismo equipo_pm
LEFT JOIN LATERAL (
    SELECT DISTINCT ON (uf2.id_equipo_computo)
        uf2.*
    FROM public.t_computo_usuario_final uf2
    INNER JOIN public.t_computo_detalles_generales dg2 
        ON dg2.id_equipo_computo::TEXT = uf2.id_equipo_computo::TEXT
    WHERE dg2.equipo_pm = eb.id_equipo_principal
        AND uf2.id_usuario_final IS NOT NULL
    ORDER BY uf2.id_equipo_computo, uf2.id_usuario_final
    LIMIT 1
) uf ON true;

-- Comentarios para documentación
COMMENT ON VIEW public.v_equipos_computo_completo IS 
'Vista completa que une todos los apartados del inventario de cómputo: detalles generales, software, ubicación, identificación, usuario responsable, usuario final y observaciones. Los datos del usuario final ya están corregidos en t_computo_usuario_final.';

-- Verificar que la vista se creó correctamente
SELECT 
    'Vista recreada correctamente' AS estado,
    COUNT(*) AS total_registros
FROM public.v_equipos_computo_completo;

-- Mostrar algunos ejemplos para verificar los datos
SELECT 
    equipo_pm,
    inventario,
    expediente_final,
    apellido_paterno_final,
    apellido_materno_final,
    nombre_final,
    empleado_asignado_nombre,
    empresa_final,
    puesto_final
FROM public.v_equipos_computo_completo
WHERE nombre_final IS NOT NULL
ORDER BY equipo_pm
LIMIT 10;

