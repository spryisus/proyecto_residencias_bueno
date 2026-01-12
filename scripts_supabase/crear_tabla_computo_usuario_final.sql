-- Tabla 6: Usuario Final
-- Información del usuario final que utiliza el equipo

CREATE TABLE IF NOT EXISTS public.t_computo_usuario_final (
    id_usuario_final BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_equipo_computo BIGINT NOT NULL,
    expediente TEXT,
    apellido_paterno TEXT,
    apellido_materno TEXT,
    nombre TEXT NOT NULL,
    empresa TEXT NOT NULL,
    puesto TEXT,
    activo BOOLEAN NOT NULL DEFAULT true,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT fk_equipo_computo_usuario_final 
        FOREIGN KEY (id_equipo_computo) 
        REFERENCES public.t_computo_detalles_generales(id_equipo_computo) 
        ON DELETE CASCADE
);

-- Habilitar RLS
ALTER TABLE public.t_computo_usuario_final ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si existen
DROP POLICY IF EXISTS "Permitir lectura usuario final a usuarios autenticados" ON public.t_computo_usuario_final;
DROP POLICY IF EXISTS "Permitir inserción usuario final a usuarios autenticados" ON public.t_computo_usuario_final;
DROP POLICY IF EXISTS "Permitir actualización usuario final a usuarios autenticados" ON public.t_computo_usuario_final;
DROP POLICY IF EXISTS "Permitir eliminación usuario final a usuarios autenticados" ON public.t_computo_usuario_final;

-- Política para permitir lectura a usuarios autenticados
CREATE POLICY "Permitir lectura usuario final a usuarios autenticados"
ON public.t_computo_usuario_final
FOR SELECT
TO authenticated
USING (true);

-- Política para permitir inserción a usuarios autenticados
CREATE POLICY "Permitir inserción usuario final a usuarios autenticados"
ON public.t_computo_usuario_final
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Política para permitir actualización a usuarios autenticados
CREATE POLICY "Permitir actualización usuario final a usuarios autenticados"
ON public.t_computo_usuario_final
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Política para permitir eliminación a usuarios autenticados
CREATE POLICY "Permitir eliminación usuario final a usuarios autenticados"
ON public.t_computo_usuario_final
FOR DELETE
TO authenticated
USING (true);

-- Crear función para actualizar actualizado_en automáticamente
CREATE OR REPLACE FUNCTION public.actualizar_actualizado_en_computo_usuario_final()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_en = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Eliminar trigger existente si existe
DROP TRIGGER IF EXISTS trigger_actualizar_actualizado_en_computo_usuario_final ON public.t_computo_usuario_final;

-- Crear trigger para actualizar actualizado_en
CREATE TRIGGER trigger_actualizar_actualizado_en_computo_usuario_final
    BEFORE UPDATE ON public.t_computo_usuario_final
    FOR EACH ROW
    EXECUTE FUNCTION public.actualizar_actualizado_en_computo_usuario_final();

-- Crear índice único para asegurar un solo registro de usuario final por equipo
CREATE UNIQUE INDEX IF NOT EXISTS idx_computo_usuario_final_equipo 
ON public.t_computo_usuario_final(id_equipo_computo);

-- Crear índice para búsquedas rápidas
CREATE INDEX IF NOT EXISTS idx_computo_usuario_final_nombre 
ON public.t_computo_usuario_final(nombre, apellido_paterno, apellido_materno);

CREATE INDEX IF NOT EXISTS idx_computo_usuario_final_activo 
ON public.t_computo_usuario_final(activo);

