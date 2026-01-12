# 🔄 Guía de Restauración de Backup

## ⚠️ IMPORTANTE

Si se pierde tu base de datos, necesitas **RESTAURAR** el backup, no ejecutar el script de backup de nuevo.

---

## 📋 Opciones para Restaurar

### ✅ Opción 1: Desde PostgreSQL Client Local (RECOMENDADO)

**Ventajas:**
- ✅ Funciona con backups de cualquier tamaño
- ✅ Más rápido y confiable
- ✅ Mejor manejo de errores

**Pasos:**

1. **Asegúrate de tener el archivo de backup:**
   ```bash
   ls -lh backups/backup_*.sql
   ```

2. **Usa el script de restauración:**
   ```bash
   cd scripts_supabase
   ./restore_database.sh backups/backup_20260107_111054.sql
   ```

3. **O manualmente con psql:**
   ```bash
   export PGPASSWORD="tu_contraseña"
   
   psql \
     -h db.eulpljyplqyjuyuvvnwm.supabase.co \
     -p 5432 \
     -U postgres \
     -d postgres \
     -f backups/backup_20260107_111054.sql
   
   unset PGPASSWORD
   ```

---

### ⚠️ Opción 2: Desde Supabase SQL Editor (Solo para scripts pequeños)

**Limitaciones:**
- ❌ Máximo ~1-2 MB de SQL
- ❌ Puede fallar con backups grandes
- ❌ Timeout en operaciones largas

**Pasos:**

1. Ve a **Supabase Dashboard** → **SQL Editor**
2. Abre tu archivo de backup (`.sql`)
3. Copia el contenido (o una parte si es muy grande)
4. Pégalo en el editor SQL
5. Haz clic en **"Run"**

**Nota:** Si el backup es grande, divídelo en partes más pequeñas o usa la Opción 1.

---

### 🔧 Opción 3: Restaurar solo tablas específicas

Si solo necesitas restaurar algunas tablas:

```bash
# Extraer solo las tablas que necesitas del backup
grep -A 1000 "CREATE TABLE public.t_bitacora_envios" backups/backup_*.sql > restore_bitacora.sql

# Restaurar solo esa tabla
export PGPASSWORD="tu_contraseña"
psql \
  -h db.eulpljyplqyjuyuvvnwm.supabase.co \
  -p 5432 \
  -U postgres \
  -d postgres \
  -f restore_bitacora.sql
unset PGPASSWORD
```

---

## 🆘 Si NO tienes PostgreSQL Client instalado

### Instalar PostgreSQL Client:

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install postgresql-client-17

# O usar Docker (sin instalar nada)
docker run --rm \
  -v $(pwd)/backups:/backups \
  -e PGPASSWORD="tu_contraseña" \
  postgres:17 \
  psql \
  -h db.eulpljyplqyjuyuvvnwm.supabase.co \
  -p 5432 \
  -U postgres \
  -d postgres \
  -f /backups/backup_20260107_111054.sql
```

---

## 📝 Verificar Restauración

Después de restaurar, verifica en Supabase:

1. **Dashboard** → **Table Editor**
2. Revisa que las tablas tengan datos
3. Ejecuta algunas consultas de prueba:

```sql
-- Verificar bitácoras
SELECT COUNT(*) FROM t_bitacora_envios;

-- Verificar inventarios
SELECT COUNT(*) FROM t_productos;

-- Verificar empleados
SELECT COUNT(*) FROM t_empleados;
```

---

## ⚠️ Advertencias Importantes

1. **La restauración SOBRESCRIBE** todos los datos actuales
2. **Haz backup ANTES** de restaurar si hay datos nuevos que quieres conservar
3. **Verifica el archivo de backup** antes de restaurar (debe tener tamaño > 0)
4. **No interrumpas** el proceso de restauración

---

## 🔄 Flujo Completo de Backup y Restauración

### 1. Crear Backup (cuando todo está bien):
```bash
cd scripts_supabase
./backup_database.sh
```

### 2. Si se pierde la base de datos:
```bash
cd scripts_supabase
./restore_database.sh backups/backup_20260107_111054.sql
```

### 3. Verificar que todo esté bien:
- Revisar en Supabase Dashboard
- Probar la aplicación Flutter

---

## 💡 Tips

- **Backups regulares:** Programa backups automáticos (cron)
- **Múltiples backups:** Guarda varios backups en diferentes fechas
- **Backups comprimidos:** Usa `gzip` para ahorrar espacio
- **Verificar backups:** Prueba restaurar un backup de prueba ocasionalmente





