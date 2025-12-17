# 🚀 Guía de Despliegue en Render.com - FastAPI Tracking Service

## 📋 Requisitos Previos

1. ✅ Cuenta en [Render.com](https://render.com)
2. ✅ Código subido a GitHub
3. ✅ URL de tu proxy Puppeteer (si lo tienes desplegado)

---

## 🔧 Paso 1: Preparar el Repositorio

Asegúrate de que el código esté en GitHub:

```bash
cd ~/Flutter/proyecto_residencia_2025_2026
git add fastapi_tracking_service/
git commit -m "Add FastAPI tracking service for Render deployment"
git push
```

---

## 🌐 Paso 2: Crear Servicio en Render

### Opción A: Usando render.yaml (Recomendado)

1. Ve a [Render Dashboard](https://dashboard.render.com)
2. Clic en **"New"** → **"Blueprint"**
3. Conecta tu repositorio de GitHub
4. Render detectará automáticamente el `render.yaml` en `fastapi_tracking_service/`
5. Render creará el servicio automáticamente

### Opción B: Creación Manual

1. Ve a [Render Dashboard](https://dashboard.render.com)
2. Clic en **"New"** → **"Web Service"**
3. Conecta tu repositorio de GitHub
4. Configura:
   - **Name:** `fastapi-tracking-service`
   - **Environment:** `Python 3`
   - **Root Directory:** `fastapi_tracking_service`
   - **Build Command:** `pip install -r requirements.txt`
   - **Start Command:** `uvicorn main:app --host 0.0.0.0 --port $PORT`

---

## ⚙️ Paso 3: Configurar Variables de Entorno

En el dashboard de Render, ve a **Environment** y agrega:

| Variable | Valor | Descripción |
|----------|-------|-------------|
| `PORT` | `8000` | Puerto del servicio (Render lo sobrescribe automáticamente) |
| `CACHE_TTL_SECONDS` | `1800` | Tiempo de vida del caché (30 minutos) |
| `UPSTREAM_TIMEOUT_SECONDS` | `10` | Timeout para peticiones a DHL |
| `PUPPETEER_PROXY_URL` | `https://tu-proxy.onrender.com` | URL de tu proxy Puppeteer (si lo tienes) |
| `ALLOWED_ORIGINS` | `*` | Orígenes permitidos para CORS (o lista separada por comas) |

**⚠️ IMPORTANTE:** Actualiza `PUPPETEER_PROXY_URL` con la URL real de tu proxy Puppeteer en Render.

---

## 🚀 Paso 4: Desplegar

1. Clic en **"Create Web Service"** o **"Save Changes"**
2. Render comenzará a construir y desplegar automáticamente
3. Espera 5-10 minutos para que complete el despliegue
4. Obtendrás una URL como: `https://fastapi-tracking-service.onrender.com`

---

## ✅ Paso 5: Verificar el Despliegue

Prueba los endpoints:

```bash
# Health check
curl https://tu-fastapi.onrender.com/health

# Tracking (reemplaza con una guía real)
curl "https://tu-fastapi.onrender.com/tracking/9068591556"
```

---

## 🔄 Paso 6: Actualizar Flutter

Actualiza la URL de producción en `lib/app/config/dhl_proxy_config.dart`:

```dart
static const String fastApiProductionUrl = 'https://tu-fastapi.onrender.com';
```

---

## 📝 Notas Importantes

### Plan Gratuito
- ⚠️ El servicio se "duerme" después de 15 minutos de inactividad
- ⚠️ La primera petición después de dormirse puede tardar 30-60 segundos (cold start)
- ✅ Para evitar esto, puedes usar un servicio de keep-alive (UptimeRobot, cron-job.org)

### Plan Pagado ($7/mes)
- ✅ Servicio siempre activo
- ✅ Sin cold starts
- ✅ Mejor rendimiento

### Caché SQLite
- El caché se guarda en `cache.db` en el sistema de archivos
- ⚠️ En Render, el sistema de archivos es **efímero** (se pierde al reiniciar)
- Esto está bien para caché, pero no para datos críticos
- Si necesitas persistencia, considera usar Redis (add-on de Render)

---

## 🔧 Troubleshooting

### Error: "Module not found"
- Verifica que `requirements.txt` tenga todas las dependencias
- Revisa los logs de build en Render

### Error: "Port already in use"
- Render asigna el puerto automáticamente via `$PORT`
- No hardcodees el puerto en el código

### El servicio se duerme muy rápido
- Usa un servicio de keep-alive externo
- O actualiza al plan Starter ($7/mes)

### CORS errors desde Flutter
- Verifica que `ALLOWED_ORIGINS` incluya tu dominio Flutter
- O usa `*` para desarrollo (no recomendado en producción)

---

## 📚 Recursos

- [Documentación de Render](https://render.com/docs)
- [FastAPI en Render](https://render.com/docs/deploy-fastapi)
- [Variables de Entorno en Render](https://render.com/docs/environment-variables)

