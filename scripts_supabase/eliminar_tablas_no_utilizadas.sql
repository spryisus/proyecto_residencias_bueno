-- ============================================
-- ELIMINAR TABLAS NO UTILIZADAS Y OPTIMIZAR CONSULTAS
-- ============================================
--
-- Este script elimina las tablas que NO están siendo utilizadas en la aplicación
-- y optimiza las consultas existentes con subconsultas donde sea necesario.
--
-- IMPORTANTE: 
-- 1. Hacer BACKUP completo de la base de datos antes de ejecutar
-- 2. Verificar que estas tablas realmente no se usen en producción
-- 3. Ejecutar este script en el SQL Editor de Supabase
-- Ruta: Dashboard > SQL Editor > New Query
-- ============================================

-- ============================================
-- PASO 1: VERIFICAR TABLAS A ELIMINAR
-- ============================================
-- Ejecutar estas consultas primero para verificar que las tablas están vacías o no se usan

-- Verificar registros en tablas a eliminar
SELECT 
    't_computo' as tabla,
    COUNT(*) as registros
FROM public.t_computo
UNION ALL
SELECT 
    't_envios' as tabla,
    COUNT(*) as registros
FROM public.t_envios
UNION ALL
SELECT 
    't_envios_detalles' as tabla,
    COUNT(*) as registros
FROM public.t_envios_detalles
UNION ALL
SELECT 
    't_historial_asignaciones' as tabla,
    COUNT(*) as registros
FROM public.t_historial_asignaciones
UNION ALL
SELECT 
    't_reportes' as tabla,
    COUNT(*) as registros
FROM public.t_reportes
UNION ALL
SELECT 
    't_reportes_inventarios' as tabla,
    COUNT(*) as registros
FROM public.t_reportes_inventarios
UNION ALL
SELECT 
    't_ubicaciones_administrativas' as tabla,
    COUNT(*) as registros
FROM public.t_ubicaciones_administrativas
UNION ALL
SELECT 
    't_ubicaciones_computo' as tabla,
    COUNT(*) as registros
FROM public.t_ubicaciones_computo;

-- ============================================
-- PASO 2: ELIMINAR FOREIGN KEYS Y CONSTRAINTS
-- ============================================

-- Eliminar FK de t_equipos_computo a t_ubicaciones_administrativas
ALTER TABLE public.t_equipos_computo
DROP CONSTRAINT IF EXISTS fk_ubicacion_admin;

-- Eliminar FK de t_equipos_computo a t_ubicaciones_computo
ALTER TABLE public.t_equipos_computo
DROP CONSTRAINT IF EXISTS fk_ubicacion_fisica;

-- Eliminar FK de t_historial_asignaciones
ALTER TABLE public.t_historial_asignaciones
DROP CONSTRAINT IF EXISTS fk_equipo_historial;

ALTER TABLE public.t_historial_asignaciones
DROP CONSTRAINT IF EXISTS fk_empleado_historial;

-- Eliminar FK de t_reportes_inventarios
ALTER TABLE public.t_reportes_inventarios
DROP CONSTRAINT IF EXISTS t_reportes_inventarios_id_reporte_fkey;

ALTER TABLE public.t_reportes_inventarios
DROP CONSTRAINT IF EXISTS t_reportes_inventarios_id_inventario_fkey;

-- Eliminar FK de t_reportes
ALTER TABLE public.t_reportes
DROP CONSTRAINT IF EXISTS t_reportes_id_empleado_fkey;

-- Eliminar FK de t_envios_detalles
ALTER TABLE public.t_envios_detalles
DROP CONSTRAINT IF EXISTS t_envios_detalles_id_envio_fkey;

ALTER TABLE public.t_envios_detalles
DROP CONSTRAINT IF EXISTS t_envios_detalles_id_producto_fkey;

-- Eliminar FK de t_envios
ALTER TABLE public.t_envios
DROP CONSTRAINT IF EXISTS t_envios_id_origen_fkey;

