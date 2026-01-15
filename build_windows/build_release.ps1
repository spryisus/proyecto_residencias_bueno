# Script PowerShell para compilar la aplicación Flutter para Windows en modo Release
# Ejecutar desde la raíz del proyecto

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Compilando proyecto_telmex para Windows" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar que Flutter esté instalado
$flutterPath = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterPath) {
    Write-Host "[ERROR] Flutter no está instalado o no está en el PATH" -ForegroundColor Red
    Write-Host "Por favor, instala Flutter desde https://flutter.dev" -ForegroundColor Yellow
    Read-Host "Presiona Enter para salir"
    exit 1
}

Write-Host "[1/5] Verificando instalación de Flutter..." -ForegroundColor Yellow
flutter doctor
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ADVERTENCIA] Hay problemas con la instalación de Flutter" -ForegroundColor Yellow
    Write-Host "Revisa los mensajes anteriores" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host ""
Write-Host "[2/5] Habilitando soporte para Windows Desktop..." -ForegroundColor Yellow
flutter config --enable-windows-desktop

Write-Host ""
Write-Host "[3/5] Obteniendo dependencias..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Error al obtener dependencias" -ForegroundColor Red
    Read-Host "Presiona Enter para salir"
    exit 1
}

Write-Host ""
Write-Host "[4/5] Limpiando compilaciones anteriores..." -ForegroundColor Yellow
flutter clean

Write-Host ""
Write-Host "[5/5] Compilando en modo Release..." -ForegroundColor Yellow
Write-Host "Esto puede tardar varios minutos..." -ForegroundColor Gray
flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Error durante la compilación" -ForegroundColor Red
    Read-Host "Presiona Enter para salir"
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Compilación completada exitosamente!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "El ejecutable se encuentra en:" -ForegroundColor Cyan
Write-Host "build\windows\x64\runner\Release\proyecto_telmex.exe" -ForegroundColor White
Write-Host ""
Read-Host "Presiona Enter para salir"








