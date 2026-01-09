#!/bin/bash

# ============================================
# Script para iniciar el sistema completo en modo red local
# Permite acceso desde otras computadoras en la misma red
# ============================================

set -e  # Salir si hay algún error

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Directorio del proyecto
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$PROJECT_DIR"

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  🚀 Sistema Telmex - Inicio en Modo Red Local${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Función para obtener IP local
get_local_ip() {
    # Intentar obtener IP en Linux
    if command -v hostname &> /dev/null; then
        local ip=$(hostname -I 2>/dev/null | awk '{print $1}')
        if [ ! -z "$ip" ]; then
            echo "$ip"
            return
        fi
    fi
    
    # Método 2: ip addr (Linux moderno)
    if command -v ip &> /dev/null; then
        local ip=$(ip addr show | grep -E 'inet.*scope global' | awk '{print $2}' | cut -d'/' -f1 | head -n1)
        if [ ! -z "$ip" ]; then
            echo "$ip"
            return
        fi
    fi
    
    # Método 3: ifconfig (Linux/Mac)
    if command -v ifconfig &> /dev/null; then
        local ip=$(ifconfig | grep -E 'inet.*broadcast' | awk '{print $2}' | head -n1)
        if [ ! -z "$ip" ]; then
            echo "$ip"
            return
        fi
    fi
    
    # Si no se encuentra, usar localhost
    echo "localhost"
}

LOCAL_IP=$(get_local_ip)

echo -e "${CYAN}📡 IP Local detectada: ${GREEN}$LOCAL_IP${NC}"
echo ""

# Puertos que se usarán
PORT_WEB=8080
PORT_FASTAPI=8000
PORT_EXCEL=8001
PORT_DHL=3000

# Función para verificar si un puerto está en uso
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        return 0  # Puerto en uso
    else
        return 1  # Puerto libre
    fi
}

# Función para matar procesos en un puerto
kill_port() {
    local port=$1
    local pids=$(lsof -ti:$port 2>/dev/null)
    if [ ! -z "$pids" ]; then
        echo -e "${YELLOW}⚠️  Deteniendo procesos en puerto $port...${NC}"
        kill -9 $pids 2>/dev/null || true
        sleep 1
    fi
}

# Verificar y liberar puertos
echo -e "${BLUE}🔍 Verificando puertos...${NC}"
for port in $PORT_WEB $PORT_FASTAPI $PORT_EXCEL $PORT_DHL; do
    if check_port $port; then
        echo -e "${YELLOW}⚠️  Puerto $port está en uso${NC}"
        read -p "¿Deseas detener los procesos en el puerto $port? (s/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[SsYy]$ ]]; then
            kill_port $port
        else
            echo -e "${RED}❌ No se puede continuar. Por favor, libera el puerto $port manualmente.${NC}"
            exit 1
        fi
    fi
done
echo -e "${GREEN}✅ Todos los puertos están disponibles${NC}"
echo ""

# Configurar firewall
echo -e "${BLUE}🔥 Configurando firewall...${NC}"
if command -v ufw &> /dev/null; then
    echo -e "${CYAN}   Usando UFW${NC}"
    for port in $PORT_WEB $PORT_FASTAPI $PORT_EXCEL $PORT_DHL; do
        sudo ufw allow $port/tcp 2>/dev/null || true
    done
    echo -e "${GREEN}✅ Reglas de firewall configuradas${NC}"
elif command -v firewall-cmd &> /dev/null; then
    echo -e "${CYAN}   Usando firewalld${NC}"
    for port in $PORT_WEB $PORT_FASTAPI $PORT_EXCEL $PORT_DHL; do
        sudo firewall-cmd --permanent --add-port=$port/tcp 2>/dev/null || true
    done
    sudo firewall-cmd --reload 2>/dev/null || true
    echo -e "${GREEN}✅ Reglas de firewall configuradas${NC}"
else
    echo -e "${YELLOW}⚠️  No se encontró UFW ni firewalld. Asegúrate de configurar el firewall manualmente.${NC}"
fi
echo ""

# Función para limpiar procesos al salir
cleanup() {
    echo ""
    echo -e "${YELLOW}🛑 Deteniendo servicios...${NC}"
    kill_port $PORT_WEB
    kill_port $PORT_FASTAPI
    kill_port $PORT_EXCEL
    kill_port $PORT_DHL
    echo -e "${GREEN}✅ Servicios detenidos${NC}"
    exit 0
}

# Capturar Ctrl+C
trap cleanup SIGINT SIGTERM

# Iniciar servicios en background
echo -e "${BLUE}🚀 Iniciando servicios backend...${NC}"
echo ""

# 1. Servicio FastAPI (Tracking)
echo -e "${CYAN}📡 Iniciando FastAPI Tracking Service (puerto $PORT_FASTAPI)...${NC}"
cd "$PROJECT_DIR/fastapi_tracking_service"
if [ ! -d "venv" ]; then
    python3 -m venv venv
    source venv/bin/activate
    pip install -q -r requirements.txt
else
    source venv/bin/activate
fi
PORT=$PORT_FASTAPI uvicorn main:app --host 0.0.0.0 --port $PORT_FASTAPI > /tmp/fastapi_service.log 2>&1 &
FASTAPI_PID=$!
echo -e "${GREEN}✅ FastAPI iniciado (PID: $FASTAPI_PID)${NC}"
sleep 2

