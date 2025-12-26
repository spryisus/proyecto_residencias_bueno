-- =====================================================
-- Script para crear tabla t_jumper_contenedores
-- Permite múltiples contenedores por jumper (producto)
-- =====================================================

-- Crear la tabla t_jumper_contenedores
CREATE TABLE IF NOT EXISTS public.t_jumper_contenedores (
  id_contenedor INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_producto INTEGER NOT NULL,
  rack TEXT,
  contenedor TEXT NOT NULL,
  cantidad INTEGER DEFAULT 0,
  fecha_registro TIMESTAMP DEFAULT NOW(),
  
  -- Foreign key a t_productos
  CONSTRAINT fk_jumper_contenedor_producto 
    FOREIGN KEY (id_producto) 
    REFERENCES public.t_productos(id_producto) 
    ON DELETE CASCADE
);

-- Crear índice para mejorar las consultas por producto
CREATE INDEX IF NOT EXISTS idx_jumper_contenedores_producto 
  ON public.t_jumper_contenedores(id_producto);

-- Crear índice para mejorar las consultas por contenedor
CREATE INDEX IF NOT EXISTS idx_jumper_contenedores_contenedor 
  ON public.t_jumper_contenedores(contenedor);

-- Comentarios en la tabla y columnas
COMMENT ON TABLE public.t_jumper_contenedores IS 
  'Almacena múltiples contenedores para cada jumper (producto). Permite que un mismo jumper esté en diferentes contenedores.';

COMMENT ON COLUMN public.t_jumper_contenedores.id_contenedor IS 
  'Identificador único del contenedor (auto-generado)';

COMMENT ON COLUMN public.t_jumper_contenedores.id_producto IS 
  'Referencia al producto (jumper) al que pertenece este contenedor';

COMMENT ON COLUMN public.t_jumper_contenedores.rack IS 
  'Rack donde se encuentra el contenedor (opcional)';

COMMENT ON COLUMN public.t_jumper_contenedores.contenedor IS 
  'Nombre o identificador del contenedor (obligatorio)';

COMMENT ON COLUMN public.t_jumper_contenedores.cantidad IS 
  'Cantidad de jumpers en este contenedor específico';

COMMENT ON COLUMN public.t_jumper_contenedores.fecha_registro IS 
  'Fecha y hora en que se registró este contenedor';

-- =====================================================
-- Script opcional: Migrar datos existentes
-- Si ya tienes jumpers con rack y contenedor en t_productos,
-- puedes ejecutar este script para migrarlos a la nueva tabla
-- =====================================================

-- NOTA: Descomenta y ejecuta solo si quieres migrar los datos existentes
/*
INSERT INTO public.t_jumper_contenedores (id_producto, rack, contenedor, cantidad, fecha_registro)
SELECT 
  id_producto,
  rack,
  contenedor,
  COALESCE(CAST(unidad AS INTEGER), 0) as cantidad,
  NOW() as fecha_registro
FROM public.t_productos
WHERE rack IS NOT NULL OR contenedor IS NOT NULL;
*/



