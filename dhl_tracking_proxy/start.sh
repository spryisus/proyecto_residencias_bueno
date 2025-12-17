#!/bin/bash

# Script de inicio para DHL Tracking Proxy

echo "🚀 Iniciando DHL Tracking Proxy..."
echo ""

# Verificar si Node.js está instalado
if ! command -v node &> /dev/null
then
    echo "❌ Node.js no está instalado"
    echo "Por favor instala Node.js desde: https://nodejs.org/"
    exit 1
fi

# Verificar si npm está instalado
if ! command -v npm &> /dev/null
then
    echo "❌ npm no está instalado"
    exit 1
fi

echo "✅ Node.js $(node --version)"
echo "✅ npm $(npm --version)"
echo ""

# Verificar si node_modules existe
if [ ! -d "node_modules" ]; then
    echo "📦 Instalando dependencias..."
    npm install
    echo ""
fi

# Iniciar el servidor
echo "🚀 Iniciando servidor..."
echo "📡 El servidor estará disponible en: http://localhost:3000"
echo "📡 Endpoint: http://localhost:3000/api/track/:trackingNumber"
echo ""
echo "Presiona Ctrl+C para detener el servidor"
echo ""

npm start


