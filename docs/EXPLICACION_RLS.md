# ¿Qué son las Políticas RLS (Row Level Security)?

## 📚 Conceptos Básicos

**RLS (Row Level Security)** es un sistema de seguridad de PostgreSQL/Supabase que controla **qué usuarios pueden hacer qué operaciones** en tus tablas de base de datos.

### 🔒 ¿Por qué existe RLS?

Sin RLS, cualquier persona con la clave de tu proyecto podría:
- Leer todos los datos
- Modificar cualquier registro
- Eliminar información importante

Con RLS habilitado, puedes controlar **exactamente** quién puede hacer qué.

## 🎯 Cómo Funciona

Las políticas RLS son como "reglas de acceso" que se aplican a cada operación en tu tabla:

### Tipos de Operaciones (COMMAND):
- **SELECT**: Leer datos
- **INSERT**: Crear nuevos registros
- **UPDATE**: Modificar registros existentes
- **DELETE**: Eliminar registros

### Roles (APPLIED TO):
- **authenticated**: Usuarios que han iniciado sesión
- **anon**: Usuarios anónimos (no autenticados)
- **service_role**: Servicios internos (muy poderoso, úsalo con cuidado)

## 📋 Tu Situación Actual

En tu tabla `t_empleados`:

✅ **RLS está HABILITADO** (bueno para seguridad)
✅ **Tienes una política para SELECT** (`lectura_publica_empleados`)
❌ **NO tienes política para UPDATE** (por eso falla la actualización)

### ¿Qué significa esto?

- ✅ Puedes **leer** empleados (SELECT funciona)
- ❌ **NO puedes actualizar** empleados (UPDATE está bloqueado por RLS)

## 🔧 Solución

Necesitas crear una política para UPDATE. He creado un script SQL que puedes ejecutar en Supabase.

### Pasos para aplicar la solución:

1. **Ve a Supabase Dashboard**
   - Abre tu proyecto
   - Ve a **SQL Editor** (en el menú lateral)

2. **Ejecuta el script**
   - Abre el archivo: `scripts_supabase/politica_rls_update_empleados.sql`
   - Copia y pega el contenido en el SQL Editor
   - Haz clic en **Run** o presiona `Ctrl+Enter`

3. **Verifica que funcionó**
   - Ve a **Authentication > Policies**
   - Busca `t_empleados`
   - Deberías ver una nueva política para UPDATE

## 🛡️ Seguridad

La política que creamos permite a **todos los usuarios autenticados** actualizar empleados. Esto es aceptable porque:

1. Tu aplicación Flutter ya valida que solo admins pueden acceder a la pantalla de gestión
2. Es más simple de implementar
3. Puedes restringir más después si es necesario

### Si quieres más seguridad:

Puedes crear una política más restrictiva que solo permita UPDATE a usuarios con rol "admin", pero requiere configuración adicional de autenticación en Supabase.

## 📖 Ejemplo Visual

```
┌─────────────────────────────────────┐
│  Tabla: t_empleados                │
│  RLS: ✅ HABILITADO                 │
├─────────────────────────────────────┤
│  Políticas:                         │
│                                     │
│  SELECT ✅                          │
│  └─ lectura_publica_empleados      │
│                                     │
│  UPDATE ❌ (FALTA)                  │
│  └─ [Necesitas crear esta]         │
│                                     │
│  INSERT ❌ (FALTA)                  │
│  DELETE ❌ (FALTA)                  │
└─────────────────────────────────────┘
```

## 🔍 Verificar Políticas Existentes

Puedes ver todas las políticas de una tabla ejecutando:

```sql
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE tablename = 't_empleados';
```

## ❓ Preguntas Frecuentes

### ¿RLS afecta el rendimiento?
- Mínimamente. Las políticas se evalúan rápidamente.

### ¿Puedo deshabilitar RLS?
- Sí, pero **NO es recomendado** en producción. Sin RLS, cualquiera con tu clave puede modificar datos.

### ¿Necesito políticas para todas las operaciones?
- Depende. Si solo necesitas SELECT y UPDATE, solo crea políticas para esas operaciones.

### ¿Qué pasa si no tengo política para una operación?
- La operación será **rechazada** (como está pasando con UPDATE ahora).

## 📝 Resumen

**RLS = Control de acceso a nivel de fila**

- Sin política UPDATE → No puedes actualizar
- Con política UPDATE → Puedes actualizar (según las reglas de la política)

**Solución:** Ejecuta el script SQL para crear la política UPDATE.

