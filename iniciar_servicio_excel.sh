#!/bin/bash

# Script para iniciar el servicio de generación de Excel
# Uso: ./iniciar_servicio_excel.sh

echo "🚀 Iniciando servicio de generación de Excel..."
echo ""

# Cambiar al directorio del servicio
cd "$(dirname "$0")/excel_generator_service" || exit 1

# Verificar si Python está instalado
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python3 no está instalado"
    exit 1
fi

# Verificar si el puerto 8001 está en uso
if lsof -Pi :8001 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo "⚠️  El puerto 8001 ya está en uso"
    echo "   ¿Quieres detener el proceso existente? (s/n)"
    read -r respuesta
    if [ "$respuesta" = "s" ] || [ "$respuesta" = "S" ]; then
        echo "🛑 Deteniendo proceso en puerto 8001..."
        lsof -ti:8001 | xargs kill -9 2>/dev/null
        sleep 2
    else
        echo "❌ No se puede iniciar el servicio. Puerto ocupado."
        exit 1
    fi
fi

# Verificar si existe el archivo main.py
if [ ! -f "main.py" ]; then
    echo "❌ Error: No se encontró main.py en excel_generator_service/"
    exit 1
fi

# Verificar si uvicorn está instalado
if ! python3 -c "import uvicorn" 2>/dev/null; then
    echo "📦 Instalando dependencias..."
    if [ -f "requirements.txt" ]; then
        pip3 install -r requirements.txt
    else
        pip3 install fastapi uvicorn openpyxl
    fi
fi

echo "✅ Iniciando servidor en http://localhost:8001"
echo "   Presiona Ctrl+C para detener el servidor"
echo ""

# Iniciar el servidor
python3 -m uvicorn main:app --host 0.0.0.0 --port 8001 --reload


















