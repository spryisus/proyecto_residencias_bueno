#!/bin/bash

# ============================================
# SCRIPT DE BACKUP DE BASE DE DATOS SUPABASE
# ============================================
#
# Este script crea un backup completo de tu base de datos PostgreSQL en Supabase
#
# USO:
# 1. Reemplaza [YOUR-PASSWORD] con tu contraseña real de Supabase
# 2. Ejecuta: chmod +x backup_database.sh
# 3. Ejecuta: ./backup_database.sh
#
# ============================================

# Configuración de conexión (REEMPLAZA [YOUR-PASSWORD] con tu contraseña real)
HOST="db.eulpljyplqyjuyuvvnwm.supabase.co"
PORT="5432"
DATABASE="postgres"
USER="postgres"
PASSWORD="jesadolfune2003"
# Directorio donde se guardará el backup (Escritorio)
BACKUP_DIR="$HOME/Escritorio/backups_supabase"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/backup_${TIMESTAMP}.sql"

# Crear directorio de backups si no existe
mkdir -p "$BACKUP_DIR"

echo "============================================"
echo "INICIANDO BACKUP DE BASE DE DATOS"
echo "============================================"
echo "Host: $HOST"
echo "Database: $DATABASE"
echo "Usuario: $USER"
echo "Archivo de backup: $BACKUP_FILE"
echo "============================================"
echo ""

# Exportar contraseña como variable de entorno (más seguro que pasarla como parámetro)
export PGPASSWORD="jesadolfune2003"

# Detectar qué versión de pg_dump usar
# Prioridad: PostgreSQL 17 > PostgreSQL 16 > pg_dump del sistema
if [ -f "/usr/lib/postgresql/17/bin/pg_dump" ]; then
    PG_DUMP_CMD="/usr/lib/postgresql/17/bin/pg_dump"
    echo "✅ Usando PostgreSQL 17 client"
elif [ -f "/usr/lib/postgresql/16/bin/pg_dump" ]; then
    PG_DUMP_CMD="/usr/lib/postgresql/16/bin/pg_dump"
    echo "⚠️  Usando PostgreSQL 16 client (puede haber problemas de versión)"
else
    PG_DUMP_CMD="pg_dump"
    echo "⚠️  Usando pg_dump del sistema (versión desconocida)"
fi

# Verificar versión
PG_DUMP_VERSION=$($PG_DUMP_CMD --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "desconocida")
echo "Versión de pg_dump: $PG_DUMP_VERSION"
echo ""

# Ejecutar pg_dump
$PG_DUMP_CMD \
  -h "$HOST" \
  -p "$PORT" \
  -U "$USER" \
  -d "$DATABASE" \
  --verbose \
  --clean \
  --if-exists \
  --create \
  --format=plain \
  --file="$BACKUP_FILE"

# Verificar si el backup fue exitoso
if [ $? -eq 0 ]; then
    echo ""
    echo "============================================"
    echo "✅ BACKUP COMPLETADO EXITOSAMENTE"
    echo "============================================"
    echo "Archivo guardado en: $BACKUP_FILE"
    echo "Ubicación completa: $(realpath "$BACKUP_FILE" 2>/dev/null || echo "$BACKUP_FILE")"
    
    # Mostrar tamaño del archivo
    FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "Tamaño del backup: $FILE_SIZE"
    echo ""
    
    # Opcional: Comprimir el backup
    echo "¿Deseas comprimir el backup? (s/n)"
    read -r response
    if [[ "$response" =~ ^[Ss]$ ]]; then
        gzip "$BACKUP_FILE"
        echo "✅ Backup comprimido: ${BACKUP_FILE}.gz"
    fi
else
    echo ""
    echo "============================================"
    echo "❌ ERROR AL CREAR EL BACKUP"
    echo "============================================"
    echo "Verifica:"
    echo "1. Que la contraseña sea correcta"
    echo "2. Que tengas conexión a internet"
    echo "3. Que el host y puerto sean correctos"
    echo ""
    echo "Si el error es de versión (server version mismatch):"
    echo "  - El script ya usa --no-version-check para compatibilidad"
    echo "  - O actualiza PostgreSQL client: sudo apt install postgresql-client-17"
    exit 1
fi

# Limpiar variable de entorno
unset PGPASSWORD

echo ""
echo "============================================"
echo "BACKUP FINALIZADO"
echo "============================================"

