# Script de PowerShell para compilar el proyecto en Windows
# Ejecutar desde PowerShell: .\compilar_windows.ps1

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Compilando Sistema Telmex para Windows" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar que Flutter esté instalado
Write-Host "Verificando Flutter..." -ForegroundColor Yellow
$flutterVersion = flutter --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Flutter no está instalado o no está en el PATH" -ForegroundColor Red
    Write-Host "Por favor, instala Flutter desde: https://flutter.dev/docs/get-started/install/windows" -ForegroundColor Red
    exit 1
}
Write-Host "Flutter encontrado" -ForegroundColor Green
Write-Host ""

# Verificar configuración de Flutter
Write-Host "Verificando configuración de Flutter..." -ForegroundColor Yellow
flutter doctor
Write-Host ""

# Limpiar builds anteriores
Write-Host "Limpiando builds anteriores..." -ForegroundColor Yellow
flutter clean
Write-Host ""

# Obtener dependencias
Write-Host "Obteniendo dependencias..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: No se pudieron obtener las dependencias" -ForegroundColor Red
    exit 1
}
Write-Host "Dependencias obtenidas correctamente" -ForegroundColor Green
Write-Host ""

# Analizar el código
Write-Host "Analizando código..." -ForegroundColor Yellow
flutter analyze
Write-Host ""

# Compilar en modo release
Write-Host "Compilando en modo RELEASE..." -ForegroundColor Yellow
Write-Host "Esto puede tardar varios minutos..." -ForegroundColor Yellow
flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: La compilación falló" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Verificar que el ejecutable existe
$exePath = "build\windows\runner\Release\proyecto_telmex.exe"
if (Test-Path $exePath) {
    $fileInfo = Get-Item $exePath
    $fileSizeMB = [math]::Round($fileInfo.Length / 1MB, 2)
    
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "¡Compilación exitosa!" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Ejecutable creado en:" -ForegroundColor Cyan
    Write-Host "$(Resolve-Path $exePath)" -ForegroundColor White
    Write-Host ""
    Write-Host "Tamaño: $fileSizeMB MB" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Para distribuir la aplicación, copia:" -ForegroundColor Yellow
    Write-Host "1. El ejecutable: proyecto_telmex.exe" -ForegroundColor White
    Write-Host "2. Todas las DLLs en la carpeta Release" -ForegroundColor White
    Write-Host "3. La carpeta 'data' completa" -ForegroundColor White
    Write-Host ""
    Write-Host "Carpeta completa: build\windows\runner\Release\" -ForegroundColor Cyan
    Write-Host ""
    
    # Preguntar si quiere abrir la carpeta
    $openFolder = Read-Host "¿Deseas abrir la carpeta del ejecutable? (S/N)"
    if ($openFolder -eq "S" -or $openFolder -eq "s") {
        explorer.exe "build\windows\runner\Release"
    }
} else {
    Write-Host "ERROR: El ejecutable no se encontró después de la compilación" -ForegroundColor Red
    exit 1
}