ALTER TABLE public.t_envios
DROP CONSTRAINT IF EXISTS t_envios_id_destino_fkey;

-- Eliminar FK de t_movimientos_inventario a t_envios_detalles
ALTER TABLE public.t_movimientos_inventario
DROP CONSTRAINT IF EXISTS t_movimientos_inventario_id_envio_detalle_fkey;

-- Eliminar FK de t_movimientos_inventario a t_reportes
ALTER TABLE public.t_movimientos_inventario
DROP CONSTRAINT IF EXISTS t_movimientos_inventario_id_reporte_fkey;

-- ============================================
-- PASO 3: ELIMINAR TABLAS (en orden de dependencias)
-- ============================================

-- Eliminar tablas dependientes primero
DROP TABLE IF EXISTS public.t_reportes_inventarios CASCADE;
DROP TABLE IF EXISTS public.t_historial_asignaciones CASCADE;
DROP TABLE IF EXISTS public.t_envios_detalles CASCADE;
DROP TABLE IF EXISTS public.t_componentes_computo CASCADE; -- Solo si no se usa

-- Eliminar tablas principales
DROP TABLE IF EXISTS public.t_reportes CASCADE;
DROP TABLE IF EXISTS public.t_envios CASCADE;
DROP TABLE IF EXISTS public.t_computo CASCADE;
DROP TABLE IF EXISTS public.t_ubicaciones_administrativas CASCADE;
DROP TABLE IF EXISTS public.t_ubicaciones_computo CASCADE;

-- ============================================
-- PASO 4: ACTUALIZAR t_equipos_computo
-- ============================================
-- Eliminar columnas que referencian tablas eliminadas

ALTER TABLE public.t_equipos_computo
DROP COLUMN IF EXISTS id_ubicacion_fisica;

ALTER TABLE public.t_equipos_computo
DROP COLUMN IF EXISTS id_ubicacion_admin;

-- ============================================
-- PASO 5: ACTUALIZAR t_movimientos_inventario
-- ============================================
-- Eliminar columnas que referencian tablas eliminadas

ALTER TABLE public.t_movimientos_inventario
DROP COLUMN IF EXISTS id_envio_detalle;

ALTER TABLE public.t_movimientos_inventario
DROP COLUMN IF EXISTS id_reporte;

-- ============================================
-- PASO 6: OPTIMIZAR CONSULTAS CON SUBCONSULTAS
-- ============================================

-- Crear índices para mejorar rendimiento de consultas frecuentes
CREATE INDEX IF NOT EXISTS idx_bitacora_envios_fecha 
ON public.t_bitacora_envios(fecha DESC);

CREATE INDEX IF NOT EXISTS idx_bitacora_envios_tarjeta 
ON public.t_bitacora_envios(tarjeta) 
WHERE tarjeta IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_bitacora_envios_codigo 
ON public.t_bitacora_envios(codigo) 
WHERE codigo IS NOT NULL;

-- Índice para búsqueda por últimos 4 caracteres del código
-- (PostgreSQL puede usar este índice con LIKE '%XXXX')
CREATE INDEX IF NOT EXISTS idx_bitacora_envios_codigo_suffix 
ON public.t_bitacora_envios(SUBSTRING(codigo FROM LENGTH(codigo) - 3)) 
WHERE codigo IS NOT NULL AND LENGTH(codigo) >= 4;

-- Índice compuesto para filtros comunes
CREATE INDEX IF NOT EXISTS idx_bitacora_envios_fecha_tarjeta_estado 
ON public.t_bitacora_envios(fecha DESC, tarjeta, estado) 
WHERE tarjeta IS NOT NULL AND estado IS NOT NULL;

-- ============================================
-- PASO 7: CREAR VISTA OPTIMIZADA PARA BÚSQUEDAS
-- ============================================

