# 🔧 Pasos Detallados: Configurar Render.com para Node (NO Docker)

## ⚠️ Problema Actual

Render está configurado para usar **Docker**, pero necesitas usar **Node** directamente.

## ✅ Solución: Cambiar a Node

### Opción 1: Eliminar y Recrear el Servicio (MÁS FÁCIL)

Si acabas de crear el servicio y no tienes datos importantes:

1. **Eliminar el servicio actual:**
   - En Render, ve a tu servicio
   - Settings → Scroll hasta el final
   - Busca "Delete or suspend"
   - Haz clic en "Delete"
   - Confirma la eliminación

2. **Crear nuevo servicio con Node:**
   - Haz clic en "New +" → "Web Service"
   - Selecciona tu repositorio
   - **IMPORTANTE:** En la pantalla de configuración inicial:
     - **Environment:** Selecciona **"Node"** (NO Docker)
     - **Root Directory:** `dhl_tracking_proxy`
     - **Build Command:** `npm install`
     - **Start Command:** `npm start`
   - Haz clic en "Create Web Service"

### Opción 2: Cambiar Configuración del Servicio Actual

Si quieres mantener el servicio actual:

1. **Ve a Settings → Build & Deploy** (en el menú lateral derecho)

2. **Busca la sección "Environment" o "Runtime":**
   - Debería haber una opción para cambiar entre Docker y Node
   - Si no la ves, puede que necesites eliminar y recrear

3. **Configura Root Directory:**
   - En "Root Directory" (debería estar en la primera pantalla que viste)
   - Haz clic en "Edit"
   - Escribe: `dhl_tracking_proxy`
   - Guarda

4. **Si Render sigue intentando usar Docker:**
   - Ve a la sección "Dockerfile Path" (si la ves)
   - Déjala vacía o elimina cualquier valor
   - Guarda

## 📋 Configuración Correcta que Debes Ver

Cuando esté bien configurado, deberías ver:

**Build & Deploy:**
- ✅ **Environment:** `Node` (NO Docker)
- ✅ **Root Directory:** `dhl_tracking_proxy`
- ✅ **Build Command:** `npm install`
- ✅ **Start Command:** `npm start`

**Environment Variables:**
- `NODE_ENV` = `production`
- `PORT` = `3000`
- `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD` = `false`

## 🎯 Pasos Específicos para tu Caso

Basándome en las imágenes que compartiste:

### Paso 1: Configurar Root Directory

1. En la primera pantalla de Settings que viste (con Repository, Branch, etc.)
2. Busca **"Root Directory"**
3. Haz clic en **"Edit"**
4. Escribe: `dhl_tracking_proxy`
5. Guarda

### Paso 2: Verificar/Cambiar Environment

1. En el menú lateral derecho, haz clic en **"Build & Deploy"**
2. Busca una opción que diga **"Environment"** o **"Runtime"**
3. Si dice "Docker", necesitas cambiarlo a "Node"
4. Si no puedes cambiarlo, elimina el servicio y créalo de nuevo

### Paso 3: Configurar Build Commands

Si ves opciones de Docker, ignóralas. Busca:
- **Build Command:** Debe ser `npm install`
- **Start Command:** Debe ser `npm start`

### Paso 4: Agregar Variables de Entorno

1. Ve a **"Environment"** en el menú lateral
2. Agrega estas variables:
   - `NODE_ENV` = `production`
   - `PORT` = `3000`
   - `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD` = `false`

## 🔄 Si No Puedes Cambiar de Docker a Node

**Solución:** Elimina el servicio y créalo de nuevo:

1. Settings → Scroll hasta el final → "Delete or suspend" → "Delete"
2. "New +" → "Web Service"
3. **IMPORTANTE:** Al crear, asegúrate de seleccionar **"Node"** como Environment
4. Configura Root Directory: `dhl_tracking_proxy`

## ✅ Después de Configurar

1. Guarda todos los cambios
2. Ve a "Events" o "Deploys"
3. Haz clic en "Manual Deploy" → "Deploy latest commit"
4. Espera 5-10 minutos
5. Prueba: `https://tu-app.onrender.com/health`



