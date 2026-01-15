# 🪟 Guía para Compilar Ejecutable de Windows

Esta carpeta contiene todo lo necesario para generar el ejecutable de la aplicación Flutter para Windows.

## 🚀 Opción Rápida: Crear Copia del Proyecto

Si estás en Linux/macOS y quieres preparar el proyecto para compilar en Windows:

```bash
cd build_windows
./preparar_proyecto_windows.sh
```

Esto creará una carpeta `proyecto_telmex_windows/` con solo los archivos necesarios. Luego copia esa carpeta a tu máquina Windows.

📖 **Ver documentación completa**: `README_COPIA_WINDOWS.md`

## 📋 Requisitos Previos

Antes de compilar, asegúrate de tener instalado:

1. **Flutter SDK** (versión estable recomendada)
   - Descarga desde: https://flutter.dev/docs/get-started/install/windows
   - Verifica la instalación: `flutter doctor`

2. **Visual Studio 2022** (con componentes de desarrollo de escritorio de C++)
   - Descarga desde: https://visualstudio.microsoft.com/downloads/
   - Durante la instalación, selecciona:
     - "Desarrollo para el escritorio con C++"
     - "Herramientas de compilación de C++ para Windows"

3. **Git** (para clonar el repositorio)
   - Descarga desde: https://git-scm.com/download/win

4. **Windows 10/11** (64-bit)

## 🚀 Pasos para Compilar

### Opción 1: Usando el Script Automatizado (Recomendado)

1. Abre PowerShell o CMD como **Administrador**
2. Navega a la carpeta del proyecto:
   ```powershell
   cd ruta\al\proyecto_residencia_2025_2026
   ```
3. Ejecuta el script:
   ```powershell
   .\build_windows\build_release.bat
   ```
   O si prefieres PowerShell:
   ```powershell
   .\build_windows\build_release.ps1
   ```

### Opción 2: Compilación Manual

1. **Verifica que Flutter esté configurado correctamente:**
   ```bash
   flutter doctor
   ```
   Asegúrate de que no haya errores críticos.

2. **Obtén las dependencias:**
   ```bash
   flutter pub get
   ```

3. **Compila la aplicación en modo release:**
   ```bash
   flutter build windows --release
   ```

4. **El ejecutable estará en:**
   ```
   build\windows\x64\runner\Release\proyecto_telmex.exe
   ```

## 📦 Crear Instalador (Opcional)

Si deseas crear un instalador para distribuir la aplicación:

1. **Instala Inno Setup** (gratuito):
   - Descarga desde: https://jrsoftware.org/isdl.php

2. **Usa el script de instalador incluido:**
   - Edita `build_windows\create_installer.iss` con tus datos
   - Compila el instalador desde Inno Setup

## 🔧 Configuración Adicional

### Variables de Entorno

Asegúrate de que estas variables estén configuradas:
- `FLUTTER_ROOT`: Ruta a tu instalación de Flutter
- `PATH`: Debe incluir `%FLUTTER_ROOT%\bin`

### Verificar Plataforma Windows

```bash
flutter config --enable-windows-desktop
```

## 📝 Notas Importantes

- **Tiempo de compilación**: La primera compilación puede tardar 10-30 minutos
- **Tamaño del ejecutable**: El ejecutable final será de aproximadamente 50-100 MB
- **Dependencias**: El ejecutable incluye todas las dependencias necesarias
- **Antivirus**: Algunos antivirus pueden marcar el ejecutable como sospechoso (falso positivo)

## 🐛 Solución de Problemas

### Error: "Visual Studio no encontrado"
- Instala Visual Studio 2022 con los componentes mencionados arriba
- Ejecuta `flutter doctor` para verificar

### Error: "Flutter no reconocido"
- Verifica que Flutter esté en el PATH
- Reinicia la terminal después de instalar Flutter

### Error: "No se puede encontrar el SDK de Windows"
- Ejecuta: `flutter config --enable-windows-desktop`
- Verifica: `flutter doctor`

## 📞 Soporte

Si encuentras problemas durante la compilación:
1. Revisa los logs de compilación
2. Ejecuta `flutter doctor -v` para diagnóstico detallado
3. Consulta la documentación oficial: https://flutter.dev/docs/deployment/windows

