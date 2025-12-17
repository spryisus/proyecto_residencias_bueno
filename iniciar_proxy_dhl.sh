#!/bin/bash

# Script para iniciar el servidor proxy DHL
# Uso: ./iniciar_proxy_dhl.sh

echo "🚀 Iniciando servidor proxy DHL..."
echo ""

# Cambiar al directorio del proxy
cd "$(dirname "$0")/dhl_tracking_proxy"

# Verificar si Node.js está instalado
if ! command -v node &> /dev/null; then
    echo "❌ Error: Node.js no está instalado"
    echo "Por favor instala Node.js desde: https://nodejs.org/"
    exit 1
fi

echo "✅ Node.js $(node --version)"
echo ""

# Obtener la IP local
LOCAL_IP=$(hostname -I | awk '{print $1}')
echo "📡 Tu IP local es: $LOCAL_IP"
echo ""

# Verificar si node_modules existe
if [ ! -d "node_modules" ]; then
    echo "📦 Instalando dependencias..."
    npm install
    echo ""
fi

# Verificar si el puerto está en uso
if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo "⚠️  El puerto 3000 ya está en uso"
    echo "   ¿Quieres detener el servidor anterior? (s/n)"
    read -r respuesta
    if [ "$respuesta" = "s" ] || [ "$respuesta" = "S" ]; then
        echo "   Deteniendo servidor anterior..."
        pkill -f "node.*server.js"
        sleep 2
    else
        echo "   Usando el servidor que ya está corriendo..."
        echo ""
        echo "✅ Servidor accesible en: http://$LOCAL_IP:3000"
        echo "📡 Endpoint: http://$LOCAL_IP:3000/api/track/:trackingNumber"
        exit 0
    fi
fi

# Iniciar el servidor
echo "🚀 Iniciando servidor proxy DHL..."
echo "📡 El servidor estará disponible en: http://localhost:3000"
echo "📡 Accesible desde tu red local en: http://$LOCAL_IP:3000"
echo "📡 Endpoint: http://$LOCAL_IP:3000/api/track/:trackingNumber"
echo ""
echo "💡 Para dispositivos móviles en la misma red WiFi, usa:"
echo "   http://$LOCAL_IP:3000"
echo ""
echo "⚠️  Presiona Ctrl+C para detener el servidor"
echo ""

# Iniciar el servidor
npm start


