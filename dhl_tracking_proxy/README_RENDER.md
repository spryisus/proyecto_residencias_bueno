# 🚀 Despliegue en Render.com - Guía Rápida

## 📋 Pasos para Desplegar

### 1. Preparar el Repositorio

Asegúrate de que tu código esté en GitHub y que el directorio `dhl_tracking_proxy` esté incluido.

### 2. Crear Nuevo Servicio en Render

1. Ve a [dashboard.render.com](https://dashboard.render.com)
2. Haz clic en **"New +"** → **"Web Service"**
3. Conecta tu repositorio de GitHub si aún no lo has hecho
4. Selecciona el repositorio que contiene este proyecto

### 3. Configurar el Servicio

**Configuración Básica:**
- **Name:** `dhl-tracking-proxy` (o el nombre que prefieras)
- **Region:** Elige la región más cercana a tus usuarios (ej: `Oregon (US West)`)
- **Branch:** `main` (o la rama que uses)

**Configuración de Build:**
- **Root Directory:** `dhl_tracking_proxy` ⚠️ **IMPORTANTE: Esto es crucial**
- **Environment:** `Node`
- **Build Command:** `npm install`
- **Start Command:** `npm start`

**Plan:**
- **Free:** Para empezar (se duerme tras 15 min de inactividad)
- **Starter ($7/mes):** Siempre activo, 512MB RAM

### 4. Variables de Entorno

En la sección "Environment Variables", agrega:

```
NODE_ENV=production
PORT=3000
PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=false
```

**Nota:** Render automáticamente proporciona el puerto, pero es bueno tenerlo definido.

### 5. Desplegar

1. Haz clic en **"Create Web Service"**
2. Render comenzará a construir y desplegar tu servicio
3. Esto puede tomar 5-10 minutos la primera vez
4. Verás los logs en tiempo real

### 6. Obtener la URL

Una vez desplegado, Render te dará una URL como:
```
https://dhl-tracking-proxy.onrender.com
```

**⚠️ IMPORTANTE:** Guarda esta URL, la necesitarás para actualizar tu app Flutter.

### 7. Probar el Servicio

```bash
# Health check
curl https://tu-app.onrender.com/health

# Probar tracking
curl https://tu-app.onrender.com/api/track/6376423056
```

## 🔧 Solución de Problemas

### Error: "Cannot find module"
- Verifica que el **Root Directory** esté configurado como `dhl_tracking_proxy`
- Asegúrate de que `package.json` esté en ese directorio

### Error: "Puppeteer no funciona"
- Render instala Chrome automáticamente
- Si hay problemas, verifica que las flags en `server.js` incluyan `--no-sandbox`

### El servicio se duerme (tier gratuito)
- El tier gratuito se duerme tras 15 min de inactividad
- La primera petición después de dormirse puede tardar 30-60 segundos
- Considera el plan Starter ($7/mes) para producción

### Timeout en las peticiones
- Render tiene un timeout de 30 segundos por defecto
- Si tus consultas tardan más, considera aumentar el timeout o usar un plan superior

## 📱 Actualizar tu App Flutter

Después de obtener la URL de Render:

1. Abre `lib/app/config/dhl_proxy_config.dart`
2. Actualiza `productionUrl`:
```dart
static const String productionUrl = 'https://tu-app.onrender.com';
```

3. En `lib/screens/shipments/track_shipment_screen.dart`, cambia:
```dart
proxyUrl: DHLProxyConfig.getProxyUrl(useProduction: true), // Cambiar a true
```

4. Recompila tu app Flutter

## ✅ Checklist Pre-Despliegue

- [ ] Código subido a GitHub
- [ ] Root Directory configurado como `dhl_tracking_proxy`
- [ ] Variables de entorno configuradas
- [ ] Build Command: `npm install`
- [ ] Start Command: `npm start`
- [ ] Health check funciona (`/health`)

## 🎉 ¡Listo!

Tu servidor proxy DHL estará disponible en la nube y tu app móvil podrá usarlo desde cualquier lugar.

