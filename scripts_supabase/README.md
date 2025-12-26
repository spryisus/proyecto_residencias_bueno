# Scripts de Base de Datos - Múltiples Contenedores para Jumpers

## 📋 Descripción

Este script crea la tabla `t_jumper_contenedores` que permite que un mismo jumper (producto) tenga múltiples contenedores, cada uno con su propio rack, nombre de contenedor y cantidad.

## 🚀 Instrucciones de Ejecución

### Opción 1: Ejecutar desde Supabase Dashboard

1. Abre tu proyecto en [Supabase Dashboard](https://app.supabase.com)
2. Ve a **SQL Editor** en el menú lateral
3. Copia y pega el contenido del archivo `t_jumper_contenedores.sql`
4. Haz clic en **Run** o presiona `Ctrl+Enter` (o `Cmd+Enter` en Mac)

### Opción 2: Ejecutar desde la línea de comandos (psql)

```bash
psql -h <tu-host> -U postgres -d postgres -f scripts_supabase/t_jumper_contenedores.sql
```

## 📝 Scripts Incluidos

### `t_jumper_contenedores.sql`

Este script:
- ✅ Crea la tabla `t_jumper_contenedores`
- ✅ Define las relaciones con `t_productos` (foreign key)
- ✅ Crea índices para mejorar el rendimiento
- ✅ Agrega comentarios descriptivos
- ⚠️ Incluye un script opcional (comentado) para migrar datos existentes

## ⚠️ Importante

- **No ejecutes el script de migración** (la parte comentada) a menos que quieras migrar datos existentes de `t_productos.rack` y `t_productos.contenedor` a la nueva tabla.
- Si ejecutas la migración, los datos existentes se copiarán a la nueva tabla, pero los campos originales en `t_productos` permanecerán (para retrocompatibilidad).

## 🔍 Verificación

Después de ejecutar el script, verifica que la tabla se creó correctamente:

```sql
SELECT * FROM t_jumper_contenedores LIMIT 5;
```

Deberías ver una tabla vacía (o con datos si ejecutaste la migración).

## 📊 Estructura de la Tabla

```sql
t_jumper_contenedores
├── id_contenedor (INTEGER, PRIMARY KEY, AUTO-GENERATED)
├── id_producto (INTEGER, FOREIGN KEY -> t_productos)
├── rack (TEXT, opcional)
├── contenedor (TEXT, obligatorio)
├── cantidad (INTEGER, default: 0)
└── fecha_registro (TIMESTAMP, default: NOW())
```

## ✅ Listo

Una vez ejecutado el script, la aplicación Flutter podrá:
- Agregar múltiples contenedores a un jumper
- Mostrar todos los contenedores de cada jumper
- Gestionar cantidades por contenedor



