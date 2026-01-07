#!/bin/bash
# Script para comprimir proyecto Flutter para Windows
# Uso: ./comprimir_para_windows.sh

PROJECT_NAME="proyecto_residencia_2025_2026"
ZIP_NAME="proyecto_telmex_para_windows.zip"

echo "📦 Comprimiendo proyecto para Windows..."
echo ""

# Verificar que estamos en la carpeta correcta
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: No se encontró pubspec.yaml"
    echo "   Asegúrate de ejecutar este script desde la raíz del proyecto"
    exit 1
fi

# Crear carpeta temporal
TEMP_DIR="temp_compress_$(date +%s)"
mkdir -p "$TEMP_DIR"

echo "📋 Copiando archivos esenciales..."

# Archivos y carpetas esenciales
cp -r lib "$TEMP_DIR/" 2>/dev/null || echo "⚠️  No se encontró lib/"
cp -r windows "$TEMP_DIR/" 2>/dev/null || echo "⚠️  No se encontró windows/"
cp -r assets "$TEMP_DIR/" 2>/dev/null || echo "⚠️  No se encontró assets/"

# Archivos de configuración
cp pubspec.yaml "$TEMP_DIR/" 2>/dev/null || echo "❌ Error: No se encontró pubspec.yaml"
cp pubspec.lock "$TEMP_DIR/" 2>/dev/null || echo "⚠️  No se encontró pubspec.lock"
cp analysis_options.yaml "$TEMP_DIR/" 2>/dev/null || echo "⚠️  No se encontró analysis_options.yaml"
cp .gitignore "$TEMP_DIR/" 2>/dev/null || echo "⚠️  No se encontró .gitignore"

# Documentación útil
if [ -f "README.md" ]; then
    cp README.md "$TEMP_DIR/"
fi

if [ -d "scripts_supabase" ]; then
    echo "📄 Copiando scripts_supabase..."
    cp -r scripts_supabase "$TEMP_DIR/"
fi

if [ -d "docs" ]; then
    echo "📄 Copiando docs..."
    cp -r docs "$TEMP_DIR/"
fi

if [ -f "COMPILAR_WINDOWS.md" ]; then
    cp COMPILAR_WINDOWS.md "$TEMP_DIR/"
fi

if [ -f "PROMPT_COMPILAR_WINDOWS.md" ]; then
    cp PROMPT_COMPILAR_WINDOWS.md "$TEMP_DIR/"
fi

if [ -f "INSTRUCCIONES_COMPRIMIR_PROYECTO.md" ]; then
    cp INSTRUCCIONES_COMPRIMIR_PROYECTO.md "$TEMP_DIR/"
fi

# Crear ZIP
echo ""
echo "🗜️  Creando archivo ZIP..."
cd "$TEMP_DIR"
zip -r "../$ZIP_NAME" . -x "*.DS_Store" "*.log" "*.tmp" "*.swp" "*~" > /dev/null 2>&1
cd ..

# Limpiar carpeta temporal
rm -rf "$TEMP_DIR"

# Verificar que el ZIP se creó
if [ -f "$ZIP_NAME" ]; then
    echo ""
    echo "✅ Proyecto comprimido exitosamente: $ZIP_NAME"
    echo ""
    echo "📊 Información del archivo:"
    ls -lh "$ZIP_NAME" | awk '{print "   Tamaño: " $5}'
    echo ""
    echo "📋 Contenido del ZIP:"
    unzip -l "$ZIP_NAME" | head -20
    echo ""
    echo "🚀 Siguiente paso:"
    echo "   1. Transfiere $ZIP_NAME a Windows"
    echo "   2. Extrae el contenido"
    echo "   3. Abre PowerShell en la carpeta extraída"
    echo "   4. Ejecuta: flutter pub get"
    echo "   5. Ejecuta: flutter build windows --release"
else
    echo "❌ Error: No se pudo crear el archivo ZIP"
    exit 1
fi




