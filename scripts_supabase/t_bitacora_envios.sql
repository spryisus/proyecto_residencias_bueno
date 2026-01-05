-- ============================================
-- TABLA: t_bitacora_envios
-- ============================================
-- 
-- Esta tabla almacena las bitácoras de envíos realizados.
-- Campos basados en el formato de bitácora mostrado en la imagen.
--
-- IMPORTANTE: Ejecuta este script en el SQL Editor de Supabase
-- Ruta: Dashboard > SQL Editor > New Query
-- ============================================

-- Crear la tabla
CREATE TABLE IF NOT EXISTS public.t_bitacora_envios (
    -- ID único de la bitácora (auto-incremental)
    id_bitacora SERIAL PRIMARY KEY,
    
    -- CONS. (Consecutivo) - Número consecutivo del registro (puede ser texto como "17-01")
    consecutivo TEXT NOT NULL,
    
    -- FECHA - Fecha del envío
    fecha DATE NOT NULL DEFAULT CURRENT_DATE,
    
    -- TEC (Técnico) - Nombre o ID del técnico responsable
    tecnico TEXT,
    
    -- TARJETA - Número o identificación de la tarjeta
    tarjeta TEXT,
    
    -- CODIGO - Código del producto/equipo
    codigo TEXT,
    
    -- SERIE - Número de serie
    serie TEXT,
    
    -- FOLIO - Número de folio
    folio TEXT,
    
    -- ENVIA - Quien envía (origen)
    envia TEXT,
    
    -- RECIBE - Quien recibe (destino)
    recibe TEXT,
    
    -- GUIA - Número de guía de envío
    guia TEXT,
    
    -- ANEXOS - Archivos adjuntos o referencias (puede ser JSON o texto)
    anexos TEXT,
    
    -- OBSERVACIONES - Notas adicionales sobre el envío
    observaciones TEXT,
    
    -- Campos de auditoría
    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    creado_por TEXT,
    actualizado_por TEXT
);

-- ============================================
-- ÍNDICES
-- ============================================

-- Índice para búsqueda rápida por consecutivo (TEXT)
CREATE INDEX IF NOT EXISTS idx_bitacora_consecutivo 
ON public.t_bitacora_envios(consecutivo);

-- Índice para búsqueda por fecha
CREATE INDEX IF NOT EXISTS idx_bitacora_fecha 
ON public.t_bitacora_envios(fecha DESC);

-- Índice para búsqueda por guía
CREATE INDEX IF NOT EXISTS idx_bitacora_guia 
ON public.t_bitacora_envios(guia) WHERE guia IS NOT NULL;

-- Índice para búsqueda por código
CREATE INDEX IF NOT EXISTS idx_bitacora_codigo 
ON public.t_bitacora_envios(codigo) WHERE codigo IS NOT NULL;

-- Índice para búsqueda por serie
CREATE INDEX IF NOT EXISTS idx_bitacora_serie 
ON public.t_bitacora_envios(serie) WHERE serie IS NOT NULL;

-- ============================================
-- TRIGGER PARA ACTUALIZAR actualizado_en
-- ============================================

-- Función para actualizar el campo actualizado_en automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_en = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger que se ejecuta antes de actualizar
CREATE TRIGGER update_bitacora_updated_at
    BEFORE UPDATE ON public.t_bitacora_envios
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- NOTA SOBRE CONSECUTIVO
-- ============================================
-- El consecutivo es de tipo TEXT para permitir formatos como "17-01", "2024-001", etc.
-- La aplicación Flutter generará el consecutivo automáticamente basándose en el último valor.
-- ============================================

-- ============================================
-- COMENTARIOS PARA DOCUMENTACIÓN
-- ============================================

COMMENT ON TABLE public.t_bitacora_envios IS 'Tabla para almacenar bitácoras de envíos realizados';
COMMENT ON COLUMN public.t_bitacora_envios.id_bitacora IS 'ID único de la bitácora (auto-incremental)';
COMMENT ON COLUMN public.t_bitacora_envios.consecutivo IS 'Número consecutivo del registro en la bitácora (formato texto, ej: "17-01", "2024-001")';
COMMENT ON COLUMN public.t_bitacora_envios.fecha IS 'Fecha en que se realizó el envío';
COMMENT ON COLUMN public.t_bitacora_envios.tecnico IS 'Nombre o ID del técnico responsable';
COMMENT ON COLUMN public.t_bitacora_envios.tarjeta IS 'Número o identificación de la tarjeta';
COMMENT ON COLUMN public.t_bitacora_envios.codigo IS 'Código del producto/equipo';
COMMENT ON COLUMN public.t_bitacora_envios.serie IS 'Número de serie del equipo';
COMMENT ON COLUMN public.t_bitacora_envios.folio IS 'Número de folio del envío';
COMMENT ON COLUMN public.t_bitacora_envios.envia IS 'Persona o lugar que envía (origen)';
COMMENT ON COLUMN public.t_bitacora_envios.recibe IS 'Persona o lugar que recibe (destino)';
COMMENT ON COLUMN public.t_bitacora_envios.guia IS 'Número de guía de envío';
COMMENT ON COLUMN public.t_bitacora_envios.anexos IS 'Archivos adjuntos o referencias adicionales';
COMMENT ON COLUMN public.t_bitacora_envios.observaciones IS 'Notas y observaciones sobre el envío';

-- ============================================
-- POLÍTICAS RLS (Row Level Security)
-- ============================================

-- Habilitar RLS
ALTER TABLE public.t_bitacora_envios ENABLE ROW LEVEL SECURITY;

-- Política para SELECT (lectura)
CREATE POLICY "usuarios_autenticados_pueden_leer_bitacora"
ON public.t_bitacora_envios
FOR SELECT
TO authenticated
USING (true);

-- Política para INSERT (crear registros)
CREATE POLICY "usuarios_autenticados_pueden_insertar_bitacora"
ON public.t_bitacora_envios
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Política para UPDATE (actualizar registros)
CREATE POLICY "usuarios_autenticados_pueden_actualizar_bitacora"
ON public.t_bitacora_envios
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Política para DELETE (eliminar registros)
CREATE POLICY "usuarios_autenticados_pueden_eliminar_bitacora"
ON public.t_bitacora_envios
FOR DELETE
TO authenticated
USING (true);

-- ============================================
-- VERIFICACIÓN
-- ============================================
-- Después de ejecutar, verifica que la tabla se creó correctamente:
-- SELECT * FROM t_bitacora_envios LIMIT 5;
-- 
-- Verifica las políticas RLS:
-- SELECT schemaname, tablename, policyname, cmd 
-- FROM pg_policies 
-- WHERE tablename = 't_bitacora_envios'
-- ORDER BY cmd;
-- ============================================

