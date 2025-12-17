# FastAPI – DHL Tracking Ligero

Microservicio para consultar tracking DHL sin Puppeteer, con caché en SQLite y fallback opcional al proxy actual basado en Puppeteer.

## Endpoints

- `GET /health` – estado simple.
- `GET /tracking/{guia}` – retorna tracking. Respuesta uniforme:
  ```json
  {
    "success": true,
    "source": "direct|proxy",
    "data": {
      "trackingNumber": "123",
      "status": "En tránsito",
      "events": [
        {
          "description": "Evento",
          "timestamp": "2024-01-01T12:00:00Z",
          "location": "CDMX",
          "status": "En tránsito"
        }
      ],
      "origin": null,
      "destination": null,
      "currentLocation": null,
      "estimatedDelivery": null,
      "raw": {} // payload original para debugging
    }
  }
  ```

## Configuración por variables de entorno

- `PORT` (default `8000`)
- `CACHE_DB_PATH` (default `cache.db`)
- `CACHE_TTL_SECONDS` (default `1800`)
- `UPSTREAM_TIMEOUT_SECONDS` (default `10`)
- `DHL_URL_TEMPLATE` (default `https://www.dhl.com/mx-es/home/tracking/tracking-data.html?tracking-id={tracking_number}&submit=1`)
- `PUPPETEER_PROXY_URL` (opcional; fallback al proxy actual `/api/track/{guia}`)
- `ALLOWED_ORIGINS` (lista separada por comas; default `*`)

## Levantar en local

```bash
cd fastapi_tracking_service
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

## Deploy

- Render/Railway/Fly: usar `pip install -r requirements.txt` y `uvicorn main:app --host 0.0.0.0 --port $PORT`.
- El caché en SQLite será efímero si el disco es efímero; usar volumen si se desea persistencia. Para multiinstancia, migrar a Redis.

## Notas

- El parser está pensado para el endpoint interno ligero. Si DHL cambia el payload, ajustar la función `parse_tracking_payload`.
- Si el endpoint interno falla o responde distinto, el servicio puede intentar el fallback al proxy Puppeteer si `PUPPETEER_PROXY_URL` está configurado.

