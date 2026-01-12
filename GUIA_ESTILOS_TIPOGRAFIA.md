# 🎨 GUÍA DE ESTILOS Y TIPOGRAFÍA - PROYECTO TELMEX

## 📋 RESUMEN EJECUTIVO

Esta guía documenta todos los estilos de texto, colores y tipografía utilizados en la aplicación Flutter del Sistema de Inventarios Telmex.

---

## 🎨 PALETA DE COLORES

### Colores Principales (Telmex)
```
🔵 Azul Primario:     #003366 (Color(0xFF003366))
🔵 Azul Secundario:   #0066CC (Color(0xFF0066CC))
🔵 Azul Acento:       #4A90E2 (Color(0xFF4A90E2))
🔵 Azul Claro:        #E6F3FF (Color(0xFFE6F3FF))
```

### Colores de Estado
```
✅ Verde Éxito:       #28A745 (Color(0xFF28A745))
⚠️ Naranja Advertencia: #FF9800 (Color(0xFFFF9800))
❌ Rojo Error:        #DC3545 (Color(0xFFDC3545))
ℹ️ Azul Info:         #17A2B8 (Color(0xFF17A2B8))
```

### Escala de Grises
```
Gris 100: #F8F9FA (Fondo claro)
Gris 200: #E9ECEF (Bordes suaves)
Gris 300: #DEE2E6 (Bordes)
Gris 400: #CED4DA (Texto deshabilitado)
Gris 500: #ADB5BD (Texto secundario)
Gris 600: #6C757D (Texto secundario medio)
Gris 700: #495057 (Texto principal)
Gris 800: #343A40 (Texto importante)
Gris 900: #212529 (Texto muy importante)
```

### Colores Especiales
```
Blanco:               #FFFFFF (Colors.white)
Negro:                #000000 (Colors.black)
```

---

## 📝 TIPOGRAFÍA BASE (Tema Global)

### Fuente
- **Familia:** Roboto (por defecto de Material Design 3)
- **No hay fuentes personalizadas** - Usa las fuentes del sistema

### Escala de Tamaños (TextTheme)

#### Display (Títulos Grandes)
```
displayLarge:
  - Tamaño: 32px
  - Peso: Bold (FontWeight.bold)
  - Color: Gris 800 (#343A40)
  - Letter Spacing: -0.5

displayMedium:
  - Tamaño: 28px
  - Peso: Bold
  - Color: Gris 800
  - Letter Spacing: -0.25

displaySmall:
  - Tamaño: 24px
  - Peso: Semi-Bold (FontWeight.w600)
  - Color: Gris 800
  - Letter Spacing: 0
```

#### Headline (Encabezados)
```
headlineLarge:
  - Tamaño: 22px
  - Peso: Semi-Bold (w600)
  - Color: Gris 800
  - Letter Spacing: 0

headlineMedium:
  - Tamaño: 20px
  - Peso: Semi-Bold (w600)
  - Color: Gris 800
  - Letter Spacing: 0.15

headlineSmall:
  - Tamaño: 18px
  - Peso: Semi-Bold (w600)
  - Color: Gris 800
  - Letter Spacing: 0.15
```

#### Title (Títulos)
```
titleLarge:
  - Tamaño: 18px
  - Peso: Semi-Bold (w600)
  - Color: Gris 800
  - Letter Spacing: 0.15

titleMedium:
  - Tamaño: 16px
  - Peso: Medium (w500)
  - Color: Gris 800
  - Letter Spacing: 0.15

titleSmall:
  - Tamaño: 14px
  - Peso: Medium (w500)
  - Color: Gris 800
  - Letter Spacing: 0.1
```

#### Body (Texto Normal)
```
bodyLarge:
  - Tamaño: 16px
  - Peso: Normal (FontWeight.normal)
  - Color: Gris 700 (#495057)
  - Letter Spacing: 0.15

bodyMedium:
  - Tamaño: 14px
  - Peso: Normal
  - Color: Gris 700
  - Letter Spacing: 0.25

bodySmall:
  - Tamaño: 12px
  - Peso: Normal
  - Color: Gris 600 (#6C757D)
  - Letter Spacing: 0.4
```

#### Label (Etiquetas)
```
labelLarge:
  - Tamaño: 14px
  - Peso: Medium (w500)
  - Color: Gris 700
  - Letter Spacing: 0.1

labelMedium:
  - Tamaño: 12px
  - Peso: Medium (w500)
  - Color: Gris 700
  - Letter Spacing: 0.5

labelSmall:
  - Tamaño: 11px
  - Peso: Medium (w500)
  - Color: Gris 600
  - Letter Spacing: 0.5
```

