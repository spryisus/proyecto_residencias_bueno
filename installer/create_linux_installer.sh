#!/bin/bash

# Script para crear instaladores de Linux para Sistema Telmex
# Soporta: AppImage, .deb, .rpm

echo "🐧 Sistema Telmex - Creador de Instaladores Linux"
echo "================================================"

APP_NAME="Sistema Telmex"
APP_VERSION="1.0.0"
APP_DESCRIPTION="Sistema de Inventarios y Envíos Telmex"
APP_PUBLISHER="Telmex"
APP_EXECUTABLE="proyecto_telmex"

# Función para crear AppImage
create_appimage() {
    echo ""
    echo "📦 Creando AppImage..."
    echo "====================="
    
    # Crear estructura de directorios
    mkdir -p AppDir/usr/bin
    mkdir -p AppDir/usr/share/applications
    mkdir -p AppDir/usr/share/icons/hicolor/256x256/apps
    mkdir -p AppDir/usr/share/metainfo
    
    # Copiar ejecutable
    if [ -f "proyecto_telmex" ]; then
        cp proyecto_telmex AppDir/usr/bin/
        chmod +x AppDir/usr/bin/proyecto_telmex
    else
        echo "❌ No se encontró el ejecutable. Ejecuta primero: flutter build linux --release"
        return 1
    fi
    
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
    
    # Crear icono (si no existe, crear uno básico)
    if [ ! -f "icon.png" ]; then
        echo "⚠️ No se encontró icon.png, creando icono básico..."
        # Crear un icono básico usando ImageMagick si está disponible
        if command -v convert &> /dev/null; then
            convert -size 256x256 xc:blue -fill white -pointsize 48 -gravity center -annotate +0+0 "T" icon.png
        else
            echo "❌ ImageMagick no está instalado. Instala con: sudo apt install imagemagick"
            return 1
        fi
    fi
    
    cp icon.png AppDir/usr/share/icons/hicolor/256x256/apps/sistema-telmex.png
    
    # Crear AppImage usando appimagetool
    if command -v appimagetool &> /dev/null; then
        appimagetool AppDir SistemaTelmex-${APP_VERSION}.AppImage
        echo "✅ AppImage creado: SistemaTelmex-${APP_VERSION}.AppImage"
    else
        echo "❌ appimagetool no está instalado."
        echo "Para instalar:"
        echo "  wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
        echo "  chmod +x appimagetool-x86_64.AppImage"
        echo "  sudo mv appimagetool-x86_64.AppImage /usr/local/bin/appimagetool"
        return 1
    fi
}

# Función para crear paquete .deb
create_deb_package() {
    echo ""
    echo "📦 Creando paquete .deb..."
    echo "========================="
    
    # Crear estructura de directorios para .deb
    mkdir -p debian/DEBIAN
    mkdir -p debian/usr/bin
    mkdir -p debian/usr/share/applications
    mkdir -p debian/usr/share/icons/hicolor/256x256/apps
    mkdir -p debian/usr/share/doc/sistema-telmex
    
    # Copiar ejecutable
    cp proyecto_telmex debian/usr/bin/
    chmod +x debian/usr/bin/proyecto_telmex
    
    # Crear archivo .desktop
    cat > debian/usr/share/applications/sistema-telmex.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=${APP_NAME}
Comment=${APP_DESCRIPTION}
Exec=${APP_EXECUTABLE}
Icon=sistema-telmex
Terminal=false
Categories=Office;Business;
EOF
    
    # Copiar icono
    if [ -f "icon.png" ]; then
        cp icon.png debian/usr/share/icons/hicolor/256x256/apps/sistema-telmex.png
    fi
    
    # Crear archivo de control
    cat > debian/DEBIAN/control << EOF
Package: sistema-telmex
Version: ${APP_VERSION}
Section: office
Priority: optional
Architecture: amd64
Depends: libc6 (>= 2.17), libgtk-3-0 (>= 3.10.0)
Maintainer: ${APP_PUBLISHER} <soporte@telmex.com>
Description: ${APP_DESCRIPTION}
 Sistema completo de gestión de inventarios y seguimiento de envíos.
 Características:
  - Gestión de inventarios por categorías
  - Escaneo de códigos QR
  - Seguimiento de envíos en tiempo real
  - Reportes detallados
  - Panel de administración
Homepage: https://telmex.com
EOF
    
    # Crear archivo de copyright
    cat > debian/usr/share/doc/sistema-telmex/copyright << EOF
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: Sistema Telmex
Source: https://telmex.com

Files: *
Copyright: 2024 ${APP_PUBLISHER}
License: MIT

License: MIT
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 .
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
EOF
    
    # Crear changelog
    cat > debian/usr/share/doc/sistema-telmex/changelog.Debian << EOF
sistema-telmex (${APP_VERSION}) unstable; urgency=medium

  * Versión inicial del Sistema Telmex
  * Gestión completa de inventarios y envíos
  * Interfaz moderna y fácil de usar

 -- ${APP_PUBLISHER} <soporte@telmex.com>  $(date -R)
EOF
    
    gzip -9 debian/usr/share/doc/sistema-telmex/changelog.Debian
    
    # Crear el paquete .deb
    dpkg-deb --build debian sistema-telmex_${APP_VERSION}_amd64.deb
    
    if [ $? -eq 0 ]; then
        echo "✅ Paquete .deb creado: sistema-telmex_${APP_VERSION}_amd64.deb"
        echo "📦 Para instalar: sudo dpkg -i sistema-telmex_${APP_VERSION}_amd64.deb"
    else
        echo "❌ Error al crear el paquete .deb"
        return 1
    fi
}

