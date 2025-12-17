#!/bin/bash

# Script maestro para crear instaladores del Sistema Telmex
# Soporta: Windows (NSIS/Inno Setup), Linux (AppImage/.deb/.rpm)

echo "🚀 Sistema Telmex - Creador de Instaladores"
echo "============================================"

APP_NAME="Sistema Telmex"
APP_VERSION="1.0.0"
APP_DESCRIPTION="Sistema de Inventarios y Envíos Telmex"
APP_PUBLISHER="Telmex"

# Función para crear ejecutables
create_executables() {
    echo ""
    echo "🔨 Creando ejecutables..."
    echo "========================"
    
    # Linux
    echo "🐧 Compilando para Linux..."
    flutter config --enable-linux-desktop
    flutter clean
    flutter pub get
    flutter build linux --release
    
    if [ $? -eq 0 ]; then
        echo "✅ Ejecutable de Linux creado"
        cp build/linux/x64/release/bundle/proyecto_telmex .
    else
        echo "❌ Error al crear ejecutable de Linux"
        return 1
    fi
}

# Función para crear instalador de Windows
create_windows_installer() {
    echo ""
    echo "🪟 Preparando instalador de Windows..."
    echo "====================================="
    
    # Crear directorio para Windows
    mkdir -p windows_installer
    
    # Copiar archivos necesarios
    cp installer/sistema_telmex.nsi windows_installer/
    cp installer/sistema_telmex.iss windows_installer/
    
    # Crear archivos de documentación
    cat > windows_installer/README.txt << EOF
Sistema Telmex - Sistema de Inventarios y Envíos

DESCRIPCIÓN:
${APP_DESCRIPTION}

CARACTERÍSTICAS:
- Gestión de inventarios por categorías
- Escaneo de códigos QR con cámara
- Seguimiento de envíos en tiempo real
- Reportes detallados y estadísticas
- Panel de administración completo
- Interfaz moderna y fácil de usar

REQUISITOS DEL SISTEMA:
- Windows 10 o superior
- 4 GB RAM mínimo
- 100 MB espacio en disco
- Conexión a internet para sincronización

INSTRUCCIONES DE INSTALACIÓN:
1. Ejecute el instalador como administrador
2. Siga las instrucciones en pantalla
3. El sistema se instalará automáticamente
4. Busque "Sistema Telmex" en el menú inicio

SOPORTE TÉCNICO:
- Email: soporte@telmex.com
- Teléfono: 800-TELMEX
- Web: https://telmex.com/soporte

© 2024 ${APP_PUBLISHER}. Todos los derechos reservados.
EOF
    
    cat > windows_installer/LICENSE.txt << EOF
MIT License

Copyright (c) 2024 ${APP_PUBLISHER}

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
    
    # Crear icono básico si no existe
    if [ ! -f "icon.ico" ]; then
        echo "⚠️ No se encontró icon.ico, creando icono básico..."
        # Crear un icono básico usando ImageMagick si está disponible
        if command -v convert &> /dev/null; then
            convert -size 256x256 xc:blue -fill white -pointsize 48 -gravity center -annotate +0+0 "T" icon.png
            # Convertir PNG a ICO (requiere ImageMagick)
            convert icon.png icon.ico
        else
            echo "❌ ImageMagick no está instalado. Instala con: sudo apt install imagemagick"
            echo "📝 Nota: Necesitarás crear manualmente icon.ico para el instalador"
        fi
    fi
    
    if [ -f "icon.ico" ]; then
        cp icon.ico windows_installer/
    fi
    
    echo "✅ Archivos de Windows preparados en: windows_installer/"
    echo ""
    echo "📋 Para crear el instalador de Windows:"
    echo "1. Instala NSIS: https://nsis.sourceforge.io/Download"
    echo "2. O instala Inno Setup: https://jrsoftware.org/isinfo.php"
    echo "3. Ejecuta el script .nsi o .iss desde Windows"
    echo "4. El instalador estará listo para distribuir"
}

# Función para crear instaladores de Linux
create_linux_installers() {
    echo ""
    echo "🐧 Creando instaladores de Linux..."
    echo "=================================="
    
    # Hacer ejecutable el script de Linux
    chmod +x installer/create_linux_installer.sh
    
    # Ejecutar el script
    ./installer/create_linux_installer.sh
}

