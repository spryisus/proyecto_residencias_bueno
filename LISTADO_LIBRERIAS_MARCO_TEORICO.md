# Listado de Librerías y Tecnologías - Proyecto Telmex Inventarios

## Resumen de Lenguajes Utilizados

Este proyecto utiliza los siguientes lenguajes de programación:
- **Dart/Flutter** (Aplicación principal móvil y de escritorio)
- **JavaScript/Node.js** (Servicio proxy de rastreo DHL)
- **Python** (Servicios backend: generación de Excel y rastreo FastAPI)
- **Kotlin/Java** (Configuración nativa Android)

---

## 1. LIBRERÍAS DART/FLUTTER

### Dependencias Principales

| Librería | Versión | Propósito |
|----------|---------|-----------|
| `flutter` | SDK | Framework principal de desarrollo multiplataforma |
| `cupertino_icons` | ^1.0.8 | Iconos estilo iOS/Cupertino |
| `supabase` | ^2.9.1 | Cliente Dart para Supabase (backend) |
| `supabase_flutter` | ^2.10.1 | Integración Flutter para Supabase |
| `http` | ^1.5.0 | Cliente HTTP para peticiones REST |
| `mobile_scanner` | ^5.0.0 | Escaneo de códigos QR y códigos de barras |
| `permission_handler` | ^11.3.1 | Manejo de permisos del sistema operativo |
| `provider` | ^6.1.1 | Gestión de estado (State Management) |
| `shared_preferences` | ^2.2.2 | Almacenamiento local de preferencias |
| `bcrypt` | ^1.1.3 | Encriptación de contraseñas |
| `geolocator` | ^13.0.1 | Obtención de ubicación GPS |
| `table_calendar` | ^3.1.2 | Widget de calendario para selección de fechas |
| `intl` | ^0.19.0 | Internacionalización y formato de fechas/números |
| `excel` | ^4.0.5 | Generación y manipulación de archivos Excel |
| `path_provider` | ^2.1.1 | Acceso a rutas del sistema de archivos |
| `url_launcher` | ^6.2.5 | Apertura de URLs y aplicaciones externas |
| `file_picker` | ^8.1.4 | Selección de archivos del sistema |
| `share_plus` | ^10.1.2 | Compartir contenido entre aplicaciones |
| `open_filex` | ^4.5.0 | Apertura de archivos con aplicación predeterminada |

### Dependencias de Desarrollo

| Librería | Versión | Propósito |
|----------|---------|-----------|
| `flutter_test` | SDK | Framework de pruebas unitarias |
| `flutter_lints` | ^5.0.0 | Reglas de linting para código Dart |
| `flutter_launcher_icons` | ^0.13.1 | Generación automática de íconos de aplicación |

### Versión del SDK Dart
- **Dart SDK**: ^3.6.1

---

## 2. LIBRERÍAS JAVASCRIPT/NODE.JS

### Servicio: DHL Tracking Proxy (`dhl_tracking_proxy/`)

#### Dependencias Principales

| Librería | Versión | Propósito |
|----------|---------|-----------|
| `express` | ^4.18.2 | Framework web para Node.js |
| `cors` | ^2.8.5 | Middleware para habilitar CORS |
| `puppeteer` | ^21.5.0 | Automatización de navegador (headless Chrome) |
| `puppeteer-extra` | ^3.3.6 | Extensión de Puppeteer con plugins |
| `puppeteer-extra-plugin-stealth` | ^2.11.2 | Plugin para evitar detección de automatización |
| `@puppeteer/browsers` | ^1.7.0 | Gestión de navegadores para Puppeteer |
| `dotenv` | ^16.3.1 | Manejo de variables de entorno |

#### Dependencias de Desarrollo

| Librería | Versión | Propósito |
|----------|---------|-----------|
| `nodemon` | ^3.0.1 | Reinicio automático del servidor en desarrollo |

#### Versiones de Node.js Requeridas
- **Node.js**: >=18.0.0
- **npm**: >=8.0.0

---

## 3. LIBRERÍAS PYTHON

### Servicio 1: FastAPI Tracking Service (`fastapi_tracking_service/`)

