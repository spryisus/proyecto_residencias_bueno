# Restructuración del Inventario de Cómputo

Este documento describe la nueva estructura del inventario de cómputo dividida en 7 tablas separadas.

## 📋 Orden de Ejecución de Scripts

**IMPORTANTE:** Ejecuta los scripts en el siguiente orden:

1. **`eliminar_tablas_computo_antiguas.sql`** - Elimina las tablas antiguas
2. **`crear_tabla_computo_detalles_generales.sql`** - Crea la tabla de equipos principales Y la tabla de detalles generales (componentes)
3. **`crear_tabla_computo_software.sql`** - Crea la tabla de software
4. **`crear_tabla_computo_ubicacion.sql`** - Crea la tabla de ubicación (compartida)
5. **`crear_tabla_computo_identificacion.sql`** - Crea la tabla de identificación
6. **`crear_tabla_computo_usuario_responsable.sql`** - Crea la tabla de usuario responsable (compartida)
7. **`crear_tabla_computo_usuario_final.sql`** - Crea la tabla de usuario final
8. **`crear_tabla_computo_observaciones.sql`** - Crea la tabla de observaciones
9. **`crear_vista_computo_completo.sql`** - Crea la vista unificada

## 🗂️ Estructura de las Tablas

### 1. **t_computo_equipos_principales** (Tabla de Agrupación)
Tabla que agrupa los equipos principales (equipo_pm). Un equipo_pm puede contener múltiples componentes.

**Campos:**
- `id_equipo_principal` (BIGINT, PK, AUTO)
- `equipo_pm` (TEXT, UNIQUE, NOT NULL)
- `creado_en` (TIMESTAMP)
- `actualizado_en` (TIMESTAMP)

**Relación:** 1:N con `t_computo_detalles_generales` (un equipo_pm puede tener múltiples componentes)

### 2. **t_computo_detalles_generales** (Tabla de Componentes)
Información de cada componente individual que pertenece a un equipo_pm.

**Campos:**
- `id_equipo_computo` (BIGINT, PK, AUTO)
- `id_equipo_principal` (BIGINT, FK → t_computo_equipos_principales, NOT NULL)
- `inventario` (TEXT, UNIQUE, NOT NULL)
- `fecha_registro` (DATE)
- `tipo_equipo` (TEXT, NOT NULL)
- `marca` (TEXT)
- `modelo` (TEXT)
- `procesador` (TEXT)
- `numero_serie` (TEXT)
- `disco_duro` (TEXT)
- `memoria_ram` (TEXT)
- `id_ubicacion` (BIGINT, FK → t_computo_ubicacion)
- `id_usuario_responsable` (BIGINT, FK → t_computo_usuario_responsable)
- `creado_en` (TIMESTAMP)
- `actualizado_en` (TIMESTAMP)

**Relación:** N:1 con `t_computo_equipos_principales` (múltiples componentes pertenecen a un equipo_pm)

### 3. **t_computo_software**
Información del software instalado en el equipo.

**Campos:**
- `id_software` (BIGINT, PK, AUTO)
- `id_equipo_computo` (BIGINT, FK → t_computo_detalles_generales)
- `sistema_operativo_instalado` (TEXT)
- `etiqueta_sistema_operativo` (TEXT)
- `office_instalado` (TEXT)
- `creado_en` (TIMESTAMP)
- `actualizado_en` (TIMESTAMP)

**Relación:** 1:1 con `t_computo_detalles_generales`

### 4. **t_computo_ubicacion** (Compartida)
Información de ubicación física compartida para múltiples equipos.

**Campos:**
- `id_ubicacion` (BIGINT, PK, AUTO)
- `direccion_fisica` (TEXT, NOT NULL)
- `estado` (TEXT, NOT NULL)
- `ciudad` (TEXT, NOT NULL)
- `tipo_edificio` (TEXT)
- `nombre_edificio` (TEXT)
- `creado_en` (TIMESTAMP)
- `actualizado_en` (TIMESTAMP)

**Características:**
- Tabla independiente (no depende de equipos)
- Puede ser referenciada por múltiples equipos
- Constraint UNIQUE para evitar duplicados exactos

**Relación:** N:1 (múltiples equipos pueden compartir la misma ubicación)

### 5. **t_computo_identificacion**
Información de identificación y clasificación del equipo.

**Campos:**
- `id_identificacion` (BIGINT, PK, AUTO)
- `id_equipo_computo` (BIGINT, FK → t_computo_detalles_generales)
- `tipo_uso` (TEXT)
- `nombre_equipo_dominio` (TEXT)
- `status` (TEXT, DEFAULT 'ASIGNADO')
- `direccion_administrativa` (TEXT)
- `subdireccion` (TEXT)
- `gerencia` (TEXT)
- `creado_en` (TIMESTAMP)
- `actualizado_en` (TIMESTAMP)

**Relación:** 1:1 con `t_computo_detalles_generales`

### 6. **t_computo_usuario_responsable** (Compartida)
Información del usuario responsable compartida para múltiples equipos.

