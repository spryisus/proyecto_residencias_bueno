# 🔍 Diagnosticar Error 500 en Render

## 📋 Pasos para Ver el Error Real

### Paso 1: Ver los Logs en Render

1. Ve a tu servicio en Render: `dhl-tracking-proxy`
2. En el menú lateral, haz clic en **"Logs"**
3. Verás los logs en tiempo real
4. Busca errores que digan:
   - `Error:`
   - `Failed to launch`
   - `Cannot find`
   - O cualquier mensaje en rojo

### Paso 2: Identificar el Error

Los logs mostrarán el error exacto. Los más comunes son:

**Error 1: "Cannot find Chrome"**
```
Error: Failed to launch the browser process!
Cannot find Chrome/Chromium
```

**Error 2: "Permission denied"**
```
Error: spawn /usr/bin/google-chrome-stable EACCES
```

**Error 3: "Timeout"**
```
Error: Navigation timeout of 30000 ms exceeded
```

## 🔧 Soluciones por Tipo de Error

### Error: Chrome no encontrado

**Problema:** Puppeteer no puede encontrar Chrome

**Solución:**
1. En Render → Settings → Environment
2. Agrega/Verifica estas variables:
   - `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD` = `false`
   - `PUPPETEER_EXECUTABLE_PATH` = (déjalo vacío o elimínalo)

3. O mejor: **Permitir que Puppeteer descargue Chrome**
   - Cambia `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD` a `false`
   - O elimina la variable completamente

### Error: Timeout

**Problema:** El proceso tarda demasiado

**Solución:**
- Render tiene un timeout de 30 segundos en el plan gratuito
- Considera aumentar el timeout o usar el plan Starter

### Error: Memoria insuficiente

**Problema:** El plan gratuito tiene poca RAM (512MB)

**Solución:**
- Usar el plan Starter ($7/mes) con más recursos
- O optimizar el código (ya está optimizado)

## 🚀 Solución Rápida: Permitir Descarga de Chrome

El problema más común es que configuramos Puppeteer para NO descargar Chrome, pero Render no tiene Chrome en las rutas esperadas.

### Cambiar Variables de Entorno en Render:

1. Ve a Settings → Environment
2. **Elimina o cambia:**
   - `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD` → Cambiar a `false` o eliminarla
   - `PUPPETEER_EXECUTABLE_PATH` → Eliminarla completamente

3. Guarda y haz un nuevo deploy

Esto permitirá que Puppeteer descargue su propio Chrome durante el build.

## 📝 Compartir los Logs

Para ayudarte mejor, puedes:
1. Copiar los últimos 50-100 líneas de los logs
2. O hacer una captura de pantalla del error
3. Compartirla y te ayudo a solucionarlo





