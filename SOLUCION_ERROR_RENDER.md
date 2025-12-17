# 🔧 Solución: Error "Dockerfile not found" en Render.com

## ❌ Problema

Render está intentando usar Docker cuando debería usar Node directamente.

Error:
```
failed to read dockerfile: open Dockerfile: no such file or directory
```

## ✅ Solución

Render detecta automáticamente el Dockerfile y trata de usarlo. Necesitas configurar el servicio para usar **Node** explícitamente.

### Opción 1: Configurar en Render Dashboard (RECOMENDADO)

1. Ve a tu servicio en Render.com
2. Haz clic en **"Settings"** (en el menú lateral)
3. Busca la sección **"Build & Deploy"**
4. Verifica/Configura:
   - **Environment:** Debe ser `Node` (NO Docker)
   - **Build Command:** `npm install`
   - **Start Command:** `npm start`
   - **Root Directory:** `dhl_tracking_proxy`

5. Si ves una opción de "Docker", desactívala o asegúrate de que esté en modo "Node"

6. Guarda los cambios
7. Haz clic en **"Manual Deploy"** → **"Deploy latest commit"**

### Opción 2: Eliminar/Renombrar Dockerfile temporalmente

Si la Opción 1 no funciona:

1. Renombra el Dockerfile para que Render no lo detecte:
```bash
cd dhl_tracking_proxy
mv Dockerfile Dockerfile.backup
```

2. Sube el cambio:
```bash
git add dhl_tracking_proxy/Dockerfile.backup
git rm dhl_tracking_proxy/Dockerfile
git commit -m "Renombrar Dockerfile para evitar conflicto con Render"
git push origin main
```

3. Render debería detectar automáticamente Node.js

### Opción 3: Usar render.yaml (si Render lo soporta)

El archivo `render.yaml` debería funcionar, pero Render puede no detectarlo automáticamente.

1. Ve a Settings → Build & Deploy
2. Busca "Render YAML" o "Configuration File"
3. Especifica: `dhl_tracking_proxy/render.yaml`

## ✅ Configuración Correcta en Render

**Settings → Build & Deploy:**
- ✅ **Environment:** `Node`
- ✅ **Build Command:** `npm install`
- ✅ **Start Command:** `npm start`
- ✅ **Root Directory:** `dhl_tracking_proxy`
- ❌ **NO usar Docker**

**Environment Variables:**
- `NODE_ENV` = `production`
- `PORT` = `3000`
- `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD` = `false`

## 🔄 Después de Corregir

1. Guarda los cambios en Settings
2. Ve a "Events" o "Deploys"
3. Haz clic en **"Manual Deploy"** → **"Deploy latest commit"**
4. Espera a que se complete el despliegue
5. Verifica que funcione: `https://tu-app.onrender.com/health`

## 📝 Nota

El Dockerfile es útil para otras plataformas (Railway, Fly.io), pero Render funciona mejor con Node directamente cuando tienes un `package.json`.

