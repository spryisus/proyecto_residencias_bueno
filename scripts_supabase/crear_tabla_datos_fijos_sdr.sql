-- Script para crear la tabla de datos fijos de SDR
-- Esta tabla almacena los campos que tienen valores fijos compartidos por todos los usuarios

CREATE TABLE IF NOT EXISTS public.t_datos_fijos_sdr (
  id_dato_fijo SERIAL PRIMARY KEY,
  campo_nombre TEXT NOT NULL UNIQUE,
  valor TEXT NOT NULL,
  descripcion TEXT,
  actualizado_en TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  actualizado_por TEXT,
  creado_en TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  creado_por TEXT
);

-- Insertar los valores iniciales de los campos fijos
INSERT INTO public.t_datos_fijos_sdr (campo_nombre, valor, descripcion, creado_por) VALUES
  ('grupo_planificador', 'LD. 70', 'Grupo planificador por defecto', 'Sistema'),
  ('puesto_trabajo_responsable', 'PTAZ POZA RICA', 'Puesto de trabajo responsable por defecto', 'Sistema'),
  ('autor_aviso', '0117', 'Autor de aviso por defecto', 'Sistema'),
  ('centro_emplazamiento', 'LDTX', 'Centro de emplazamiento por defecto', 'Sistema'),
  ('puesto_trabajo_emplazamiento', 'COM-PUE', 'Puesto de trabajo de emplazamiento por defecto', 'Sistema'),
  ('division', '70', 'División por defecto', 'Sistema'),
  ('emplazamiento_1', 'PTAZ PORZA RICA', 'Emplazamiento 1 por defecto', 'Sistema')
ON CONFLICT (campo_nombre) DO NOTHING;

-- Crear índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_datos_fijos_sdr_campo_nombre ON public.t_datos_fijos_sdr(campo_nombre);
CREATE INDEX IF NOT EXISTS idx_datos_fijos_sdr_actualizado_en ON public.t_datos_fijos_sdr(actualizado_en DESC);

-- Habilitar RLS (Row Level Security)
ALTER TABLE public.t_datos_fijos_sdr ENABLE ROW LEVEL SECURITY;

-- Política para permitir lectura a todos los usuarios autenticados
CREATE POLICY "Permitir lectura a usuarios autenticados"
  ON public.t_datos_fijos_sdr
  FOR SELECT
  TO authenticated
  USING (true);

-- Política para permitir inserción a todos los usuarios autenticados
CREATE POLICY "Permitir inserción a usuarios autenticados"
  ON public.t_datos_fijos_sdr
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Política para permitir actualización a todos los usuarios autenticados
CREATE POLICY "Permitir actualización a usuarios autenticados"
  ON public.t_datos_fijos_sdr
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Comentarios para documentación
COMMENT ON TABLE public.t_datos_fijos_sdr IS 
'Tabla que almacena los valores fijos compartidos para las solicitudes SDR. Cuando un usuario actualiza un valor, todos los usuarios verán el cambio.';

COMMENT ON COLUMN public.t_datos_fijos_sdr.campo_nombre IS 
'Nombre único del campo (ej: grupo_planificador, autor_aviso, etc.)';

COMMENT ON COLUMN public.t_datos_fijos_sdr.valor IS 
'Valor actual del campo fijo';

COMMENT ON COLUMN public.t_datos_fijos_sdr.actualizado_por IS 
'Usuario que realizó la última actualización';