# Función para crear paquete portable
create_portable_package() {
    echo ""
    echo "📦 Creando paquete portable..."
    echo "============================="
    
    # Crear directorio portable
    mkdir -p SistemaTelmex-Portable
    
    # Copiar ejecutable
    if [ -f "proyecto_telmex" ]; then
        cp proyecto_telmex SistemaTelmex-Portable/
        chmod +x SistemaTelmex-Portable/proyecto_telmex
    else
        echo "❌ No se encontró el ejecutable"
        return 1
    fi
    
    # Crear script de ejecución
    cat > SistemaTelmex-Portable/ejecutar.sh << EOF
#!/bin/bash
# Script de ejecución para Sistema Telmex Portable

echo "🚀 Iniciando Sistema Telmex..."
echo "=============================="

# Verificar dependencias
if ! command -v flutter &> /dev/null; then
    echo "⚠️ Flutter no está instalado en el sistema"
    echo "El ejecutable puede no funcionar correctamente"
fi

# Ejecutar aplicación
./proyecto_telmex

echo "👋 Sistema Telmex cerrado"
EOF
    
    chmod +x SistemaTelmex-Portable/ejecutar.sh
    
    # Crear README para el paquete portable
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
    
    echo "✅ Paquete portable creado: SistemaTelmex-Portable-${APP_VERSION}.tar.gz"
}

# Función para crear documentación de distribución
create_distribution_docs() {
    echo ""
    echo "📚 Creando documentación de distribución..."
    echo "========================================"
    
    cat > DISTRIBUCION_INSTALADORES.md << EOF
# 📦 Guía de Instaladores - Sistema Telmex

## 🎯 Instaladores Disponibles

### 🪟 Windows
- **NSIS**: SistemaTelmexInstaller.exe (usando sistema_telmex.nsi)
- **Inno Setup**: SistemaTelmexInstaller.exe (usando sistema_telmex.iss)

### 🐧 Linux
- **AppImage**: SistemaTelmex-${APP_VERSION}.AppImage (portable)
- **Debian**: sistema-telmex_${APP_VERSION}_amd64.deb (Ubuntu/Debian)
- **Red Hat**: sistema-telmex-${APP_VERSION}-1.x86_64.rpm (Fedora/RHEL)

### 📦 Portable
- **Linux Portable**: SistemaTelmex-Portable-${APP_VERSION}.tar.gz

## 🚀 Instrucciones de Instalación

### Windows
1. Descargar el instalador correspondiente
2. Ejecutar como administrador
3. Seguir las instrucciones en pantalla
4. Buscar "Sistema Telmex" en el menú inicio

### Linux - AppImage
\`\`\`bash
chmod +x SistemaTelmex-${APP_VERSION}.AppImage
./SistemaTelmex-${APP_VERSION}.AppImage
\`\`\`

### Linux - Debian/Ubuntu
\`\`\`bash
sudo dpkg -i sistema-telmex_${APP_VERSION}_amd64.deb
sudo apt-get install -f  # Si hay dependencias faltantes
\`\`\`

### Linux - Red Hat/Fedora
\`\`\`bash
sudo rpm -i sistema-telmex-${APP_VERSION}-1.x86_64.rpm
\`\`\`

### Linux - Portable
\`\`\`bash
tar -xzf SistemaTelmex-Portable-${APP_VERSION}.tar.gz
cd SistemaTelmex-Portable
./ejecutar.sh
\`\`\`

## 🔧 Requisitos del Sistema

### Windows
- Windows 10 o superior
- 4 GB RAM mínimo
- 100 MB espacio en disco
- Conexión a internet

### Linux
- Linux x64 (Ubuntu 18.04+, Fedora 30+, etc.)
- GTK 3.0 o superior
- 4 GB RAM mínimo
- 100 MB espacio en disco
- Conexión a internet

## 📞 Soporte Técnico

- **Email**: soporte@telmex.com
- **Teléfono**: 800-TELMEX
- **Web**: https://telmex.com/soporte
- **Documentación**: https://telmex.com/docs

## 🔄 Actualizaciones

Las actualizaciones se pueden descargar desde:
- **Windows**: Panel de Control > Programas > Sistema Telmex > Actualizar
- **Linux**: Usar el gestor de paquetes correspondiente
- **Portable**: Descargar nueva versión desde el sitio web

---

**Sistema Telmex v${APP_VERSION}**  
*Desarrollado con Flutter*  
© 2024 ${APP_PUBLISHER}
EOF
    
    echo "✅ Documentación creada: DISTRIBUCION_INSTALADORES.md"
}

# Menú principal
echo ""
echo "¿Qué instaladores deseas crear?"
echo "1) Solo ejecutables"
echo "2) Instaladores de Windows"
echo "3) Instaladores de Linux"
echo "4) Paquete portable"
echo "5) Todo lo anterior"
echo ""
read -p "Selecciona una opción (1-5): " choice

case $choice in
    1)
        create_executables
        ;;
    2)
        create_executables
        create_windows_installer
        ;;
    3)
        create_executables
        create_linux_installers
        ;;
    4)
        create_executables
        create_portable_package
        ;;
    5)
        create_executables
        create_windows_installer
        create_linux_installers
        create_portable_package
        create_distribution_docs
        ;;
    *)
        echo "❌ Opción inválida"
        exit 1
        ;;
esac

echo ""
echo "🎉 ¡Proceso completado!"
echo "📁 Revisa los archivos creados en el directorio actual"
echo "📧 Para soporte técnico, contacta al equipo de desarrollo"
