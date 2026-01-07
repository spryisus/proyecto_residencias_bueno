#!/bin/bash

# ============================================
# SCRIPT DE RESTAURACIÓN DE BASE DE DATOS SUPABASE
# ============================================
#
# Este script restaura un backup de tu base de datos PostgreSQL en Supabase
#
# USO:
# 1. Reemplaza [YOUR-PASSWORD] con tu contraseña real de Supabase
# 2. Ejecuta: chmod +x restore_database.sh
# 3. Ejecuta: ./restore_database.sh [ruta_al_backup.sql]
#
# Ejemplo:
#   ./restore_database.sh backups/backup_20260107_111054.sql
#
# ============================================

# Configuración de conexión (REEMPLAZA [YOUR-PASSWORD] con tu contraseña real)
HOST="db.eulpljyplqyjuyuvvnwm.supabase.co"
PORT="5432"
DATABASE="postgres"
USER="postgres"
PASSWORD="jesadolfune2003"

# Verificar que se proporcionó el archivo de backup
if [ -z "$1" ]; then
    echo "============================================"
    echo "❌ ERROR: No se especificó archivo de backup"
    echo "============================================"
    echo ""
    echo "Uso: $0 [ruta_al_backup.sql]"
    echo ""
    echo "Ejemplo:"
    echo "  $0 ~/Escritorio/backups_supabase/backup_20260107_111054.sql"
    echo ""
    echo "Backups disponibles en el escritorio:"
    BACKUP_DIR_DEFAULT="$HOME/Escritorio/backups_supabase"
    if [ -d "$BACKUP_DIR_DEFAULT" ]; then
        ls -lh "$BACKUP_DIR_DEFAULT"/*.sql 2>/dev/null | tail -5
    else
        echo "  No se encontró el directorio '$BACKUP_DIR_DEFAULT'"
    fi
    exit 1
fi

BACKUP_FILE="$1"

# Verificar que el archivo existe
if [ ! -f "$BACKUP_FILE" ]; then
    echo "============================================"
    echo "❌ ERROR: Archivo no encontrado"
    echo "============================================"
    echo "Archivo: $BACKUP_FILE"
    echo ""
    echo "Verifica la ruta del archivo"
    exit 1
fi

# Verificar tamaño del archivo
FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
echo "============================================"
echo "RESTAURANDO BASE DE DATOS"
echo "============================================"
echo "Host: $HOST"
echo "Database: $DATABASE"
echo "Usuario: $USER"
echo "Archivo de backup: $BACKUP_FILE"
echo "Tamaño: $FILE_SIZE"
echo "============================================"
echo ""
echo "⚠️  ADVERTENCIA: Esta operación SOBRESCRIBIRÁ la base de datos actual"
echo "⚠️  Todos los datos actuales serán ELIMINADOS y reemplazados por el backup"
echo ""
read -p "¿Estás seguro de que deseas continuar? (escribe 'SI' para confirmar): " confirmacion

if [ "$confirmacion" != "SI" ]; then
    echo ""
    echo "❌ Restauración cancelada"
    exit 0
fi

echo ""
echo "Iniciando restauración..."
echo ""

# Detectar qué versión de psql usar
if [ -f "/usr/lib/postgresql/17/bin/psql" ]; then
    PSQL_CMD="/usr/lib/postgresql/17/bin/psql"
    echo "✅ Usando PostgreSQL 17 client"
elif [ -f "/usr/lib/postgresql/16/bin/psql" ]; then
    PSQL_CMD="/usr/lib/postgresql/16/bin/psql"
    echo "⚠️  Usando PostgreSQL 16 client"
else
    PSQL_CMD="psql"
    echo "⚠️  Usando psql del sistema"
fi

# Exportar contraseña
export PGPASSWORD="$PASSWORD"

# Ejecutar restauración
$PSQL_CMD \
  -h "$HOST" \
  -p "$PORT" \
  -U "$USER" \
  -d "$DATABASE" \
  -f "$BACKUP_FILE"

# Verificar si la restauración fue exitosa
if [ $? -eq 0 ]; then
    echo ""
    echo "============================================"
    echo "✅ RESTAURACIÓN COMPLETADA EXITOSAMENTE"
    echo "============================================"
    echo "La base de datos ha sido restaurada desde: $BACKUP_FILE"
    echo ""
    echo "Verifica que los datos se restauraron correctamente en Supabase Dashboard"
else
    echo ""
    echo "============================================"
    echo "❌ ERROR AL RESTAURAR"
    echo "============================================"
    echo "Verifica:"
    echo "1. Que la contraseña sea correcta"
    echo "2. Que tengas conexión a internet"
    echo "3. Que el archivo de backup esté completo"
    echo "4. Que no haya errores en el archivo SQL"
    exit 1
fi

# Limpiar variable de entorno
unset PGPASSWORD

echo ""
echo "============================================"
echo "✅ BASE DE DATOS RESTAURADA EXITOSAMENTE"
echo "============================================"
echo ""
echo "La restauración se completó sin errores."
echo "Tu base de datos ha sido restaurada desde el backup."
echo ""
echo "============================================"

