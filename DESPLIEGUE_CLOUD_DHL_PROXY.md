# ☁️ Guía de Despliegue del Servidor Proxy DHL en la Nube

## 📊 Análisis de Requisitos

**Tecnología:**
- Node.js + Express
- Puppeteer (requiere Chrome headless)
- ~500MB - 1GB RAM recomendado
- Proceso de largo plazo (no serverless puro)

**Requisitos Críticos:**
- ✅ Soporte para Puppeteer/Chrome headless
- ✅ Memoria suficiente (mínimo 512MB, ideal 1GB+)
- ✅ Ejecución continua (no solo funciones serverless)
- ✅ Instalación de dependencias del sistema para Chrome

---

## 🏆 RECOMENDACIONES (Ordenadas por facilidad/costo)

### 🥇 **1. Render.com** ⭐ RECOMENDADO

**Ventajas:**
- ✅ **GRATIS** para empezar (tier gratuito disponible)
- ✅ Muy fácil de desplegar (conecta con GitHub)
- ✅ Soporte nativo para Puppeteer
- ✅ Auto-deploy desde Git
- ✅ SSL/HTTPS automático
- ✅ Monitoreo incluido
- ✅ Perfecto para aplicaciones pequeñas/medianas

**Desventajas:**
- ⚠️ Tier gratuito se "duerme" después de 15 min de inactividad
- ⚠️ Tiempo de arranque puede ser lento (30-60 segundos)

**Costo:**
- Gratis: 512MB RAM, se duerme tras inactividad
- $7/mes: 512MB RAM, siempre activo
- $25/mes: 2GB RAM, siempre activo

**Mejor para:** Proyectos pequeños/medianos, testing, desarrollo

---

### 🥈 **2. Railway.app** ⭐ MUY RECOMENDADO

**Ventajas:**
- ✅ **GRATIS** para empezar ($5 crédito mensual)
- ✅ Extremadamente fácil de desplegar
- ✅ Soporte excelente para Node.js + Puppeteer
- ✅ Auto-deploy desde GitHub
- ✅ Variables de entorno fáciles
- ✅ Logs en tiempo real
- ✅ Sin configuración compleja

**Desventajas:**
- ⚠️ Créditos pueden acabarse rápido con alto tráfico
- ⚠️ Precios pueden escalar con el uso

**Costo:**
- $5 crédito gratis/mes
- ~$0.01 por GB de RAM/hora
- ~$7-15/mes para uso típico

**Mejor para:** Proyectos que necesitan facilidad de uso y despliegue rápido

---

### 🥉 **3. Fly.io** ⭐ BUENO PARA PRODUCCIÓN

**Ventajas:**
- ✅ **GRATIS** tier disponible
- ✅ Muy rápido (edge computing)
- ✅ Excelente para aplicaciones globales
- ✅ Docker nativo
- ✅ Escalado fácil
- ✅ Buena documentación

**Desventajas:**
- ⚠️ Requiere Dockerfile
- ⚠️ Curva de aprendizaje un poco mayor

**Costo:**
- Gratis: 3 VMs compartidas, 256MB RAM cada una
- Pago: ~$5-10/mes por VM con más recursos

**Mejor para:** Aplicaciones que necesitan distribución global

---

### **4. DigitalOcean App Platform**

**Ventajas:**
- ✅ Predecible y estable
- ✅ Buena relación precio/rendimiento
- ✅ Excelente soporte técnico
- ✅ Múltiples opciones de despliegue
- ✅ Buena para empresas

**Desventajas:**
- ⚠️ No tiene tier gratuito
- ⚠️ Requiere tarjeta de crédito desde el inicio

**Costo:**
- $5/mes: 512MB RAM (Basic)
- $12/mes: 1GB RAM (Professional)

**Mejor para:** Proyectos de producción serios, empresas

---

### **5. Heroku**

**Ventajas:**
- ✅ Muy fácil de usar
- ✅ Ecosystem maduro
- ✅ Add-ons disponibles
- ✅ Buena documentación

**Desventajas:**
- ❌ **Ya no tiene tier gratuito** (eliminado en 2022)
- ⚠️ Más caro que alternativas modernas
- ⚠️ Puede ser lento

**Costo:**
- $7/mes mínimo (Eco Dyno)
- $25/mes para mejor rendimiento

**Mejor para:** Proyectos existentes en Heroku, empresas grandes

---

### **6. AWS (EC2 / ECS / Elastic Beanstalk)**

**Ventajas:**
- ✅ Máximo control
- ✅ Infraestructura robusta
- ✅ Escalabilidad infinita
- ✅ Opciones de configuración avanzadas

**Desventajas:**
- ❌ **Complejo de configurar**
- ❌ Curva de aprendizaje alta
- ❌ Puede ser costoso si no se optimiza
- ❌ Requiere conocimiento de AWS

**Costo:**
- EC2 t3.micro: ~$7-10/mes
- Elastic Beanstalk: ~$10-20/mes

**Mejor para:** Empresas grandes, equipos con experiencia en AWS

---

## 🚀 RECOMENDACIÓN FINAL

### **Para tu caso específico, te recomiendo:**

1. **Empezar con Railway.app o Render.com** (ambos tienen tier gratuito)
2. **Migrar a DigitalOcean App Platform** cuando necesites más estabilidad
3. **Usar AWS** solo si necesitas escalabilidad empresarial

