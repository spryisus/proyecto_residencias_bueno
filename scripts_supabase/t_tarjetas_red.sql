-- =====================================================
-- Script para crear tabla t_tarjetas_red (SICOR)
-- Tabla para el inventario de tarjetas de red
-- =====================================================

-- Crear la tabla t_tarjetas_red
CREATE TABLE IF NOT EXISTS public.t_tarjetas_red (
  id_tarjeta_red INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  en_stock TEXT DEFAULT 'SI' NOT NULL,
  numero TEXT NOT NULL,
  codigo TEXT,
  serie TEXT,
  marca TEXT,
  posicion TEXT,
  comentarios TEXT,
  fecha_registro TIMESTAMP DEFAULT NOW(),
  fecha_actualizacion TIMESTAMP DEFAULT NOW()
);

-- Crear índice para mejorar las consultas por número
CREATE INDEX IF NOT EXISTS idx_tarjetas_red_numero 
  ON public.t_tarjetas_red(numero);

-- Crear índice para mejorar las consultas por código
CREATE INDEX IF NOT EXISTS idx_tarjetas_red_codigo 
  ON public.t_tarjetas_red(codigo);

-- Crear índice para mejorar las consultas por serie
CREATE INDEX IF NOT EXISTS idx_tarjetas_red_serie 
  ON public.t_tarjetas_red(serie);

-- Crear índice para mejorar las consultas por estado de stock
CREATE INDEX IF NOT EXISTS idx_tarjetas_red_en_stock 
  ON public.t_tarjetas_red(en_stock);

-- Función para actualizar fecha_actualizacion automáticamente
CREATE OR REPLACE FUNCTION update_tarjetas_red_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.fecha_actualizacion = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para actualizar fecha_actualizacion
CREATE TRIGGER trigger_update_tarjetas_red_timestamp
  BEFORE UPDATE ON public.t_tarjetas_red
  FOR EACH ROW
  EXECUTE FUNCTION update_tarjetas_red_timestamp();

-- Comentarios en la tabla y columnas
COMMENT ON TABLE public.t_tarjetas_red IS 
  'Almacena el inventario de tarjetas de red (SICOR)';

COMMENT ON COLUMN public.t_tarjetas_red.id_tarjeta_red IS 
  'Identificador único de la tarjeta de red (auto-generado)';

COMMENT ON COLUMN public.t_tarjetas_red.en_stock IS 
  'Indica si la tarjeta está en stock: "SI" o "NO"';

COMMENT ON COLUMN public.t_tarjetas_red.numero IS 
  'Número de identificación de la tarjeta de red';

COMMENT ON COLUMN public.t_tarjetas_red.codigo IS 
  'Código de la tarjeta de red';

COMMENT ON COLUMN public.t_tarjetas_red.serie IS 
  'Número de serie de la tarjeta de red';

COMMENT ON COLUMN public.t_tarjetas_red.marca IS 
  'Marca de la tarjeta de red';

COMMENT ON COLUMN public.t_tarjetas_red.posicion IS 
  'Posición o ubicación de la tarjeta de red';

COMMENT ON COLUMN public.t_tarjetas_red.comentarios IS 
  'Comentarios adicionales sobre la tarjeta de red';

COMMENT ON COLUMN public.t_tarjetas_red.fecha_registro IS 
  'Fecha y hora en que se registró la tarjeta de red';

COMMENT ON COLUMN public.t_tarjetas_red.fecha_actualizacion IS 
  'Fecha y hora de la última actualización de la tarjeta de red';

-- =====================================================
-- Migración: Si la tabla ya existe con BOOLEAN, convertir a TEXT
-- =====================================================

-- Verificar si la columna en_stock es BOOLEAN y convertirla a TEXT
DO $$
BEGIN
  -- Si la tabla existe y la columna es BOOLEAN, convertirla a TEXT
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 't_tarjetas_red' 
    AND column_name = 'en_stock'
    AND data_type = 'boolean'
  ) THEN
    -- Convertir valores booleanos a texto
    ALTER TABLE public.t_tarjetas_red 
    ALTER COLUMN en_stock TYPE TEXT USING 
      CASE 
        WHEN en_stock = true THEN 'SI'
        WHEN en_stock = false THEN 'NO'
        ELSE 'SI'
      END;
    
    -- Establecer valor por defecto
    ALTER TABLE public.t_tarjetas_red 
    ALTER COLUMN en_stock SET DEFAULT 'SI';
    
    RAISE NOTICE '✅ Columna en_stock convertida de BOOLEAN a TEXT';
  END IF;
END $$;

-- =====================================================
-- Crear o verificar la categoría SICOR en t_categorias
-- =====================================================

-- Insertar la categoría SICOR si no existe
INSERT INTO public.t_categorias (nombre, descripcion)
SELECT 'SICOR', 'Tarjetas de red'
WHERE NOT EXISTS (
  SELECT 1 FROM public.t_categorias 
  WHERE LOWER(nombre) = 'sicor' 
     OR LOWER(nombre) LIKE '%medición%' 
     OR LOWER(nombre) LIKE '%medicion%'
);

-- Si existe una categoría con "medición" o "medicion", actualizarla a SICOR
UPDATE public.t_categorias
SET nombre = 'SICOR',
    descripcion = 'Tarjetas de red'
WHERE (LOWER(nombre) LIKE '%medición%' OR LOWER(nombre) LIKE '%medicion%')
  AND LOWER(nombre) != 'sicor';

-- =====================================================
-- Verificación
-- =====================================================

-- Verificar que la tabla se creó correctamente
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 't_tarjetas_red'
  ) THEN
    RAISE NOTICE '✅ Tabla t_tarjetas_red creada correctamente';
  ELSE
    RAISE EXCEPTION '❌ Error: La tabla t_tarjetas_red no se creó';
  END IF;
END $$;

-- Verificar que la categoría SICOR existe
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.t_categorias 
    WHERE LOWER(nombre) = 'sicor'
  ) THEN
    RAISE NOTICE '✅ Categoría SICOR creada/actualizada correctamente';
  ELSE
    RAISE EXCEPTION '❌ Error: La categoría SICOR no existe';
  END IF;
END $$;

