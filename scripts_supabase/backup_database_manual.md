# 📦 Guía Manual de Backup de Base de Datos Supabase

## 🔐 Información de Conexión

Basado en tu configuración de Supabase:

- **Host:** `db.eulpljyplqyjuyuvvnwm.supabase.co`
- **Port:** `5432`
- **Database:** `postgres`
- **User:** `postgres`
- **Password:** [Obtener desde Supabase Dashboard → Settings → Database]

---

## 📋 Método 1: Backup usando pg_dump (Recomendado)

### Paso 1: Instalar PostgreSQL Client

**En Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install postgresql-client
```

**En macOS:**
```bash
brew install postgresql
```

**En Windows:**
Descargar desde: https://www.postgresql.org/download/windows/

### Paso 2: Obtener tu contraseña

1. Ve a tu proyecto en Supabase: https://supabase.com/dashboard
2. Selecciona tu proyecto
3. Ve a **Settings** → **Database**
4. En la sección "Database password", si no la tienes, haz clic en **"Reset database password"**
5. **Guarda la contraseña de forma segura**

### Paso 3: Ejecutar el backup

**Opción A: Usando el script automático**
```bash
# Editar el script y reemplazar [YOUR-PASSWORD]
nano scripts_supabase/backup_database.sh

# Dar permisos de ejecución
chmod +x scripts_supabase/backup_database.sh

# Ejecutar
./scripts_supabase/backup_database.sh
```

**Opción B: Comando manual**
```bash
# Reemplaza [YOUR-PASSWORD] con tu contraseña real
export PGPASSWORD="tu_contraseña_aqui"

pg_dump \
  -h db.eulpljyplqyjuyuvvnwm.supabase.co \
  -p 5432 \
  -U postgres \
  -d postgres \
  --verbose \
  --clean \
  --if-exists \
  --create \
  --format=plain \
  --file=backup_$(date +%Y%m%d_%H%M%S).sql

unset PGPASSWORD
```

**Opción C: Backup comprimido (más pequeño)**
```bash
export PGPASSWORD="tu_contraseña_aqui"

pg_dump \
  -h db.eulpljyplqyjuyuvvnwm.supabase.co \
  -p 5432 \
  -U postgres \
  -d postgres \
  --verbose \
  --clean \
  --if-exists \
  --create \
  --format=custom \
  --file=backup_$(date +%Y%m%d_%H%M%S).dump

unset PGPASSWORD
```

---

## 📋 Método 2: Backup desde Supabase Dashboard

1. Ve a tu proyecto en Supabase Dashboard
2. Ve a **Database** → **Backups**
3. Haz clic en **"Create backup"**
4. Espera a que se complete
5. Descarga el backup cuando esté listo

**Nota:** Este método puede tener limitaciones en el plan gratuito.

---

## 📋 Método 3: Backup usando psql (solo esquema)

Si solo quieres el esquema (estructura) sin los datos:

```bash
export PGPASSWORD="tu_contraseña_aqui"

pg_dump \
  -h db.eulpljyplqyjuyuvvnwm.supabase.co \
  -p 5432 \
  -U postgres \
  -d postgres \
  --schema-only \
  --file=esquema_backup_$(date +%Y%m%d_%H%M%S).sql

unset PGPASSWORD
```

---

## 🔄 Restaurar un Backup

### Restaurar desde archivo SQL:
```bash
export PGPASSWORD="tu_contraseña_aqui"

psql \
  -h db.eulpljyplqyjuyuvvnwm.supabase.co \
  -p 5432 \
  -U postgres \
  -d postgres \
  -f backup_20250115_120000.sql

unset PGPASSWORD
```

### Restaurar desde archivo comprimido (.dump):
```bash
export PGPASSWORD="tu_contraseña_aqui"

pg_restore \
  -h db.eulpljyplqyjuyuvvnwm.supabase.co \
  -p 5432 \
  -U postgres \
  -d postgres \
  --verbose \
  --clean \
  --if-exists \
  backup_20250115_120000.dump

unset PGPASSWORD
```

---

## ⚠️ Consideraciones de Seguridad

1. **Nunca compartas tu contraseña** de la base de datos
2. **No subas backups** a repositorios públicos de Git
3. **Guarda los backups** en un lugar seguro y encriptado
4. **Elimina backups antiguos** periódicamente
5. **Usa variables de entorno** para la contraseña en lugar de hardcodearla

### Usar archivo .pgpass (más seguro):

Crear archivo `~/.pgpass`:
```
db.eulpljyplqyjuyuvvnwm.supabase.co:5432:postgres:postgres:tu_contraseña_aqui
```

Dar permisos:
```bash
chmod 600 ~/.pgpass
```

Luego puedes ejecutar pg_dump sin exportar PGPASSWORD:
```bash
pg_dump -h db.eulpljyplqyjuyuvvnwm.supabase.co -p 5432 -U postgres -d postgres -f backup.sql
```

---

## 📊 Verificar el Backup

Para verificar que el backup se creó correctamente:

```bash
# Ver tamaño del archivo
ls -lh backup_*.sql

# Ver primeras líneas del backup
head -n 50 backup_*.sql

# Contar líneas (debe tener muchas)
wc -l backup_*.sql
```

---

## 🕐 Automatizar Backups

### Usar cron para backups automáticos diarios:

```bash
# Editar crontab
crontab -e

# Agregar esta línea para backup diario a las 2 AM
0 2 * * * /ruta/completa/a/backup_database.sh >> /var/log/backup.log 2>&1
```

---

## 📝 Notas Importantes

- **Tiempo de backup:** Depende del tamaño de tu base de datos (puede tardar varios minutos)
- **Espacio necesario:** El backup puede ser grande, asegúrate de tener espacio suficiente
- **Conexión:** Necesitas conexión estable a internet durante el backup
- **Plan gratuito:** Supabase puede tener límites de tiempo de conexión

---

## 🆘 Solución de Problemas

### Error: "password authentication failed"
- Verifica que la contraseña sea correcta
- Asegúrate de no tener espacios extra al copiar/pegar

### Error: "could not connect to server"
- Verifica tu conexión a internet
- Verifica que el host y puerto sean correctos
- Verifica que Supabase no esté en modo pausado

### Error: "permission denied"
- Verifica que tengas permisos de escritura en el directorio de destino
- Usa `sudo` si es necesario (aunque no es recomendado)

### El backup es muy lento
- Usa formato `custom` en lugar de `plain` (más rápido)
- Comprime el backup después con `gzip`


