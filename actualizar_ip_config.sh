#!/bin/bash

# Script para actualizar automáticamente la IP local en la configuración

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Función para obtener IP local
get_local_ip() {
    if command -v hostname &> /dev/null; then
        local ip=$(hostname -I 2>/dev/null | awk '{print $1}')
        if [ ! -z "$ip" ]; then
            echo "$ip"
            return
        fi
    fi
    if command -v ip &> /dev/null; then
        local ip=$(ip addr show | grep -E 'inet.*scope global' | awk '{print $2}' | cut -d'/' -f1 | head -n1)
        if [ ! -z "$ip" ]; then
            echo "$ip"
            return
        fi
    fi
    echo "localhost"
}

NEW_IP=$(get_local_ip)
CONFIG_FILE="lib/app/config/dhl_proxy_config.dart"

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}❌ No se encontró el archivo de configuración: $CONFIG_FILE${NC}"
    exit 1
fi

echo -e "${BLUE}🔄 Actualizando IP local en configuración...${NC}"
echo -e "${YELLOW}   Nueva IP: $NEW_IP${NC}"

# Actualizar IP en el archivo de configuración
sed -i "s|http://[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+:3000|http://$NEW_IP:3000|g" "$CONFIG_FILE"
sed -i "s|http://[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+:8000|http://$NEW_IP:8000|g" "$CONFIG_FILE"

echo -e "${GREEN}✅ Configuración actualizada${NC}"
echo ""
echo -e "${YELLOW}💡 Recuerda recompilar la aplicación si es necesario:${NC}"
echo -e "   flutter build web --release"
























