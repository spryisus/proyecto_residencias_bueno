-- Tabla 1: Equipos Principales (equipo_pm)
-- Esta tabla agrupa los equipos principales que contienen múltiples componentes

CREATE TABLE IF NOT EXISTS public.t_computo_equipos_principales (
    id_equipo_principal BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    equipo_pm TEXT NOT NULL UNIQUE,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla 2: Detalles Generales (Componentes)
-- Esta tabla contiene los componentes individuales que pertenecen a un equipo_pm

CREATE TABLE IF NOT EXISTS public.t_computo_detalles_generales (
    id_equipo_computo BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    inventario TEXT NOT NULL UNIQUE,
    fecha_registro DATE,
    tipo_equipo TEXT NOT NULL,
    marca TEXT,
    modelo TEXT,
    procesador TEXT,
    numero_serie TEXT,
    disco_duro TEXT,
    memoria_ram TEXT,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Agregar columna id_equipo_principal si no existe (para migración de tablas existentes)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 't_computo_detalles_generales' 
        AND column_name = 'id_equipo_principal'
    ) THEN
        ALTER TABLE public.t_computo_detalles_generales
        ADD COLUMN id_equipo_principal BIGINT;
    END IF;
END $$;

-- Agregar constraint de foreign key si no existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_schema = 'public' 
        AND constraint_name = 'fk_equipo_principal'
        AND table_name = 't_computo_detalles_generales'
    ) THEN
        ALTER TABLE public.t_computo_detalles_generales
        ADD CONSTRAINT fk_equipo_principal 
            FOREIGN KEY (id_equipo_principal) 
            REFERENCES public.t_computo_equipos_principales(id_equipo_principal) 
            ON DELETE CASCADE;
    END IF;
END $$;

-- Hacer la columna NOT NULL solo si no tiene valores NULL (para migración)
DO $$
BEGIN
    -- Primero verificar si hay valores NULL
    IF NOT EXISTS (
        SELECT 1 FROM public.t_computo_detalles_generales 
        WHERE id_equipo_principal IS NULL
    ) THEN
        -- Si no hay NULL, hacer la columna NOT NULL
        ALTER TABLE public.t_computo_detalles_generales
        ALTER COLUMN id_equipo_principal SET NOT NULL;
    END IF;
END $$;

-- Habilitar RLS para equipos principales
ALTER TABLE public.t_computo_equipos_principales ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si existen (equipos principales)
DROP POLICY IF EXISTS "Permitir lectura equipos principales a usuarios autenticados" ON public.t_computo_equipos_principales;
DROP POLICY IF EXISTS "Permitir inserción equipos principales a usuarios autenticados" ON public.t_computo_equipos_principales;
DROP POLICY IF EXISTS "Permitir actualización equipos principales a usuarios autenticados" ON public.t_computo_equipos_principales;
DROP POLICY IF EXISTS "Permitir eliminación equipos principales a usuarios autenticados" ON public.t_computo_equipos_principales;

-- Política para permitir lectura a usuarios autenticados (equipos principales)
CREATE POLICY "Permitir lectura equipos principales a usuarios autenticados"
ON public.t_computo_equipos_principales
FOR SELECT
TO authenticated
USING (true);

-- Política para permitir inserción a usuarios autenticados (equipos principales)
CREATE POLICY "Permitir inserción equipos principales a usuarios autenticados"
ON public.t_computo_equipos_principales
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Política para permitir actualización a usuarios autenticados (equipos principales)
CREATE POLICY "Permitir actualización equipos principales a usuarios autenticados"
ON public.t_computo_equipos_principales
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Política para permitir eliminación a usuarios autenticados (equipos principales)
CREATE POLICY "Permitir eliminación equipos principales a usuarios autenticados"
ON public.t_computo_equipos_principales
FOR DELETE
TO authenticated
USING (true);

-- Crear función para actualizar actualizado_en automáticamente (equipos principales)
CREATE OR REPLACE FUNCTION public.actualizar_actualizado_en_computo_equipos_principales()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_en = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Eliminar trigger existente si existe (equipos principales)
DROP TRIGGER IF EXISTS trigger_actualizar_actualizado_en_computo_equipos_principales ON public.t_computo_equipos_principales;

-- Crear trigger para actualizar actualizado_en (equipos principales)
CREATE TRIGGER trigger_actualizar_actualizado_en_computo_equipos_principales
    BEFORE UPDATE ON public.t_computo_equipos_principales
    FOR EACH ROW
    EXECUTE FUNCTION public.actualizar_actualizado_en_computo_equipos_principales();

-- Crear índice para búsquedas rápidas (equipos principales)
CREATE INDEX IF NOT EXISTS idx_computo_equipos_principales_equipo_pm 
ON public.t_computo_equipos_principales(equipo_pm);

-- Habilitar RLS para detalles generales
ALTER TABLE public.t_computo_detalles_generales ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si existen (detalles generales)
DROP POLICY IF EXISTS "Permitir lectura detalles generales a usuarios autenticados" ON public.t_computo_detalles_generales;
DROP POLICY IF EXISTS "Permitir inserción detalles generales a usuarios autenticados" ON public.t_computo_detalles_generales;
DROP POLICY IF EXISTS "Permitir actualización detalles generales a usuarios autenticados" ON public.t_computo_detalles_generales;
DROP POLICY IF EXISTS "Permitir eliminación detalles generales a usuarios autenticados" ON public.t_computo_detalles_generales;

-- Política para permitir lectura a usuarios autenticados
CREATE POLICY "Permitir lectura detalles generales a usuarios autenticados"
ON public.t_computo_detalles_generales
FOR SELECT
TO authenticated
USING (true);

-- Política para permitir inserción a usuarios autenticados
CREATE POLICY "Permitir inserción detalles generales a usuarios autenticados"
ON public.t_computo_detalles_generales
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Política para permitir actualización a usuarios autenticados
CREATE POLICY "Permitir actualización detalles generales a usuarios autenticados"
ON public.t_computo_detalles_generales
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Política para permitir eliminación a usuarios autenticados
CREATE POLICY "Permitir eliminación detalles generales a usuarios autenticados"
ON public.t_computo_detalles_generales
FOR DELETE
TO authenticated
USING (true);

-- Crear función para actualizar actualizado_en automáticamente
CREATE OR REPLACE FUNCTION public.actualizar_actualizado_en_computo_detalles_generales()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_en = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Eliminar trigger existente si existe (detalles generales)
DROP TRIGGER IF EXISTS trigger_actualizar_actualizado_en_computo_detalles_generales ON public.t_computo_detalles_generales;

-- Crear trigger para actualizar actualizado_en
CREATE TRIGGER trigger_actualizar_actualizado_en_computo_detalles_generales
    BEFORE UPDATE ON public.t_computo_detalles_generales
    FOR EACH ROW
    EXECUTE FUNCTION public.actualizar_actualizado_en_computo_detalles_generales();

-- Crear índice para búsquedas rápidas (detalles generales)
CREATE INDEX IF NOT EXISTS idx_computo_detalles_generales_inventario 
ON public.t_computo_detalles_generales(inventario);

CREATE INDEX IF NOT EXISTS idx_computo_detalles_generales_tipo_equipo 
ON public.t_computo_detalles_generales(tipo_equipo);

CREATE INDEX IF NOT EXISTS idx_computo_detalles_generales_equipo_principal 
ON public.t_computo_detalles_generales(id_equipo_principal);

