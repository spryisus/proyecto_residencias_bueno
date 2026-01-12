-- Tabla 5: Usuario Responsable (Compartida)
-- Información del usuario responsable compartida para múltiples equipos
-- Esta tabla es independiente y puede ser referenciada por múltiples equipos

CREATE TABLE IF NOT EXISTS public.t_computo_usuario_responsable (
    id_usuario_responsable BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    expediente TEXT,
    apellido_paterno TEXT,
    apellido_materno TEXT,
    nombre TEXT NOT NULL,
    empresa TEXT NOT NULL,
    puesto TEXT,
    activo BOOLEAN NOT NULL DEFAULT true,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    -- Constraint para evitar duplicados exactos
    CONSTRAINT uq_usuario_responsable_completo 
        UNIQUE (expediente, apellido_paterno, apellido_materno, nombre, empresa, puesto)
);

-- Habilitar RLS
ALTER TABLE public.t_computo_usuario_responsable ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si existen
DROP POLICY IF EXISTS "Permitir lectura usuario responsable a usuarios autenticados" ON public.t_computo_usuario_responsable;
DROP POLICY IF EXISTS "Permitir inserción usuario responsable a usuarios autenticados" ON public.t_computo_usuario_responsable;
DROP POLICY IF EXISTS "Permitir actualización usuario responsable a usuarios autenticados" ON public.t_computo_usuario_responsable;
DROP POLICY IF EXISTS "Permitir eliminación usuario responsable a usuarios autenticados" ON public.t_computo_usuario_responsable;

-- Política para permitir lectura a usuarios autenticados
CREATE POLICY "Permitir lectura usuario responsable a usuarios autenticados"
ON public.t_computo_usuario_responsable
FOR SELECT
TO authenticated
USING (true);

-- Política para permitir inserción a usuarios autenticados
CREATE POLICY "Permitir inserción usuario responsable a usuarios autenticados"
ON public.t_computo_usuario_responsable
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Política para permitir actualización a usuarios autenticados
CREATE POLICY "Permitir actualización usuario responsable a usuarios autenticados"
ON public.t_computo_usuario_responsable
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Política para permitir eliminación a usuarios autenticados
CREATE POLICY "Permitir eliminación usuario responsable a usuarios autenticados"
ON public.t_computo_usuario_responsable
FOR DELETE
TO authenticated
USING (true);

-- Crear función para actualizar actualizado_en automáticamente
CREATE OR REPLACE FUNCTION public.actualizar_actualizado_en_computo_usuario_responsable()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_en = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Eliminar trigger existente si existe
DROP TRIGGER IF EXISTS trigger_actualizar_actualizado_en_computo_usuario_responsable ON public.t_computo_usuario_responsable;

-- Crear trigger para actualizar actualizado_en
CREATE TRIGGER trigger_actualizar_actualizado_en_computo_usuario_responsable
    BEFORE UPDATE ON public.t_computo_usuario_responsable
    FOR EACH ROW
    EXECUTE FUNCTION public.actualizar_actualizado_en_computo_usuario_responsable();

-- Agregar columna de referencia en la tabla de detalles generales si no existe
ALTER TABLE public.t_computo_detalles_generales
ADD COLUMN IF NOT EXISTS id_usuario_responsable BIGINT;

-- Agregar constraint de foreign key si no existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_schema = 'public' 
        AND constraint_name = 'fk_equipo_usuario_responsable'
        AND table_name = 't_computo_detalles_generales'
    ) THEN
        ALTER TABLE public.t_computo_detalles_generales
        ADD CONSTRAINT fk_equipo_usuario_responsable 
            FOREIGN KEY (id_usuario_responsable) 
            REFERENCES public.t_computo_usuario_responsable(id_usuario_responsable) 
            ON DELETE SET NULL;
    END IF;
END $$;

-- Crear índice para búsquedas rápidas
CREATE INDEX IF NOT EXISTS idx_computo_usuario_responsable_nombre 
ON public.t_computo_usuario_responsable(nombre, apellido_paterno, apellido_materno);

CREATE INDEX IF NOT EXISTS idx_computo_usuario_responsable_activo 
ON public.t_computo_usuario_responsable(activo);

