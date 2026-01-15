# 📋 Requisitos Detallados para Compilación en Windows

## 🔧 Software Necesario

### 1. Flutter SDK
- **Versión**: 3.x o superior (recomendado: última estable)
- **Descarga**: https://flutter.dev/docs/get-started/install/windows
- **Instalación**:
  1. Descarga el ZIP de Flutter
  2. Extrae a `C:\src\flutter` (o la ubicación que prefieras)
  3. Agrega `C:\src\flutter\bin` al PATH del sistema
  4. Reinicia la terminal
  5. Verifica: `flutter doctor`

### 2. Visual Studio 2022
- **Versión**: Community, Professional o Enterprise
- **Descarga**: https://visualstudio.microsoft.com/downloads/
- **Componentes Requeridos**:
  - ✅ Desarrollo para el escritorio con C++
  - ✅ Herramientas de compilación de C++ para Windows
  - ✅ Windows 10/11 SDK (última versión)
  - ✅ CMake tools para Windows

### 3. Git
- **Versión**: Cualquier versión reciente
- **Descarga**: https://git-scm.com/download/win
- **Uso**: Para clonar el repositorio y gestionar versiones

### 4. Windows
- **Versión**: Windows 10 (64-bit) o superior
- **Arquitectura**: x64

## ✅ Verificación de Instalación

Ejecuta el script de verificación:
```bash
.\build_windows\verificar_requisitos.bat
```

O verifica manualmente:
```bash
flutter doctor
```

Deberías ver algo como:
```
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 3.x.x, ...)
[✓] Windows Version (Installed version of Windows is version 10 or higher)
[✓] Android toolchain - develop for Android devices
[✓] Chrome - develop for the web
[✓] Visual Studio - develop for Windows (Visual Studio Build Tools 2022)
[✓] Android Studio
[✓] VS Code
[✓] Connected device
[✓] Network resources
```

## 🔍 Solución de Problemas Comunes

### Flutter no reconocido
**Problema**: `'flutter' no se reconoce como un comando`

**Solución**:
1. Verifica que Flutter esté en el PATH
2. Reinicia la terminal después de agregar al PATH
3. Verifica: `echo %PATH%` (debe incluir la ruta a Flutter)

### Visual Studio no encontrado
**Problema**: `Visual Studio - develop for Windows` muestra error

**Solución**:
1. Instala Visual Studio 2022 con los componentes mencionados
2. Ejecuta: `flutter config --enable-windows-desktop`
3. Reinicia la terminal

### Error de compilación
**Problema**: Errores durante `flutter build windows`

**Solución**:
1. Ejecuta `flutter clean`
2. Ejecuta `flutter pub get`
3. Verifica que Visual Studio esté correctamente instalado
4. Revisa los logs de error para más detalles

## 📚 Recursos Adicionales

- **Documentación oficial de Flutter para Windows**: 
  https://flutter.dev/docs/deployment/windows

- **Guía de instalación de Flutter**: 
  https://flutter.dev/docs/get-started/install/windows

- **Foro de Flutter**: 
  https://stackoverflow.com/questions/tagged/flutter

## 💡 Tips

1. **Primera compilación**: Puede tardar 10-30 minutos (descarga dependencias)
2. **Compilaciones subsecuentes**: Mucho más rápidas (2-5 minutos)
3. **Modo Debug vs Release**: 
   - Debug: Más rápido, incluye información de depuración
   - Release: Optimizado, más pequeño, listo para distribución

4. **Tamaño del ejecutable**: 
   - Ejecutable solo: ~50-100 MB
   - Con todas las DLLs: ~150-200 MB








