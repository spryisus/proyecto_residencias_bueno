#!/bin/bash

# Script para compilar y servir la aplicación Flutter para web
# Accesible desde otras máquinas en la red local

echo "🚀 Compilando aplicación Flutter para web..."
echo ""

# Navegar al directorio del proyecto
cd "$(dirname "$0")"

# Limpiar builds anteriores (opcional, descomenta si quieres limpiar)
# echo "🧹 Limpiando builds anteriores..."
# flutter clean

# Obtener dependencias
echo "📦 Obteniendo dependencias..."
flutter pub get

# Compilar para web
echo "🔨 Compilando para web..."
flutter build web --release

if [ $? -ne 0 ]; then
    echo "❌ Error al compilar la aplicación"
    exit 1
fi

echo ""
echo "✅ Compilación completada exitosamente"
echo ""

# Obtener la IP local
get_local_ip() {
    # Intentar obtener IP en Linux
    if command -v hostname &> /dev/null; then
        # Método 1: hostname -I (Linux)
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
PORT=8080

echo "🌐 Iniciando servidor web..."
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  📱 Aplicación disponible en:"
echo ""
echo "  🖥️  Local:     http://localhost:$PORT"
echo "  🌐 Red local: http://$LOCAL_IP:$PORT"
echo ""
echo "  💡 Para acceder desde otra máquina:"
echo "     Abre el navegador y ve a: http://$LOCAL_IP:$PORT"
echo ""
echo "  ⚠️  Asegúrate de que el firewall permita conexiones en el puerto $PORT"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "  Presiona Ctrl+C para detener el servidor"
echo ""

# Verificar si Python está disponible (método más común)
if command -v python3 &> /dev/null; then
    echo "🐍 Usando Python 3 para servir la aplicación..."
    cd build/web
    python3 -m http.server $PORT --bind 0.0.0.0
elif command -v python &> /dev/null; then
    echo "🐍 Usando Python para servir la aplicación..."
    cd build/web
    python -m SimpleHTTPServer $PORT
elif command -v php &> /dev/null; then
    echo "🐘 Usando PHP para servir la aplicación..."
    cd build/web
    php -S 0.0.0.0:$PORT
elif command -v npx &> /dev/null; then
    echo "📦 Usando npx serve para servir la aplicación..."
    cd build/web
    npx serve -l $PORT --host 0.0.0.0
else
    echo "❌ No se encontró ningún servidor HTTP disponible"
    echo ""
    echo "💡 Opciones para instalar un servidor:"
    echo "   - Python 3: sudo apt install python3 (Linux)"
    echo "   - PHP: sudo apt install php (Linux)"
    echo "   - Node.js: sudo apt install nodejs npm (Linux)"
    echo ""
    echo "   O puedes usar cualquier servidor HTTP que escuche en 0.0.0.0:$PORT"
    echo "   y apunte al directorio: build/web"
    exit 1
fi


