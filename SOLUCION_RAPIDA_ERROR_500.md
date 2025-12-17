# ⚡ Solución Rápida para Error 500

## 🔧 Cambiar Variables de Entorno en Render

El problema más común es que Puppeteer no puede encontrar Chrome.

### Paso 1: Ir a Settings → Environment

1. Ve a tu servicio en Render
2. Settings (menú lateral)
3. Environment

### Paso 2: Cambiar/Agregar Variables

**Elimina estas variables si existen:**
- ❌ `PUPPETEER_EXECUTABLE_PATH` (elimínala)
- ❌ `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD` (elimínala o cambia a `false`)

**Agrega/Mantén estas:**
- ✅ `NODE_ENV` = `production`
- ✅ `PORT` = `3000`

### Paso 3: Guardar y Redesplegar

1. Guarda los cambios
2. Ve a "Events" o "Deploys"
3. Manual Deploy → Deploy latest commit
4. Espera 5-10 minutos

Esto permitirá que Puppeteer descargue Chrome durante el build.





