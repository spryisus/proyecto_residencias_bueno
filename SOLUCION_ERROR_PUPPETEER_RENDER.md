# 🔧 Solución: Error de Puppeteer en Render.com

## ❌ Problema

El build falla durante `npm install` porque Puppeteer intenta descargar Chrome (~200MB) y el proceso se interrumpe:

```
npm error chrome-headless-shell (121.0.6167.85) downloaded to ...
npm error signal SIGTERM
==> Build failed
```

## ✅ Solución

Render ya tiene Chrome instalado en sus servidores. Necesitamos configurar Puppeteer para:
1. **NO descargar Chrome** durante `npm install`
2. **Usar el Chrome del sistema** que Render ya tiene

## 🔧 Cambios Realizados

### 1. Actualizado `package.json`
Agregado configuración para saltar la descarga de Chrome:
```json
"puppeteer": {
  "skipChromiumDownload": true
}
```

### 2. Actualizado `server.js`
Configurado para usar el Chrome del sistema cuando esté en Render:
```javascript
const executablePath = process.env.PUPPETEER_EXECUTABLE_PATH || 
                      (process.env.RENDER ? '/usr/bin/google-chrome-stable' : undefined);
```

### 3. Variables de Entorno en Render
Necesitas agregar estas variables en Render:

| Key | Value |
|-----|-------|
| `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD` | `true` |
| `PUPPETEER_EXECUTABLE_PATH` | `/usr/bin/google-chrome-stable` |
| `NODE_ENV` | `production` |
| `PORT` | `3000` |

## 📋 Pasos para Aplicar la Solución

### Paso 1: Subir los cambios a GitHub

```bash
cd /home/spryisus/Flutter/Proyecto_Telmex
git add dhl_tracking_proxy/package.json dhl_tracking_proxy/server.js
git commit -m "Configurar Puppeteer para usar Chrome del sistema en Render"
git push origin main
```

### Paso 2: Actualizar Variables de Entorno en Render

1. Ve a tu servicio en Render.com
2. Settings → Environment
3. Agrega/Actualiza estas variables:

**PUPPETEER_SKIP_CHROMIUM_DOWNLOAD** = `true`

**PUPPETEER_EXECUTABLE_PATH** = `/usr/bin/google-chrome-stable`

4. Guarda los cambios

### Paso 3: Hacer Nuevo Deploy

1. Ve a "Events" o "Deploys"
2. Haz clic en "Manual Deploy" → "Deploy latest commit"
3. Espera 3-5 minutos (será más rápido ahora sin descargar Chrome)

## ✅ Resultado Esperado

El build ahora:
- ✅ NO descargará Chrome durante `npm install`
- ✅ Usará el Chrome que Render ya tiene instalado
- ✅ Será mucho más rápido (3-5 minutos en lugar de 15+ minutos)
- ✅ No fallará con timeout

## 🔍 Verificar que Funciona

Después del despliegue, prueba:

```bash
curl https://tu-app.onrender.com/health
```

Deberías ver:
```json
{"status":"ok","service":"DHL Tracking Proxy"}
```

## 🐛 Si Sigue Fallando

### Opción 1: Verificar que las Variables Estén Configuradas
- Asegúrate de que `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true`
- Asegúrate de que `PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome-stable`

### Opción 2: Verificar la Ruta de Chrome
Render puede tener Chrome en diferentes rutas. Prueba:
- `/usr/bin/google-chrome-stable`
- `/usr/bin/chromium-browser`
- `/usr/bin/chromium`

Si ninguna funciona, el código detectará automáticamente el Chrome del sistema.

### Opción 3: Usar Plan Starter
El plan gratuito puede tener limitaciones de memoria. Considera:
- Plan Starter ($7/mes) con más recursos

## 📝 Notas

- **Primera vez:** Puede tardar 3-5 minutos (sin descargar Chrome)
- **Siguientes deploys:** 2-3 minutos (con cache)
- **Chrome del sistema:** Render ya lo tiene instalado, no necesitas descargarlo


