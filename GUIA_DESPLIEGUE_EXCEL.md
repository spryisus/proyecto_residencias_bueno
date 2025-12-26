# 🚀 Guía de Despliegue para Exportación de Excel

Esta guía te ayudará a desplegar el servicio de generación de Excel para que funcione en producción.

## 📋 Requisitos

Para que la exportación de Excel funcione en producción, necesitas:

1. **Servicio Python FastAPI** corriendo y accesible desde internet
2. **Plantillas Excel** disponibles en el servidor
3. **Configuración de URL** en la app Flutter

---

## 🎯 Opción 1: Desplegar en Render.com (Recomendado - Gratis)

### Paso 1: Preparar el repositorio

1. Asegúrate de que el servicio esté en tu repositorio Git
2. Crea un archivo `render.yaml` en la raíz del proyecto:

```yaml
services:
  - type: web
    name: excel-generator-service
    env: python
    buildCommand: cd excel_generator_service && pip install -r requirements.txt
    startCommand: cd excel_generator_service && uvicorn main:app --host 0.0.0.0 --port $PORT
    envVars:
      - key: PORT
        value: 8001
```

### Paso 2: Desplegar en Render

1. Ve a [render.com](https://render.com) y crea una cuenta
2. Conecta tu repositorio de GitHub/GitLab
3. Crea un nuevo **Web Service**
4. Configura:
   - **Name**: `excel-generator-service`
   - **Environment**: `Python 3`
   - **Build Command**: `cd excel_generator_service && pip install -r requirements.txt`
   - **Start Command**: `cd excel_generator_service && uvicorn main:app --host 0.0.0.0 --port $PORT`
   - **Root Directory**: Dejar vacío o poner `/excel_generator_service`

5. Render te dará una URL como: `https://excel-generator-service.onrender.com`

### Paso 3: Actualizar configuración en Flutter

Edita `lib/app/config/excel_service_config.dart`:

```dart
static const String productionUrl = 'https://excel-generator-service.onrender.com';
```

### Paso 4: Verificar despliegue

Visita en tu navegador:
- `https://tu-servicio.onrender.com/health` - Debe responder con estado OK
- `https://tu-servicio.onrender.com/docs` - Documentación de la API

---

## 🎯 Opción 2: Desplegar en Railway.app

### Paso 1: Preparar el proyecto

1. Crea un archivo `Procfile` en `excel_generator_service/`:

```
web: uvicorn main:app --host 0.0.0.0 --port $PORT
```

### Paso 2: Desplegar en Railway

1. Ve a [railway.app](https://railway.app) y crea una cuenta
2. Crea un nuevo proyecto
3. Conecta tu repositorio
4. Railway detectará automáticamente que es Python
5. Configura:
   - **Start Command**: `uvicorn main:app --host 0.0.0.0 --port $PORT`
   - **Root Directory**: `excel_generator_service`

### Paso 3: Actualizar configuración

Actualiza `productionUrl` en Flutter con la URL que Railway te proporcione.

---

## 🎯 Opción 3: Desplegar en Fly.io

### Paso 1: Instalar Fly CLI

```bash
curl -L https://fly.io/install.sh | sh
```

### Paso 2: Crear configuración

En `excel_generator_service/`, crea `fly.toml`:

```toml
app = "excel-generator-service"
primary_region = "iad"

[build]
  builder = "paketobuildpacks/builder:base"

[env]
  PORT = "8001"

[[services]]
  internal_port = 8001
  protocol = "tcp"

  [[services.ports]]
    port = 80
    handlers = ["http"]
    force_https = true

  [[services.ports]]
    port = 443
    handlers = ["tls", "http"]
```

### Paso 3: Desplegar

```bash
cd excel_generator_service
fly launch
fly deploy
```

---

## 🎯 Opción 4: Desplegar en tu propio servidor (VPS)

### Paso 1: Preparar el servidor

```bash
# Instalar Python 3.10+
sudo apt update
sudo apt install python3 python3-pip python3-venv

# Clonar tu repositorio
git clone tu-repositorio
cd proyecto_residencia_2025_2026/excel_generator_service
```

### Paso 2: Configurar entorno virtual

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Paso 3: Usar systemd para mantener el servicio corriendo

Crea `/etc/systemd/system/excel-service.service`:

```ini
[Unit]
Description=Excel Generator Service
After=network.target

[Service]
Type=simple
User=tu-usuario
WorkingDirectory=/ruta/a/excel_generator_service
Environment="PATH=/ruta/a/excel_generator_service/venv/bin"
ExecStart=/ruta/a/excel_generator_service/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8001
Restart=always

[Install]
WantedBy=multi-user.target
```

### Paso 4: Iniciar el servicio

```bash
sudo systemctl enable excel-service
sudo systemctl start excel-service
sudo systemctl status excel-service
```

### Paso 5: Configurar Nginx como proxy reverso (opcional)

```nginx
server {
    listen 80;
    server_name tu-dominio.com;

    location / {
        proxy_pass http://localhost:8001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## ✅ Verificación Post-Despliegue

### 1. Verificar que el servicio está corriendo

```bash
curl https://tu-servicio.com/health
```

Debe responder:
```json
{
  "ok": true,
  "templates": {
    "jumpers": true,
    "computo": true,
    "sdr": true
  }
}
```

### 2. Probar desde Flutter

En tu app Flutter, verifica que la URL de producción esté configurada:

```dart
// En lib/app/config/excel_service_config.dart
static const String productionUrl = 'https://tu-servicio.com';
```

### 3. Forzar uso de producción (opcional)

Si quieres forzar el uso de producción en desarrollo:

```dart
ExcelServiceConfig.getServiceUrl(useProduction: true)
```

---

## 🔧 Configuración de Variables de Entorno

### Para Render/Railway/Fly.io

Puedes configurar variables de entorno en el panel de control:

- `PORT`: Puerto donde corre el servicio (generalmente se asigna automáticamente)
- `ENVIRONMENT`: `production` o `development`

### Para VPS propio

Crea un archivo `.env` en `excel_generator_service/`:

```env
PORT=8001
ENVIRONMENT=production
```

---

## 📦 Plantillas Excel

Asegúrate de que las plantillas estén disponibles en el servidor:

1. **En Render/Railway/Fly.io**: Las plantillas deben estar en el repositorio en:
   - `excel_generator_service/assets/templates/plantilla_jumpers.xlsx`
   - `excel_generator_service/assets/templates/plantilla_inventario_computo.xlsx`
   - `excel_generator_service/assets/templates/plantilla_sdr.xlsx`

2. **En VPS**: Copia las plantillas al servidor o asegúrate de que estén en el repositorio.

---

## 🐛 Solución de Problemas

### Error: "Connection refused"

- Verifica que el servicio esté corriendo
- Verifica que la URL esté correcta
- Verifica que el puerto esté abierto (firewall)

### Error: "CORS policy"

El servicio ya tiene CORS configurado, pero si tienes problemas:

```python
# En main.py, verifica que CORS esté así:
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En producción, especifica tus dominios
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### Error: "Template not found"

- Verifica que las plantillas estén en la ruta correcta
- Verifica los permisos de lectura de los archivos

---

## 📝 Resumen de URLs Necesarias

1. **Desarrollo Local**:
   - Web: `http://localhost:8001`
   - Móvil: `http://[TU_IP_LOCAL]:8001`

2. **Producción**:
   - Actualiza `productionUrl` en `excel_service_config.dart` con tu URL de producción

---

## 🎉 Listo!

Una vez desplegado, tu aplicación Flutter podrá generar archivos Excel desde cualquier dispositivo conectado a internet, sin necesidad de tener el servicio corriendo localmente.

