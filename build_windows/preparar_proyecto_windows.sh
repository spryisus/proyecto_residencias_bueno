#!/bin/bash
# Script para crear una copia del proyecto con solo los archivos necesarios para Windows

echo "=========================================="
echo "Preparando proyecto para Windows"
echo "=========================================="
echo ""

# Directorio de destino
DEST_DIR="../proyecto_telmex_windows"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Crear directorio de destino
echo "[1/6] Creando directorio de destino..."
rm -rf "$DEST_DIR"
mkdir -p "$DEST_DIR"

# Archivos y carpetas a copiar
echo "[2/6] Copiando archivos esenciales..."

# Archivos raíz
cp "$PROJECT_ROOT/pubspec.yaml" "$DEST_DIR/"
cp "$PROJECT_ROOT/analysis_options.yaml" "$DEST_DIR/" 2>/dev/null || true
cp "$PROJECT_ROOT/README.md" "$DEST_DIR/" 2>/dev/null || true
cp "$PROJECT_ROOT/.gitignore" "$DEST_DIR/" 2>/dev/null || true

# Carpeta lib/ (código fuente)
echo "  - Copiando lib/..."
cp -r "$PROJECT_ROOT/lib" "$DEST_DIR/"

# Carpeta assets/ (recursos)
echo "  - Copiando assets/..."
if [ -d "$PROJECT_ROOT/assets" ]; then
    cp -r "$PROJECT_ROOT/assets" "$DEST_DIR/"
fi

# Carpeta windows/ (configuración de Windows)
echo "  - Copiando windows/..."
if [ -d "$PROJECT_ROOT/windows" ]; then
    cp -r "$PROJECT_ROOT/windows" "$DEST_DIR/"
fi

# Carpeta build_windows/ (scripts de compilación)
echo "  - Copiando build_windows/..."
cp -r "$PROJECT_ROOT/build_windows" "$DEST_DIR/"

# Carpeta excel_generator_service/ (servicio de exportación)
echo "  - Copiando excel_generator_service/..."
if [ -d "$PROJECT_ROOT/excel_generator_service" ]; then
    cp -r "$PROJECT_ROOT/excel_generator_service" "$DEST_DIR/"
fi

# Scripts útiles
echo "[3/6] Copiando scripts útiles..."
if [ -f "$PROJECT_ROOT/actualizar_ip_config.sh" ]; then
    cp "$PROJECT_ROOT/actualizar_ip_config.sh" "$DEST_DIR/"
fi
if [ -f "$PROJECT_ROOT/iniciar_servicio_excel.sh" ]; then
    cp "$PROJECT_ROOT/iniciar_servicio_excel.sh" "$DEST_DIR/"
fi

# Crear .gitignore específico para Windows
echo "[4/6] Creando .gitignore para Windows..."
cat > "$DEST_DIR/.gitignore" << 'EOF'
# Flutter/Dart/Pub related
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
build/
flutter_*.png
linked_*.ds
unlinked.ds
unlinked_spec.ds

# Android related
**/android/**/gradle-wrapper.jar
**/android/.gradle
**/android/captures/
**/android/gradlew
**/android/gradlew.bat
**/android/local.properties
**/android/**/GeneratedPluginRegistrant.java
**/android/key.properties
*.jks

# iOS/XCode related
**/ios/**/*.mode1v3
**/ios/**/*.mode2v3
**/ios/**/*.moved-aside
**/ios/**/*.pbxuser
**/ios/**/*.perspectivev3
**/ios/**/*sync/
**/ios/**/.sconsign.dblite
**/ios/**/.tags*
**/ios/**/.vagrant/
**/ios/**/DerivedData/
**/ios/**/Icon?
**/ios/**/Pods/
**/ios/**/.symlinks/
**/ios/**/profile
**/ios/**/xcuserdata
**/ios/.generated/
**/ios/Flutter/App.framework
**/ios/Flutter/Flutter.framework
**/ios/Flutter/Flutter.podspec
**/ios/Flutter/Generated.xcconfig
**/ios/Flutter/ephemeral
**/ios/Flutter/app.flx
**/ios/Flutter/app.zip
**/ios/Flutter/flutter_assets/
**/ios/Flutter/flutter_export_environment.sh
**/ios/ServiceDefinitions.json
**/ios/Runner/GeneratedPluginRegistrant.*

