# 🚀 Guía de Despliegue a Producción - Sistema Telmex

## 📋 Componentes a Desplegar

Tu proyecto tiene 3 componentes principales:

1. **Aplicación Flutter** (Móvil, Web, Desktop)
2. **Backend Proxy Node.js** (DHL Tracking)
3. **Base de Datos Supabase** (Ya desplegada ✅)

---

## 🎯 OPCIÓN 1: Solución Todo-en-Uno (Recomendada para empezar)

### **Vercel** (Flutter Web + Node.js Backend) - ⭐ **MÁS FÁCIL**

**Ventajas:**
- ✅ Gratis para proyectos personales
- ✅ Despliegue automático desde GitHub
- ✅ SSL incluido (HTTPS)
- ✅ CDN global
- ✅ Soporta Flutter Web y Node.js

**Desventajas:**
- ⚠️ Backend puede tener cold starts (timeout en funciones serverless)
- ⚠️ Puppeteer puede ser problemático (requiere ajustes)

**Pasos:**

1. **Desplegar Flutter Web en Vercel:**
```bash
# Instalar Vercel CLI
npm i -g vercel

# Compilar Flutter Web
flutter build web --release

# Desplegar
cd build/web
vercel --prod
```

2. **Desplegar Backend Node.js en Vercel:**
```bash
cd dhl_tracking_proxy
vercel --prod
```

**Costo:** Gratis (hasta 100GB bandwidth/mes)

---

### **Netlify** (Similar a Vercel)

**Ventajas:**
- ✅ Gratis
- ✅ Fácil de usar
- ✅ SSL automático

**Pasos similares a Vercel**

**Costo:** Gratis

---

## 🔧 OPCIÓN 2: Solución Separada (Más Control)

### **A. Aplicación Flutter**

#### **Web:**
- **Vercel/Netlify** (Gratis) ⭐
- **Firebase Hosting** (Gratis) ⭐
- **GitHub Pages** (Gratis pero limitado)

#### **Móvil (Android/iOS):**
- **Google Play Store** (Android) - $25 una vez
- **Apple App Store** (iOS) - $99/año
- **Alternativas:**
  - **F-Droid** (Android Open Source) - Gratis
  - **APK directo** (Para uso interno) - Gratis

#### **Desktop (Windows/Linux/macOS):**
- **Descarga directa desde tu servidor** - Gratis
- **Chocolatey** (Windows) - Gratis
- **Snap Store** (Linux) - Gratis

---

### **B. Backend Node.js (DHL Proxy)**

#### **Opción B1: Railway** ⭐ **RECOMENDADA PARA BACKEND**

**Ventajas:**
- ✅ $5/mes (plan básico)
- ✅ Soporta Puppeteer perfectamente
- ✅ Base de datos incluida
- ✅ SSL automático
- ✅ Fácil de desplegar

**Pasos:**
```bash
# 1. Instalar Railway CLI
npm i -g @railway/cli

# 2. Iniciar sesión
railway login

# 3. Inicializar proyecto
cd dhl_tracking_proxy
railway init

# 4. Desplegar
railway up
```

**Costo:** $5/mes (500 horas de CPU)

---

#### **Opción B2: Render** ⭐

**Ventajas:**
- ✅ Plan gratuito disponible
- ✅ Bueno para Node.js
- ✅ SSL incluido

**Pasos:**
1. Conectar repositorio GitHub
2. Seleccionar "Web Service"
3. Build: `npm install`
4. Start: `npm start`

**Costo:** Gratis (con límites) o $7/mes

---

#### **Opción B3: Fly.io** ⭐

**Ventajas:**
- ✅ Plan gratuito
- ✅ Soporta Docker
- ✅ Puppeteer funciona bien

**Costo:** Gratis (3 VMs compartidas)

---

#### **Opción B4: DigitalOcean App Platform**

**Ventajas:**
- ✅ $5/mes (plan básico)
- ✅ Muy confiable
- ✅ Buen soporte

**Costo:** $5/mes mínimo

---

#### **Opción B5: Servidor VPS (Más Control)**

**Proveedores:**
- **DigitalOcean Droplet** - $4-6/mes
- **Linode** - $5/mes
- **Vultr** - $2.50/mes
- **Hetzner** - €4/mes (muy barato)
- **AWS Lightsail** - $3.50/mes

**Configuración:**
```bash
# 1. Crear VPS Ubuntu 22.04
# 2. Conectar por SSH

# 3. Instalar Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# 4. Clonar proyecto
git clone tu-repositorio
cd dhl_tracking_proxy
npm install

# 5. Instalar PM2
npm install -g pm2

# 6. Iniciar servidor
pm2 start server.js --name dhl-proxy
pm2 save
pm2 startup  # Auto-iniciar al reiniciar

# 7. Configurar Nginx (reverse proxy)
sudo apt install nginx
# Configurar /etc/nginx/sites-available/default
```

**Ventajas:**
- ✅ Control total
- ✅ Más barato para tráfico alto
- ✅ Puedes instalar lo que necesites