---

## 🎯 ESTILOS POR SECCIÓN

### 1. APP BAR (Barra Superior)

#### Tema Claro
```
Título:
  - Tamaño: 20px
  - Peso: Semi-Bold (w600)
  - Color: Gris 800 (#343A40)
  - Letter Spacing: 0.5
  - Alineación: Centrado

Fondo: Blanco (#FFFFFF)
Iconos: Gris 800
```

#### Tema Oscuro (si se usa)
```
Título:
  - Tamaño: 20px
  - Peso: Semi-Bold (w600)
  - Color: Blanco
  - Letter Spacing: 0.5

Fondo: Gris 900 (#212529)
Iconos: Blanco
```

#### App Bar Especial (Bitácora, Envíos)
```
Título:
  - Tamaño: 20px
  - Peso: Semi-Bold (w600)
  - Color: Blanco
  - Fondo: Azul Primario (#003366)
```

---

### 2. BOTONES

#### ElevatedButton (Botones Principales)
```
Texto:
  - Tamaño: 16px
  - Peso: Medium (w500)
  - Color: Blanco
  - Letter Spacing: 0.5

Fondo: Azul Primario (#003366)
Padding: 24px horizontal, 12px vertical
Border Radius: 12px
```

#### TextButton (Botones de Texto)
```
Texto:
  - Tamaño: 16px
  - Peso: Medium (w500)
  - Color: Azul Primario (#003366)

Padding: 16px horizontal, 8px vertical
```

#### IconButton (Botones de Icono)
```
Tamaño de Icono: 24px (por defecto)
Color: Gris 600 o según contexto
```

---

### 3. FORMULARIOS Y INPUTS

#### Labels de Campos
```
Tamaño: 14px
Peso: Semi-Bold (w600)
Color: Gris 700 (#495057)
```

#### TextField/TextFormField
```
Texto de Entrada:
  - Tamaño: 16px (por defecto del tema)
  - Peso: Normal
  - Color: Gris 800

Placeholder/Hint:
  - Tamaño: 16px
  - Color: Gris 500 (#ADB5BD)
  - Estilo: Italic

Borde:
  - Normal: Gris 300 (#DEE2E6), 1px
  - Focus: Azul Primario (#003366), 2px
  - Error: Rojo Error (#DC3545), 2px
  - Border Radius: 12px
```

#### DropdownButton
```
Texto Seleccionado:
  - Tamaño: 16px
  - Peso: Normal
  - Color: Gris 800

Items:
  - Tamaño: 16px
  - Overflow: Ellipsis
  - Max Lines: 1
```

---

### 4. TARJETAS Y CONTENEDORES

#### Cards (Tarjetas Principales)
```
Elevación: 2
Border Radius: 16px
Sombra: Negro con 26% opacidad
Fondo: Blanco
```

#### Contenido de Cards
```
Títulos en Cards:
  - Tamaño: 18px
  - Peso: Semi-Bold (w600)
  - Color: Gris 800

Texto en Cards:
  - Tamaño: 14px
  - Peso: Normal
  - Color: Gris 700
```

---

### 5. TABLAS Y LISTAS

#### Headers de Tabla
```
Tamaño: 12px
Peso: Bold
Color: Blanco
Fondo: Azul Primario (#003366)
```

#### Celdas de Tabla
```
Tamaño: 12px
Peso: Normal
Color: Gris 800
```

#### Items de Lista
```
Tamaño Principal: 14px
Peso: Normal o Semi-Bold según importancia
Color: Gris 700 o Gris 800
```

---

### 6. BITÁCORA DE ENVÍOS

#### Encabezado de Bitácora (Consecutivo)
```
Badge "CONS. XX-XX":
  - Tamaño: 13px
  - Peso: Bold
  - Color: Blanco
  - Fondo: Azul Primario (#003366)
  - Padding: 10px horizontal, 6px vertical
  - Border Radius: 6px
```

#### Fecha
```
Tamaño: 13px
Peso: Medium (w500)
Color: Gris 700 (#495057)
Icono: 16px, Gris 600
```

#### Campos de Bitácora
```
Label (Técnico, Tarjeta, etc.):
  - Tamaño: 13px o 14px
  - Peso: Semi-Bold (w600)
  - Color: Gris 700

Valor:
  - Tamaño: 14px
  - Peso: Normal
  - Color: Gris 800
```

