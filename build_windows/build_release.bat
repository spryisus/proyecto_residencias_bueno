@echo off
REM Script para compilar la aplicación Flutter para Windows en modo Release
REM Ejecutar desde la raíz del proyecto

echo ========================================
echo Compilando proyecto_telmex para Windows
echo ========================================
echo.

REM Verificar que Flutter esté instalado
where flutter >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Flutter no está instalado o no está en el PATH
    echo Por favor, instala Flutter desde https://flutter.dev
    pause
    exit /b 1
)

echo [1/5] Verificando instalación de Flutter...
flutter doctor
if %ERRORLEVEL% NEQ 0 (
    echo [ADVERTENCIA] Hay problemas con la instalación de Flutter
    echo Revisa los mensajes anteriores
    echo.
)

echo.
echo [2/5] Habilitando soporte para Windows Desktop...
flutter config --enable-windows-desktop

echo.
echo [3/5] Obteniendo dependencias...
flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Error al obtener dependencias
    pause
    exit /b 1
)

echo.
echo [4/5] Limpiando compilaciones anteriores...
flutter clean

echo.
echo [5/5] Compilando en modo Release...
echo Esto puede tardar varios minutos...
flutter build windows --release
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Error durante la compilación
    pause
    exit /b 1
)

echo.
echo ========================================
echo Compilación completada exitosamente!
echo ========================================
echo.
echo El ejecutable se encuentra en:
echo build\windows\x64\runner\Release\proyecto_telmex.exe
echo.
pause








