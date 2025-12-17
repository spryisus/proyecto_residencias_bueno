#!/bin/bash

# Script automatizado para crear AppImage de Sistema Telmex
echo "🐧 Sistema Telmex - Creando AppImage Automático"
echo "=============================================="

APP_NAME="Sistema Telmex"
APP_VERSION="1.0.0"
APP_DESCRIPTION="Sistema de Inventarios y Envíos Telmex"
APP_PUBLISHER="Telmex"
APP_EXECUTABLE="proyecto_telmex"

# Verificar que existe el ejecutable
if [ ! -f "proyecto_telmex" ]; then
    echo "❌ No se encontró el ejecutable. Ejecuta primero: flutter build linux --release"
    exit 1
fi

echo "📦 Creando AppImage..."
echo "====================="

# Crear estructura de directorios
mkdir -p AppDir/usr/bin
mkdir -p AppDir/usr/share/applications
mkdir -p AppDir/usr/share/icons/hicolor/256x256/apps
mkdir -p AppDir/usr/share/metainfo

# Copiar ejecutable
cp proyecto_telmex AppDir/usr/bin/
chmod +x AppDir/usr/bin/proyecto_telmex

# Crear archivo .desktop
cat > AppDir/usr/share/applications/sistema-telmex.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=${APP_NAME}
Comment=${APP_DESCRIPTION}
Exec=${APP_EXECUTABLE}
Icon=sistema-telmex
Terminal=false
Categories=Office;Business;
StartupNotify=true
MimeType=application/x-sistema-telmex;
EOF

# Crear archivo de metadatos
cat > AppDir/usr/share/metainfo/sistema-telmex.appdata.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<component type="desktop-application">
  <id>sistema-telmex</id>
  <metadata_license>MIT</metadata_license>
  <project_license>MIT</project_license>
  <name>${APP_NAME}</name>
  <summary>${APP_DESCRIPTION}</summary>
  <description>
    <p>Sistema completo de gestión de inventarios y seguimiento de envíos para Telmex.</p>
    <p>Características:</p>
    <ul>
      <li>Gestión de inventarios por categorías</li>
      <li>Escaneo de códigos QR</li>
      <li>Seguimiento de envíos en tiempo real</li>
      <li>Reportes detallados</li>
      <li>Panel de administración</li>
    </ul>
  </description>
  <launchable type="desktop-id">sistema-telmex.desktop</launchable>
  <url type="homepage">https://telmex.com</url>
  <url type="bugtracker">https://telmex.com/soporte</url>
  <screenshots>
    <screenshot type="default">
      <caption>Pantalla principal del sistema</caption>
    </screenshot>
  </screenshots>
  <releases>
    <release version="${APP_VERSION}" date="$(date +%Y-%m-%d)">
      <description>
        <p>Versión inicial del Sistema Telmex</p>
      </description>
    </release>
  </releases>
  <provides>
    <binary>${APP_EXECUTABLE}</binary>
  </provides>
</component>
EOF

# Crear icono básico si no existe
if [ ! -f "icon.png" ]; then
    echo "⚠️ Creando icono básico..."
    if command -v convert &> /dev/null; then
        convert -size 256x256 xc:blue -fill white -pointsize 48 -gravity center -annotate +0+0 "T" icon.png
    else
        echo "❌ ImageMagick no está instalado. Creando icono simple..."
        # Crear un archivo PNG básico usando Python si está disponible
        python3 -c "
import struct
width, height = 256, 256
# Crear un PNG simple azul con una T blanca
data = []
for y in range(height):
    for x in range(width):
        if (x-128)**2 + (y-128)**2 < 10000:  # Círculo azul
            data.extend([0, 0, 255, 255])  # Azul
        else:
            data.extend([255, 255, 255, 255])  # Blanco
