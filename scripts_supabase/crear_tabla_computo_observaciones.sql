-- Tabla 7: Observaciones
-- Observaciones y notas adicionales sobre el equipo

CREATE TABLE IF NOT EXISTS public.t_computo_observaciones (
    id_observacion BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_equipo_computo BIGINT NOT NULL,
    observaciones TEXT,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT fk_equipo_computo_observaciones 
        FOREIGN KEY (id_equipo_computo) 
        REFERENCES public.t_computo_detalles_generales(id_equipo_computo) 
        ON DELETE CASCADE
);

-- Habilitar RLS
ALTER TABLE public.t_computo_observaciones ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si existen
DROP POLICY IF EXISTS "Permitir lectura observaciones a usuarios autenticados" ON public.t_computo_observaciones;
DROP POLICY IF EXISTS "Permitir inserción observaciones a usuarios autenticados" ON public.t_computo_observaciones;
DROP POLICY IF EXISTS "Permitir actualización observaciones a usuarios autenticados" ON public.t_computo_observaciones;
DROP POLICY IF EXISTS "Permitir eliminación observaciones a usuarios autenticados" ON public.t_computo_observaciones;

-- Política para permitir lectura a usuarios autenticados
CREATE POLICY "Permitir lectura observaciones a usuarios autenticados"
ON public.t_computo_observaciones
FOR SELECT
TO authenticated
USING (true);

-- Política para permitir inserción a usuarios autenticados
CREATE POLICY "Permitir inserción observaciones a usuarios autenticados"
ON public.t_computo_observaciones
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Política para permitir actualización a usuarios autenticados
CREATE POLICY "Permitir actualización observaciones a usuarios autenticados"
ON public.t_computo_observaciones
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Política para permitir eliminación a usuarios autenticados
CREATE POLICY "Permitir eliminación observaciones a usuarios autenticados"
ON public.t_computo_observaciones
FOR DELETE
TO authenticated
USING (true);

-- Crear función para actualizar actualizado_en automáticamente
CREATE OR REPLACE FUNCTION public.actualizar_actualizado_en_computo_observaciones()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_en = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Eliminar trigger existente si existe
DROP TRIGGER IF EXISTS trigger_actualizar_actualizado_en_computo_observaciones ON public.t_computo_observaciones;

-- Crear trigger para actualizar actualizado_en
CREATE TRIGGER trigger_actualizar_actualizado_en_computo_observaciones
    BEFORE UPDATE ON public.t_computo_observaciones
    FOR EACH ROW
    EXECUTE FUNCTION public.actualizar_actualizado_en_computo_observaciones();

-- Crear índice único para asegurar un solo registro de observaciones por equipo
CREATE UNIQUE INDEX IF NOT EXISTS idx_computo_observaciones_equipo 
ON public.t_computo_observaciones(id_equipo_computo);

