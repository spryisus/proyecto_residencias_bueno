@echo off
REM Script para verificar que todos los requisitos estén instalados

echo ========================================
echo Verificando Requisitos para Compilación
echo ========================================
echo.

REM Verificar Flutter
echo [1/4] Verificando Flutter...
where flutter >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] Flutter está instalado
    flutter --version
) else (
    echo [ERROR] Flutter NO está instalado
    echo Descarga desde: https://flutter.dev/docs/get-started/install/windows
)
echo.

REM Verificar Visual Studio
echo [2/4] Verificando Visual Studio...
where cl >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] Visual Studio está instalado
) else (
    echo [ADVERTENCIA] Visual Studio puede no estar en el PATH
    echo Verifica que Visual Studio 2022 esté instalado con:
    echo - Desarrollo para el escritorio con C++
    echo - Herramientas de compilación de C++ para Windows
)
echo.

REM Verificar Git
echo [3/4] Verificando Git...
where git >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] Git está instalado
    git --version
) else (
    echo [ERROR] Git NO está instalado
    echo Descarga desde: https://git-scm.com/download/win
)
echo.

REM Verificar Flutter Doctor
echo [4/4] Ejecutando Flutter Doctor...
flutter doctor
echo.

echo ========================================
echo Verificación completada
echo ========================================
echo.
pause








