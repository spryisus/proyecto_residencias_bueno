#!/bin/bash

# Script para actualizar automáticamente la IP local en la configuración

echo "🔍 Detectando IP local actual..."

# Obtener la IP local
get_local_ip() {
    # Método 1: hostname -I (Linux)
    if command -v hostname &> /dev/null; then
        local ip=$(hostname -I 2>/dev/null | awk '{print $1}')
        if [ ! -z "$ip" ] && [ "$ip" != "127.0.0.1" ]; then
            echo "$ip"
            return
        fi
    fi
    
    # Método 2: ip addr (Linux moderno)
    if command -v ip &> /dev/null; then
        local ip=$(ip addr show | grep -E 'inet.*scope global' | awk '{print $2}' | cut -d'/' -f1 | head -n1)
        if [ ! -z "$ip" ] && [ "$ip" != "127.0.0.1" ]; then
            echo "$ip"
            return
        fi
    fi
    
    # Método 3: ifconfig (Linux/Mac)
    if command -v ifconfig &> /dev/null; then
        local ip=$(ifconfig | grep -E 'inet.*broadcast' | awk '{print $2}' | head -n1)
        if [ ! -z "$ip" ] && [ "$ip" != "127.0.0.1" ]; then
            echo "$ip"
            return
        fi
    fi
    
    echo ""
}

NEW_IP=$(get_local_ip)

if [ -z "$NEW_IP" ]; then
    echo "❌ No se pudo detectar la IP local automáticamente"
    echo "💡 Por favor, ingresa tu IP manualmente:"
    read -p "IP local: " NEW_IP
fi

if [ -z "$NEW_IP" ]; then
    echo "❌ IP no válida"
    exit 1
fi

echo "✅ IP detectada: $NEW_IP"
echo ""

# Navegar al directorio del proyecto
cd "$(dirname "$0")"

# Archivo de configuración
CONFIG_FILE="lib/app/config/dhl_proxy_config.dart"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ No se encontró el archivo de configuración: $CONFIG_FILE"
    exit 1
fi

# Buscar la línea con la IP antigua y reemplazarla
OLD_PATTERN='static const String localUrl = '\''http://[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+:3000'\'';'
NEW_LINE="  static const String localUrl = 'http://$NEW_IP:3000';"

# Usar sed para reemplazar (compatible con diferentes versiones)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s|static const String localUrl = 'http://[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}:3000';|$NEW_LINE|g" "$CONFIG_FILE"
else
    # Linux
    sed -i "s|static const String localUrl = 'http://[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}:3000';|$NEW_LINE|g" "$CONFIG_FILE"
fi

if [ $? -eq 0 ]; then
    echo "✅ IP actualizada exitosamente en $CONFIG_FILE"
    echo ""
    echo "📝 Nueva configuración:"
    echo "   Proxy DHL local: http://$NEW_IP:3000"
    echo ""
    echo "💡 Recuerda:"
    echo "   - Reinicia la aplicación Flutter para que tome los cambios"
    echo "   - Asegúrate de que el proxy DHL esté corriendo en el puerto 3000"
    echo "   - Para servir la web, usa: ./servir_web.sh"
else
    echo "❌ Error al actualizar la IP"
    echo "💡 Puedes actualizarla manualmente en: $CONFIG_FILE"
    echo "   Busca la línea: static const String localUrl = ..."
    echo "   Y cámbiala a: static const String localUrl = 'http://$NEW_IP:3000';"
    exit 1
fi