#### Filtros
```
Título "Filtrar por año/código":
  - Tamaño: 14px
  - Peso: Semi-Bold (w600)
  - Color: Gris 700

Chips de Filtro:
  - Tamaño: 12px
  - Peso: Normal o Bold (si seleccionado)
  - Color: Gris 700 (normal) / Blanco (seleccionado)
  - Fondo Seleccionado: Azul 300 (#90CAF9)
```

---

### 7. INVENTARIO DE CÓMPUTO

#### Tarjetas de Equipo (Móvil)
```
Título/Inventario:
  - Tamaño: 13px
  - Peso: Bold
  - Color: Azul Primario (#003366)

Status Badge:
  - Tamaño: 9px
  - Peso: Bold
  - Color: Blanco
  - Fondo: Color según status

Usuario Asignado:
  - Tamaño: 10px
  - Peso: Bold
  - Color: Azul
  - Fondo: Azul 50

Marca/Modelo:
  - Tamaño: 10px
  - Peso: Normal
  - Color: Gris 700
```

#### Vista Desktop (Tabla)
```
Headers:
  - Tamaño: 12px
  - Peso: Bold
  - Color: Blanco
  - Fondo: Azul Primario

Celdas:
  - Tamaño: 12px
  - Peso: Normal
  - Color: Gris 800
```

---

### 8. ADMINISTRACIÓN DE USUARIOS

#### Títulos de Sección
```
Tamaño: 18px o 20px
Peso: Semi-Bold (w600)
Color: Gris 800
```

#### Lista de Usuarios
```
Nombre de Usuario:
  - Tamaño: 16px
  - Peso: Medium (w500)
  - Color: Gris 800

Email:
  - Tamaño: 14px
  - Peso: Normal
  - Color: Gris 600

Roles:
  - Tamaño: 12px
  - Peso: Medium (w500)
  - Color: Gris 700
```

#### Botones de Acción
```
Toggle Switch:
  - Color Activo: Verde (#28A745)
  - Color Inactivo: Gris 400

Iconos:
  - Editar: Azul, 20px
  - Eliminar: Rojo, 20px
```

---

### 9. MENSAJES Y NOTIFICACIONES

#### SnackBar (Éxito)
```
Texto:
  - Tamaño: 14px (por defecto)
  - Peso: Normal
  - Color: Blanco
Fondo: Verde (#28A745)
```

#### SnackBar (Error)
```
Texto:
  - Tamaño: 14px
  - Peso: Normal
  - Color: Blanco
Fondo: Rojo (#DC3545)
```

#### SnackBar (Advertencia)
```
Texto:
  - Tamaño: 14px
  - Peso: Normal
  - Color: Blanco
Fondo: Naranja (#FF9800)
```

#### SnackBar (Info)
```
Texto:
  - Tamaño: 14px
  - Peso: Normal
  - Color: Blanco
Fondo: Azul Info (#17A2B8)
```

---

### 10. DIÁLOGOS Y MODALES

#### Título del Diálogo
```
Tamaño: 18px o 20px
Peso: Semi-Bold (w600)
Color: Gris 800
```

#### Contenido del Diálogo
```
Tamaño: 14px o 16px
Peso: Normal
Color: Gris 700
```

#### Botones del Diálogo
```
Cancelar (TextButton):
  - Tamaño: 16px
  - Color: Gris 700 o Azul Primario

Confirmar (ElevatedButton):
  - Tamaño: 16px
  - Peso: Medium (w500)
  - Color: Blanco
  - Fondo: Azul Primario
```

---

### 11. CHIPS Y BADGES

#### FilterChip (Filtros)
```
Texto Normal:
  - Tamaño: 12px
  - Peso: Normal
  - Color: Gris 700

Texto Seleccionado:
  - Tamaño: 12px
  - Peso: Bold
  - Color: Blanco
  - Fondo: Azul 300 (#90CAF9)

Border Radius: 16px
Padding: 10px horizontal, 6px vertical
```

#### YearChip (Filtro de Años)
```
Texto:
  - Tamaño: 14px
  - Peso: Medium (w500)
  - Color: Gris 700 (normal) / Blanco (seleccionado)
  - Fondo Seleccionado: Azul Primario (#003366)
```

