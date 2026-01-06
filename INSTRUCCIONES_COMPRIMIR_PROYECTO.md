# 📦 INSTRUCCIONES PARA COMPRIMIR EL PROYECTO PARA WINDOWS

## 🎯 OBJETIVO

Comprimir el proyecto Flutter para transferirlo a Windows y compilar el ejecutable.

## ✅ ARCHIVOS Y CARPETAS A INCLUIR

### 📁 CARPETAS ESENCIALES (INCLUIR SIEMPRE)

```
proyecto_residencia_2025_2026/
├── lib/                          ✅ CÓDIGO FUENTE (OBLIGATORIO)
├── windows/                      ✅ CONFIGURACIÓN WINDOWS (OBLIGATORIO)
├── assets/                       ✅ ASSETS (plantillas Excel)
├── pubspec.yaml                  ✅ CONFIGURACIÓN PROYECTO (OBLIGATORIO)
├── pubspec.lock                  ✅ LOCK DE DEPENDENCIAS (OBLIGATORIO)
├── analysis_options.yaml         ✅ CONFIGURACIÓN LINTER
├── .gitignore                    ✅ IGNORE (útil para referencia)
└── README.md                     ✅ DOCUMENTACIÓN
```

### 📁 CARPETAS OPCIONALES (ÚTILES PERO NO CRÍTICAS)

```
├── scripts_supabase/             ⚠️ Scripts SQL (útil para referencia)
├── docs/                         ⚠️ Documentación adicional
├── COMPILAR_WINDOWS.md           ⚠️ Guía de compilación
└── PROMPT_COMPILAR_WINDOWS.md    ⚠️ Prompt para IA
```

## ❌ ARCHIVOS Y CARPETAS A EXCLUIR

### 🚫 EXCLUIR (SE REGENERAN O NO SON NECESARIOS)

```
❌ build/                         (Se regenera al compilar)
❌ .dart_tool/                    (Se regenera con flutter pub get)
❌ android/                       (No necesario para Windows)
❌ ios/                           (No necesario para Windows)
❌ linux/                         (No necesario para Windows)
❌ macos/                         (No necesario para Windows)
❌ web/                           (No necesario para Windows)
❌ .git/                          (Muy pesado, no necesario)
❌ excel_generator_service/venv/ (Entorno virtual Python, MUY PESADO)
❌ dhl_tracking_proxy/node_modules/ (Si existe, muy pesado)
❌ *.log                          (Archivos de log)
❌ *.tmp                          (Archivos temporales)
❌ .DS_Store                       (Archivos de macOS)
❌ Thumbs.db                      (Archivos de Windows)
```

## 📝 SCRIPT PARA COMPRIMIR (Linux/Mac)

Si estás en Linux, puedes usar este script:

```bash
#!/bin/bash
# Script para comprimir proyecto para Windows

PROJECT_NAME="proyecto_residencia_2025_2026"
ZIP_NAME="proyecto_telmex_para_windows.zip"

echo "📦 Comprimiendo proyecto para Windows..."

# Crear carpeta temporal
TEMP_DIR="temp_compress"
mkdir -p "$TEMP_DIR"

# Copiar archivos esenciales
echo "📋 Copiando archivos esenciales..."
cp -r lib "$TEMP_DIR/"
cp -r windows "$TEMP_DIR/"
cp -r assets "$TEMP_DIR/"
cp pubspec.yaml "$TEMP_DIR/"
cp pubspec.lock "$TEMP_DIR/"
cp analysis_options.yaml "$TEMP_DIR/"
cp .gitignore "$TEMP_DIR/"
cp README.md "$TEMP_DIR/"

# Copiar documentación útil
if [ -d "scripts_supabase" ]; then
    cp -r scripts_supabase "$TEMP_DIR/"
fi

if [ -d "docs" ]; then
    cp -r docs "$TEMP_DIR/"
fi

if [ -f "COMPILAR_WINDOWS.md" ]; then
    cp COMPILAR_WINDOWS.md "$TEMP_DIR/"
fi

if [ -f "PROMPT_COMPILAR_WINDOWS.md" ]; then
    cp PROMPT_COMPILAR_WINDOWS.md "$TEMP_DIR/"
fi

# Crear ZIP
echo "🗜️ Creando archivo ZIP..."
cd "$TEMP_DIR"
zip -r "../$ZIP_NAME" . -x "*.DS_Store" "*.log" "*.tmp"
cd ..

# Limpiar carpeta temporal
rm -rf "$TEMP_DIR"

echo "✅ Proyecto comprimido: $ZIP_NAME"
echo "📊 Tamaño del archivo:"
ls -lh "$ZIP_NAME"
```

