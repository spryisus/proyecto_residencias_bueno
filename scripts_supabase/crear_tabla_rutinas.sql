-- Crear tabla de rutinas
CREATE TABLE IF NOT EXISTS public.t_rutinas (
    id_rutina UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre VARCHAR(255) NOT NULL,
    fecha DATE,
    color_value BIGINT NOT NULL DEFAULT 4280391411, -- Color por defecto (azul) - BIGINT para valores grandes
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Habilitar RLS
ALTER TABLE public.t_rutinas ENABLE ROW LEVEL SECURITY;

-- Política para permitir lectura a usuarios autenticados
CREATE POLICY "Permitir lectura a usuarios autenticados"
ON public.t_rutinas
FOR SELECT
TO authenticated
USING (true);

-- Política para permitir inserción a usuarios autenticados
CREATE POLICY "Permitir inserción a usuarios autenticados"
ON public.t_rutinas
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Política para permitir actualización a usuarios autenticados
CREATE POLICY "Permitir actualización a usuarios autenticados"
ON public.t_rutinas
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Política para permitir eliminación a usuarios autenticados
CREATE POLICY "Permitir eliminación a usuarios autenticados"
ON public.t_rutinas
FOR DELETE
TO authenticated
USING (true);

-- Crear función para actualizar actualizado_en automáticamente
CREATE OR REPLACE FUNCTION public.actualizar_actualizado_en_rutinas()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_en = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear trigger para actualizar actualizado_en
CREATE TRIGGER trigger_actualizar_actualizado_en_rutinas
    BEFORE UPDATE ON public.t_rutinas
    FOR EACH ROW
    EXECUTE FUNCTION public.actualizar_actualizado_en_rutinas();

-- Insertar rutinas por defecto si no existen
-- Nota: Los IDs UUID se generarán automáticamente, el código buscará por nombre
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.t_rutinas WHERE nombre = 'Rutina 1') THEN
        INSERT INTO public.t_rutinas (nombre, color_value)
        VALUES ('Rutina 1', 4280391411); -- Azul
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM public.t_rutinas WHERE nombre = 'Rutina 2') THEN
        INSERT INTO public.t_rutinas (nombre, color_value)
        VALUES ('Rutina 2', 4288423856); -- Morado
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM public.t_rutinas WHERE nombre = 'Rutina 3') THEN
        INSERT INTO public.t_rutinas (nombre, color_value)
        VALUES ('Rutina 3', 4278255360); -- Teal
    END IF;
END $$;

