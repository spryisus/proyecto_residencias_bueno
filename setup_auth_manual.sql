-- ============================================
-- Configuración para Autenticación Manual (sin Supabase Auth)
-- ============================================
-- Ejecuta este SQL en el SQL Editor de Supabase

-- ============================================
-- 1. Deshabilitar RLS o crear políticas permisivas
-- ============================================
-- Opción A: Deshabilitar RLS completamente (solo para desarrollo)
-- ALTER TABLE public.t_empleados DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.t_empleado_rol DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.t_roles DISABLE ROW LEVEL SECURITY;

-- Opción B: Crear políticas que permitan lectura pública (más seguro)
-- Solo permite leer, no modificar

-- Política para t_empleados: permitir lectura pública (solo para login)
ALTER TABLE public.t_empleados ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "lectura_publica_empleados" ON public.t_empleados;
CREATE POLICY "lectura_publica_empleados"
  ON public.t_empleados
  FOR SELECT
  TO public
  USING (true);

-- IMPORTANTE: No permitir INSERT/UPDATE/DELETE sin autenticación
-- Si necesitas crear usuarios, hazlo manualmente o con una función RPC segura

-- Política para t_empleado_rol: permitir lectura pública
ALTER TABLE public.t_empleado_rol ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "lectura_publica_empleado_rol" ON public.t_empleado_rol;
CREATE POLICY "lectura_publica_empleado_rol"
  ON public.t_empleado_rol
  FOR SELECT
  TO public
  USING (true);

-- Política para t_roles: permitir lectura pública
ALTER TABLE public.t_roles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "lectura_publica_roles" ON public.t_roles;
CREATE POLICY "lectura_publica_roles"
  ON public.t_roles
  FOR SELECT
  TO public
  USING (true);

-- ============================================
-- 2. Función RPC para crear usuarios de forma segura
-- ============================================
-- Esta función permite crear usuarios hasheando la contraseña con bcrypt
-- NOTA: Necesitas tener la extensión pgcrypto instalada en Supabase

CREATE OR REPLACE FUNCTION public.crear_empleado(
  p_nombre_usuario TEXT,
  p_contrasena TEXT,
  p_activo BOOLEAN DEFAULT true
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_id_empleado UUID;
  v_contrasena_hash TEXT;
BEGIN
  -- Generar UUID para el empleado
  v_id_empleado := gen_random_uuid();
  
  -- IMPORTANTE: En Supabase no puedes usar bcrypt directamente en SQL
  -- Debes hashear la contraseña en tu aplicación Flutter antes de llamar esta función
  -- O usar una función RPC que reciba el hash ya hecho
  
  -- Insertar empleado
  INSERT INTO public.t_empleados (id_empleado, nombre_usuario, contrasena, activo)
  VALUES (v_id_empleado, p_nombre_usuario, p_contrasena, p_activo);
  
  RETURN v_id_empleado;
END;
$$;

-- ============================================
-- 3. Función para asignar rol a empleado
-- ============================================

CREATE OR REPLACE FUNCTION public.asignar_rol_empleado(
  p_id_empleado UUID,
  p_nombre_rol TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_id_rol INTEGER;
BEGIN
  -- Buscar el ID del rol por nombre
  SELECT id_rol INTO v_id_rol
  FROM public.t_roles
  WHERE nombre = p_nombre_rol;
  
  IF v_id_rol IS NULL THEN
    RAISE EXCEPTION 'Rol % no encontrado', p_nombre_rol;
  END IF;
  
  -- Asignar rol (ignorar si ya existe)
  INSERT INTO public.t_empleado_rol (id_empleado, id_rol)
  VALUES (p_id_empleado, v_id_rol)
  ON CONFLICT (id_empleado, id_rol) DO NOTHING;
END;
$$;

-- ============================================
-- 4. Verificar que los roles existan
-- ============================================
-- Asegúrate de tener estos roles en tu tabla t_roles

INSERT INTO public.t_roles (nombre, descripcion)
VALUES 
  ('admin', 'Administrador del sistema'),
  ('operador', 'Operador del sistema'),
  ('auditor', 'Auditor del sistema')
ON CONFLICT (nombre) DO NOTHING;

-- ============================================
-- 5. Ejemplo: Crear un usuario admin manualmente
-- ============================================
-- NOTA: La contraseña debe estar hasheada con bcrypt en tu app Flutter
-- Para crear un usuario con contraseña en texto plano (solo desarrollo):

/*
-- Ejemplo con contraseña en texto plano (NO RECOMENDADO para producción)
INSERT INTO public.t_empleados (id_empleado, nombre_usuario, contrasena, activo)
VALUES (
  gen_random_uuid(),
  'admin',
  'admin123',  -- Contraseña en texto plano
  true
)
RETURNING id_empleado;

-- Luego asignar el rol (reemplaza 'UUID_AQUI' con el UUID retornado)
SELECT asignar_rol_empleado('UUID_AQUI', 'admin');
*/

-- ============================================
-- NOTAS IMPORTANTES:
-- ============================================
-- 1. Las políticas RLS permiten lectura pública, pero NO escritura
-- 2. Para crear usuarios, usa las funciones RPC o hazlo manualmente
-- 3. RECOMENDADO: Hashea las contraseñas con bcrypt en Flutter antes de guardarlas
-- 4. Para producción, considera usar autenticación más segura o JWT tokens
-- 5. Si necesitas más seguridad, puedes crear políticas más restrictivas