-- Vista para búsquedas rápidas de bitácoras con filtros comunes
CREATE OR REPLACE VIEW v_bitacora_envios_busqueda AS
SELECT 
    id_bitacora,
    consecutivo,
    fecha,
    tecnico,
    tarjeta,
    codigo,
    serie,
    folio,
    envia,
    recibe,
    guia,
    anexos,
    observaciones,
    cobo,
    estado,
    creado_en,
    actualizado_en,
    creado_por,
    actualizado_por,
    -- Campos calculados para búsqueda
    EXTRACT(YEAR FROM fecha::date) as año,
    SUBSTRING(codigo FROM GREATEST(1, LENGTH(codigo) - 3)) as ultimos_4_digitos_codigo,
    UPPER(TRIM(tarjeta)) as tarjeta_normalizada
FROM public.t_bitacora_envios
WHERE codigo IS NOT NULL 
  AND tarjeta IS NOT NULL;

-- Comentario en la vista
COMMENT ON VIEW v_bitacora_envios_busqueda IS
'Vista optimizada para búsquedas de bitácoras con campos calculados para filtros rápidos';

-- ============================================
-- PASO 8: FUNCIÓN PARA BÚSQUEDA POR ÚLTIMOS 4 DÍGITOS
-- ============================================

CREATE OR REPLACE FUNCTION buscar_bitacora_por_ultimos_4_digitos(
    digitos_buscar TEXT,
    tarjeta_filtro TEXT DEFAULT NULL
)
RETURNS TABLE (
    id_bitacora integer,
    consecutivo text,
    fecha text,
    tecnico text,
    tarjeta text,
    codigo text,
    serie text,
    folio text,
    envia text,
    recibe text,
    guia text,
    anexos text,
    observaciones text,
    cobo text,
    estado text,
    creado_en timestamp with time zone,
    actualizado_en timestamp with time zone
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        b.id_bitacora,
        b.consecutivo,
        b.fecha,
        b.tecnico,
        b.tarjeta,
        b.codigo,
        b.serie,
        b.folio,
        b.envia,
        b.recibe,
        b.guia,
        b.anexos,
        b.observaciones,
        b.cobo,
        b.estado,
        b.creado_en,
        b.actualizado_en
    FROM public.t_bitacora_envios b
    WHERE b.codigo IS NOT NULL
      AND LENGTH(b.codigo) >= 4
      AND UPPER(SUBSTRING(b.codigo FROM LENGTH(b.codigo) - 3)) = UPPER(digitos_buscar)
      AND (tarjeta_filtro IS NULL OR UPPER(TRIM(b.tarjeta)) = UPPER(TRIM(tarjeta_filtro)))
    ORDER BY b.fecha DESC, b.creado_en DESC;
END;
$$ LANGUAGE plpgsql;

-- Comentario en la función
COMMENT ON FUNCTION buscar_bitacora_por_ultimos_4_digitos IS
'Función optimizada para buscar bitácoras por los últimos 4 dígitos del código, opcionalmente filtrada por tarjeta';

-- ============================================
-- PASO 9: VERIFICACIÓN FINAL
-- ============================================

-- Verificar que las tablas fueron eliminadas
SELECT 
    table_name,
    'Eliminada correctamente' as estado
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    't_computo',
    't_envios',
    't_envios_detalles',
    't_historial_asignaciones',
    't_reportes',
    't_reportes_inventarios',
    't_ubicaciones_administrativas',
    't_ubicaciones_computo'
  );

-- Si la consulta anterior no devuelve resultados, las tablas fueron eliminadas correctamente

-- Verificar índices creados
SELECT 
    indexname,
    tablename,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename = 't_bitacora_envios'
  AND indexname LIKE 'idx_bitacora%'
ORDER BY indexname;

-- ============================================
-- NOTAS FINALES
-- ============================================
-- 1. Las tablas eliminadas NO se pueden recuperar sin un backup
-- 2. Los índices mejorarán el rendimiento de las consultas de búsqueda
-- 3. La vista v_bitacora_envios_busqueda puede usarse para consultas más rápidas
-- 4. La función buscar_bitacora_por_ultimos_4_digitos() está optimizada para búsquedas
-- 5. Si necesitas las tablas eliminadas en el futuro, deberás restaurarlas desde un backup






