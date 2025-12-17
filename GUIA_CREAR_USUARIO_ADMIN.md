# Guía Paso a Paso para Crear Usuario Admin

## El Error Actual
`Invalid login credentials` significa que el usuario no existe en Supabase Auth o las credenciales son incorrectas.

## Solución Detallada

### Paso 1: Crear Usuario en Supabase Auth Dashboard

1. **Ve al Dashboard de Supabase**
   - Abre tu proyecto en https://supabase.com/dashboard
   - Navega a **Authentication** en el menú lateral
   - Haz clic en **Users**

2. **Crear Nuevo Usuario**
   - Haz clic en **"Add User"** o **"Invite User"**
   - Completa los campos:
     - **Email**: `admin@telmex.com`
     - **Password**: `admin123`
     - **Confirm Password**: `admin123`
   - Haz clic en **"Create User"**

3. **Copiar el UUID del Usuario**
   - Una vez creado, verás una lista de usuarios
   - Busca `admin@telmex.com`
   - **Copia el UUID** (es un string largo como `12345678-1234-1234-1234-123456789abc`)

### Paso 2: Ejecutar SQL en Supabase

1. **Ve a SQL Editor**
   - En el Dashboard de Supabase, ve a **SQL Editor**
   - Haz clic en **"New Query"**

2. **Ejecutar este SQL** (reemplaza `TU_UUID_AQUI` con el UUID real):

```sql
-- Insertar empleado
INSERT INTO t_empleados (id_empleado, nombre_usuario, activo) VALUES
  ('TU_UUID_AQUI', 'admin@telmex.com', true);

-- Asignar rol de admin
INSERT INTO t_empleado_rol (id_empleado, id_rol)
SELECT 'TU_UUID_AQUI', id_rol
FROM t_roles WHERE nombre = 'admin';

-- Verificar que todo esté correcto
SELECT 
  e.nombre_usuario,
  e.activo,
  r.nombre as rol
FROM t_empleados e
JOIN t_empleado_rol er ON e.id_empleado = er.id_empleado
JOIN t_roles r ON er.id_rol = r.id_rol
WHERE e.nombre_usuario = 'admin@telmex.com';
```

### Paso 3: Probar el Login

1. **En la aplicación Flutter**:
   - Email: `admin@telmex.com`
   - Password: `admin123`
   - Haz clic en **"Iniciar sesión"**

## Verificación Adicional

Si aún tienes problemas, ejecuta este SQL para verificar que todo esté en orden:

```sql
-- Verificar roles
SELECT * FROM t_roles;

-- Verificar empleados
SELECT * FROM t_empleados;

-- Verificar asignaciones de roles
SELECT 
  e.nombre_usuario,
  r.nombre as rol
FROM t_empleados e
JOIN t_empleado_rol er ON e.id_empleado = er.id_empleado
JOIN t_roles r ON er.id_rol = r.id_rol;
```

## Posibles Problemas

1. **Usuario no confirmado**: Si el usuario no está confirmado, ve a Authentication > Users y haz clic en "Confirm" junto al usuario.

2. **UUID incorrecto**: Asegúrate de copiar el UUID completo sin espacios.

3. **Roles no creados**: Si no tienes roles, ejecuta primero:
   ```sql
   INSERT INTO t_roles (nombre, descripcion) VALUES
     ('admin','Acceso total al sistema'),
     ('operador','Opera inventario y reportes'),
     ('auditor','Solo lectura y auditoría');
   ```

## Resultado Esperado

Después de seguir estos pasos, deberías poder:
- Hacer login con `admin@telmex.com` / `admin123`
- Ser redirigido al Admin Dashboard
- Ver todas las funcionalidades administrativas

