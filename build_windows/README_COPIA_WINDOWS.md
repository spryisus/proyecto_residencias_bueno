# 📦 Crear Copia del Proyecto para Windows

Este documento explica cómo crear una copia completa del proyecto con solo los archivos necesarios para compilar en Windows.

## 🚀 Uso Rápido

### En Linux/macOS:
```bash
cd build_windows
./preparar_proyecto_windows.sh
```

### En Windows (con Git Bash o WSL):
```bash
cd build_windows
bash preparar_proyecto_windows.sh
```

## 📋 ¿Qué hace el script?

El script `preparar_proyecto_windows.sh` crea una copia del proyecto en `../proyecto_telmex_windows` que incluye:

### ✅ Archivos Incluidos:
- **lib/** - Todo el código fuente de Flutter
- **assets/** - Recursos (imágenes, plantillas Excel, etc.)
- **windows/** - Configuración específica de Windows
- **build_windows/** - Scripts de compilación y documentación
- **excel_generator_service/** - Servicio de exportación a Excel
- **pubspec.yaml** - Dependencias del proyecto
- **README_WINDOWS.md** - Documentación específica para Windows
- **INSTRUCCIONES.txt** - Guía rápida de uso

### ❌ Archivos Excluidos:
- **.git/** - Historial de Git (no necesario para compilar)
- **build/** - Archivos de compilación (se generarán en Windows)
- **android/**, **ios/**, **linux/**, **macos/** - Configuraciones de otras plataformas
- **node_modules/** - Dependencias de Node.js (si existen)
- Archivos temporales y de IDE

## 📁 Estructura Resultante

```
proyecto_telmex_windows/
├── lib/                          # Código fuente
├── assets/                       # Recursos
├── windows/                      # Configuración Windows
├── build_windows/                # Scripts de compilación
├── excel_generator_service/      # Servicio Excel
├── pubspec.yaml                  # Dependencias
├── README_WINDOWS.md             # Documentación
├── INSTRUCCIONES.txt             # Guía rápida
└── .gitignore                    # Ignorar archivos generados
```

## 🔄 Proceso Completo

1. **Ejecutar el script** (en Linux/macOS o WSL):
   ```bash
   ./build_windows/preparar_proyecto_windows.sh
   ```

2. **Copiar la carpeta a Windows**:
   - Usa USB, red compartida, o servicio en la nube
   - La carpeta será: `proyecto_telmex_windows/`

3. **En Windows, compilar**:
   ```bash
   cd proyecto_telmex_windows
   .\build_windows\verificar_requisitos.bat
   .\build_windows\build_release.bat
   ```

## 📝 Notas Importantes

- **Tamaño**: La copia será más pequeña que el proyecto completo (sin .git, build, etc.)
- **Dependencias**: Necesitarás ejecutar `flutter pub get` en Windows antes de compilar
- **Primera vez**: La primera compilación descargará todas las dependencias de Flutter

## 🛠️ Personalización

Si necesitas incluir archivos adicionales, edita el script `preparar_proyecto_windows.sh` y agrega las líneas correspondientes en la sección de copia.

## ❓ Preguntas Frecuentes

**P: ¿Puedo compilar directamente sin crear la copia?**
R: Sí, pero la copia es más limpia y fácil de transferir a otra máquina.

**P: ¿La copia incluye el historial de Git?**
R: No, solo los archivos necesarios para compilar. Si necesitas Git, copia la carpeta .git manualmente.

**P: ¿Puedo usar esta copia en otra máquina Windows?**
R: Sí, solo necesitas tener Flutter y Visual Studio instalados en esa máquina.








