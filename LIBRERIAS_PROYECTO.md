# Listado de Librerías y Dependencias del Proyecto
## Sistema de Gestión de Inventarios y Rastreo de Envíos - TELMEX

---

## 1. LENGUAJE: DART / FLUTTER

### 1.1 Framework y SDK Base

| Librería | Versión | Propósito en el Proyecto |
|----------|---------|--------------------------|
| **Flutter SDK** | ^3.6.1 | Framework multiplataforma para desarrollo de aplicaciones móviles, web y de escritorio |
| **Dart SDK** | ^3.6.1 | Lenguaje de programación utilizado para el desarrollo del frontend |

### 1.2 Backend y Base de Datos

| Librería | Versión | Propósito en el Proyecto |
|----------|---------|--------------------------|
| **supabase** | ^2.9.1 | Cliente Dart para interactuar con la base de datos Supabase (PostgreSQL) |
| **supabase_flutter** | ^2.10.1 | Integración de Supabase con Flutter para autenticación, almacenamiento y consultas a la base de datos |

### 1.3 Comunicación HTTP y Red

| Librería | Versión | Propósito en el Proyecto |
|----------|---------|--------------------------|
| **http** | ^1.5.0 | Cliente HTTP para realizar peticiones REST a servicios externos (FastAPI, proxy Puppeteer) y APIs de rastreo de envíos |

### 1.4 Gestión de Estado

| Librería | Versión | Propósito en el Proyecto |
|----------|---------|--------------------------|
| **provider** | ^6.1.1 | Gestión reactiva del estado de la aplicación, manejo de datos globales y sincronización entre componentes |

### 1.5 Almacenamiento Local

| Librería | Versión | Propósito en el Proyecto |
|----------|---------|--------------------------|
| **shared_preferences** | ^2.2.2 | Almacenamiento persistente de preferencias del usuario, configuraciones y datos de sesión en formato clave-valor |

### 1.6 Autenticación y Seguridad

| Librería | Versión | Propósito en el Proyecto |
|----------|---------|--------------------------|
| **bcrypt** | ^1.1.3 | Algoritmo de hashing para encriptación segura de contraseñas de usuarios en la base de datos |

### 1.7 Escaneo y Código de Barras

| Librería | Versión | Propósito en el Proyecto |
|----------|---------|--------------------------|
| **mobile_scanner** | ^5.0.0 | Escaneo de códigos QR y códigos de barras mediante la cámara del dispositivo para identificación rápida de equipos y envíos |

### 1.8 Permisos del Sistema

| Librería | Versión | Propósito en el Proyecto |
|----------|---------|--------------------------|
| **permission_handler** | ^11.3.1 | Gestión y solicitud de permisos del sistema operativo (cámara, ubicación GPS, almacenamiento) |

### 1.9 Geolocalización

| Librería | Versión | Propósito en el Proyecto |
|----------|---------|--------------------------|
| **geolocator** | ^13.0.1 | Obtención de coordenadas GPS del dispositivo para registro de ubicación en inventarios y envíos |

### 1.10 Calendario y Fechas

| Librería | Versión | Propósito en el Proyecto |
|----------|---------|--------------------------|
| **table_calendar** | ^3.1.2 | Widget de calendario interactivo para visualización y selección de fechas en reportes y filtros |
| **intl** | ^0.19.0 | Internacionalización y formato de fechas, números y monedas según la configuración regional |

### 1.11 Manejo de Archivos

| Librería | Versión | Propósito en el Proyecto |
|----------|---------|--------------------------|
| **excel** | ^4.0.5 | Lectura y escritura de archivos Excel (.xlsx) para importación/exportación de datos de inventario |
| **path_provider** | ^2.1.1 | Obtención de rutas del sistema de archivos para guardar y acceder a documentos generados |
| **file_picker** | ^8.1.4 | Selector de archivos del sistema para importar plantillas Excel y otros documentos |
| **open_filex** | ^4.5.0 | Apertura de archivos con la aplicación predeterminada del sistema operativo |

### 1.12 Compartir y Enlaces Externos

