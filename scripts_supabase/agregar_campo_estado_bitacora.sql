-- ============================================
-- AGREGAR CAMPO ESTADO A t_bitacora_envios
-- ============================================
-- 
-- Este script agrega el campo 'estado' para rastrear el estado de los envíos:
-- - ENVIADO: La pieza fue enviada
-- - EN_TRANSITO: La pieza está en camino
-- - RECIBIDO: La pieza llegó a su destino
--
-- IMPORTANTE: Ejecuta este script en el SQL Editor de Supabase
-- Ruta: Dashboard > SQL Editor > New Query
-- ============================================

-- Agregar columna estado si no existe
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 't_bitacora_envios' 
        AND column_name = 'estado'
    ) THEN
        ALTER TABLE public.t_bitacora_envios
        ADD COLUMN estado TEXT DEFAULT 'RECIBIDO'
        CHECK (estado IN ('ENVIADO', 'EN_TRANSITO', 'RECIBIDO'));
        
        -- Agregar comentario
        COMMENT ON COLUMN public.t_bitacora_envios.estado IS 
        'Estado del envío: ENVIADO (pieza enviada), EN_TRANSITO (en camino), RECIBIDO (llegó a destino)';
        
        RAISE NOTICE 'Columna estado agregada exitosamente';
    ELSE
        RAISE NOTICE 'La columna estado ya existe';
    END IF;
END $$;

-- Actualizar todos los registros existentes a RECIBIDO (ya están recibidos)
-- También actualizar los que tienen FINALIZADO (compatibilidad)
UPDATE public.t_bitacora_envios
SET estado = 'RECIBIDO'
WHERE estado IS NULL OR estado = '' OR estado = 'FINALIZADO';

-- Crear índice para búsquedas rápidas por estado
CREATE INDEX IF NOT EXISTS idx_bitacora_estado 
ON public.t_bitacora_envios(estado) 
WHERE estado IS NOT NULL;

-- Crear índice compuesto para búsquedas por código y estado
CREATE INDEX IF NOT EXISTS idx_bitacora_codigo_estado 
ON public.t_bitacora_envios(codigo, estado) 
WHERE codigo IS NOT NULL AND estado IS NOT NULL;

-- ============================================
-- FUNCIÓN PARA OBTENER EL ESTADO ACTUAL POR CÓDIGO
-- ============================================
-- Esta función devuelve el estado más reciente de un código
-- (útil cuando hay múltiples registros con el mismo código)

CREATE OR REPLACE FUNCTION obtener_estado_actual_codigo(codigo_buscar TEXT)
RETURNS TEXT AS $$
DECLARE
    estado_actual TEXT;
BEGIN
    SELECT estado INTO estado_actual
    FROM public.t_bitacora_envios
    WHERE codigo = codigo_buscar
    ORDER BY fecha DESC, creado_en DESC
    LIMIT 1;
    
    RETURN COALESCE(estado_actual, 'FINALIZADO');
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- VISTA PARA ENVÍOS ACTIVOS
-- ============================================
-- Vista que muestra solo los códigos con estado ENVIADO o EN_TRANSITO
-- Agrupa por código y muestra el registro más reciente

CREATE OR REPLACE VIEW v_envios_activos AS
SELECT DISTINCT ON (codigo)
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
    actualizado_por
FROM public.t_bitacora_envios
WHERE codigo IS NOT NULL 
  AND codigo != ''
  AND estado IN ('ENVIADO', 'EN_TRANSITO')
ORDER BY codigo, fecha DESC, creado_en DESC;

-- Comentario en la vista
COMMENT ON VIEW v_envios_activos IS 
'Vista que muestra los envíos activos (ENVIADO o EN_TRANSITO), agrupados por código con el registro más reciente. Los RECIBIDOS no se muestran.';

-- ============================================
-- VERIFICACIÓN
-- ============================================

-- Verificar que la columna se agregó correctamente
SELECT 
    column_name, 
    data_type, 
    column_default,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 't_bitacora_envios' 
  AND column_name = 'estado';

-- Mostrar conteo de registros por estado
SELECT 
    estado,
    COUNT(*) as total
FROM public.t_bitacora_envios
GROUP BY estado
ORDER BY estado;

-- ============================================
-- NOTAS
-- ============================================
-- 1. Todos los registros existentes se marcan como RECIBIDO
-- 2. Los nuevos registros de 2026 pueden empezar con ENVIADO o EN_TRANSITO
-- 3. La vista v_envios_activos muestra solo envíos activos agrupados por código (no RECIBIDOS)
-- 4. La función obtener_estado_actual_codigo() devuelve el estado más reciente de un código
-- 5. Los estados antiguos con FINALIZADO se actualizan automáticamente a RECIBIDO

