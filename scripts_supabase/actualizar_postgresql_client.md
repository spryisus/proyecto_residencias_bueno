# 🔧 Actualizar PostgreSQL Client para Backup

## Problema Detectado

Tu servidor Supabase usa **PostgreSQL 17.6**, pero tu cliente local tiene **pg_dump 16.11**.

Error:
```
pg_dump: error: aborting because of server version mismatch
pg_dump: detail: server version: 17.6; pg_dump version: 16.11
```

## ✅ Solución 1: Usar --no-version-check (Ya implementado)

El script ya incluye `--no-version-check` que permite hacer backup de servidores más nuevos. Esto debería funcionar.

## ✅ Solución 2: Actualizar PostgreSQL Client (Recomendado)

### Para Ubuntu/Debian:

```bash
# Agregar repositorio oficial de PostgreSQL
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Agregar clave GPG
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# Actualizar repositorios
sudo apt update

# Instalar PostgreSQL 17 client
sudo apt install postgresql-client-17

# Verificar versión
pg_dump --version
# Debería mostrar: pg_dump (PostgreSQL) 17.x
```

### Alternativa: Instalar desde snap

```bash
sudo snap install postgresql17
```

### Verificar instalación

```bash
# Ver qué versión de pg_dump se está usando
which pg_dump
pg_dump --version

# Si tienes múltiples versiones, puedes especificar la ruta completa
/usr/lib/postgresql/17/bin/pg_dump --version
```

## ✅ Solución 3: Usar Docker (Si no quieres modificar sistema)

```bash
# Crear script de backup con Docker
docker run --rm \
  -e PGPASSWORD="tu_contraseña" \
  postgres:17 \
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
  > backup_$(date +%Y%m%d_%H%M%S).sql
```

## 🔍 Verificar el Problema

```bash
# Ver versión actual
pg_dump --version

# Ver versión del servidor (conectarse y verificar)
psql -h db.eulpljyplqyjuyuvvnwm.supabase.co -p 5432 -U postgres -d postgres -c "SELECT version();"
```

## 📝 Nota

El script `backup_database.sh` ya incluye `--no-version-check` que debería resolver el problema sin necesidad de actualizar. Si aún tienes problemas, actualiza el cliente como se indica arriba.