| Librería | Versión | Propósito |
|----------|---------|-----------|
| `fastapi` | 0.115.5 | Framework web moderno y rápido para APIs |
| `uvicorn[standard]` | 0.32.0 | Servidor ASGI de alto rendimiento |
| `httpx` | 0.27.2 | Cliente HTTP asíncrono |
| `beautifulsoup4` | 4.12.3 | Parsing y scraping de HTML/XML |
| `pydantic` | 2.9.2 | Validación de datos y configuración |

### Servicio 2: Excel Generator Service (`excel_generator_service/`)

| Librería | Versión | Propósito |
|----------|---------|-----------|
| `fastapi` | >=0.104.0 | Framework web para API REST |
| `uvicorn[standard]` | >=0.24.0 | Servidor ASGI |
| `openpyxl` | >=3.1.0 | Generación y manipulación de archivos Excel (.xlsx) |

---

## 4. TECNOLOGÍAS Y HERRAMIENTAS ADICIONALES

### Backend y Base de Datos
- **Supabase**: Plataforma backend como servicio (BaaS) que proporciona:
  - Base de datos PostgreSQL
  - Autenticación
  - Almacenamiento
  - APIs REST y GraphQL

### Plataformas de Despliegue
- **Render**: Plataforma cloud para despliegue de servicios

### Herramientas de Build
- **Gradle**: Sistema de construcción para Android
- **Kotlin**: Lenguaje para desarrollo nativo Android
- **Java**: Compatibilidad Android (versión 1.8)

### Contenedores
- **Docker**: Containerización de servicios (Dockerfile presente en proyecto)

---

## 5. RESUMEN POR CATEGORÍA

### Frontend/Móvil
- Flutter/Dart (aplicación principal)
- Provider (gestión de estado)
- Mobile Scanner (escaneo QR/barras)
- Geolocator (GPS)
- Table Calendar (calendarios)

### Backend y APIs
- Supabase (backend principal)
- FastAPI (servicios Python)
- Express.js (servicio proxy Node.js)
- Uvicorn (servidor ASGI)

### Manipulación de Datos
- Excel (generación Excel en Dart)
- OpenPyXL (generación Excel en Python)
- BeautifulSoup4 (scraping web)
- Pydantic (validación de datos)

### Automatización Web
- Puppeteer (automatización de navegador)
- Puppeteer Extra (extensión con plugins)
- Puppeteer Stealth (evitar detección)

### Utilidades
- HTTP/HTTPX (peticiones HTTP)
- Shared Preferences (almacenamiento local)
- File Picker (selección de archivos)
- Path Provider (rutas del sistema)
- Permission Handler (permisos del SO)
- URL Launcher (abrir URLs)
- Share Plus (compartir contenido)
- Open FileX (abrir archivos)

### Seguridad
- Bcrypt (encriptación de contraseñas)
- CORS (configuración de seguridad web)

### Internacionalización
- Intl (formato de fechas, números, monedas)

---

## 6. VERSIONES DE ENTORNO

### Flutter/Dart
- Dart SDK: ^3.6.1
- Flutter SDK: (versión del SDK Flutter instalado)

### Node.js
- Node.js: >=18.0.0
- npm: >=8.0.0

### Python
- Python: (versión especificada en runtime.txt si existe)

### Android
- Kotlin: (versión del plugin Kotlin)
- Java: 1.8 (JavaVersion.VERSION_1_8)

---

## Notas para el Marco Teórico

1. **Flutter/Dart**: Framework multiplataforma que permite desarrollar aplicaciones para iOS, Android, Web, Windows, Linux y macOS desde un solo código base.

2. **Supabase**: Alternativa open-source a Firebase, proporciona backend completo con base de datos PostgreSQL, autenticación y almacenamiento.

3. **FastAPI**: Framework moderno de Python para construir APIs rápidas con validación automática de datos y documentación interactiva.

4. **Puppeteer**: Herramienta de automatización que controla navegadores headless para web scraping y pruebas automatizadas.

5. **Provider**: Patrón de gestión de estado recomendado por Flutter para manejar el estado de la aplicación de forma eficiente.

6. **OpenPyXL/Excel**: Librerías para manipulación de archivos Excel, esenciales para la generación de reportes de inventario.

---

**Fecha de generación**: $(date)
**Proyecto**: Sistema de Inventarios Telmex
**Versión del proyecto**: 1.0.0+1

