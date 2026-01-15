@echo off
echo ========================================
echo    SIBE PR - Compilacion para Windows
echo ========================================
echo.

echo [1/3] Instalando dependencias de Flutter...
call flutter pub get
if errorlevel 1 (
    echo ERROR: No se pudieron instalar las dependencias
    pause
    exit /b 1
)
echo.

echo [2/3] Compilando aplicacion en modo Release...
call flutter build windows --release
if errorlevel 1 (
    echo ERROR: La compilacion fallo
    pause
    exit /b 1
)
echo.

echo [3/3] Compilacion completada exitosamente!
echo.
echo El ejecutable esta en: build\windows\x64\runner\Release\
echo.
pause
