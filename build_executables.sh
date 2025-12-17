#!/bin/bash

# Script para crear ejecutables del Sistema Telmex
# Autor: Sistema de Inventarios Telmex

echo "🚀 Sistema Telmex - Generador de Ejecutables"
echo "=============================================="

# Verificar que Flutter esté instalado
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter no está instalado. Por favor instala Flutter primero."
    exit 1
fi

echo "✅ Flutter encontrado: $(flutter --version | head -n 1)"

# Función para crear ejecutable de Linux
build_linux() {
    echo ""
    echo "🐧 Compilando para Linux..."
    echo "=========================="
    
    flutter config --enable-linux-desktop
    flutter clean
    flutter pub get
    flutter build linux --release
    
    if [ $? -eq 0 ]; then
        echo "✅ Ejecutable de Linux creado exitosamente!"
        echo "📁 Ubicación: build/linux/x64/release/bundle/"
        echo "📄 Archivo principal: proyecto_telmex"
        echo ""
        echo "Para ejecutar:"
        echo "  cd build/linux/x64/release/bundle/"
        echo "  ./proyecto_telmex"
    else
        echo "❌ Error al crear ejecutable de Linux"
        return 1
    fi
}

# Función para mostrar instrucciones de Windows
show_windows_instructions() {
    echo ""
    echo "🪟 Instrucciones para Windows"
    echo "============================="
    echo ""
    echo "Para crear un ejecutable de Windows, necesitas:"
    echo ""
    echo "1. 📥 Instalar Flutter en Windows:"
    echo "   https://flutter.dev/docs/get-started/install/windows"
    echo ""
    echo "2. 🔧 Habilitar Windows desktop:"
    echo "   flutter config --enable-windows-desktop"
    echo ""
    echo "3. 🏗️ Compilar en modo release:"
    echo "   flutter build windows --release"
    echo ""
    echo "4. 📁 El ejecutable estará en:"
    echo "   build/windows/x64/runner/Release/proyecto_telmex.exe"
    echo ""
    echo "5. 📦 Para crear un instalador, puedes usar:"
    echo "   - NSIS (Nullsoft Scriptable Install System)"
    echo "   - Inno Setup"
    echo "   - Advanced Installer"
    echo ""
    echo "💡 Alternativa: Usar GitHub Actions (automático)"
    echo "   - Sube tu código a GitHub"
    echo "   - El workflow creará automáticamente ejecutables para Windows y Linux"
    echo "   - Descarga los artefactos desde la pestaña 'Actions'"
}

# Función para crear AppImage (Linux portable)
create_appimage() {
    echo ""
    echo "📦 Creando AppImage portable..."
    echo "=============================="
    
    # Verificar si AppImageTool está disponible
    if ! command -v appimagetool &> /dev/null; then
        echo "⚠️ AppImageTool no está instalado."
        echo "Para instalar:"
        echo "  wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
        echo "  chmod +x appimagetool-x86_64.AppImage"
        echo "  sudo mv appimagetool-x86_64.AppImage /usr/local/bin/appimagetool"
        return 1
    fi
    
    # Crear estructura para AppImage
    mkdir -p AppDir/usr/bin
    mkdir -p AppDir/usr/share/applications
    mkdir -p AppDir/usr/share/icons
    
    # Copiar ejecutable
    cp build/linux/x64/release/bundle/proyecto_telmex AppDir/usr/bin/
    chmod +x AppDir/usr/bin/proyecto_telmex
    
    # Crear archivo .desktop
    cat > AppDir/usr/share/applications/proyecto_telmex.desktop << EOF
[Desktop Entry]
Name=Sistema Telmex
Comment=Sistema de Inventarios y Envíos Telmex
Exec=proyecto_telmex
Icon=proyecto_telmex
Type=Application
Categories=Office;
EOF
    
    # Crear AppImage
    appimagetool AppDir proyecto_telmex.AppImage
    
    if [ $? -eq 0 ]; then
        echo "✅ AppImage creado: proyecto_telmex.AppImage"
        echo "📱 Este archivo es portable y funciona en cualquier Linux"
    else
        echo "❌ Error al crear AppImage"
    fi
}

# Menú principal
echo ""
echo "¿Qué deseas hacer?"
echo "1) Crear ejecutable para Linux"
echo "2) Ver instrucciones para Windows"
echo "3) Crear AppImage portable (Linux)"
echo "4) Todo lo anterior"
echo ""
read -p "Selecciona una opción (1-4): " choice

case $choice in
    1)
        build_linux
        ;;
    2)
        show_windows_instructions
        ;;
    3)
        build_linux
        if [ $? -eq 0 ]; then
            create_appimage
        fi
        ;;
    4)
        build_linux
        if [ $? -eq 0 ]; then
            create_appimage
        fi
        show_windows_instructions
        ;;
    *)
        echo "❌ Opción inválida"
        exit 1
        ;;
esac

echo ""
echo "🎉 ¡Proceso completado!"
echo "📧 Para soporte técnico, contacta al equipo de desarrollo"