---

## 📋 PASOS PARA DESPLEGAR EN RENDER.COM (Más fácil)

### Paso 1: Preparar el proyecto

1. Asegúrate de que tu código esté en GitHub
2. Crea un archivo `render.yaml` (opcional) o despliega manualmente

### Paso 2: Crear cuenta en Render

1. Ve a [render.com](https://render.com)
2. Conecta tu cuenta de GitHub
3. Selecciona "New Web Service"

### Paso 3: Configurar el servicio

**Configuración:**
- **Name:** `dhl-tracking-proxy`
- **Environment:** `Node`
- **Build Command:** `npm install`
- **Start Command:** `npm start`
- **Plan:** Free (para empezar) o Starter ($7/mes)

**Variables de Entorno:**
```
PORT=3000
NODE_ENV=production
```

### Paso 4: Desplegar

1. Selecciona tu repositorio de GitHub
2. Render detectará automáticamente Node.js
3. Haz clic en "Create Web Service"
4. Espera a que se complete el despliegue (5-10 minutos)

### Paso 5: Obtener la URL

Render te dará una URL como:
```
https://dhl-tracking-proxy.onrender.com
```

---

## 📋 PASOS PARA DESPLEGAR EN RAILWAY.APP

### Paso 1: Preparar el proyecto

1. Sube tu código a GitHub
2. Railway puede auto-detectar Node.js

### Paso 2: Crear cuenta en Railway

1. Ve a [railway.app](https://railway.app)
2. Conecta con GitHub
3. Clic en "New Project"
4. Selecciona "Deploy from GitHub repo"

### Paso 3: Configurar

Railway detectará automáticamente:
- **Build Command:** `npm install`
- **Start Command:** `npm start`

**Variables de Entorno:**
- Agrega `PORT` (Railway lo proporciona automáticamente)
- Agrega `NODE_ENV=production`

### Paso 4: Obtener dominio

Railway genera automáticamente un dominio:
```
https://dhl-tracking-proxy.railway.app
```

---

## 🔧 CONFIGURACIONES NECESARIAS PARA PUPPETEER

Ambas plataformas necesitan estas configuraciones:

### 1. Variables de Entorno Adicionales:

```env
PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=false
PUPPETEER_CACHE_DIR=/tmp/.puppeteer_cache
```

### 2. Actualizar `package.json`:

Render y Railway necesitan asegurarse de que Puppeteer use las dependencias correctas:

```json
{
  "engines": {
    "node": ">=18.0.0",
    "npm": ">=8.0.0"
  },
  "scripts": {
    "start": "node server.js",
    "postinstall": "node -e \"require('puppeteer').executablePath()\""
  }
}
```

### 3. Actualizar `server.js` para producción:

Las plataformas cloud ya tienen las flags necesarias, pero asegúrate:

```javascript
browser = await puppeteer.launch({
  headless: true,
  args: [
    '--no-sandbox',
    '--disable-setuid-sandbox',
    '--disable-dev-shm-usage',
    '--disable-accelerated-2d-canvas',
    '--disable-gpu',
    '--single-process', // Para entornos con poca memoria
  ],
});
```

---

## 📱 ACTUALIZAR TU APLICACIÓN FLUTTER

Después de desplegar, actualiza la URL en tu app Flutter:

### Opción 1: Variable de entorno

Crea un archivo de configuración para diferentes ambientes:

```dart
// lib/app/config/dhl_proxy_config.dart
class DHLProxyConfig {
  // Desarrollo local
  static const String localUrl = 'http://192.168.1.178:3000';
  
  // Producción (actualizar con tu URL de Render/Railway)
  static const String productionUrl = 'https://dhl-tracking-proxy.onrender.com';
  
  // Detectar ambiente
  static String get proxyUrl {
    const bool isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);
    return isProduction ? productionUrl : localUrl;
  }
}
```

### Opción 2: Actualizar directamente en `track_shipment_screen.dart`

```dart
String _getProxyUrl() {
  if (kIsWeb) {
    return 'http://localhost:3000';
  } else {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Cambiar a tu URL de producción
        return 'https://dhl-tracking-proxy.onrender.com';
      } else {
        return 'http://localhost:3000';
      }
    } catch (e) {
      return 'http://localhost:3000';
    }
  }
}
```

---

## ✅ CHECKLIST PRE-DESPLIEGUE

- [ ] Código subido a GitHub
- [ ] `package.json` tiene scripts correctos
- [ ] Variables de entorno configuradas
- [ ] `server.js` tiene flags correctas para Puppeteer
- [ ] Puerto usa variable de entorno `PORT`
- [ ] CORS configurado para aceptar tu dominio Flutter
- [ ] Health check endpoint funcionando (`/health`)

---

## 🧪 PROBAR EL DESPLIEGUE

Después de desplegar, prueba:

```bash
# Health check
curl https://tu-app.onrender.com/health

# Probar tracking
curl https://tu-app.onrender.com/api/track/6376423056
```

---

## 💡 RECOMENDACIÓN FINAL

**Para empezar:** Railway.app o Render.com (ambos gratis)

**Para producción seria:** DigitalOcean App Platform o Fly.io

**¿Necesitas ayuda con el despliegue?** Puedo crear los archivos de configuración necesarios.


