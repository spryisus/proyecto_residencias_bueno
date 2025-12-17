# 📚 Documentación de Dart y Flutter - Proyecto Telmex

## 📋 Índice
- [¿Qué es Dart?](#qué-es-dart)
- [Conceptos Básicos de Dart](#conceptos-básicos-de-dart)
- [Análisis de Códigos del Proyecto](#análisis-de-códigos-del-proyecto)
- [Explicaciones Detalladas](#explicaciones-detalladas)
- [Cambios Realizados](#cambios-realizados)
- [Conceptos Clave de Flutter](#conceptos-clave-de-flutter)

---

## ¿Qué es Dart?

**Dart** es un lenguaje de programación desarrollado por Google que está diseñado para ser:
- **Rápido**: Compila a código nativo para máximo rendimiento
- **Productivo**: Sintaxis clara y herramientas excelentes
- **Escalable**: Perfecto para aplicaciones grandes
- **Multiplataforma**: Funciona en web, móvil, escritorio y servidor

Dart es especialmente famoso porque **Flutter** (el framework que estamos usando) está construido con Dart.

---

## Conceptos Básicos de Dart

### 1. Variables y Tipos de Datos
```dart
// Variables con tipo explícito
String nombre = "Juan";
int edad = 25;
double altura = 1.75;
bool esEstudiante = true;

// Variables con tipo inferido (Dart adivina el tipo)
var apellido = "Pérez"; // Dart sabe que es String
var numero = 42; // Dart sabe que es int
```

### 2. Clases y Objetos
```dart
class Persona {
  String nombre;
  int edad;
  
  // Constructor
  Persona(this.nombre, this.edad);
  
  // Método
  void saludar() {
    print("Hola, soy $nombre y tengo $edad años");
  }
}

// Crear un objeto
var persona = Persona("María", 30);
persona.saludar();
```

---

## Análisis de Códigos del Proyecto

### Estructura de Archivos Flutter
```
lib/
├── screens/
│   ├── shipments/
│   │   ├── shipments_screen.dart      ← Pantalla principal de envíos
│   │   └── shipment_reports_screen.dart ← Pantalla de reportes
│   └── inventory/
│       └── inventory_screen.dart      ← Pantalla de inventarios
```

### Análisis del `shipments_screen.dart`

#### Imports
```dart
import 'package:flutter/material.dart';
import 'track_shipment_screen.dart';
import 'shipment_reports_screen.dart';
```
**Explicación**: 
- `import` trae librerías externas
- `flutter/material.dart` contiene todos los widgets de Material Design
- Los otros imports son archivos de nuestro proyecto

#### Definición de Clase
```dart
class ShipmentsScreen extends StatelessWidget {
  const ShipmentsScreen({super.key});
```
**Explicación**:
- `class` define una nueva clase
- `extends StatelessWidget` significa que hereda de StatelessWidget (un widget que no cambia)
- `const` significa que es constante (no puede cambiar)
- `super.key` pasa la clave al widget padre

#### Método Build
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
```
**Explicación**:
- `@override` indica que estamos sobrescribiendo un método del padre
- `Widget build()` es el método que construye la interfaz
- `BuildContext context` contiene información sobre la ubicación del widget
- `Scaffold` es como el "esqueleto" de la pantalla

#### AppBar
```dart
appBar: AppBar(
  title: const Text('Envíos'),
  centerTitle: true,
  backgroundColor: const Color(0xFF003366),
  foregroundColor: Colors.white,
),
```
**Explicación**:
- `AppBar` es la barra superior de la pantalla
- `title` es el texto que aparece
- `centerTitle: true` centra el título
- `Color(0xFF003366)` es un color en formato hexadecimal (azul oscuro)
- `Colors.white` es blanco predefinido

#### Body y Layout
```dart
body: Padding(
  padding: const EdgeInsets.all(16.0),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
```
**Explicación**:
- `Padding` añade espacio alrededor del contenido
- `EdgeInsets.all(16.0)` añade 16 píxeles de espacio en todos los lados
- `Column` organiza widgets verticalmente
- `crossAxisAlignment.start` alinea los elementos al inicio (izquierda)

---

## Explicaciones Detalladas

### El LayoutBuilder - ¡La Parte Más Importante!

```dart
Expanded(
  child: LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 600) {
        // Una columna en pantallas pequeñas
        return Column(
          children: [
            Expanded(
              child: _buildEnvioOptionCard(...),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _buildEnvioOptionCard(...),
            ),
          ],
        );
      } else {
        // Dos columnas centradas en pantallas medianas y grandes
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 1,
              child: _buildEnvioOptionCard(...),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 1,
              child: _buildEnvioOptionCard(...),
            ),
          ],
        );
      }
    },
  ),
),
```

**Explicación Detallada**:

1. **`Expanded`**: Hace que el widget ocupe todo el espacio disponible
2. **`LayoutBuilder`**: Un widget especial que nos da información sobre el tamaño disponible
3. **`constraints.maxWidth`**: Nos dice cuánto ancho tenemos disponible
4. **Condicional `if`**: 
   - Si la pantalla es menor a 600px → usa `Column` (vertical)
   - Si es mayor → usa `Row` (horizontal)
5. **`Row`**: Organiza widgets horizontalmente
6. **`MainAxisAlignment.center`**: Centra los elementos horizontalmente
7. **`Expanded` con `flex: 1`**: Cada botón ocupa la misma cantidad de espacio
8. **`SizedBox`**: Añade espacio entre elementos

### Función Personalizada para Crear Botones

```dart
Widget _buildEnvioOptionCard(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required Color color,
  required VoidCallback onTap,
}) {
```

**Explicación**:
- `Widget` es el tipo de retorno (devuelve un widget)
- `_buildEnvioOptionCard` es el nombre de la función (el `_` indica que es privada)
- Los parámetros entre `{}` son **parámetros nombrados**
- `required` significa que es obligatorio pasar ese parámetro
- `IconData`, `String`, `Color` son tipos específicos
- `VoidCallback` es una función que no devuelve nada

### Card y InkWell

```dart
return Card(
  elevation: 6,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  child: InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
```

**Explicación**:
- `Card` crea una tarjeta con sombra
- `elevation: 6` añade profundidad (sombra)
- `RoundedRectangleBorder` hace las esquinas redondeadas
- `BorderRadius.circular(16)` hace esquinas con radio de 16 píxeles
- `InkWell` añade efecto de "ripple" al tocar
- `onTap: onTap` ejecuta la función cuando se toca

---

## Cambios Realizados

### Cambio 1: Tamaño de Botones
```dart
// ANTES
childAspectRatio: 1.2,  // Botones más altos

// DESPUÉS  
childAspectRatio: 1.1,  // Botones más cuadrados (como inventarios)
```

### Cambio 2: Número de Columnas
```dart
// ANTES
int crossAxisCount = 2;  // Solo 2 columnas

// DESPUÉS
int crossAxisCount = 3;  // 3 columnas por defecto
if (constraints.maxWidth < 800) crossAxisCount = 2;
if (constraints.maxWidth < 600) crossAxisCount = 1;
```

### Cambio 3: Centrar Botones
```dart
// ANTES: GridView (botones pegados a los bordes)
return GridView.count(...)

// DESPUÉS: Row centrado
return Row(
  mainAxisAlignment: MainAxisAlignment.center,  // ¡Centra los botones!
  children: [
    Expanded(flex: 1, child: boton1),
    SizedBox(width: 20),  // Espacio entre botones
    Expanded(flex: 1, child: boton2),
  ],
);
```

---

## Conceptos Clave de Flutter

### 1. Widget Tree (Árbol de Widgets)
Flutter organiza todo como un árbol:
```
Scaffold
├── AppBar
└── Body
    └── Padding
        └── Column
            ├── Text
            ├── Text
            └── Expanded
                └── LayoutBuilder
                    └── Row/Column
                        └── Expanded
                            └── Card
```

### 2. Responsive Design
```dart
if (constraints.maxWidth < 600) {
  // Pantalla pequeña: 1 columna
} else {
  // Pantalla grande: 2 columnas centradas
}
```

### 3. Material Design
- `Card` con `elevation` para profundidad
- `InkWell` para efectos de toque
- `RoundedRectangleBorder` para esquinas redondeadas
- Colores consistentes (`Color(0xFF003366)`)

---

## Flujo de la Aplicación

1. **Usuario abre la app** → `main.dart`
2. **Navega a Envíos** → `ShipmentsScreen`
3. **Ve 2 botones centrados** → LayoutBuilder decide el layout
4. **Toca "Reportes"** → Va a `ShipmentReportsScreen`
5. **Ve 6 botones en grid** → GridView con 3 columnas

---

## 📝 Notas Adicionales

### ¿Por Qué Hicimos Estos Cambios?

1. **Consistencia Visual**: Todos los botones tienen el mismo tamaño
2. **Mejor UX**: Los botones centrados se ven más profesionales
3. **Responsive**: Se adapta a diferentes tamaños de pantalla
4. **Mantenibilidad**: Código más limpio y fácil de entender

### Widgets Importantes Usados

- **Scaffold**: Estructura básica de la pantalla
- **AppBar**: Barra superior
- **Padding**: Espaciado
- **Column/Row**: Organización vertical/horizontal
- **Expanded**: Ocupa espacio disponible
- **LayoutBuilder**: Información de tamaño
- **Card**: Tarjeta con sombra
- **InkWell**: Efecto de toque
- **GridView**: Cuadrícula de elementos

---

## 🐧 Instalador de Linux

### Archivos Creados:
- **`instalar_linux.sh`**: Instalador automático para Linux
- **`SistemaTelmex-Portable-1.0.0.tar.gz`**: Paquete portable
- **`README_INSTALADOR_LINUX.md`**: Instrucciones detalladas de instalación

### Comandos para Instalar:
```bash
# Instalador automático (recomendado)
./instalar_linux.sh

# Versión portable
tar -xzf SistemaTelmex-Portable-1.0.0.tar.gz
cd SistemaTelmex-Portable
./ejecutar.sh
```

### Requisitos:
- Linux x64 (Ubuntu 18.04+, Fedora 30+)
- GTK 3.0 o superior
- 4 GB RAM mínimo
- 100 MB espacio en disco

---

*Documentación creada el: $(date)*
*Última actualización: $(date)*