**Campos:**
- `id_usuario_responsable` (BIGINT, PK, AUTO)
- `expediente` (TEXT)
- `apellido_paterno` (TEXT)
- `apellido_materno` (TEXT)
- `nombre` (TEXT, NOT NULL)
- `empresa` (TEXT, NOT NULL)
- `puesto` (TEXT)
- `activo` (BOOLEAN, DEFAULT true)
- `creado_en` (TIMESTAMP)
- `actualizado_en` (TIMESTAMP)

**Características:**
- Tabla independiente (no depende de equipos)
- Puede ser referenciada por múltiples equipos
- Constraint UNIQUE para evitar duplicados exactos

**Relación:** N:1 (múltiples equipos pueden compartir el mismo usuario responsable)

### 7. **t_computo_usuario_final**
Información del usuario final que utiliza el equipo.

**Campos:**
- `id_usuario_final` (BIGINT, PK, AUTO)
- `id_equipo_computo` (BIGINT, FK → t_computo_detalles_generales)
- `expediente` (TEXT)
- `apellido_paterno` (TEXT)
- `apellido_materno` (TEXT)
- `nombre` (TEXT, NOT NULL)
- `empresa` (TEXT, NOT NULL)
- `puesto` (TEXT)
- `activo` (BOOLEAN, DEFAULT true)
- `creado_en` (TIMESTAMP)
- `actualizado_en` (TIMESTAMP)

**Relación:** 1:1 con `t_computo_detalles_generales`

### 8. **t_computo_observaciones**
Observaciones y notas adicionales sobre el equipo.

**Campos:**
- `id_observacion` (BIGINT, PK, AUTO)
- `id_equipo_computo` (BIGINT, FK → t_computo_detalles_generales)
- `observaciones` (TEXT)
- `creado_en` (TIMESTAMP)
- `actualizado_en` (TIMESTAMP)

**Relación:** 1:1 con `t_computo_detalles_generales`

## 🔗 Relaciones entre Tablas

```
t_computo_equipos_principales (AGRUPA EQUIPOS)
    └── t_computo_detalles_generales (COMPONENTES) (N:1)
        ├── t_computo_software (1:1)
        ├── t_computo_ubicacion (N:1) [FK en detalles_generales]
        ├── t_computo_identificacion (1:1)
        ├── t_computo_usuario_responsable (N:1) [FK en detalles_generales]
        ├── t_computo_usuario_final (1:1)
        └── t_computo_observaciones (1:1)
```

**Ejemplo de estructura:**
- **Equipo Principal** (equipo_pm: "RE061260")
  - **Componente 1**: ESCRITORI (inventario: "RE061260", tipo_equipo: "ESCRITORI", marca: "DELL", ...)
  - **Componente 2**: MONITOR (inventario: "RE060369", tipo_equipo: "MONITOR", marca: "DELL", ...)
  - **Componente 3**: TECLADO (inventario: "RE060370", tipo_equipo: "TECLADO", marca: "LOGITECH", ...)
  - **Componente 4**: MOUSE (inventario: "RE060371", tipo_equipo: "MOUSE", marca: "LOGITECH", ...)

## 📊 Vista Unificada

**`v_equipos_computo_completo`**: Vista que une todas las tablas para facilitar las consultas.

Esta vista incluye todos los campos de las 7 tablas en un solo resultado, facilitando las consultas desde la aplicación Flutter.

## 🔒 Seguridad (RLS)

Todas las tablas tienen Row Level Security (RLS) habilitado con políticas que permiten:
- **SELECT**: Todos los usuarios autenticados pueden leer
- **INSERT**: Todos los usuarios autenticados pueden insertar
- **UPDATE**: Todos los usuarios autenticados pueden actualizar
- **DELETE**: Todos los usuarios autenticados pueden eliminar

## ⚠️ Notas Importantes

1. **Estructura de Agrupación**: 
   - `t_computo_equipos_principales` agrupa los equipos por `equipo_pm`
   - `t_computo_detalles_generales` contiene los componentes individuales (ESCRITORI, MONITOR, TECLADO, MOUSE, etc.)
   - Un `equipo_pm` puede tener múltiples componentes, cada uno con su propio inventario

2. **Tablas Compartidas**: `t_computo_ubicacion` y `t_computo_usuario_responsable` son tablas compartidas que pueden ser referenciadas por múltiples componentes. Esto evita duplicación de datos.

3. **Eliminación en Cascada**: 
   - Si se elimina un equipo principal, se eliminan todos sus componentes
   - Las tablas dependientes (software, identificación, usuario_final, observaciones) se eliminan automáticamente cuando se elimina un componente

4. **Eliminación con SET NULL**: Las referencias a ubicación y usuario responsable se ponen en NULL si se eliminan, para no perder los datos del componente.

5. **Índices**: Se han creado índices en campos frecuentemente consultados para mejorar el rendimiento.

6. **Triggers**: Todas las tablas tienen triggers que actualizan automáticamente el campo `actualizado_en` cuando se modifica un registro.

7. **Importación de CSV**: 
   - Primero importa los `equipo_pm` únicos a `t_computo_equipos_principales`
   - Luego importa los componentes a `t_computo_detalles_generales` referenciando el `id_equipo_principal` correspondiente

## 📝 Migración de Datos

Si tienes datos en las tablas antiguas (`t_equipos_computo` y `t_empleados_computo`), necesitarás crear scripts de migración para transferir los datos a las nuevas tablas. Esto debe hacerse después de crear todas las nuevas tablas.

