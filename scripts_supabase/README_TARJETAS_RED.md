# Scripts de Base de Datos - Tarjetas de Red (SICOR)

## 📋 Descripción

Este script crea la tabla `t_tarjetas_red` para el inventario de tarjetas de red (SICOR) y asegura que la categoría SICOR exista en la base de datos.

## 🚀 Instrucciones de Ejecución

### Si la tabla NO existe (primera vez)

#### Opción 1: Ejecutar desde Supabase Dashboard

1. Abre tu proyecto en [Supabase Dashboard](https://app.supabase.com)
2. Ve a **SQL Editor** en el menú lateral
3. Copia y pega el contenido del archivo `t_tarjetas_red.sql`
4. Haz clic en **Run** o presiona `Ctrl+Enter` (o `Cmd+Enter` en Mac)

#### Opción 2: Ejecutar desde la línea de comandos (psql)

```bash
psql -h <tu-host> -U postgres -d postgres -f scripts_supabase/t_tarjetas_red.sql
```

### Si la tabla YA existe con BOOLEAN (migración)

Si ya creaste la tabla y obtienes un error al importar datos porque `en_stock` es BOOLEAN y tus datos tienen "SI"/"NO":

1. Ve a **SQL Editor** en Supabase Dashboard
2. Copia y pega el contenido del archivo `migrar_en_stock_tarjetas_red.sql`
3. Ejecuta el script
4. Ahora podrás importar tus datos con valores "SI" y "NO"

## 📝 Estructura de la Tabla

### `t_tarjetas_red`

La tabla contiene los siguientes campos:

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id_tarjeta_red` | INTEGER (PK, AUTO) | Identificador único |
| `en_stock` | TEXT | Indica si está en stock: "SI" o "NO" |
| `numero` | TEXT | Número de identificación (No.) |
| `codigo` | TEXT | Código de la tarjeta |
| `serie` | TEXT | Número de serie |
| `marca` | TEXT | Marca de la tarjeta |
| `posicion` | TEXT | Posición o ubicación |
| `comentarios` | TEXT | Comentarios adicionales |
| `fecha_registro` | TIMESTAMP | Fecha de registro (auto) |
| `fecha_actualizacion` | TIMESTAMP | Fecha de última actualización (auto) |

## 🔍 Características

- ✅ **Auto-incremento**: El ID se genera automáticamente
- ✅ **Índices**: Creados para mejorar el rendimiento en búsquedas por número, código, serie y estado de stock
- ✅ **Trigger automático**: Actualiza `fecha_actualizacion` cuando se modifica un registro
- ✅ **Categoría SICOR**: Crea o actualiza la categoría SICOR en `t_categorias`
- ✅ **Migración**: Si existe una categoría "Equipo de Medición", la actualiza a "SICOR"

## ⚠️ Importante

- El script es **idempotente**: puedes ejecutarlo múltiples veces sin problemas
- Si ya existe una categoría con "medición" o "medicion", se actualizará automáticamente a "SICOR"
- La tabla se crea vacía, lista para recibir datos
- **El campo `en_stock` acepta valores "SI" y "NO"** (no true/false) para facilitar la importación de datos desde Excel
- Si ya creaste la tabla con BOOLEAN, ejecuta el script de migración `migrar_en_stock_tarjetas_red.sql`

## 🔍 Verificación

Después de ejecutar el script, verifica que todo se creó correctamente:

```sql
-- Verificar la tabla
SELECT * FROM t_tarjetas_red LIMIT 5;

-- Verificar la categoría SICOR
SELECT * FROM t_categorias WHERE LOWER(nombre) = 'sicor';

-- Ver estructura de la tabla
\d t_tarjetas_red
```

## 📊 Ejemplo de Uso

```sql
-- Insertar una tarjeta de red
INSERT INTO t_tarjetas_red (en_stock, numero, codigo, serie, marca, posicion, comentarios)
VALUES ('SI', 'SICOR001', 'NTFW08CB', 'NNTMA1B1C7FF7', 'NORTEL -TN16X', 'G-1 R-C', 'Tarjeta nueva');

-- Consultar todas las tarjetas en stock
SELECT * FROM t_tarjetas_red WHERE en_stock = 'SI';

-- Consultar tarjetas fuera de stock
SELECT * FROM t_tarjetas_red WHERE en_stock = 'NO';

-- Actualizar una tarjeta
UPDATE t_tarjetas_red 
SET en_stock = 'NO', comentarios = 'Fuera de servicio'
WHERE numero = 'SICOR001';
```

## 🔧 Solución de Problemas

### Error: "invalid input syntax for type boolean: 'SI'"

Si obtienes este error al importar datos, significa que la tabla fue creada con `en_stock` como BOOLEAN. 

**Solución:**
1. Ejecuta el script de migración: `migrar_en_stock_tarjetas_red.sql`
2. Vuelve a intentar importar tus datos

El script de migración convertirá automáticamente:
- `true` → `'SI'`
- `false` → `'NO'`