with open('icon.png', 'wb') as f:
    f.write(b'\x89PNG\r\n\x1a\n')
    f.write(struct.pack('>IIBBBBB', 13, 73, 72, 68, 82, width, height, 8, 6, 0, 0, 0))
    f.write(struct.pack('>I', 0))  # CRC
    f.write(struct.pack('>IIBBBBB', len(data), 73, 68, 65, 84, 120, 156))  # IDAT
    f.write(bytes(data))
    f.write(struct.pack('>I', 0))  # CRC
    f.write(struct.pack('>I', 0))  # IEND
" 2>/dev/null || echo "⚠️ No se pudo crear icono automáticamente"
    fi
fi

if [ -f "icon.png" ]; then
    cp icon.png AppDir/usr/share/icons/hicolor/256x256/apps/sistema-telmex.png
    echo "✅ Icono copiado"
else
    echo "⚠️ No se encontró icono, continuando sin él"
fi

# Crear AppImage usando appimagetool
if command -v appimagetool &> /dev/null; then
    appimagetool AppDir SistemaTelmex-${APP_VERSION}.AppImage
    echo "✅ AppImage creado: SistemaTelmex-${APP_VERSION}.AppImage"
elif [ -f "appimagetool-x86_64.AppImage" ]; then
    ./appimagetool-x86_64.AppImage AppDir SistemaTelmex-${APP_VERSION}.AppImage
    echo "✅ AppImage creado: SistemaTelmex-${APP_VERSION}.AppImage"
else
    echo "❌ appimagetool no está disponible."
    echo "📥 Descargando appimagetool..."
    wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
    chmod +x appimagetool-x86_64.AppImage
    ./appimagetool-x86_64.AppImage AppDir SistemaTelmex-${APP_VERSION}.AppImage
    echo "✅ AppImage creado: SistemaTelmex-${APP_VERSION}.AppImage"
fi

# Crear paquete portable simple
echo ""
echo "📦 Creando paquete portable..."
mkdir -p SistemaTelmex-Portable
cp proyecto_telmex SistemaTelmex-Portable/
chmod +x SistemaTelmex-Portable/proyecto_telmex

# Crear script de ejecución
cat > SistemaTelmex-Portable/ejecutar.sh << EOF
#!/bin/bash
echo "🚀 Iniciando Sistema Telmex..."
echo "=============================="
./proyecto_telmex
echo "👋 Sistema Telmex cerrado"
EOF

chmod +x SistemaTelmex-Portable/ejecutar.sh

# Crear README
cat > SistemaTelmex-Portable/README.txt << EOF
Sistema Telmex - Versión Portable

DESCRIPCIÓN:
${APP_DESCRIPTION}

INSTRUCCIONES:
1. Ejecute: ./ejecutar.sh
2. O ejecute directamente: ./proyecto_telmex

REQUISITOS:
- Linux x64
- GTK 3.0 o superior
- Librerías estándar de C

CARACTERÍSTICAS:
- Gestión de inventarios por categorías
- Escaneo de códigos QR
- Seguimiento de envíos
- Reportes detallados
- Panel de administración

SOPORTE:
- Email: soporte@telmex.com
- Web: https://telmex.com/soporte

© 2024 ${APP_PUBLISHER}
EOF

# Crear archivo tar.gz
tar -czf SistemaTelmex-Portable-${APP_VERSION}.tar.gz SistemaTelmex-Portable/

echo ""
echo "🎉 ¡Instaladores creados exitosamente!"
echo "====================================="
echo "📦 Archivos generados:"
echo "   - SistemaTelmex-${APP_VERSION}.AppImage (AppImage portable)"
echo "   - SistemaTelmex-Portable-${APP_VERSION}.tar.gz (Paquete portable)"
echo ""
echo "🚀 Para ejecutar:"
echo "   AppImage: chmod +x SistemaTelmex-${APP_VERSION}.AppImage && ./SistemaTelmex-${APP_VERSION}.AppImage"
echo "   Portable: tar -xzf SistemaTelmex-Portable-${APP_VERSION}.tar.gz && cd SistemaTelmex-Portable && ./ejecutar.sh"
echo ""
echo "📧 Para soporte técnico, contacta al equipo de desarrollo"

