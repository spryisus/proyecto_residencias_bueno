-- Script para crear usuario de prueba en Supabase Auth
-- IMPORTANTE: Este script debe ejecutarse DESPUÉS de crear el usuario en Supabase Auth

-- Paso 1: Crear usuario en Supabase Auth Dashboard
-- Ve a: Dashboard > Authentication > Users > Add User
-- Email: admin@telmex.com
-- Password: admin123
-- Confirma la creación

-- Paso 2: Obtener el UUID del usuario creado
-- Después de crear el usuario, copia su UUID desde el Dashboard

-- Paso 3: Insertar empleado (reemplaza 'TU_UUID_AQUI' con el UUID real)
INSERT INTO t_empleados (id_empleado, nombre_usuario, activo) VALUES
  ('TU_UUID_AQUI', 'admin@telmex.com', true);

-- Paso 4: Asignar rol de admin
INSERT INTO t_empleado_rol (id_empleado, id_rol)
SELECT 'TU_UUID_AQUI', id_rol
FROM t_roles WHERE nombre = 'admin';

-- Paso 5: Verificar que todo esté correcto
SELECT 
  e.nombre_usuario,
  e.activo,
  r.nombre as rol
FROM t_empleados e
JOIN t_empleado_rol er ON e.id_empleado = er.id_empleado
JOIN t_roles r ON er.id_rol = r.id_rol
WHERE e.nombre_usuario = 'admin@telmex.com';