#### Status Badge
```
Tamaño: 9px a 13px (según contexto)
Peso: Bold
Color: Blanco
Fondo: Color según status (Verde, Naranja, Rojo, etc.)
Border Radius: 6px a 8px
```

---

### 12. ICONOS

#### Tamaños Estándar
```
Pequeño: 10px - 14px (badges, chips)
Mediano: 16px - 20px (botones, listas)
Grande: 24px - 40px (cards principales, headers)
```

#### Colores de Iconos
```
Primario: Gris 600 (#6C757D)
Secundario: Azul Primario (#003366)
Acción: Azul, Verde, Rojo según contexto
Deshabilitado: Gris 400 (#CED4DA)
```

---

## 📊 RESUMEN DE TAMAÑOS DE FUENTE

### Distribución de Tamaños
```
32px: Títulos muy grandes (Display Large)
28px: Títulos grandes (Display Medium)
24px: Títulos grandes (Display Small)
22px: Encabezados grandes (Headline Large)
20px: Encabezados (Headline Medium, AppBar)
18px: Títulos de sección (Title Large, Headline Small)
16px: Texto normal grande, Botones, Inputs (Body Large, Title Medium)
14px: Texto normal, Labels, Chips (Body Medium, Title Small, Label Large)
13px: Texto pequeño en cards, Badges
12px: Texto muy pequeño, Tablas, Chips (Body Small, Label Medium)
11px: Texto mínimo (Label Small)
10px: Texto en badges pequeños
9px: Texto en badges muy pequeños
```

---

## 🎨 RESUMEN DE COLORES DE TEXTO

### Por Contexto
```
Texto Principal:        Gris 800 (#343A40)
Texto Secundario:      Gris 700 (#495057)
Texto Terciario:       Gris 600 (#6C757D)
Texto Deshabilitado:   Gris 500 (#ADB5BD)
Texto en Botones:      Blanco (sobre azul) o Azul Primario (text buttons)
Texto en Badges:       Blanco (sobre colores)
Texto de Error:         Rojo (#DC3545)
Texto de Éxito:         Verde (#28A745)
Texto de Advertencia:   Naranja (#FF9800)
```

---

## 📐 ESPACIADO Y PADDING

### Padding Estándar
```
Cards: 12px - 20px
Botones: 24px horizontal, 12px vertical
Inputs: 16px horizontal, 12px vertical
Diálogos: 16px - 24px
```

### Spacing (SizedBox)
```
Muy Pequeño: 4px
Pequeño: 6px - 8px
Mediano: 12px - 16px
Grande: 20px - 24px
Muy Grande: 32px+
```

---

## 🔤 PESOS DE FUENTE UTILIZADOS

```
FontWeight.normal (400): Texto normal, párrafos
FontWeight.w500 (500):   Texto medio, labels, botones
FontWeight.w600 (600):   Títulos, encabezados, semi-bold
FontWeight.bold (700):   Títulos importantes, badges
```

---

## 📱 RESPONSIVE (Móvil vs Desktop)

### Móvil (< 600px)
- Textos ligeramente más pequeños en algunos casos
- Padding reducido
- Más uso de `maxLines` y `overflow: ellipsis`

### Desktop (≥ 600px)
- Textos estándar
- Más espacio horizontal
- Tablas en lugar de cards

---

## 💡 NOTAS IMPORTANTES

1. **No hay fuentes personalizadas** - Usa Roboto (Material Design por defecto)
2. **Colores principales** siempre son los azules de Telmex (#003366)
3. **Consistencia**: Los tamaños siguen la escala de Material Design 3
4. **Contraste**: Todos los textos cumplen con ratios de contraste WCAG
5. **Letter Spacing**: Varía según el tamaño (más espaciado en textos pequeños)

---

## 🎯 EJEMPLOS DE USO

### Título Principal de Pantalla
```dart
Text(
  'Módulo de Envíos',
  style: Theme.of(context).textTheme.displaySmall, // 24px, w600, grey800
)
```

### Texto Normal
```dart
Text(
  'Descripción del módulo',
  style: Theme.of(context).textTheme.bodyLarge, // 16px, normal, grey700
)
```

### Badge de Status
```dart
Text(
  'ACTIVO',
  style: TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  ),
)
```

### Botón Principal
```dart
ElevatedButton(
  child: Text('Guardar'),
  // Usa el tema: 16px, w500, blanco sobre azul
)
```

---

**Última actualización:** Enero 2025
**Versión de Flutter:** 3.6.1+
**Material Design:** 3 (useMaterial3: true)








