-- Tabla 3: Ubicación (Compartida)
-- Información de ubicación física compartida para múltiples equipos
-- Esta tabla es independiente y puede ser referenciada por múltiples equipos

CREATE TABLE IF NOT EXISTS public.t_computo_ubicacion (
    id_ubicacion BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    direccion_fisica TEXT NOT NULL,
    estado TEXT NOT NULL,
    ciudad TEXT NOT NULL,
    tipo_edificio TEXT,
    nombre_edificio TEXT,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    -- Constraint para evitar duplicados exactos
    CONSTRAINT uq_ubicacion_completa 
        UNIQUE (direccion_fisica, estado, ciudad, tipo_edificio, nombre_edificio)
);

-- Habilitar RLS
ALTER TABLE public.t_computo_ubicacion ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si existen
DROP POLICY IF EXISTS "Permitir lectura ubicación a usuarios autenticados" ON public.t_computo_ubicacion;
DROP POLICY IF EXISTS "Permitir inserción ubicación a usuarios autenticados" ON public.t_computo_ubicacion;
DROP POLICY IF EXISTS "Permitir actualización ubicación a usuarios autenticados" ON public.t_computo_ubicacion;
DROP POLICY IF EXISTS "Permitir eliminación ubicación a usuarios autenticados" ON public.t_computo_ubicacion;

-- Política para permitir lectura a usuarios autenticados
CREATE POLICY "Permitir lectura ubicación a usuarios autenticados"
ON public.t_computo_ubicacion
FOR SELECT
TO authenticated
USING (true);

-- Política para permitir inserción a usuarios autenticados
CREATE POLICY "Permitir inserción ubicación a usuarios autenticados"
ON public.t_computo_ubicacion
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Política para permitir actualización a usuarios autenticados
CREATE POLICY "Permitir actualización ubicación a usuarios autenticados"
ON public.t_computo_ubicacion
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Política para permitir eliminación a usuarios autenticados
CREATE POLICY "Permitir eliminación ubicación a usuarios autenticados"
ON public.t_computo_ubicacion
FOR DELETE
TO authenticated
USING (true);

-- Crear función para actualizar actualizado_en automáticamente
CREATE OR REPLACE FUNCTION public.actualizar_actualizado_en_computo_ubicacion()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_en = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Eliminar trigger existente si existe
DROP TRIGGER IF EXISTS trigger_actualizar_actualizado_en_computo_ubicacion ON public.t_computo_ubicacion;

-- Crear trigger para actualizar actualizado_en
CREATE TRIGGER trigger_actualizar_actualizado_en_computo_ubicacion
    BEFORE UPDATE ON public.t_computo_ubicacion
    FOR EACH ROW
    EXECUTE FUNCTION public.actualizar_actualizado_en_computo_ubicacion();

-- Agregar columna de referencia en la tabla de detalles generales si no existe
ALTER TABLE public.t_computo_detalles_generales
ADD COLUMN IF NOT EXISTS id_ubicacion BIGINT;

-- Agregar constraint de foreign key si no existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_schema = 'public' 
        AND constraint_name = 'fk_equipo_ubicacion'
        AND table_name = 't_computo_detalles_generales'
    ) THEN
        ALTER TABLE public.t_computo_detalles_generales
        ADD CONSTRAINT fk_equipo_ubicacion 
            FOREIGN KEY (id_ubicacion) 
            REFERENCES public.t_computo_ubicacion(id_ubicacion) 
            ON DELETE SET NULL;
    END IF;
END $$;

-- Crear índice para búsquedas rápidas
CREATE INDEX IF NOT EXISTS idx_computo_ubicacion_estado_ciudad 
ON public.t_computo_ubicacion(estado, ciudad);

