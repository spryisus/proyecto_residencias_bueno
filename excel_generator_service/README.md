# Excel Generator Service

Servicio FastAPI para generar archivos Excel de inventarios con formato profesional.

## Endpoints Disponibles

### 1. `/api/generate-jumpers-excel` (POST)
Genera un archivo Excel para inventarios de jumpers.

**Request Body:**
```json
{
  "items": [
    {
      "tipo": "SC-SC",
      "tamano": 5,
      "cantidad": 10,
      "rack": "RACK-01",
      "contenedor": "CONT-01"
    }
  ]
}
```

**Campos soportados:**
- `tipo` o `categoryName`: Tipo de jumper (ej: "SC-SC", "FC-FC")
- `tamano` o `size`: Tamaño en metros
- `cantidad` o `quantity`: Cantidad
- `rack`: Rack donde se encuentra
- `contenedor` o `container`: Contenedor

### 2. `/api/generate-computo-excel` (POST)
Genera un archivo Excel para inventarios de equipo de cómputo.

**Request Body:**
```json
{
  "items": [
    {
      "equipo": "Laptop",
      "marca": "Dell",
      "modelo": "Latitude 5420",
      "serie": "ABC123",
      "cantidad": 1,
      "ubicacion": "Oficina Central",
      "estado": "Funcionando"
    }
  ]
}
```

**Campos soportados:**
- `equipo` o `nombre`: Nombre del equipo
- `marca`: Marca del equipo
- `modelo`: Modelo
- `serie` o `serial`: Número de serie
- `cantidad` o `quantity`: Cantidad
- `ubicacion` o `location`: Ubicación
- `estado` o `status`: Estado del equipo

### 3. `/api/generate-sdr-excel` (POST)
Genera un archivo Excel para formatos SDR.

**Request Body:**
```json
{
  "items": [
    {
      "codigo": "SDR-001",
      "descripcion": "Descripción del item",
      "cantidad": 5,
      "ubicacion": "Almacén A",
      "fecha": "2025-12-08",
      "observaciones": "Notas adicionales"
    }
  ]
}
```

**Campos soportados:**
- `codigo` o `code`: Código del item
- `descripcion` o `description`: Descripción
- `cantidad` o `quantity`: Cantidad
- `ubicacion` o `location`: Ubicación
- `fecha` o `date`: Fecha
- `observaciones` o `notes`: Observaciones

### 4. `/health` (GET)
Verifica el estado del servicio y las plantillas disponibles.

**Response:**
```json
{
  "ok": true,
  "templates": {
    "jumpers": false,
    "computo": false,
    "sdr": false
  }
}
```

### 5. `/api/debug-last-file` (GET)
Obtiene información del último archivo generado (útil para debugging).

## Plantillas

El servicio puede usar plantillas personalizadas si están disponibles en:
- `assets/templates/plantilla_jumpers.xlsx`
- `assets/templates/plantilla_computo.xlsx`
- `assets/templates/plantilla_sdr.xlsx`

Si las plantillas no existen, el servicio creará automáticamente archivos Excel con el formato correcto.

## Formato de Archivos Generados

Todos los archivos Excel generados incluyen:
- Título con mes y año en español
- Encabezados en negrita y centrados
- Bordes delgados en todas las celdas
- Celdas centradas (horizontal y vertical)
- Ancho de columnas ajustado automáticamente

## Instalación

```bash
cd excel_generator_service
python -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate
pip install fastapi uvicorn openpyxl
```

## Ejecución

### Opción 1: Usando el script de inicio (Recomendado)

Los scripts incluyen **hot reload automático** que detecta cambios en los archivos y recarga el servidor automáticamente, similar a Flutter.

**Linux/macOS:**
```bash
./start_server.sh
```

**Windows:**
```bash
start_server.bat
```

> 💡 **Hot Reload**: El servidor se recargará automáticamente cuando detecte cambios en archivos `.py`. No necesitas reiniciar manualmente. Ver [HOT_RELOAD.md](./HOT_RELOAD.md) para más detalles.

### Opción 2: Manualmente

```bash
python main.py
```

O con uvicorn directamente:
```bash
uvicorn main:app --host 0.0.0.0 --port 8001 --reload
```

### Verificar que el servidor está corriendo

Abre tu navegador y visita:
- http://localhost:8001 - Página principal con lista de endpoints
- http://localhost:8001/health - Estado del servicio y plantillas disponibles
- http://localhost:8001/docs - Documentación interactiva de la API (Swagger UI)

## Uso desde Flutter

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> exportToExcel() async {
  final url = Uri.parse('http://localhost:8001/api/generate-jumpers-excel');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'items': [
        {
          'tipo': 'SC-SC',
          'tamano': 5,
          'cantidad': 10,
          'rack': 'RACK-01',
          'contenedor': 'CONT-01',
        }
      ],
    }),
  );

  if (response.statusCode == 200) {
    // Guardar el archivo
    final file = File('inventario_jumpers.xlsx');
    await file.writeAsBytes(response.bodyBytes);
  }
}
```

