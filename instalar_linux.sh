#!/bin/bash

# Script de instalación para Sistema Telmex en Linux
echo "🚀 Sistema Telmex - Instalador para Linux"
echo "========================================="

APP_NAME="Sistema Telmex"
APP_VERSION="1.0.0"
INSTALL_DIR="$HOME/.local/share/sistema-telmex"
DESKTOP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons"

# Función para crear directorios
create_directories() {
    echo "📁 Creando directorios..."
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$DESKTOP_DIR"
    mkdir -p "$ICON_DIR"
}

# Función para instalar archivos
install_files() {
    echo "📦 Instalando archivos..."
    
    # Copiar todos los archivos del bundle
    cp -r SistemaTelmex-Portable/* "$INSTALL_DIR/"
    
    # Crear script de ejecución
    cat > "$INSTALL_DIR/sistema-telmex" << EOF
#!/bin/bash
cd "$INSTALL_DIR"
exec ./proyecto_telmex "\$@"
EOF
    
    chmod +x "$INSTALL_DIR/sistema-telmex"
    
    # Crear archivo .desktop
    cat > "$DESKTOP_DIR/sistema-telmex.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=${APP_NAME}
Comment=Sistema de Inventarios y Envíos Telmex
Exec=$INSTALL_DIR/sistema-telmex
Icon=sistema-telmex
Terminal=false
Categories=Office;Business;
StartupNotify=true
EOF
    
    # Crear icono básico si no existe
    if [ ! -f "$INSTALL_DIR/icon.png" ]; then
        echo "🎨 Creando icono básico..."
        # Crear un icono simple usando Python
        python3 -c "
import os
# Crear un archivo SVG simple
svg_content = '''<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<svg width=\"256\" height=\"256\" xmlns=\"http://www.w3.org/2000/svg\">
  <rect width=\"256\" height=\"256\" fill=\"#003366\"/>
  <text x=\"128\" y=\"140\" font-family=\"Arial\" font-size=\"120\" font-weight=\"bold\" text-anchor=\"middle\" fill=\"white\">T</text>
</svg>'''
with open('$INSTALL_DIR/icon.svg', 'w') as f:
    f.write(svg_content)
" 2>/dev/null || echo "⚠️ No se pudo crear icono SVG"
    fi
    
    # Copiar icono si existe
    if [ -f "$INSTALL_DIR/icon.svg" ]; then
        cp "$INSTALL_DIR/icon.svg" "$ICON_DIR/sistema-telmex.svg"
    fi
}

# Función para crear enlaces simbólicos
create_links() {
    echo "🔗 Creando enlaces..."
    
    # Crear enlace en el PATH del usuario
    mkdir -p "$HOME/.local/bin"
    ln -sf "$INSTALL_DIR/sistema-telmex" "$HOME/.local/bin/sistema-telmex"
    
    echo "✅ Enlace creado en ~/.local/bin/sistema-telmex"
}

# Función para actualizar la base de datos de aplicaciones
update_desktop_database() {
    echo "🔄 Actualizando base de datos de aplicaciones..."
    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database "$DESKTOP_DIR"
    fi
    echo "✅ Base de datos actualizada"
}

# Función para crear script de desinstalación
create_uninstaller() {
    echo "🗑️ Creando script de desinstalación..."
    cat > "$INSTALL_DIR/desinstalar.sh" << EOF
#!/bin/bash
echo "🗑️ Desinstalando Sistema Telmex..."
echo "=================================="

# Eliminar archivos
rm -rf "$INSTALL_DIR"
rm -f "$DESKTOP_DIR/sistema-telmex.desktop"
rm -f "$ICON_DIR/sistema-telmex.svg"
rm -f "$HOME/.local/bin/sistema-telmex"

# Actualizar base de datos
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database "$DESKTOP_DIR"
fi

echo "✅ Sistema Telmex desinstalado completamente"
EOF
    
    chmod +x "$INSTALL_DIR/desinstalar.sh"
    echo "✅ Script de desinstalación creado: $INSTALL_DIR/desinstalar.sh"
}

# Función principal
main() {
    echo ""
    echo "¿Deseas instalar Sistema Telmex? (s/n)"
    read -r response
    
    if [[ "$response" =~ ^[Ss]$ ]]; then
        create_directories
        install_files
        create_links
        update_desktop_database
        create_uninstaller
        
        echo ""
        echo "🎉 ¡Instalación completada exitosamente!"
        echo "======================================="
        echo "📱 Puedes ejecutar Sistema Telmex de las siguientes formas:"
        echo "   - Desde el menú de aplicaciones (busca 'Sistema Telmex')"
        echo "   - Desde la terminal: sistema-telmex"
        echo "   - Directamente: $INSTALL_DIR/sistema-telmex"
        echo ""
        echo "🗑️ Para desinstalar: $INSTALL_DIR/desinstalar.sh"
        echo ""
        echo "📧 Soporte técnico: soporte@telmex.com"
    else
        echo "❌ Instalación cancelada"
        exit 1
    fi
}

# Verificar que existe el directorio portable
if [ ! -d "SistemaTelmex-Portable" ]; then
    echo "❌ No se encontró el directorio SistemaTelmex-Portable"
    echo "   Ejecuta primero: ./crear_instalador_linux.sh"
    exit 1
fi

# Ejecutar función principal
main