# 2. Servicio Excel Generator
echo -e "${CYAN}📊 Iniciando Excel Generator Service (puerto $PORT_EXCEL)...${NC}"
cd "$PROJECT_DIR/excel_generator_service"
if [ ! -d "venv" ]; then
    python3 -m venv venv
    source venv/bin/activate
    pip install -q -r requirements.txt
else
    source venv/bin/activate
fi
uvicorn main:app --host 0.0.0.0 --port $PORT_EXCEL > /tmp/excel_service.log 2>&1 &
EXCEL_PID=$!
echo -e "${GREEN}✅ Excel Service iniciado (PID: $EXCEL_PID)${NC}"
sleep 2

# 3. Proxy DHL
echo -e "${CYAN}📦 Iniciando DHL Proxy (puerto $PORT_DHL)...${NC}"
cd "$PROJECT_DIR/dhl_tracking_proxy"
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}   Instalando dependencias de Node.js...${NC}"
    npm install --silent
fi
PORT=$PORT_DHL node server.js > /tmp/dhl_proxy.log 2>&1 &
DHL_PID=$!
echo -e "${GREEN}✅ DHL Proxy iniciado (PID: $DHL_PID)${NC}"
sleep 3

# 4. Compilar y servir aplicación Flutter Web
echo ""
echo -e "${BLUE}🌐 Compilando aplicación Flutter para web...${NC}"
cd "$PROJECT_DIR"

# Obtener dependencias
echo -e "${CYAN}📦 Obteniendo dependencias Flutter...${NC}"
flutter pub get > /dev/null 2>&1

# Compilar para web
echo -e "${CYAN}🔨 Compilando para web...${NC}"
flutter build web --release > /tmp/flutter_build.log 2>&1

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Error al compilar la aplicación Flutter${NC}"
    echo -e "${YELLOW}   Revisa el log: /tmp/flutter_build.log${NC}"
    cleanup
    exit 1
fi

echo -e "${GREEN}✅ Compilación completada${NC}"
echo ""

# Servir aplicación web
echo -e "${CYAN}🌐 Iniciando servidor web (puerto $PORT_WEB)...${NC}"
cd "$PROJECT_DIR/build/web"

# Verificar qué servidor HTTP está disponible
if command -v python3 &> /dev/null; then
    python3 -m http.server $PORT_WEB --bind 0.0.0.0 > /tmp/web_server.log 2>&1 &
    WEB_PID=$!
elif command -v python &> /dev/null; then
    python -m SimpleHTTPServer $PORT_WEB > /tmp/web_server.log 2>&1 &
    WEB_PID=$!
elif command -v php &> /dev/null; then
    php -S 0.0.0.0:$PORT_WEB > /tmp/web_server.log 2>&1 &
    WEB_PID=$!
elif command -v npx &> /dev/null; then
    npx serve -l $PORT_WEB --host 0.0.0.0 > /tmp/web_server.log 2>&1 &
    WEB_PID=$!
else
    echo -e "${RED}❌ No se encontró ningún servidor HTTP disponible${NC}"
    cleanup
    exit 1
fi

echo -e "${GREEN}✅ Servidor web iniciado (PID: $WEB_PID)${NC}"
sleep 2

# Verificar que todos los servicios estén corriendo
echo ""
echo -e "${BLUE}🔍 Verificando servicios...${NC}"
ALL_OK=true

for port in $PORT_WEB $PORT_FASTAPI $PORT_EXCEL $PORT_DHL; do
    if check_port $port; then
        echo -e "${GREEN}✅ Puerto $port: Activo${NC}"
    else
        echo -e "${RED}❌ Puerto $port: No responde${NC}"
        ALL_OK=false
    fi
done

if [ "$ALL_OK" = false ]; then
    echo -e "${RED}❌ Algunos servicios no están respondiendo correctamente${NC}"
    echo -e "${YELLOW}   Revisa los logs en /tmp/${NC}"
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Sistema iniciado correctamente${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}📱 Aplicación Web Flutter:${NC}"
echo -e "${GREEN}   🖥️  Local:     http://localhost:$PORT_WEB${NC}"
echo -e "${GREEN}   🌐 Red local: http://$LOCAL_IP:$PORT_WEB${NC}"
echo ""
echo -e "${CYAN}🔧 Servicios Backend:${NC}"
echo -e "${GREEN}   📡 FastAPI:   http://$LOCAL_IP:$PORT_FASTAPI${NC}"
echo -e "${GREEN}   📊 Excel:     http://$LOCAL_IP:$PORT_EXCEL${NC}"
echo -e "${GREEN}   📦 DHL Proxy: http://$LOCAL_IP:$PORT_DHL${NC}"
echo ""
echo -e "${YELLOW}💡 Para acceder desde otra computadora en la misma red:${NC}"
echo -e "${YELLOW}   Abre el navegador y ve a: ${GREEN}http://$LOCAL_IP:$PORT_WEB${NC}"
echo ""
echo -e "${CYAN}📋 Logs de servicios:${NC}"
echo -e "   FastAPI:   /tmp/fastapi_service.log"
echo -e "   Excel:     /tmp/excel_service.log"
echo -e "   DHL Proxy: /tmp/dhl_proxy.log"
echo -e "   Web:       /tmp/web_server.log"
echo ""
echo -e "${YELLOW}⚠️  Presiona Ctrl+C para detener todos los servicios${NC}"
echo ""

# Esperar indefinidamente
wait




