**Desventajas:**
- ⚠️ Requiere mantenimiento
- ⚠️ Debes configurar SSL (Let's Encrypt)
- ⚠️ Debes manejar backups

**Costo:** $3-6/mes

---

## 📊 Comparación Rápida

| Plataforma | Costo/Mes | Facilidad | Puppeteer | Recomendado |
|------------|-----------|-----------|-----------|-------------|
| **Railway** | $5 | ⭐⭐⭐⭐⭐ | ✅ | ⭐⭐⭐⭐⭐ |
| **Render** | Gratis/$7 | ⭐⭐⭐⭐ | ✅ | ⭐⭐⭐⭐ |
| **Fly.io** | Gratis | ⭐⭐⭐ | ✅ | ⭐⭐⭐⭐ |
| **VPS** | $3-6 | ⭐⭐ | ✅ | ⭐⭐⭐ |
| **Vercel** | Gratis | ⭐⭐⭐⭐⭐ | ⚠️ | ⭐⭐ |

---

## 🎯 Recomendación Final Según Tu Caso

### **Para Empezar (MVP):**

1. **Flutter Web:** Vercel (Gratis)
2. **Backend Proxy:** Railway ($5/mes) o Render (Gratis)
3. **Base de Datos:** Supabase (Ya la tienes) ✅

**Costo Total:** $0-5/mes

---

### **Para Producción (Escalable):**

1. **Flutter Web:** Vercel/Netlify (Gratis)
2. **Flutter Móvil:** 
   - Android: Google Play Store ($25 una vez)
   - iOS: App Store ($99/año)
3. **Backend Proxy:** Railway ($5/mes) o VPS ($4/mes)
4. **Base de Datos:** Supabase Pro (si necesitas más recursos)

**Costo Total:** $5-10/mes + $25-99 (stores)

---

## 📱 Plan de Despliegue Paso a Paso

### **FASE 1: Backend (Prioridad Alta)**

1. **Desplegar Backend Node.js:**
   - Usa **Railway** o **Render**
   - Conecta tu repositorio
   - Configura variables de entorno
   - Obtén la URL del backend

2. **Actualizar Flutter:**
```dart
// lib/screens/shipments/track_shipment_screen.dart
final DHLTrackingService _trackingService = DHLTrackingService(
  proxyUrl: 'https://tu-backend.railway.app', // URL de producción
);
```

---

### **FASE 2: Flutter Web**

1. **Compilar Flutter Web:**
```bash
flutter build web --release
```

2. **Desplegar en Vercel:**
```bash
cd build/web
vercel --prod
```

3. **Configurar variables de entorno** (si es necesario)

---

### **FASE 3: Aplicación Móvil**

#### **Android:**

1. **Generar APK/AAB:**
```bash
flutter build apk --release  # Para APK
flutter build appbundle --release  # Para Google Play
```

2. **Subir a Google Play Console:**
   - Crear cuenta de desarrollador ($25)
   - Subir AAB
   - Configurar descripción, capturas, etc.
   - Publicar

#### **iOS:**

1. **Compilar:**
```bash
flutter build ios --release
```

2. **Subir a App Store Connect:**
   - Requiere Mac
   - Cuenta de desarrollador ($99/año)
   - Usar Xcode

---

### **FASE 4: Desktop (Opcional)**

1. **Windows:**
```bash
flutter build windows --release
# Crear instalador con Inno Setup o NSIS
```

2. **Linux:**
```bash
flutter build linux --release
# Crear AppImage o .deb
```

---

## 🔒 Configuración de Seguridad

### **Variables de Entorno:**

1. **Backend Node.js:**
```env
PORT=3000
NODE_ENV=production
```

2. **Flutter:**
```dart
// No hardcodear URLs en producción
// Usar variables de entorno o archivos de configuración
```

### **SSL/HTTPS:**

- **Vercel/Netlify/Railway/Render:** SSL automático ✅
- **VPS:** Configurar Let's Encrypt con Certbot

---

## 📈 Monitoreo y Mantenimiento

### **Recomendado:**
1. **Sentry** (Manejo de errores) - Plan gratuito
2. **UptimeRobot** (Monitoreo de servidor) - Gratis
3. **PM2 Plus** (Si usas PM2) - Plan gratuito

---

## 💰 Presupuesto Estimado Mensual

### **Opción Económica:**
- Flutter Web (Vercel): **Gratis**
- Backend (Render): **Gratis**
- Supabase: **Gratis** (hasta 500MB)
- **Total: $0/mes**

### **Opción Profesional:**
- Flutter Web (Vercel): **Gratis**
- Backend (Railway): **$5/mes**
- Supabase: **Gratis** o **$25/mes** (si crece)
- Google Play: **$25 una vez**
- App Store: **$99/año**
- **Total: $5-30/mes**

---

## 🚀 Pasos Inmediatos Recomendados

1. ✅ **Ya tienes:** Supabase configurado
2. 📦 **Siguiente:** Desplegar backend en Railway o Render
3. 🌐 **Luego:** Desplegar Flutter Web en Vercel
4. 📱 **Finalmente:** Publicar apps móviles en stores

---

## 📝 Notas Importantes

1. **Backend con Puppeteer:**
   - Requiere suficiente memoria (mínimo 512MB RAM)
   - Railway y Render manejan esto bien
   - Vercel puede tener problemas (serverless)

2. **Base de Datos:**
   - Supabase ya está desplegada ✅
   - Solo verifica el plan si creces mucho

3. **Dominio Personalizado:**
   - Puedes agregar dominio propio en Vercel/Railway
   - Costo: $10-15/año (Namecheap, Cloudflare)

4. **Backups:**
   - Supabase tiene backups automáticos
   - Backend: Si usas VPS, configura backups manuales

---

## ❓ ¿Dudas?

Si necesitas ayuda con algún paso específico, puedo guiarte en detalle.


