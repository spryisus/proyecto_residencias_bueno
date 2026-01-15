# SIBE PR - Build para Windows

## 📋 Requisitos Previos

1. **Flutter SDK** (versión estable)
   - Descargar desde: https://flutter.dev/docs/get-started/install/windows
   - Agregar Flutter al PATH

2. **Visual Studio 2022** o superior
   - Con componentes: "Desktop development with C++"
   - Incluir: Windows 10/11 SDK

3. **Python 3.8+** (para el servicio de Excel)
   - Descargar desde: https://www.python.org/downloads/

## 🚀 Instalación y Compilación

### 1. Instalar dependencias de Flutter
```bash
flutter pub get
```

### 2. Configurar el servicio de Excel (Opcional - si usas servidor local)

#### Opción A: Usar servidor de producción (Recomendado)
El programa está configurado para usar el servidor de Render por defecto.
No necesitas configurar nada adicional.

#### Opción B: Usar servidor local
```bash
cd excel_generator_service
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python -m uvicorn main:app --host 0.0.0.0 --port 8001
```

### 3. Compilar para Windows
```bash
flutter build windows --release
```

El ejecutable estará en: `build\windows\x64\runner\Release\`

## 📁 Estructura de Archivos

```
SIBE_PR_Windows_Build/
├── lib/                    # Código fuente Flutter
├── windows/                # Configuración Windows
├── linux/                  # Configuración Linux
├── assets/                 # Recursos (imágenes, plantillas)
├── excel_generator_service/ # Servicio Python para exportar Excel
├── pubspec.yaml           # Dependencias Flutter
└── README.md              # Este archivo
```

## ⚙️ Configuración

### URL del Servicio Excel
El programa usa el servidor de Render por defecto. Si necesitas cambiar la configuración:

1. Editar: `lib/app/config/excel_service_config.dart`
2. Cambiar `useProductionByDefault` según necesites

## 🐛 Solución de Problemas

### Error: "No se puede conectar al servicio de Excel"
- Verifica tu conexión a internet (el servidor de Render requiere internet)
- O inicia el servidor local siguiendo las instrucciones arriba

### Error al compilar
- Verifica que Visual Studio esté instalado correctamente
- Ejecuta: `flutter doctor` para verificar la configuración

## 📝 Notas

- El programa está configurado para usar el servidor de producción (Render) por defecto
- Si el servidor de producción no está disponible, intentará usar el servidor local automáticamente
- Para desarrollo local, puedes cambiar `useProductionByDefault = false` en `excel_service_config.dart`


