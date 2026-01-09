-- Script para agregar la política de INSERT faltante en t_datos_fijos_sdr
-- Ejecuta este script si ya creaste la tabla pero te falta la política de INSERT

-- Eliminar la política si ya existe (para evitar errores)
DROP POLICY IF EXISTS "Permitir inserción a usuarios autenticados" ON public.t_datos_fijos_sdr;

-- Crear la política de INSERT
CREATE POLICY "Permitir inserción a usuarios autenticados"
  ON public.t_datos_fijos_sdr
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

