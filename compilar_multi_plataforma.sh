#!/bin/bash

# Script para compilar Sistema Telmex para múltiples dispositivos
echo "🚀 Sistema Telmex - Compilador Multiplataforma"
echo "============================================="

# Verificar dispositivos disponibles
echo "📱 Dispositivos disponibles:"
flutter devices
echo ""

# Función para compilar Android
compile_android() {
    echo "📱 Compilando para Android (Moto G53)..."
    flutter build apk --release --target-platform android-arm64 -d ZY22GM9L3K
    
    if [ $? -eq 0 ]; then
        echo "✅ APK creado exitosamente"
        echo "📁 Ubicación: build/app/outputs/flutter-apk/app-release.apk"
    else
        echo "❌ Error al compilar para Android"
        return 1
    fi
}

# Función para compilar Linux
compile_linux() {
    echo "🐧 Compilando para Linux..."
    flutter build linux --release -d linux
    
    if [ $? -eq 0 ]; then
        echo "✅ Ejecutable Linux creado exitosamente"
        echo "📁 Ubicación: build/linux/x64/release/bundle/proyecto_telmex"
    else
        echo "❌ Error al compilar para Linux"
        return 1
    fi
}

# Función para compilar Web
compile_web() {
    echo "🌐 Compilando para Web..."
    flutter build web --release -d chrome
    
    if [ $? -eq 0 ]; then
        echo "✅ Aplicación Web creada exitosamente"
        echo "📁 Ubicación: build/web/"
    else
        echo "❌ Error al compilar para Web"
        return 1
    fi
}

# Menú principal
echo "¿Qué plataforma deseas compilar?"
echo "1) Solo Android (Moto G53)"
echo "2) Solo Linux"
echo "3) Solo Web"
echo "4) Android + Linux"
echo "5) Todas las plataformas"
echo ""
read -p "Selecciona una opción (1-5): " choice

case $choice in
    1)
        compile_android
        ;;
    2)
        compile_linux
        ;;
    3)
        compile_web
        ;;
    4)
        compile_android
        compile_linux
        ;;
    5)
        compile_android
        compile_linux
        compile_web
        ;;
    *)
        echo "❌ Opción inválida"
        exit 1
        ;;
esac

echo ""
echo "🎉 ¡Compilación completada!"
echo "📧 Para soporte técnico, contacta al equipo de desarrollo"
