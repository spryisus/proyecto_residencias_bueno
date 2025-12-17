# DHL Tracking Proxy

Servidor proxy para consultar tracking de DHL usando web scraping con Puppeteer.

## 🚀 Instalación

```bash
# Instalar dependencias
npm install

# O con yarn
yarn install
```

## 📝 Configuración

1. Copiar el archivo de ejemplo:
```bash
cp .env.example .env
```

2. Editar `.env` y configurar el puerto (opcional, por defecto 3000)

## ▶️ Ejecutar

### Desarrollo (con auto-reload):
```bash
npm run dev
```

### Producción:
```bash
npm start
```

## 📡 API Endpoints

### GET `/api/track/:trackingNumber`
Consulta el tracking de un envío DHL.

**Ejemplo:**
```bash
curl http://localhost:3000/api/track/6376423056
```

**Respuesta:**
```json
{
  "success": true,
  "data": {
    "trackingNumber": "6376423056",
    "status": "Entregado",
    "events": [
      {
        "description": "Paquete entregado",
        "timestamp": "2024-01-15T10:30:00Z",
        "location": "Guadalajara",
        "status": "Entregado"
      }
    ],
    "origin": "CDMX",
    "destination": "Guadalajara",
    "currentLocation": null,
    "estimatedDelivery": null
  }
}
```

### GET `/health`
Verifica el estado del servidor.

**Respuesta:**
```json
{
  "status": "ok",
  "service": "DHL Tracking Proxy"
}
```

## 🔧 Para Producción

1. Usar PM2 o similar para mantener el proceso corriendo
2. Configurar reverse proxy (nginx) si es necesario
3. Asegurar que el servidor tenga suficiente memoria para Puppeteer

## 📱 Integración con Flutter

Actualiza la URL del servicio en tu app Flutter para apuntar a este endpoint:

```dart
final url = Uri.parse('http://TU_SERVIDOR:3000/api/track/$trackingNumber');
```


