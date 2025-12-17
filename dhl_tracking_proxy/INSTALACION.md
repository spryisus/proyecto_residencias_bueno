# 🚀 Instalación del Proxy DHL Tracking

## Requisitos

- Node.js (versión 16 o superior)
- npm o yarn

## Pasos de Instalación

### 1. Instalar Node.js (si no lo tienes)

**Linux:**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install nodejs npm

# Verificar instalación
node --version
npm --version
```

**Windows:**
- Descargar desde: https://nodejs.org/
- Instalar el instalador .msi

**macOS:**
```bash
# Con Homebrew
brew install node

# O descargar desde nodejs.org
```

### 2. Instalar Dependencias del Proxy

```bash
cd dhl_tracking_proxy
npm install
```

Esto instalará:
- `express` - Servidor web
- `cors` - Habilitar CORS para Flutter
- `puppeteer` - Navegador headless para web scraping
- `dotenv` - Variables de entorno

**Nota:** La primera vez que instales Puppeteer, descargará Chromium (alrededor de 200MB).

### 3. Configurar Variables de Entorno (Opcional)

```bash
cp .env.example .env
```

Editar `.env` y configurar el puerto si quieres cambiarlo:
```
PORT=3000
```

### 4. Iniciar el Servidor

**Modo Desarrollo (con auto-reload):**
```bash
npm run dev
```

**Modo Producción:**
```bash
npm start
```

Deberías ver:
```
🚀 Servidor DHL Tracking Proxy corriendo en puerto 3000
📡 Endpoint: http://localhost:3000/api/track/:trackingNumber
```

## 🧪 Probar el Proxy

### Con curl:
```bash
curl http://localhost:3000/api/track/6376423056
```

### En el navegador:
Abrir: `http://localhost:3000/api/track/6376423056`

### Verificar salud del servidor:
```bash
curl http://localhost:3000/health
```

## 📱 Configurar Flutter

1. Abre `lib/screens/shipments/track_shipment_screen.dart`
2. Busca la línea donde se crea `DHLTrackingService`
3. Descomenta y configura la URL del proxy:

```dart
final DHLTrackingService _trackingService = DHLTrackingService(
  proxyUrl: 'http://localhost:3000', // Para desarrollo local
  // O para producción:
  // proxyUrl: 'https://tu-servidor.com',
);
```

### Para Android Emulador:
Si estás usando un emulador de Android, usa:
```dart
proxyUrl: 'http://10.0.2.2:3000', // Android emulator
```

### Para Dispositivo Físico:
Si estás usando un dispositivo físico, usa la IP local de tu computadora:
```dart
proxyUrl: 'http://192.168.1.X:3000', // Tu IP local
```

Para encontrar tu IP local:
- **Linux/Mac:** `ifconfig` o `ip addr`
- **Windows:** `ipconfig`

## 🔧 Producción

### Usar PM2 (recomendado):

```bash
# Instalar PM2 globalmente
npm install -g pm2

# Iniciar el servidor con PM2
cd dhl_tracking_proxy
pm2 start server.js --name dhl-proxy

# Ver logs
pm2 logs dhl-proxy

# Reiniciar
pm2 restart dhl-proxy

# Detener
pm2 stop dhl-proxy
```

### Configurar Nginx como Reverse Proxy (Opcional):

```nginx
server {
    listen 80;
    server_name tu-dominio.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## 🐛 Solución de Problemas

### Error: "Puppeteer no puede encontrar Chromium"
```bash
npm install puppeteer --force
```

### Error: "Puerto 3000 ya está en uso"
Cambiar el puerto en `.env`:
```
PORT=3001
```

### Error: "Timeout en las peticiones"
- Aumentar el timeout en `server.js`
- Verificar conexión a internet
- Verificar que DHL no esté bloqueando tu IP

## 📝 Notas

- El servidor usa Puppeteer que simula un navegador real, por lo que consume más recursos
- Primera petición puede tardar más (Puppeteer inicia Chromium)
- Recomendado tener al menos 2GB de RAM disponible para el servidor

