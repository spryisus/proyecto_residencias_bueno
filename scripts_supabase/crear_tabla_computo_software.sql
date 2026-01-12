-- Tabla 2: Software
-- Información del software instalado en el equipo

CREATE TABLE IF NOT EXISTS public.t_computo_software (
    id_software BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_equipo_computo BIGINT NOT NULL,
    sistema_operativo_instalado TEXT,
    etiqueta_sistema_operativo TEXT,
    office_instalado TEXT,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT fk_equipo_computo_software 
        FOREIGN KEY (id_equipo_computo) 
        REFERENCES public.t_computo_detalles_generales(id_equipo_computo) 
        ON DELETE CASCADE
);

-- Habilitar RLS
ALTER TABLE public.t_computo_software ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si existen
DROP POLICY IF EXISTS "Permitir lectura software a usuarios autenticados" ON public.t_computo_software;
DROP POLICY IF EXISTS "Permitir inserción software a usuarios autenticados" ON public.t_computo_software;
DROP POLICY IF EXISTS "Permitir actualización software a usuarios autenticados" ON public.t_computo_software;
DROP POLICY IF EXISTS "Permitir eliminación software a usuarios autenticados" ON public.t_computo_software;

-- Política para permitir lectura a usuarios autenticados
CREATE POLICY "Permitir lectura software a usuarios autenticados"
ON public.t_computo_software
FOR SELECT
TO authenticated
USING (true);

-- Política para permitir inserción a usuarios autenticados
CREATE POLICY "Permitir inserción software a usuarios autenticados"
ON public.t_computo_software
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Política para permitir actualización a usuarios autenticados
CREATE POLICY "Permitir actualización software a usuarios autenticados"
ON public.t_computo_software
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Política para permitir eliminación a usuarios autenticados
CREATE POLICY "Permitir eliminación software a usuarios autenticados"
ON public.t_computo_software
FOR DELETE
TO authenticated
USING (true);

-- Crear función para actualizar actualizado_en automáticamente
CREATE OR REPLACE FUNCTION public.actualizar_actualizado_en_computo_software()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_en = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Eliminar trigger existente si existe
DROP TRIGGER IF EXISTS trigger_actualizar_actualizado_en_computo_software ON public.t_computo_software;

-- Crear trigger para actualizar actualizado_en
CREATE TRIGGER trigger_actualizar_actualizado_en_computo_software
    BEFORE UPDATE ON public.t_computo_software
    FOR EACH ROW
    EXECUTE FUNCTION public.actualizar_actualizado_en_computo_software();

-- Crear índice único para asegurar un solo registro de software por equipo
CREATE UNIQUE INDEX IF NOT EXISTS idx_computo_software_equipo 
ON public.t_computo_software(id_equipo_computo);

