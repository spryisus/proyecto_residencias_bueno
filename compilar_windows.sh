#!/bin/bash

# Script para preparar la compilación de Windows
# Este script prepara el proyecto para ser compilado en Windows

echo "=========================================="
echo "Preparando proyecto para compilación Windows"
echo "=========================================="

# Limpiar builds anteriores
echo "Limpiando builds anteriores..."
flutter clean

# Obtener dependencias
echo "Obteniendo dependencias..."
flutter pub get

# Verificar que el proyecto esté listo
echo "Verificando configuración..."
flutter analyze

echo ""
echo "=========================================="
echo "Proyecto preparado para compilación"
echo "=========================================="
echo ""
echo "Para compilar en Windows, ejecuta en una máquina Windows:"
echo ""
echo "1. Asegúrate de tener Flutter instalado en Windows"
echo "2. Abre PowerShell o CMD en la carpeta del proyecto"
echo "3. Ejecuta: flutter pub get"
echo "4. Ejecuta: flutter build windows --release"
echo ""
echo "El ejecutable estará en:"
echo "build/windows/runner/Release/proyecto_telmex.exe"
echo ""
echo "Para crear un instalador, puedes usar:"
echo "- Inno Setup (Windows)"
echo "- NSIS (Nullsoft Scriptable Install System)"
echo ""


