#!/bin/bash
# Script para comprimir proyecto Flutter para Windows
# Solo incluye los archivos necesarios para compilar
# Uso: ./comprimir_para_windows.sh

PROJECT_NAME="proyecto_residencia_2025_2026"
ZIP_NAME="proyecto_telmex_para_windows.zip"

echo "=========================================="
echo "📦 Comprimiendo proyecto para Windows"
echo "=========================================="
echo ""

# Verificar que estamos en la carpeta correcta
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: No se encontró pubspec.yaml"
    echo "   Asegúrate de ejecutar este script desde la raíz del proyecto"
    exit 1
fi

# Eliminar ZIP anterior si existe
if [ -f "$ZIP_NAME" ]; then
    echo "🗑️  Eliminando ZIP anterior..."
    rm -f "$ZIP_NAME"
fi

# Crear carpeta temporal
TEMP_DIR="temp_compress_$(date +%s)"
mkdir -p "$TEMP_DIR"

echo "📋 Copiando archivos esenciales..."
echo ""

# ============================================
# CARPETAS ESENCIALES (OBLIGATORIAS)
# ============================================
echo "  ✅ lib/ (código fuente)"
cp -r lib "$TEMP_DIR/" 2>/dev/null || { echo "❌ Error: No se encontró lib/"; exit 1; }

echo "  ✅ windows/ (configuración Windows)"
cp -r windows "$TEMP_DIR/" 2>/dev/null || { echo "❌ Error: No se encontró windows/"; exit 1; }

echo "  ✅ assets/ (recursos)"
if [ -d "assets" ]; then
    cp -r assets "$TEMP_DIR/" 2>/dev/null || echo "⚠️  No se pudo copiar assets/"
else
    echo "⚠️  No se encontró assets/ (puede ser opcional)"
fi

# ============================================
# ARCHIVOS DE CONFIGURACIÓN (OBLIGATORIOS)
# ============================================
echo "  ✅ pubspec.yaml"
cp pubspec.yaml "$TEMP_DIR/" 2>/dev/null || { echo "❌ Error: No se encontró pubspec.yaml"; exit 1; }

echo "  ✅ pubspec.lock"
cp pubspec.lock "$TEMP_DIR/" 2>/dev/null || echo "⚠️  No se encontró pubspec.lock (se regenerará con flutter pub get)"

echo "  ✅ analysis_options.yaml"
cp analysis_options.yaml "$TEMP_DIR/" 2>/dev/null || echo "⚠️  No se encontró analysis_options.yaml"

# ============================================
# DOCUMENTACIÓN ÚTIL (OPCIONAL)
# ============================================
echo ""
echo "📄 Copiando documentación útil..."

if [ -f "README.md" ]; then
    cp README.md "$TEMP_DIR/"
    echo "  ✅ README.md"
fi

if [ -d "scripts_supabase" ]; then
    cp -r scripts_supabase "$TEMP_DIR/"
    echo "  ✅ scripts_supabase/"
fi

if [ -d "docs" ]; then
    cp -r docs "$TEMP_DIR/"
    echo "  ✅ docs/"
fi

if [ -f "COMPILAR_WINDOWS.md" ]; then
    cp COMPILAR_WINDOWS.md "$TEMP_DIR/"
    echo "  ✅ COMPILAR_WINDOWS.md"
fi

# ============================================
# LIMPIAR ARCHIVOS INNECESARIOS DENTRO DE LAS CARPETAS
# ============================================
echo ""
echo "🧹 Limpiando archivos innecesarios..."

# Eliminar archivos ephemeral de Flutter (se regeneran automáticamente)
if [ -d "$TEMP_DIR/windows/flutter/ephemeral" ]; then
    rm -rf "$TEMP_DIR/windows/flutter/ephemeral" 2>/dev/null || true
    echo "  ✅ Eliminado: windows/flutter/ephemeral/"
fi

# Eliminar archivos de ejemplo de plugins
find "$TEMP_DIR" -type d -path "*/example/*" -exec rm -rf {} + 2>/dev/null || true
find "$TEMP_DIR" -type d -path "*/test/*" -exec rm -rf {} + 2>/dev/null || true

# Eliminar __pycache__ si existe en assets o cualquier carpeta
find "$TEMP_DIR" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find "$TEMP_DIR" -type f -name "*.pyc" -delete 2>/dev/null || true