## 📝 COMANDO MANUAL (Linux/Mac)

Si prefieres hacerlo manualmente:

```bash
# Desde la carpeta del proyecto
zip -r proyecto_telmex_para_windows.zip \
  lib/ \
  windows/ \
  assets/ \
  pubspec.yaml \
  pubspec.lock \
  analysis_options.yaml \
  .gitignore \
  README.md \
  scripts_supabase/ \
  docs/ \
  COMPILAR_WINDOWS.md \
  PROMPT_COMPILAR_WINDOWS.md \
  -x "*.DS_Store" "*.log" "*.tmp"
```

## 📝 COMANDO MANUAL (Windows PowerShell)

Si ya estás en Windows y quieres comprimir:

```powershell
# Crear ZIP con archivos esenciales
Compress-Archive -Path `
  lib, `
  windows, `
  assets, `
  pubspec.yaml, `
  pubspec.lock, `
  analysis_options.yaml, `
  .gitignore, `
  README.md `
  -DestinationPath proyecto_telmex_para_windows.zip -Force
```

## 📊 TAMAÑO ESTIMADO

**Con archivos esenciales solamente:**
- `lib/`: ~500 KB - 2 MB (depende del código)
- `windows/`: ~50 KB
- `assets/`: ~100 KB - 500 KB (plantillas Excel)
- **Total estimado: ~1-3 MB** (muy manejable)

**Si incluyes documentación:**
- `scripts_supabase/`: ~50 KB
- `docs/`: ~100 KB
- **Total estimado: ~1.5-4 MB**

## ✅ VERIFICACIÓN ANTES DE COMPRIMIR

Antes de comprimir, verifica que tienes:

- [ ] Carpeta `lib/` con todo el código
- [ ] Carpeta `windows/` con configuración
- [ ] Archivo `pubspec.yaml`
- [ ] Archivo `pubspec.lock`
- [ ] Carpeta `assets/` (si la aplicación la usa)

## 🚀 DESPUÉS DE DESCOMPRIMIR EN WINDOWS

1. **Extraer** el ZIP en una carpeta
2. **Abrir PowerShell** en esa carpeta
3. **Ejecutar:**
   ```powershell
   flutter pub get
   flutter build windows --release
   ```

## 💡 CONSEJOS

1. **Tamaño del ZIP:** Si el ZIP es muy grande (>50 MB), probablemente incluiste carpetas que no debes (como `build/`, `.dart_tool/`, `venv/`)

2. **Verificar contenido:** Antes de enviar, verifica que el ZIP contiene lo esencial:
   - Debe tener `lib/`
   - Debe tener `pubspec.yaml`
   - Debe tener `windows/`

3. **Usar Git (alternativa):** Si el proyecto está en GitHub, es más fácil clonarlo en Windows:
   ```powershell
   git clone [URL_DEL_REPOSITORIO]
   ```

## 📞 SI ALGO FALLA

Si al descomprimir en Windows falta algo:
- Verifica que incluiste todas las carpetas esenciales
- Asegúrate de que `pubspec.yaml` está presente
- Ejecuta `flutter pub get` para regenerar dependencias

