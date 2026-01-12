-- Vista completa que une todas las tablas de cómputo
-- Esta vista facilita las consultas combinando todos los apartados

CREATE OR REPLACE VIEW public.v_equipos_computo_completo AS
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
    
    -- Software
    sw.sistema_operativo_instalado,
    sw.etiqueta_sistema_operativo,
    sw.office_instalado,
    
    -- Ubicación
    ub.id_ubicacion,
    ub.direccion_fisica,
    ub.estado AS estado_ubicacion,
    ub.ciudad,
    ub.tipo_edificio,
    ub.nombre_edificio,
    
    -- Identificación
    id.tipo_uso,
    id.nombre_equipo_dominio,
    id.status,
    id.direccion_administrativa,
    id.subdireccion,
    id.gerencia,
    
    -- Usuario Responsable
    ur.id_usuario_responsable,
    ur.expediente AS expediente_responsable,
    ur.apellido_paterno AS apellido_paterno_responsable,
    ur.apellido_materno AS apellido_materno_responsable,
    ur.nombre AS nombre_responsable,
    ur.empresa AS empresa_responsable,
    ur.puesto AS puesto_responsable,
    
    -- Usuario Final
    uf.id_usuario_final,
    uf.expediente AS expediente_final,
    uf.apellido_paterno AS apellido_paterno_final,
    uf.apellido_materno AS apellido_materno_final,
    uf.nombre AS nombre_final,
    uf.empresa AS empresa_final,
    uf.puesto AS puesto_final,
    -- Campo combinado para mostrar nombre completo del usuario final
    TRIM(
      CONCAT(
        COALESCE(uf.nombre, ''),
        ' ',
        COALESCE(uf.apellido_paterno, ''),
        ' ',
        COALESCE(uf.apellido_materno, '')
      )
    ) AS empleado_asignado_nombre,
    
    -- Observaciones
    obs.observaciones
    
FROM public.t_computo_equipos_principales ep
LEFT JOIN public.t_computo_detalles_generales dg 
    ON dg.equipo_pm = ep.id_equipo_principal
LEFT JOIN public.t_computo_software sw 
    ON dg.id_equipo_computo = sw.id_equipo_computo
LEFT JOIN public.t_computo_ubicacion ub 
    ON dg.id_ubicacion = ub.id_ubicacion
LEFT JOIN public.t_computo_identificacion id 
    ON dg.id_equipo_computo::TEXT = id.id_equipo_computo::TEXT
LEFT JOIN public.t_computo_usuario_responsable ur 
    ON dg.id_usuario_responsable = ur.id_usuario_responsable
LEFT JOIN public.t_computo_usuario_final uf 
    ON dg.id_equipo_computo::TEXT = uf.id_equipo_computo::TEXT
LEFT JOIN public.t_computo_observaciones obs 
    ON dg.id_equipo_computo::TEXT = obs.id_equipo_computo
ORDER BY ep.id_equipo_principal, dg.id_equipo_computo;

-- Comentarios para documentación
COMMENT ON VIEW public.v_equipos_computo_completo IS 
'Vista completa que une todos los apartados del inventario de cómputo: detalles generales, software, ubicación, identificación, usuario responsable, usuario final y observaciones';

