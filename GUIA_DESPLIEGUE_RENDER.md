# 🚀 Guía Completa: Desplegar Servidor Proxy DHL en Render.com

## ✅ Pre-requisitos Completados

- ✅ Cuenta de GitHub creada
- ✅ Cuenta de Render.com creada
- ✅ GitHub conectado a Render.com

## 📝 Paso 1: Preparar el Repositorio

### 1.1 Verificar que todo esté listo

```bash
cd /home/spryisus/Flutter/Proyecto_Telmex
git status
```

### 1.2 Agregar y commitear los cambios nuevos

```bash
# Agregar todos los archivos nuevos y modificados
git add .

# Hacer commit
git commit -m "Preparar proyecto para despliegue en Render.com - Agregar configuración DHL proxy"

# Subir a GitHub
git push origin main
```

## 🌐 Paso 2: Crear Servicio en Render.com

### 2.1 Acceder a Render Dashboard

1. Ve a [dashboard.render.com](https://dashboard.render.com)
2. Inicia sesión con tu cuenta

### 2.2 Crear Nuevo Web Service

1. Haz clic en el botón **"New +"** (arriba a la derecha)
2. Selecciona **"Web Service"**
3. Si te pide conectar un repositorio:
   - Haz clic en **"Connect account"** o **"Configure account"**
   - Autoriza Render para acceder a tus repositorios de GitHub
   - Selecciona los repositorios que quieres conectar (o todos)

### 2.3 Seleccionar Repositorio

1. En la lista de repositorios, busca y selecciona tu repositorio del proyecto Telmex
2. Haz clic en **"Connect"**

### 2.4 Configurar el Servicio ⚠️ IMPORTANTE

**Configuración Básica:**
- **Name:** `dhl-tracking-proxy` (o el nombre que prefieras)
- **Region:** Elige la más cercana (ej: `Oregon (US West)` para México)
- **Branch:** `main` (o la rama que uses)

**⚠️ CONFIGURACIÓN CRÍTICA - Root Directory:**
- **Root Directory:** `dhl_tracking_proxy`
  - Esto le dice a Render que el código del servidor está en la carpeta `dhl_tracking_proxy`
  - **Sin esto, Render no encontrará tu `package.json` y fallará**

**Configuración de Build:**
- **Environment:** `Node`
- **Build Command:** `npm install`
- **Start Command:** `npm start`

**Plan:**
- Para empezar: **Free** (gratis, pero se duerme tras inactividad)
- Para producción: **Starter** ($7/mes, siempre activo)

### 2.5 Variables de Entorno

En la sección **"Environment Variables"**, agrega estas variables:

| Key | Value |
|-----|-------|
| `NODE_ENV` | `production` |
| `PORT` | `3000` |
| `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD` | `false` |

**Nota:** Render automáticamente proporciona una variable `PORT`, pero es bueno tenerla definida.

### 2.6 Crear el Servicio

1. Revisa toda la configuración
2. Haz clic en **"Create Web Service"**
3. Render comenzará a construir tu servicio

## ⏳ Paso 3: Esperar el Despliegue

### 3.1 Ver el Progreso

Render mostrará los logs en tiempo real:
- Instalando dependencias
- Construyendo la aplicación
- Iniciando el servidor

**Primera vez:** Puede tardar 5-10 minutos

### 3.2 Verificar que Funcione

Una vez completado, verás:
- ✅ Estado: "Live"
- ✅ URL: `https://dhl-tracking-proxy.onrender.com` (o similar)

## 🧪 Paso 4: Probar el Servicio

### 4.1 Health Check

Abre en tu navegador o usa curl:
```
https://tu-app.onrender.com/health
```

Deberías ver:
```json
{"status":"ok","service":"DHL Tracking Proxy"}
```

### 4.2 Probar Tracking

```
https://tu-app.onrender.com/api/track/6376423056
```

Deberías recibir una respuesta JSON con los datos del tracking.

## 📱 Paso 5: Actualizar tu App Flutter

### 5.1 Actualizar la URL de Producción

1. Abre `lib/app/config/dhl_proxy_config.dart`
2. Busca la línea:
```dart
static const String productionUrl = 'https://dhl-tracking-proxy.onrender.com';
```
3. Reemplaza con tu URL real de Render:
```dart
static const String productionUrl = 'https://TU-APP.onrender.com';
```

### 5.2 Cambiar a Modo Producción

1. Abre `lib/screens/shipments/track_shipment_screen.dart`
2. Busca la línea ~26:
```dart
proxyUrl: DHLProxyConfig.getProxyUrl(useProduction: false),
```
3. Cambia a:
```dart
proxyUrl: DHLProxyConfig.getProxyUrl(useProduction: true),
```

### 5.3 Recompilar la App

```bash
# Limpiar build anterior
flutter clean

# Recompilar
flutter build apk --release
# O para probar:
flutter run -d ZY22GM9L3K
```

## 🔧 Solución de Problemas Comunes

### ❌ Error: "Cannot find module 'express'"

**Causa:** Root Directory no está configurado correctamente

**Solución:**
1. Ve a Settings del servicio en Render
2. Verifica que **Root Directory** sea exactamente: `dhl_tracking_proxy`
3. Guarda y vuelve a desplegar

### ❌ Error: "Puppeteer failed to launch"

**Causa:** Chrome no se instaló correctamente

**Solución:**
- Render instala Chrome automáticamente
- Verifica que `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=false` esté en las variables de entorno
- Las flags en `server.js` ya incluyen `--no-sandbox` que es necesario

### ⏱️ El servicio tarda mucho en responder

**Causa:** Tier gratuito se duerme tras 15 min de inactividad

**Solución:**
- Primera petición después de dormirse puede tardar 30-60 segundos
- Considera el plan Starter ($7/mes) para producción
- O usa un servicio de "ping" para mantenerlo activo

### 🔒 Error de CORS

**Causa:** Tu app Flutter no puede hacer peticiones al servidor

**Solución:**
- El servidor ya tiene CORS habilitado (`app.use(cors())`)
- Si persiste, verifica que la URL sea HTTPS (no HTTP)

## 📊 Monitoreo

Render proporciona:
- **Logs en tiempo real:** Ve a tu servicio → "Logs"
- **Métricas:** CPU, Memoria, Red
- **Eventos:** Despliegues, errores, etc.

## 💰 Costos

**Free Tier:**
- ✅ Gratis
- ⚠️ Se duerme tras 15 min de inactividad
- ⚠️ Primera petición después de dormirse es lenta

**Starter ($7/mes):**
- ✅ Siempre activo
- ✅ 512MB RAM
- ✅ Respuesta rápida siempre
- ✅ Ideal para producción

## ✅ Checklist Final

- [ ] Repositorio subido a GitHub
- [ ] Servicio creado en Render.com
- [ ] Root Directory configurado como `dhl_tracking_proxy`
- [ ] Variables de entorno configuradas
- [ ] Servicio desplegado y funcionando
- [ ] Health check responde correctamente
- [ ] URL actualizada en `dhl_proxy_config.dart`
- [ ] App Flutter configurada para usar producción
- [ ] App probada y funcionando

## 🎉 ¡Listo!

Tu servidor proxy DHL está en la nube y tu app móvil puede usarlo desde cualquier lugar sin necesidad de tu laptop.

---

**¿Necesitas ayuda?** Revisa los logs en Render o consulta la documentación en `dhl_tracking_proxy/README_RENDER.md`

