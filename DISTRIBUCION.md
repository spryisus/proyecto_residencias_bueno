# 📦 Guía de Distribución - Sistema Telmex

## 🚀 Crear Ejecutables para Diferentes Plataformas

### 🐧 **Para Linux (Ubuntu/Debian)**

#### Opción 1: Usar el Script Automático
```bash
./build_executables.sh
```

#### Opción 2: Manual
```bash
flutter config --enable-linux-desktop
flutter build linux --release
```

**Ubicación del ejecutable:**
- `build/linux/x64/release/bundle/proyecto_telmex`

### 🪟 **Para Windows**

#### Requisitos:
1. **Instalar Flutter en Windows:**
   - Descargar desde: https://flutter.dev/docs/get-started/install/windows
   - Instalar Visual Studio con C++ workload

#### Pasos:
```bash
# 1. Habilitar Windows desktop
flutter config --enable-windows-desktop

# 2. Crear soporte para Windows
flutter create --platforms=windows .

# 3. Compilar en modo release
flutter build windows --release
```

**Ubicación del ejecutable:**
- `build/windows/x64/runner/Release/proyecto_telmex.exe`

### 🍎 **Para macOS**

```bash
flutter config --enable-macos-desktop
flutter build macos --release
```

**Ubicación del ejecutable:**
- `build/macos/Build/Products/Release/proyecto_telmex.app`

## 📱 **Para Móviles**

### Android APK
```bash
flutter build apk --release
```

**Ubicación:**
- `build/app/outputs/flutter-apk/app-release.apk`

### iOS (requiere macOS)
```bash
flutter build ios --release
```

## 🌐 **Para Web**

```bash
flutter build web --release
```

**Ubicación:**
- `build/web/`

## 🔧 **Crear Instaladores**

### Windows - NSIS
1. Instalar NSIS
2. Crear script `.nsi`
3. Compilar instalador

### Windows - Inno Setup
1. Descargar Inno Setup
2. Crear script `.iss`
3. Compilar instalador

### Linux - AppImage
```bash
# Instalar AppImageTool
wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x appimagetool-x86_64.AppImage
sudo mv appimagetool-x86_64.AppImage /usr/local/bin/appimagetool

# Crear AppImage
./build_executables.sh
```

## 🤖 **Compilación Automática con GitHub Actions**

El proyecto incluye un workflow de GitHub Actions que compila automáticamente para:
- ✅ Windows
- ✅ Linux
- ✅ Android

**Para usar:**
1. Subir código a GitHub
2. Ir a la pestaña "Actions"
3. Descargar artefactos compilados

## 📋 **Requisitos del Sistema**

### Windows
- Windows 10 o superior
- Visual Studio 2019/2022 con C++ workload
- Flutter SDK

### Linux
- Ubuntu 18.04+ o distribución compatible
- Clang/LLVM
- GTK development libraries

### macOS
- macOS 10.14 o superior
- Xcode 12 o superior
- Flutter SDK

## 🚀 **Distribución**

### Para Usuarios Finales:

#### Windows:
- Entregar `proyecto_telmex.exe`
- Crear instalador con NSIS/Inno Setup
- Incluir dependencias de Visual C++ Redistributable

#### Linux:
- Entregar AppImage (portable)
- O crear paquete `.deb` para Ubuntu/Debian
- O crear paquete `.rpm` para Red Hat/Fedora

#### Android:
- Entregar archivo `.apk`
- Subir a Google Play Store (opcional)

## 🔒 **Firma Digital**

Para distribución profesional, considera:
- Firmar ejecutables con certificado digital
- Firmar APKs para Android
- Usar certificados de Apple para iOS

## 📞 **Soporte**

Para problemas de compilación o distribución:
- Revisar logs de compilación
- Verificar requisitos del sistema
- Consultar documentación de Flutter

---

**Sistema Telmex - Inventarios y Envíos**  
*Desarrollado con Flutter*