# Linux related
**/linux/flutter/generated_plugin_registrant.cc
**/linux/flutter/generated_plugin_registrant.h
**/linux/flutter/generated_plugins.cmake

# macOS related
**/macos/Flutter/GeneratedPluginRegistrant.swift
**/macos/Flutter/ephemeral

# Web related
**/web/*.dart.js
**/web/*.dart.js.map
**/web/*.js_
**/web/*.js.deps
**/web/*.js.map

# Exceptions to above rules.
!**/ios/**/default.mode1v3
!**/ios/**/default.mode2v3
!**/ios/**/default.pbxuser
!**/ios/**/default.perspectivev3

# IDE
.idea/
*.iml
*.ipr
*.iws
.vscode/
*.swp
*.swo
*~

# OS
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Logs
*.log

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
ENV/
.venv

# Excel service
excel_generator_service/__pycache__/
excel_generator_service/*.pyc
EOF

# Crear README específico para la copia de Windows
echo "[5/6] Creando README para Windows..."
cat > "$DEST_DIR/README_WINDOWS.md" << 'EOF'
# 🪟 Proyecto Telmex - Versión para Windows

Esta es una copia del proyecto preparada específicamente para compilar en Windows.

## 📋 Requisitos

Antes de compilar, asegúrate de tener instalado:

1. **Flutter SDK** - https://flutter.dev/docs/get-started/install/windows
2. **Visual Studio 2022** - https://visualstudio.microsoft.com/downloads/
   - Componente: "Desarrollo para el escritorio con C++"
3. **Git** - https://git-scm.com/download/win

## 🚀 Compilación Rápida

1. Abre PowerShell o CMD como Administrador
2. Navega a esta carpeta
3. Ejecuta:
   ```bash
   .\build_windows\build_release.bat
   ```

## 📁 Estructura del Proyecto

- `lib/` - Código fuente de la aplicación
- `assets/` - Recursos (imágenes, plantillas, etc.)
- `windows/` - Configuración específica de Windows
- `build_windows/` - Scripts de compilación y documentación
- `excel_generator_service/` - Servicio de exportación a Excel

## 📝 Notas

- El ejecutable se generará en: `build\windows\x64\runner\Release\proyecto_telmex.exe`
- La primera compilación puede tardar 10-30 minutos
- Consulta `build_windows/README.md` para más detalles

## 🔧 Verificar Requisitos

Ejecuta antes de compilar:
```bash
.\build_windows\verificar_requisitos.bat
```

## 📞 Soporte

Para problemas durante la compilación, consulta:
- `build_windows/README.md`
- `build_windows/REQUISITOS.md`
EOF

# Crear archivo de instrucciones rápidas
echo "[6/6] Creando INSTRUCCIONES.txt..."
cat > "$DEST_DIR/INSTRUCCIONES.txt" << 'EOF'
═══════════════════════════════════════════════════════════════
  PROYECTO TELMEX - INSTRUCCIONES RÁPIDAS PARA WINDOWS
═══════════════════════════════════════════════════════════════

PASO 1: Verificar Requisitos
─────────────────────────────
Ejecuta: build_windows\verificar_requisitos.bat

PASO 2: Compilar
────────────────
Ejecuta: build_windows\build_release.bat

PASO 3: Encontrar el Ejecutable
────────────────────────────────
Ruta: build\windows\x64\runner\Release\proyecto_telmex.exe

═══════════════════════════════════════════════════════════════

Para más información, consulta:
- README_WINDOWS.md
- build_windows\README.md
- build_windows\REQUISITOS.md

═══════════════════════════════════════════════════════════════
EOF

# Mostrar resumen
echo ""
echo "=========================================="
echo "✅ Proyecto preparado para Windows"
echo "=========================================="
echo ""
echo "Ubicación: $DEST_DIR"
echo ""
echo "Archivos copiados:"
echo "  ✓ Código fuente (lib/)"
echo "  ✓ Configuración (pubspec.yaml, windows/)"
echo "  ✓ Recursos (assets/)"
echo "  ✓ Scripts de compilación (build_windows/)"
echo "  ✓ Servicio Excel (excel_generator_service/)"
echo ""
echo "Próximos pasos:"
echo "  1. Copia la carpeta '$DEST_DIR' a tu máquina Windows"
echo "  2. Ejecuta: build_windows\\verificar_requisitos.bat"
echo "  3. Ejecuta: build_windows\\build_release.bat"
echo ""








