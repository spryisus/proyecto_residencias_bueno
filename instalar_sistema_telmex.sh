#!/bin/bash

# Script universal de instalación para Sistema Telmex
# Funciona desde cualquier directorio

echo "🚀 Sistema Telmex - Instalador Universal para Linux"
echo "==============================================="

# Encontrar el directorio del proyecto
PROJECT_DIR=""
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Buscar el directorio del proyecto
if [ -d "$SCRIPT_DIR/SistemaTelmex-Portable" ]; then
    PROJECT_DIR="$SCRIPT_DIR"
elif [ -d "$HOME/Flutter/Proyecto_Telmex/SistemaTelmex-Portable" ]; then
    PROJECT_DIR="$HOME/Flutter/Proyecto_Telmex"
elif [ -d "/home/$USER/Flutter/Proyecto_Telmex/SistemaTelmex-Portable" ]; then
    PROJECT_DIR="/home/$USER/Flutter/Proyecto_Telmex"
else
    echo "❌ No se encontró el directorio SistemaTelmex-Portable"
    echo ""
    echo "🔍 Directorios buscados:"
    echo "   - $SCRIPT_DIR/SistemaTelmex-Portable"
    echo "   - $HOME/Flutter/Proyecto_Telmex/SistemaTelmex-Portable"
    echo "   - /home/$USER/Flutter/Proyecto_Telmex/SistemaTelmex-Portable"
    echo ""
    echo "💡 Soluciones:"
    echo "   1. Ejecuta este script desde el directorio del proyecto"
    echo "   2. O ejecuta: cd /home/$USER/Flutter/Proyecto_Telmex && ./instalar_sistema_telmex.sh"
    echo "   3. O asegúrate de que SistemaTelmex-Portable existe"
    echo ""
    exit 1
fi

echo "✅ Directorio del proyecto encontrado: $PROJECT_DIR"
echo ""

# Cambiar al directorio del proyecto
cd "$PROJECT_DIR" || {
    echo "❌ No se pudo acceder al directorio del proyecto"
    exit 1
}

# Verificar que existe el directorio portable
if [ ! -d "SistemaTelmex-Portable" ]; then
    echo "❌ No se encontró SistemaTelmex-Portable en $PROJECT_DIR"
    echo ""
    echo "🔧 Para crearlo, ejecuta:"
    echo "   cd $PROJECT_DIR"
    echo "   ./crear_instalador_linux.sh"
    echo ""
    exit 1
fi

# Verificar que existe el ejecutable
if [ ! -f "SistemaTelmex-Portable/proyecto_telmex" ]; then
    echo "❌ No se encontró el ejecutable en SistemaTelmex-Portable/proyecto_telmex"
    echo ""
    echo "🔧 Para compilar, ejecuta:"
    echo "   cd $PROJECT_DIR"
    echo "   flutter build linux --release"
    echo "   ./crear_instalador_linux.sh"
    echo ""
    exit 1
fi

echo "🎯 Iniciando instalación desde: $PROJECT_DIR"
echo ""

# Ejecutar el instalador original
exec ./instalar_linux.sh




