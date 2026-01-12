-- Tabla 4: Identificación del Equipo
-- Información de identificación y clasificación del equipo

CREATE TABLE IF NOT EXISTS public.t_computo_identificacion (
    id_identificacion BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_equipo_computo BIGINT NOT NULL,
    tipo_uso TEXT,
    nombre_equipo_dominio TEXT,
    status TEXT NOT NULL DEFAULT 'ASIGNADO',
    direccion_administrativa TEXT,
    subdireccion TEXT,
    gerencia TEXT,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT fk_equipo_computo_identificacion 
        FOREIGN KEY (id_equipo_computo) 
        REFERENCES public.t_computo_detalles_generales(id_equipo_computo) 
        ON DELETE CASCADE
);

-- Habilitar RLS
ALTER TABLE public.t_computo_identificacion ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si existen
DROP POLICY IF EXISTS "Permitir lectura identificación a usuarios autenticados" ON public.t_computo_identificacion;
DROP POLICY IF EXISTS "Permitir inserción identificación a usuarios autenticados" ON public.t_computo_identificacion;
DROP POLICY IF EXISTS "Permitir actualización identificación a usuarios autenticados" ON public.t_computo_identificacion;
DROP POLICY IF EXISTS "Permitir eliminación identificación a usuarios autenticados" ON public.t_computo_identificacion;

-- Política para permitir lectura a usuarios autenticados
CREATE POLICY "Permitir lectura identificación a usuarios autenticados"
ON public.t_computo_identificacion
FOR SELECT
TO authenticated
USING (true);

-- Política para permitir inserción a usuarios autenticados
CREATE POLICY "Permitir inserción identificación a usuarios autenticados"
ON public.t_computo_identificacion
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Política para permitir actualización a usuarios autenticados
CREATE POLICY "Permitir actualización identificación a usuarios autenticados"
ON public.t_computo_identificacion
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Política para permitir eliminación a usuarios autenticados
CREATE POLICY "Permitir eliminación identificación a usuarios autenticados"
ON public.t_computo_identificacion
FOR DELETE
TO authenticated
USING (true);

-- Crear función para actualizar actualizado_en automáticamente
CREATE OR REPLACE FUNCTION public.actualizar_actualizado_en_computo_identificacion()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_en = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Eliminar trigger existente si existe
DROP TRIGGER IF EXISTS trigger_actualizar_actualizado_en_computo_identificacion ON public.t_computo_identificacion;

-- Crear trigger para actualizar actualizado_en
CREATE TRIGGER trigger_actualizar_actualizado_en_computo_identificacion
    BEFORE UPDATE ON public.t_computo_identificacion
    FOR EACH ROW
    EXECUTE FUNCTION public.actualizar_actualizado_en_computo_identificacion();

-- Crear índice único para asegurar un solo registro de identificación por equipo
CREATE UNIQUE INDEX IF NOT EXISTS idx_computo_identificacion_equipo 
ON public.t_computo_identificacion(id_equipo_computo);

-- Crear índice para búsquedas por status
CREATE INDEX IF NOT EXISTS idx_computo_identificacion_status 
ON public.t_computo_identificacion(status);

