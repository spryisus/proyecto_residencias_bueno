-- Tabla: Accesorios de Equipos
-- Esta tabla contiene los accesorios que pertenecen a equipos de cómputo

CREATE TABLE IF NOT EXISTS public.t_accesorios_equipos (
    id_accesorio BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    inventario TEXT,
    id_equipo_computo BIGINT NOT NULL,
    fecha_registro DATE,
    tipo_equipo TEXT,
    marca TEXT,
    modelo TEXT,
    numero_serie TEXT,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Agregar constraint de foreign key si no existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_schema = 'public' 
        AND constraint_name = 'fk_accesorios_equipo_computo'
        AND table_name = 't_accesorios_equipos'
    ) THEN
        ALTER TABLE public.t_accesorios_equipos
        ADD CONSTRAINT fk_accesorios_equipo_computo 
            FOREIGN KEY (id_equipo_computo) 
            REFERENCES public.t_computo_detalles_generales(id_equipo_computo) 
            ON DELETE CASCADE;
    END IF;
END $$;

-- Habilitar RLS para accesorios de equipos
ALTER TABLE public.t_accesorios_equipos ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si existen
DROP POLICY IF EXISTS "Permitir lectura accesorios equipos a usuarios autenticados" ON public.t_accesorios_equipos;
DROP POLICY IF EXISTS "Permitir inserción accesorios equipos a usuarios autenticados" ON public.t_accesorios_equipos;
DROP POLICY IF EXISTS "Permitir actualización accesorios equipos a usuarios autenticados" ON public.t_accesorios_equipos;
DROP POLICY IF EXISTS "Permitir eliminación accesorios equipos a usuarios autenticados" ON public.t_accesorios_equipos;

-- Política para permitir lectura a usuarios autenticados
CREATE POLICY "Permitir lectura accesorios equipos a usuarios autenticados"
ON public.t_accesorios_equipos
FOR SELECT
TO authenticated
USING (true);

-- Política para permitir inserción a usuarios autenticados
CREATE POLICY "Permitir inserción accesorios equipos a usuarios autenticados"
ON public.t_accesorios_equipos
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Política para permitir actualización a usuarios autenticados
CREATE POLICY "Permitir actualización accesorios equipos a usuarios autenticados"
ON public.t_accesorios_equipos
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Política para permitir eliminación a usuarios autenticados
CREATE POLICY "Permitir eliminación accesorios equipos a usuarios autenticados"
ON public.t_accesorios_equipos
FOR DELETE
TO authenticated
USING (true);

-- Crear función para actualizar actualizado_en automáticamente
CREATE OR REPLACE FUNCTION public.actualizar_actualizado_en_accesorios_equipos()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_en = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Eliminar trigger existente si existe
DROP TRIGGER IF EXISTS trigger_actualizar_actualizado_en_accesorios_equipos ON public.t_accesorios_equipos;

-- Crear trigger para actualizar actualizado_en
CREATE TRIGGER trigger_actualizar_actualizado_en_accesorios_equipos
    BEFORE UPDATE ON public.t_accesorios_equipos
    FOR EACH ROW
    EXECUTE FUNCTION public.actualizar_actualizado_en_accesorios_equipos();

-- Crear índices para búsquedas rápidas
CREATE INDEX IF NOT EXISTS idx_accesorios_equipos_inventario 
ON public.t_accesorios_equipos(inventario);

CREATE INDEX IF NOT EXISTS idx_accesorios_equipos_equipo_computo 
ON public.t_accesorios_equipos(id_equipo_computo);

CREATE INDEX IF NOT EXISTS idx_accesorios_equipos_tipo_equipo 
ON public.t_accesorios_equipos(tipo_equipo);

CREATE INDEX IF NOT EXISTS idx_accesorios_equipos_marca 
ON public.t_accesorios_equipos(marca);

