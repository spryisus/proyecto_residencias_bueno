#!/bin/bash

# Script para iniciar el servidor de generación de Excel
# Este script activa el entorno virtual y ejecuta el servidor con uvicorn

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Excel Generator Service${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Obtener el directorio del script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Verificar si existe el entorno virtual y está completo
if [ ! -d "venv" ] || [ ! -f "venv/bin/activate" ]; then
    if [ -d "venv" ]; then
        echo -e "${YELLOW}⚠️  Entorno virtual incompleto. Eliminando y recreando...${NC}"
        rm -rf venv
    else
        echo -e "${YELLOW}⚠️  Entorno virtual no encontrado. Creando uno nuevo...${NC}"
    fi
    
    if ! python3 -m venv venv; then
        echo -e "${RED}❌ Error al crear el entorno virtual${NC}"
        echo -e "${YELLOW}💡 Asegúrate de tener python3-venv instalado:${NC}"
        echo -e "${YELLOW}   sudo apt install python3-venv python3-full  # Ubuntu/Debian${NC}"
        exit 1
    fi
    
    # Verificar que se creó correctamente
    if [ ! -f "venv/bin/activate" ]; then
        echo -e "${RED}❌ Error: El entorno virtual no se creó correctamente${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Entorno virtual creado correctamente${NC}"
fi

# Activar el entorno virtual
echo -e "${BLUE}📦 Activando entorno virtual...${NC}"
source venv/bin/activate

# Verificar que el entorno virtual está activado
if [ -z "$VIRTUAL_ENV" ]; then
    echo -e "${RED}❌ Error: No se pudo activar el entorno virtual${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Entorno virtual activado: $VIRTUAL_ENV${NC}"

# Actualizar pip primero
echo -e "${BLUE}📦 Actualizando pip...${NC}"
python -m pip install --upgrade pip --quiet

# Instalar dependencias si es necesario
if [ ! -f "venv/.dependencies_installed" ]; then
    echo -e "${BLUE}📥 Instalando dependencias...${NC}"
    if ! pip install -r requirements.txt; then
        echo -e "${RED}❌ Error al instalar dependencias${NC}"
        exit 1
    fi
    touch venv/.dependencies_installed
    echo -e "${GREEN}✅ Dependencias instaladas${NC}"
else
    echo -e "${GREEN}✅ Dependencias ya instaladas${NC}"
fi

echo ""
echo -e "${GREEN}🚀 Iniciando servidor en http://0.0.0.0:8001${NC}"
echo -e "${YELLOW}💡 Presiona Ctrl+C para detener el servidor${NC}"
echo -e "${BLUE}📡 El servidor está disponible en:${NC}"
echo -e "${BLUE}   - Local: http://localhost:8001${NC}"
echo -e "${BLUE}   - Red local: http://$(hostname -I | awk '{print $1}'):8001${NC}"
echo ""
echo -e "${GREEN}🔄 Hot Reload activado: El servidor se recargará automáticamente al detectar cambios${NC}"
echo -e "${YELLOW}📝 Archivos monitoreados: *.py en el directorio actual${NC}"
echo ""

# Iniciar el servidor con uvicorn usando el Python del entorno virtual
# --reload: Activa el hot reload automático
# --reload-dir: Especifica directorios adicionales a monitorear (opcional, por defecto monitorea el directorio actual)
# --reload-include: Incluye archivos específicos para monitorear
python -m uvicorn main:app \
    --host 0.0.0.0 \
    --port 8001 \
    --reload \
    --reload-dir . \
    --reload-include "*.py"