| Librería | Versión | Propósito en el Proyecto |
|----------|---------|--------------------------|
| **share_plus** | ^10.1.2 | Compartir contenido (archivos, texto) mediante las opciones nativas del sistema operativo |
| **url_launcher** | ^6.2.5 | Abrir URLs en el navegador predeterminado y lanzar aplicaciones externas (teléfono, email, mapas) |

### 1.13 Interfaz de Usuario

| Librería | Versión | Propósito en el Proyecto |
|----------|---------|--------------------------|
| **cupertino_icons** | ^1.0.8 | Conjunto de iconos estilo iOS para mantener consistencia visual en la interfaz |

---

## 2. LENGUAJE: PYTHON

### 2.1 Framework Web

| Librería | Versión | Propósito en el Proyecto |
|----------|---------|--------------------------|
| **fastapi** | 0.115.5 | Framework web moderno y de alto rendimiento para crear APIs REST que procesa solicitudes de rastreo de envíos DHL |

### 2.2 Servidor ASGI

| Librería | Versión | Propósito en el Proyecto |
|----------|---------|--------------------------|
| **uvicorn[standard]** | 0.32.0 | Servidor ASGI de alto rendimiento que ejecuta la aplicación FastAPI en producción y desarrollo |

### 2.3 Cliente HTTP Asíncrono

| Librería | Versión | Propósito en el Proyecto |
|----------|---------|--------------------------|
| **httpx** | 0.27.2 | Cliente HTTP asíncrono para realizar peticiones a APIs externas (DHL, proxy Puppeteer) de forma eficiente |

### 2.4 Web Scraping

| Librería | Versión | Propósito en el Proyecto |
|----------|---------|--------------------------|
| **beautifulsoup4** | 4.12.3 | Parser HTML para extraer información de rastreo de envíos desde páginas web de DHL cuando no hay API disponible |

### 2.5 Validación de Datos

| Librería | Versión | Propósito en el Proyecto |
|----------|---------|--------------------------|
| **pydantic** | 2.9.2 | Validación y serialización de datos con type hints para garantizar la integridad de los datos de rastreo recibidos y enviados |

---

## 3. DEPENDENCIAS DE DESARROLLO

### 3.1 Testing

| Librería | Versión | Propósito en el Proyecto |
|----------|---------|--------------------------|
| **flutter_test** | SDK | Framework de pruebas unitarias y de integración proporcionado por Flutter para validar la funcionalidad del código |

### 3.2 Calidad de Código

| Librería | Versión | Propósito en el Proyecto |
|----------|---------|--------------------------|
| **flutter_lints** | ^5.0.0 | Conjunto de reglas de linting recomendadas para mantener estándares de código y detectar errores potenciales |

### 3.3 Generación de Recursos

| Librería | Versión | Propósito en el Proyecto |
|----------|---------|--------------------------|
| **flutter_launcher_icons** | ^0.13.1 | Herramienta para generar automáticamente iconos de la aplicación en diferentes tamaños y formatos para todas las plataformas |

---

## 4. RESUMEN ESTADÍSTICO

### 4.1 Por Lenguaje

| Lenguaje | Cantidad de Librerías | Porcentaje |
|----------|----------------------|------------|
| **Dart/Flutter** | 20 | 71.4% |
| **Python** | 5 | 17.9% |
| **Desarrollo** | 3 | 10.7% |
| **TOTAL** | **28** | **100%** |

### 4.2 Por Categoría Funcional

| Categoría | Cantidad | Librerías Principales |
|-----------|----------|----------------------|
| **Backend y Base de Datos** | 2 | Supabase, Supabase Flutter |
| **Comunicación HTTP** | 2 | HTTP, HTTPX |
| **Gestión de Estado** | 1 | Provider |
| **Almacenamiento** | 1 | Shared Preferences |
| **Seguridad** | 1 | Bcrypt |
| **Multimedia** | 1 | Mobile Scanner |
| **Permisos** | 1 | Permission Handler |
| **Geolocalización** | 1 | Geolocator |
| **Fechas y Calendario** | 2 | Table Calendar, Intl |
| **Manejo de Archivos** | 4 | Excel, Path Provider, File Picker, Open FileX |
| **Compartir y Enlaces** | 2 | Share Plus, URL Launcher |
| **UI/Icons** | 1 | Cupertino Icons |
| **Framework Web** | 1 | FastAPI |
| **Servidor** | 1 | Uvicorn |
| **Web Scraping** | 1 | BeautifulSoup4 |
| **Validación** | 1 | Pydantic |
| **Testing** | 1 | Flutter Test |
| **Linting** | 1 | Flutter Lints |
| **Herramientas** | 1 | Flutter Launcher Icons |

