# Script para crear un paquete ZIP listo para distribuir
# Ejecutar desde PowerShell: .\crear_paquete_windows.ps1

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Creando paquete de distribución Windows" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$releaseFolder = "build\windows\runner\Release"
$packageName = "Sistema_Telmex_Windows"

# Verificar que existe la carpeta Release
if (-not (Test-Path $releaseFolder)) {
    Write-Host "ERROR: No se encontró la carpeta Release" -ForegroundColor Red
    Write-Host "Por favor, compila primero el proyecto con: flutter build windows --release" -ForegroundColor Red
    exit 1
}

# Verificar que existe el ejecutable
$exePath = Join-Path $releaseFolder "proyecto_telmex.exe"
if (-not (Test-Path $exePath)) {
    Write-Host "ERROR: No se encontró el ejecutable" -ForegroundColor Red
    exit 1
}

# Crear carpeta temporal para el paquete
$tempFolder = "distribucion_temp"
if (Test-Path $tempFolder) {
    Remove-Item $tempFolder -Recurse -Force
}
New-Item -ItemType Directory -Path $tempFolder | Out-Null

Write-Host "Copiando archivos..." -ForegroundColor Yellow

# Copiar todos los archivos de Release
Copy-Item "$releaseFolder\*" -Destination $tempFolder -Recurse -Force

# Crear archivo README
$readmeContent = @"
Sistema Telmex - Instalación
============================

INSTRUCCIONES DE INSTALACIÓN:
1. Extrae todos los archivos de este ZIP en una carpeta
2. Ejecuta proyecto_telmex.exe
3. No elimines ninguna DLL ni la carpeta 'data'

REQUISITOS:
- Windows 10 o superior (64-bit)
- Conexión a Internet (para conectar con la base de datos)

NOTAS:
- No es necesario instalar nada adicional
- Todos los archivos deben estar en la misma carpeta
- La primera ejecución puede tardar un poco más

SOPORTE:
Para problemas o consultas, contacta al equipo de desarrollo.

Versión: 1.0.0
Fecha: $(Get-Date -Format "dd/MM/yyyy")
"@

$readmeContent | Out-File -FilePath "$tempFolder\LEEME.txt" -Encoding UTF8

# Crear ZIP
$zipPath = "$packageName.zip"
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

Write-Host "Creando archivo ZIP..." -ForegroundColor Yellow
Compress-Archive -Path "$tempFolder\*" -DestinationPath $zipPath -CompressionLevel Optimal

# Limpiar carpeta temporal
Remove-Item $tempFolder -Recurse -Force

# Información del paquete
$zipInfo = Get-Item $zipPath
$zipSizeMB = [math]::Round($zipInfo.Length / 1MB, 2)

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "¡Paquete creado exitosamente!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Archivo creado: $zipPath" -ForegroundColor Cyan
Write-Host "Tamaño: $zipSizeMB MB" -ForegroundColor Cyan
Write-Host ""
Write-Host "El paquete está listo para distribuir." -ForegroundColor Green
Write-Host ""

# Preguntar si quiere abrir la carpeta
$openFolder = Read-Host "¿Deseas abrir la carpeta del paquete? (S/N)"
if ($openFolder -eq "S" -or $openFolder -eq "s") {
    explorer.exe (Get-Location)
}