# Función para crear paquete .rpm
create_rpm_package() {
    echo ""
    echo "📦 Creando paquete .rpm..."
    echo "========================="
    
    # Crear estructura de directorios para .rpm
    mkdir -p rpm/BUILD
    mkdir -p rpm/RPMS/x86_64
    mkdir -p rpm/SOURCES
    mkdir -p rpm/SPECS
    
    # Copiar archivos fuente
    cp proyecto_telmex rpm/SOURCES/
    if [ -f "icon.png" ]; then
        cp icon.png rpm/SOURCES/sistema-telmex.png
    fi
    
    # Crear spec file
    cat > rpm/SPECS/sistema-telmex.spec << EOF
Name:           sistema-telmex
Version:        ${APP_VERSION}
Release:        1%{?dist}
Summary:        ${APP_DESCRIPTION}

License:        MIT
URL:            https://telmex.com
Source0:        proyecto_telmex
Source1:        sistema-telmex.png

Requires:       glibc >= 2.17, gtk3 >= 3.10.0

%description
${APP_DESCRIPTION}

Sistema completo de gestión de inventarios y seguimiento de envíos.
Características:
- Gestión de inventarios por categorías
- Escaneo de códigos QR
- Seguimiento de envíos en tiempo real
- Reportes detallados
- Panel de administración

%prep
# No hay preparación necesaria

%build
# No hay compilación necesaria

%install
mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/share/applications
mkdir -p %{buildroot}/usr/share/icons/hicolor/256x256/apps

install -m 755 %{SOURCE0} %{buildroot}/usr/bin/

cat > %{buildroot}/usr/share/applications/sistema-telmex.desktop << 'DESKTOP_EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=${APP_NAME}
Comment=${APP_DESCRIPTION}
Exec=${APP_EXECUTABLE}
Icon=sistema-telmex
Terminal=false
Categories=Office;Business;
DESKTOP_EOF

install -m 644 %{SOURCE1} %{buildroot}/usr/share/icons/hicolor/256x256/apps/sistema-telmex.png

%files
/usr/bin/proyecto_telmex
/usr/share/applications/sistema-telmex.desktop
/usr/share/icons/hicolor/256x256/apps/sistema-telmex.png

%changelog
* $(date '+%a %b %d %Y') ${APP_PUBLISHER} <soporte@telmex.com> - ${APP_VERSION}-1
- Versión inicial del Sistema Telmex
EOF
    
    # Crear el paquete .rpm
    rpmbuild --define "_topdir $(pwd)/rpm" -bb rpm/SPECS/sistema-telmex.spec
    
    if [ $? -eq 0 ]; then
        echo "✅ Paquete .rpm creado en rpm/RPMS/x86_64/"
        echo "📦 Para instalar: sudo rpm -i rpm/RPMS/x86_64/sistema-telmex-${APP_VERSION}-1.x86_64.rpm"
    else
        echo "❌ Error al crear el paquete .rpm"
        return 1
    fi
}

# Menú principal
echo ""
echo "¿Qué tipo de instalador deseas crear?"
echo "1) AppImage (portable)"
echo "2) Paquete .deb (Ubuntu/Debian)"
echo "3) Paquete .rpm (Red Hat/Fedora)"
echo "4) Todos los anteriores"
echo ""
read -p "Selecciona una opción (1-4): " choice

case $choice in
    1)
        create_appimage
        ;;
    2)
        create_deb_package
        ;;
    3)
        create_rpm_package
        ;;
    4)
        create_appimage
        create_deb_package
        create_rpm_package
        ;;
    *)
        echo "❌ Opción inválida"
        exit 1
        ;;
esac

echo ""
echo "🎉 ¡Instaladores creados exitosamente!"
echo "📧 Para soporte técnico, contacta al equipo de desarrollo"
