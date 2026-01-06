# 🪟 PROMPT PARA COMPILAR EJECUTABLE WINDOWS

## 📋 INSTRUCCIONES PARA LA IA

Copia y pega este prompt completo cuando uses Cursor, ChatGPT, Claude o cualquier IA en Windows:

---

## 🎯 CONTEXTO DEL PROYECTO

Soy el desarrollador de una aplicación Flutter llamada **"proyecto_telmex"** (Sistema de Inventarios Telmex). Necesito compilar un ejecutable para Windows (.exe) desde este proyecto Flutter.

**Información del proyecto:**
- **Nombre:** proyecto_telmex
- **Versión:** 1.0.0+1
- **Flutter SDK:** ^3.6.1
- **Tipo:** Aplicación de escritorio Flutter para Windows
- **Dependencias principales:** Supabase, HTTP, Mobile Scanner, Excel, etc.

**Estructura importante del proyecto:**
- Carpeta principal: `proyecto_residencia_2025_2026/`
- Código fuente: `lib/`
- Configuración: `pubspec.yaml`
- Assets: `assets/` (plantillas Excel)
- Windows config: `windows/`

## 🎯 OBJETIVO

Necesito que me ayudes a:
1. **Verificar** que el entorno de Flutter en Windows esté correctamente configurado
2. **Compilar** la aplicación en modo Release para Windows
3. **Crear** un paquete distribuible con el ejecutable y todas sus dependencias (DLLs, assets)
4. **Opcionalmente:** Crear un instalador o ZIP listo para distribuir

## 📝 PASOS A SEGUIR

### PASO 1: Verificar Entorno

Primero, verifica que tengo todo lo necesario:

```powershell
# Verificar Flutter
flutter doctor -v

# Verificar que Windows está habilitado
flutter doctor
```

**Requisitos esperados:**
- ✅ Flutter SDK instalado
- ✅ Visual Studio 2022 con "Desktop development with C++"
- ✅ Windows 10/11 SDK
- ✅ MSVC v143 build tools

Si falta algo, **dime exactamente qué instalar y cómo**.

### PASO 2: Preparar el Proyecto

```powershell
# Navegar a la carpeta del proyecto
cd [RUTA_DEL_PROYECTO]

# Limpiar builds anteriores
flutter clean

# Obtener todas las dependencias
flutter pub get

# Verificar que no hay errores
flutter analyze
```

Si hay errores, **ayúdame a solucionarlos**.

### PASO 3: Compilar para Windows

```powershell
# Compilar en modo Release (optimizado)
flutter build windows --release
```

**Si hay errores durante la compilación:**
- Analiza el mensaje de error completo
- Proporcióname la solución específica
- Si es necesario, modifica archivos de configuración

### PASO 4: Verificar el Ejecutable

El ejecutable debería estar en:
```
build\windows\runner\Release\proyecto_telmex.exe
```

Verifica que existe y dime su tamaño.

### PASO 5: Crear Paquete Distribuible

Necesito un script o instrucciones para crear un paquete que incluya:
- ✅ El ejecutable: `proyecto_telmex.exe`
- ✅ Todas las DLLs necesarias (están en la carpeta Release)
- ✅ La carpeta `data/` con los assets de Flutter
- ✅ Cualquier otro archivo necesario

**Crea un script PowerShell** que:
1. Cree una carpeta `distribucion/`
2. Copie todos los archivos necesarios
3. Opcionalmente: Cree un ZIP con todo

### PASO 6: Probar el Ejecutable

Antes de finalizar, verifica que:
- El ejecutable se ejecuta correctamente
- No faltan DLLs
- Los assets se cargan correctamente

## 🔧 SOLUCIÓN DE PROBLEMAS

Si encuentras algún problema:

1. **Error de compilación:**
   - Muestra el error completo
   - Analiza la causa
   - Proporciona la solución paso a paso

2. **Faltan dependencias:**
   - Identifica qué falta
   - Proporciona comandos para instalarlo

3. **El ejecutable no funciona:**
   - Verifica que todas las DLLs estén presentes
   - Verifica que la carpeta `data/` esté incluida
   - Revisa los logs de error si los hay

## 📦 ARCHIVOS IMPORTANTES A INCLUIR AL COMPRIMIR

**INCLUIR:**
- ✅ `lib/` (todo el código fuente)
- ✅ `pubspec.yaml` y `pubspec.lock`
- ✅ `windows/` (configuración de Windows)
- ✅ `assets/` (plantillas Excel)
- ✅ `analysis_options.yaml`
- ✅ `.gitignore` (para saber qué excluir)

**EXCLUIR al comprimir (para reducir tamaño):**
- ❌ `build/` (se regenera)
- ❌ `.dart_tool/` (se regenera)
- ❌ `android/` (no necesario para Windows)
- ❌ `ios/` (no necesario para Windows)
- ❌ `linux/` (no necesario para Windows)
- ❌ `macos/` (no necesario para Windows)
- ❌ `web/` (no necesario para Windows)
- ❌ `excel_generator_service/venv/` (entorno virtual Python, muy pesado)
- ❌ `dhl_tracking_proxy/node_modules/` (si existe)
- ❌ `.git/` (si existe, es muy pesado)
- ❌ Archivos temporales y logs

## 🎯 RESULTADO ESPERADO

Al final, necesito:
1. ✅ Un ejecutable funcional: `proyecto_telmex.exe`
2. ✅ Un paquete completo con todas las dependencias
3. ✅ Instrucciones claras de cómo distribuir la aplicación
4. ✅ (Opcional) Un instalador o ZIP listo para usar

## 💡 NOTAS ADICIONALES

- La aplicación se conecta a Supabase (backend en la nube)
- Usa servicios externos (Excel generator service, DHL tracking proxy)
- Tiene assets (plantillas Excel) que deben estar accesibles
- Es una aplicación de escritorio completa con múltiples pantallas

**Por favor, guíame paso a paso y si algo falla, ayúdame a solucionarlo.**

---

## 📝 COMANDOS RÁPIDOS DE REFERENCIA

```powershell
# Verificar Flutter
flutter doctor -v

# Limpiar y preparar
flutter clean
flutter pub get

# Compilar
flutter build windows --release

# Ubicación del ejecutable
# build\windows\runner\Release\proyecto_telmex.exe
```

---

**¡Gracias por tu ayuda!** 🚀