# Eliminar .DS_Store
find "$TEMP_DIR" -type f -name ".DS_Store" -delete 2>/dev/null || true

# Eliminar archivos temporales
find "$TEMP_DIR" -type f -name "*.tmp" -delete 2>/dev/null || true
find "$TEMP_DIR" -type f -name "*.log" -delete 2>/dev/null || true
find "$TEMP_DIR" -type f -name "*.swp" -delete 2>/dev/null || true
find "$TEMP_DIR" -type f -name "*~" -delete 2>/dev/null || true

# Eliminar archivos de build dentro de windows (si existen)
find "$TEMP_DIR/windows" -type d -name "build" -exec rm -rf {} + 2>/dev/null || true
find "$TEMP_DIR/windows" -type d -name "cmake-build-*" -exec rm -rf {} + 2>/dev/null || true

# ============================================
# CREAR ARCHIVO README PARA WINDOWS
# ============================================
cat > "$TEMP_DIR/LEEME_WINDOWS.txt" << 'EOF'
==========================================
SISTEMA TELMEX - INSTRUCCIONES DE COMPILACIÓN
==========================================

INSTRUCCIONES:
1. Asegúrate de tener Flutter instalado en Windows
2. Abre PowerShell en esta carpeta
3. Ejecuta: flutter pub get
4. Ejecuta: flutter build windows --release
5. El ejecutable estará en: build\windows\runner\Release\proyecto_telmex.exe

REQUISITOS:
- Flutter SDK instalado
- Windows 10 o superior
- Visual Studio con herramientas de C++ (para compilar)

NOTAS:
- No incluyas la carpeta build/ en el ZIP
- No incluyas .dart_tool/ en el ZIP
- No incluyas node_modules/ ni venv/ en el ZIP
- Estos archivos se regeneran automáticamente

SOPORTE:
Para problemas o consultas, contacta al equipo de desarrollo.
EOF

echo "  ✅ LEEME_WINDOWS.txt creado"

# ============================================
# CREAR ZIP
# ============================================
echo ""
echo "🗜️  Creando archivo ZIP..."
cd "$TEMP_DIR"
zip -r "../$ZIP_NAME" . -q -x "*.DS_Store" "*.log" "*.tmp" "*.swp" "*~" "*.pyc" "__pycache__/*" 2>/dev/null
cd ..

# Limpiar carpeta temporal
rm -rf "$TEMP_DIR"

# ============================================
# VERIFICAR Y MOSTRAR RESULTADO
# ============================================
if [ -f "$ZIP_NAME" ]; then
    echo ""
    echo "=========================================="
    echo "✅ ¡Proyecto comprimido exitosamente!"
    echo "=========================================="
    echo ""
    
    # Obtener tamaño del archivo
    ZIP_SIZE=$(du -h "$ZIP_NAME" | cut -f1)
    echo "📊 Información del archivo:"
    echo "   📦 Archivo: $ZIP_NAME"
    echo "   📏 Tamaño: $ZIP_SIZE"
    echo ""
    
    # Contar archivos en el ZIP
    FILE_COUNT=$(unzip -l "$ZIP_NAME" | tail -1 | awk '{print $2}')
    echo "📋 Contenido:"
    echo "   📄 Total de archivos: $FILE_COUNT"
    echo ""
    echo "   Estructura principal:"
    unzip -l "$ZIP_NAME" | grep -E "^[ ]*[0-9]+.*(lib/|windows/|assets/|pubspec)" | head -10 | awk '{print "   " $4}'
    echo ""
    
    echo "=========================================="
    echo "🚀 PRÓXIMOS PASOS:"
    echo "=========================================="
    echo "   1. Transfiere $ZIP_NAME a Windows"
    echo "   2. Extrae el contenido en una carpeta"
    echo "   3. Abre PowerShell en la carpeta extraída"
    echo "   4. Ejecuta: flutter pub get"
    echo "   5. Ejecuta: flutter build windows --release"
    echo ""
    echo "   El ejecutable estará en:"
    echo "   build\\windows\\runner\\Release\\proyecto_telmex.exe"
    echo ""
else
    echo ""
    echo "❌ Error: No se pudo crear el archivo ZIP"
    exit 1
fi






