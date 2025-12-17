# Guía para Compilar Ejecutable de Windows

## Requisitos Previos

Para compilar la aplicación para Windows, necesitas:

1. **Windows 10/11** (64-bit)
2. **Flutter SDK** instalado en Windows
3. **Visual Studio 2022** con los siguientes componentes:
   - Desktop development with C++
   - Windows 10/11 SDK
   - MSVC v143 - VS 2022 C++ x64/x86 build tools

## Pasos para Compilar

### 1. Preparar el Proyecto (desde Linux)

Si estás en Linux, ejecuta el script de preparación:

```bash
chmod +x compilar_windows.sh
./compilar_windows.sh
```

Esto limpiará el proyecto y obtendrá todas las dependencias.

### 2. Transferir el Proyecto a Windows

Copia todo el proyecto a una máquina Windows. Puedes usar:
- USB
- Red compartida
- Git (recomendado)
- Compartir carpeta

### 3. Compilar en Windows

Abre **PowerShell** o **CMD** en la carpeta del proyecto y ejecuta:

```powershell
# Verificar que Flutter esté instalado
flutter doctor

# Obtener dependencias
flutter pub get

# Compilar en modo release
flutter build windows --release
```

### 4. Ubicación del Ejecutable

El ejecutable estará en:
```
build\windows\runner\Release\proyecto_telmex.exe
```

### 5. Distribuir la Aplicación

Para distribuir la aplicación, necesitas copiar:

1. **El ejecutable**: `proyecto_telmex.exe`
2. **Las DLLs necesarias**: Están en la misma carpeta `Release/`
3. **La carpeta `data`**: Contiene los assets de Flutter

**Carpeta completa a distribuir:**
```
Release/
├── proyecto_telmex.exe
├── flutter_windows.dll
├── (otras DLLs necesarias)
└── data/
    └── (assets de Flutter)
```

## Crear un Instalador (Opcional)

### Opción 1: Inno Setup (Recomendado)

1. Descarga e instala [Inno Setup](https://jrsoftware.org/isdl.php)
2. Usa el script `installer/sistema_telmex.iss` (si existe)
3. O crea un nuevo script de instalación

### Opción 2: NSIS

1. Descarga e instala [NSIS](https://nsis.sourceforge.io/Download)
2. Usa el script `installer/sistema_telmex.nsi` (si existe)

### Opción 3: Script PowerShell Simple

Puedes crear un script que empaquete todo en un ZIP:

```powershell
# Crear carpeta de distribución
New-Item -ItemType Directory -Force -Path "distribucion"

# Copiar ejecutable y DLLs
Copy-Item "build\windows\runner\Release\*" -Destination "distribucion\" -Recurse

# Crear ZIP
Compress-Archive -Path "distribucion\*" -DestinationPath "Sistema_Telmex_Windows.zip"
```

## Compilación desde Linux (Cross-Compilation)

**Nota:** Flutter no soporta cross-compilation nativa de Linux a Windows. Debes compilar en Windows.

Sin embargo, si tienes acceso a una máquina Windows remota, puedes:

1. Usar **Git** para sincronizar el código
2. Usar **SSH** o **RDP** para conectarte a Windows
3. Compilar remotamente

## Solución de Problemas

### Error: "Windows toolchain not found"

Instala Visual Studio 2022 con los componentes mencionados arriba.

### Error: "MSBuild not found"

Asegúrate de tener Visual Studio instalado y ejecuta desde el "Developer Command Prompt for VS 2022".

### Error: "Flutter not found"

Asegúrate de tener Flutter en el PATH de Windows:
```powershell
# Agregar Flutter al PATH (temporal)
$env:Path += ";C:\src\flutter\bin"
```

### El ejecutable no funciona en otra PC

Asegúrate de copiar todas las DLLs y la carpeta `data` junto con el ejecutable.

## Comandos Útiles

```powershell
# Verificar configuración de Flutter
flutter doctor -v

# Limpiar build anterior
flutter clean

# Obtener dependencias
flutter pub get

# Compilar en modo debug (más rápido, pero más pesado)
flutter build windows

# Compilar en modo release (optimizado)
flutter build windows --release

# Ver tamaño del ejecutable
Get-Item "build\windows\runner\Release\proyecto_telmex.exe" | Select-Object Name, Length
```

## Notas Importantes

- El ejecutable de Windows requiere **Windows 10 o superior**
- Asegúrate de tener todas las dependencias nativas instaladas
- El primer build puede tardar varios minutos
- Los builds subsecuentes son más rápidos

## Contacto

Si tienes problemas al compilar, verifica:
1. Que Flutter esté actualizado: `flutter upgrade`
2. Que todas las dependencias estén instaladas: `flutter doctor`
3. Que el proyecto compile sin errores: `flutter analyze`


