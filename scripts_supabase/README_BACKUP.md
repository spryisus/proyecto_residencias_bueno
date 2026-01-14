# Guía para hacer Backup de la Base de Datos

## Opción 1: Backup desde Supabase Dashboard (Más fácil)

1. Ve a tu proyecto en [Supabase Dashboard](https://app.supabase.com)
2. Ve a **Settings** → **Database**
3. Busca la sección **Backups** o **Database Backups**
4. Haz clic en **Create Backup** o **Download Backup**
5. Espera a que se genere el backup (puede tardar unos minutos)
6. Descarga el archivo `.sql` o `.dump`

## Opción 2: Backup usando pg_dump (Desde terminal)

### Requisitos:
- Tener `pg_dump` instalado en tu sistema
- Tener las credenciales de conexión de Supabase

### Pasos:

1. **Obtener las credenciales de conexión:**
   - Ve a Supabase Dashboard → Settings → Database
   - Busca la sección **Connection string** o **Connection pooling**
   - Copia la cadena de conexión (formato: `postgresql://postgres:[PASSWORD]@[HOST]:[PORT]/postgres`)

2. **Ejecutar el backup:**
   ```bash
   # Backup completo de la base de datos
   pg_dump "postgresql://postgres:[PASSWORD]@[HOST]:[PORT]/postgres" > backup_completo_$(date +%Y%m%d_%H%M%S).sql
   
   # Ejemplo real (reemplaza con tus credenciales):
   pg_dump "postgresql://postgres:tu_password@db.xxxxx.supabase.co:5432/postgres" > backup_$(date +%Y%m%d_%H%M%S).sql
   ```

3. **Backup solo de la tabla específica:**
   ```bash
   # Backup solo de t_computo_usuario_final
   pg_dump "postgresql://postgres:[PASSWORD]@[HOST]:[PORT]/postgres" \
     --table=public.t_computo_usuario_final \
     --data-only \
     > backup_usuario_final_$(date +%Y%m%d_%H%M%S).sql
   ```

## Opción 3: Backup usando psql (Exportar datos específicos)

```bash
# Conectar a la base de datos
psql "postgresql://postgres:[PASSWORD]@[HOST]:[PORT]/postgres"

# Dentro de psql, exportar la tabla
\copy (SELECT * FROM public.t_computo_usuario_final) TO 'backup_usuario_final.csv' WITH CSV HEADER;
```

## Opción 4: Backup desde Supabase SQL Editor (Solo estructura y datos)

1. Ve a **SQL Editor** en Supabase Dashboard
2. Ejecuta esta consulta para exportar los datos:

```sql
-- Exportar estructura y datos de t_computo_usuario_final
SELECT 
    'INSERT INTO public.t_computo_usuario_final (id_usuario_final, id_equipo_computo, expediente, apellido_paterno, apellido_materno, nombre, empresa, puesto, creado_en, actualizado_en) VALUES (' ||
    id_usuario_final || ', ' ||
    COALESCE(id_equipo_computo::text, 'NULL') || ', ' ||
    COALESCE('''' || expediente || '''', 'NULL') || ', ' ||
    COALESCE('''' || apellido_paterno || '''', 'NULL') || ', ' ||
    COALESCE('''' || apellido_materno || '''', 'NULL') || ', ' ||
    COALESCE('''' || nombre || '''', 'NULL') || ', ' ||
    COALESCE('''' || empresa || '''', 'NULL') || ', ' ||
    COALESCE('''' || puesto || '''', 'NULL') || ', ' ||
    '''' || creado_en::text || ''', ' ||
    '''' || actualizado_en::text || ''');'
FROM public.t_computo_usuario_final
ORDER BY id_usuario_final;
```

3. Copia los resultados y guárdalos en un archivo `.sql`

## Opción 5: Backup rápido solo de la tabla (Recomendado para este caso)

Ejecuta este script SQL en el SQL Editor de Supabase:

```sql
-- Crear tabla de backup
CREATE TABLE IF NOT EXISTS public.t_computo_usuario_final_backup_20250114 AS
SELECT * FROM public.t_computo_usuario_final;

-- Verificar que se creó correctamente
SELECT COUNT(*) as total_backup 
FROM public.t_computo_usuario_final_backup_20250114;
```

Luego, si necesitas restaurar:
```sql
-- Restaurar desde el backup (CUIDADO: esto sobrescribe los datos actuales)
TRUNCATE TABLE public.t_computo_usuario_final;
INSERT INTO public.t_computo_usuario_final 
SELECT * FROM public.t_computo_usuario_final_backup_20250114;
```

## Recomendación para tu caso específico

**Para el script de corrección de rotación, te recomiendo la Opción 5** (crear una tabla de backup):

1. Es rápido y fácil
2. No requiere herramientas externas
3. Puedes verificar los datos antes y después
4. Puedes restaurar fácilmente si algo sale mal

Ejecuta esto ANTES de correr el script de corrección:

```sql
-- Backup antes de la corrección
CREATE TABLE IF NOT EXISTS public.t_computo_usuario_final_backup_pre_rotacion AS
SELECT * FROM public.t_computo_usuario_final;

-- Verificar
SELECT COUNT(*) as total_registros_backup 
FROM public.t_computo_usuario_final_backup_pre_rotacion;
```

