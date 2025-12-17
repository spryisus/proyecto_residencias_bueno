@echo off
REM Script para iniciar el servidor de generación de Excel en Windows
REM Este script activa el entorno virtual y ejecuta el servidor con uvicorn

echo ========================================
echo   Excel Generator Service
echo ========================================
echo.

REM Obtener el directorio del script
cd /d "%~dp0"

REM Verificar si existe el entorno virtual
if not exist "venv" (
    echo Creando entorno virtual...
    python -m venv venv
    echo Entorno virtual creado
)

REM Activar el entorno virtual
echo Activando entorno virtual...
call venv\Scripts\activate.bat

REM Instalar dependencias si es necesario
if not exist "venv\.dependencies_installed" (
    echo Instalando dependencias...
    pip install -r requirements.txt
    echo. > venv\.dependencies_installed
    echo Dependencias instaladas
)

echo.
echo Iniciando servidor en http://localhost:8001
echo Presiona Ctrl+C para detener el servidor
echo.
echo Hot Reload activado: El servidor se recargara automaticamente al detectar cambios
echo Archivos monitoreados: *.py en el directorio actual
echo.

REM Iniciar el servidor con uvicorn
REM --reload: Activa el hot reload automatico
REM --reload-dir: Especifica directorios adicionales a monitorear
REM --reload-include: Incluye archivos especificos para monitorear
uvicorn main:app --host 0.0.0.0 --port 8001 --reload --reload-dir . --reload-include "*.py"

