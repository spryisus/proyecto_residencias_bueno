#!/bin/bash

# Script para verificar que todos los servicios estén corriendo correctamente

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

LOCAL_IP=$(get_local_ip)

# Puertos
PORT_WEB=8080
PORT_FASTAPI=8000
PORT_EXCEL=8001
PORT_DHL=3000

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  🔍 Verificación de Servicios${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Función para verificar puerto
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        return 0
    else
        return 1
    fi
}

# Función para verificar HTTP
check_http() {
    local url=$1
    if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "$url" | grep -q "200\|404\|405"; then
        return 0
    else
        return 1
    fi
}

ALL_OK=true

# Verificar puertos
echo -e "${CYAN}📡 Verificando puertos...${NC}"
for port in $PORT_WEB $PORT_FASTAPI $PORT_EXCEL $PORT_DHL; do
    if check_port $port; then
        echo -e "${GREEN}✅ Puerto $port: Activo${NC}"
    else
        echo -e "${RED}❌ Puerto $port: No responde${NC}"
        ALL_OK=false
    fi
done
echo ""

# Verificar servicios HTTP
echo -e "${CYAN}🌐 Verificando servicios HTTP...${NC}"

# Web
if check_http "http://localhost:$PORT_WEB"; then
    echo -e "${GREEN}✅ Web (puerto $PORT_WEB): Respondiendo${NC}"
else
    echo -e "${RED}❌ Web (puerto $PORT_WEB): No responde${NC}"
    ALL_OK=false
fi

# FastAPI
if check_http "http://localhost:$PORT_FASTAPI/health" || check_http "http://localhost:$PORT_FASTAPI/"; then
    echo -e "${GREEN}✅ FastAPI (puerto $PORT_FASTAPI): Respondiendo${NC}"
else
    echo -e "${RED}❌ FastAPI (puerto $PORT_FASTAPI): No responde${NC}"
    ALL_OK=false
fi

# Excel Service
if check_http "http://localhost:$PORT_EXCEL/health" || check_http "http://localhost:$PORT_EXCEL/"; then
    echo -e "${GREEN}✅ Excel Service (puerto $PORT_EXCEL): Respondiendo${NC}"
else
    echo -e "${RED}❌ Excel Service (puerto $PORT_EXCEL): No responde${NC}"
    ALL_OK=false
fi

# DHL Proxy
if check_http "http://localhost:$PORT_DHL/health" || check_http "http://localhost:$PORT_DHL/"; then
    echo -e "${GREEN}✅ DHL Proxy (puerto $PORT_DHL): Respondiendo${NC}"
else
    echo -e "${RED}❌ DHL Proxy (puerto $PORT_DHL): No responde${NC}"
    ALL_OK=false
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
if [ "$ALL_OK" = true ]; then
    echo -e "${GREEN}  ✅ Todos los servicios están funcionando correctamente${NC}"
    echo ""
    echo -e "${CYAN}📱 URLs de acceso:${NC}"
    echo -e "${GREEN}   Aplicación Web: http://$LOCAL_IP:$PORT_WEB${NC}"
    echo -e "${GREEN}   FastAPI:        http://$LOCAL_IP:$PORT_FASTAPI${NC}"
    echo -e "${GREEN}   Excel Service:  http://$LOCAL_IP:$PORT_EXCEL${NC}"
    echo -e "${GREEN}   DHL Proxy:      http://$LOCAL_IP:$PORT_DHL${NC}"
else
    echo -e "${RED}  ❌ Algunos servicios no están funcionando${NC}"
    echo ""
    echo -e "${YELLOW}💡 Ejecuta: ./iniciar_servidor_red_local.sh${NC}"
fi
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"




