---

## 5. ESPECIFICACIONES TÉCNICAS

### 5.1 Versiones Mínimas

- **Dart SDK:** 3.6.1
- **Flutter SDK:** 3.6.1
- **Python:** 3.12.0

### 5.2 Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────┐
│                    FRONTEND (Flutter)                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Mobile     │  │     Web      │  │   Desktop    │  │
│  │  (Android/   │  │   (Chrome/   │  │  (Windows/   │  │
│  │    iOS)      │  │   Firefox)   │  │  Linux/Mac)  │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
                        │
                        │ HTTP/REST
                        ▼
┌─────────────────────────────────────────────────────────┐
│              BACKEND SERVICES                            │
│  ┌──────────────────┐  ┌──────────────────┐           │
│  │   FastAPI        │  │  Puppeteer Proxy  │           │
│  │  (Python)        │  │   (Node.js)       │           │
│  │  - Rastreo DHL   │  │  - Fallback       │           │
│  │  - Caché SQLite  │  │  - Web Scraping   │           │
│  └──────────────────┘  └──────────────────┘           │
└─────────────────────────────────────────────────────────┘
                        │
                        │ HTTP/REST
                        ▼
┌─────────────────────────────────────────────────────────┐
│              BASE DE DATOS                               │
│  ┌──────────────────────────────────────────────────┐  │
│  │            Supabase (PostgreSQL)                  │  │
│  │  - Usuarios y Autenticación                      │  │
│  │  - Inventarios                                    │  │
│  │  - Envíos y Rastreo                              │  │
│  │  - Equipos de Cómputo                            │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### 5.3 Plataformas Soportadas

- ✅ **Android** (móvil)
- ✅ **iOS** (móvil)
- ✅ **Web** (navegadores modernos)
- ✅ **Windows** (escritorio)
- ✅ **Linux** (escritorio)
- ✅ **macOS** (escritorio)

---

## 6. NOTAS ADICIONALES

### 6.1 Librerías Críticas para Funcionalidades Principales

- **Rastreo de Envíos DHL:**
  - `http` (Flutter) - Cliente HTTP
  - `fastapi` (Python) - API de rastreo
  - `httpx` (Python) - Peticiones asíncronas
  - `beautifulsoup4` (Python) - Parsing HTML

- **Gestión de Inventarios:**
  - `supabase_flutter` - Base de datos
  - `mobile_scanner` - Escaneo de códigos
  - `geolocator` - Ubicación GPS
  - `excel` - Importación/exportación

- **Autenticación y Seguridad:**
  - `supabase_flutter` - Autenticación
  - `bcrypt` - Encriptación de contraseñas
  - `shared_preferences` - Sesión local

### 6.2 Consideraciones de Rendimiento

- **FastAPI + Uvicorn:** Servidor de alto rendimiento para manejar múltiples solicitudes concurrentes
- **HTTPX:** Cliente HTTP asíncrono que permite operaciones no bloqueantes
- **Provider:** Gestión de estado eficiente que minimiza reconstrucciones innecesarias de widgets

### 6.3 Seguridad

- **Bcrypt:** Algoritmo de hashing unidireccional para contraseñas
- **Supabase:** Autenticación y autorización segura con JWT tokens
- **HTTPS:** Todas las comunicaciones con servicios externos utilizan conexiones seguras

---

**Documento generado para el Marco Teórico del Proyecto de Residencia 2025-2026**
**Sistema de Gestión de Inventarios y Rastreo de Envíos - TELMEX**

