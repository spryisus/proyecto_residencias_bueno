# Optimizaciones de Velocidad para DHL Tracking Proxy

## Problema Identificado

Cuando el servicio se despliega en Render.com (plan gratuito), el servicio se "duerme" después de 15 minutos de inactividad. Cuando se despierta, la página precargada ya no está disponible, haciendo que la primera consulta sea muy lenta (puede tardar 2-3 minutos).

## Soluciones Implementadas

### 1. Endpoint `/warmup` - Precarga Rápida

Este endpoint precarga la página de DHL antes de hacer la consulta real, acelerando significativamente la primera consulta.

**Uso desde Flutter:**
El servicio de Flutter ahora llama automáticamente a `/warmup` antes de cada consulta. Esto asegura que la página esté lista cuando se necesite.

**Uso manual:**
```bash
curl https://tu-servidor.onrender.com/warmup
```

**Respuesta:**
```json
{
  "success": true,
  "message": "Página precargada exitosamente",
  "elapsed": "15000ms",
  "ready": true
}
```

### 2. Endpoint `/keepalive` - Mantener Servicio Activo

Este endpoint mantiene el servicio activo en Render y verifica/recarga la página precargada si es necesario.

**Uso:**
```bash
curl https://tu-servidor.onrender.com/keepalive
```

**Respuesta:**
```json
{
  "status": "alive",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "preloadStatus": "ready",
  "message": "Servicio activo"
}
```

**Configuración en Render:**
Puedes configurar un cron job o servicio externo para llamar a `/keepalive` cada 10-12 minutos para mantener el servicio activo.

### 3. Optimizaciones en la Precarga

- **Cambio de `networkidle2` a `domcontentloaded`**: Reduce el tiempo de espera inicial
- **Reducción de delays**: Los tiempos de espera se redujeron de 5-10s a 3-5s durante la precarga
- **Reutilización mejorada**: La página precargada se reutiliza más eficientemente

### 4. Optimizaciones en Consultas con Página Precargada

Cuando se usa la página precargada:
- Se usa `domcontentloaded` en lugar de `networkidle2` para carga inicial más rápida
- Los delays se reducen de 10-15s a 2-4s
- La página ya está "caliente" y lista para usar

## Mejoras de Velocidad Esperadas

### Antes de las optimizaciones:
- Primera consulta (servicio dormido): **2-3 minutos**
- Consultas subsecuentes: **1-2 minutos**

### Después de las optimizaciones:
- Primera consulta con warmup: **30-60 segundos** (mejora del 50-70%)
- Consultas subsecuentes: **30-60 segundos** (mejora del 50-70%)

## Configuración Recomendada para Render

### Opción 1: Usar Keep-Alive Externo

Puedes usar un servicio gratuito como:
- **UptimeRobot** (https://uptimerobot.com): Configura un monitor HTTP que llame a `/keepalive` cada 10 minutos
- **Cron-Job.org** (https://cron-job.org): Configura un cron job que llame a `/keepalive` cada 10 minutos

### Opción 2: Actualizar Health Check

En `render.yaml`, puedes cambiar el `healthCheckPath` a `/keepalive`:

```yaml
healthCheckPath: /keepalive
```

Esto hará que Render llame automáticamente a `/keepalive` periódicamente.

## Flujo Optimizado

1. **Usuario hace consulta desde Flutter**
2. **Flutter llama automáticamente a `/warmup`** (si el servicio está dormido, esto lo despierta y precarga)
3. **Flutter espera respuesta de warmup** (máximo 30 segundos)
4. **Flutter hace la consulta real a `/api/track/:trackingNumber`**
5. **El proxy usa la página precargada** (si está disponible) o crea una nueva rápidamente

## Monitoreo

Puedes verificar el estado de la precarga llamando a:
```bash
curl https://tu-servidor.onrender.com/keepalive
```

El campo `preloadStatus` te dirá:
- `ready`: Página precargada y lista
- `expired`: Página precargada expiró (se recargará automáticamente)
- `not_loaded`: No hay página precargada (se creará cuando sea necesario)

## Notas Importantes

1. **El warmup es opcional**: Si falla, la consulta continúa normalmente (solo será más lenta)
2. **El keepalive es recomendado**: Para mantener el servicio activo en Render
3. **Los delays anti-detección se mantienen**: Las optimizaciones no afectan la seguridad contra detección de bots

## Próximos Pasos

1. Desplegar los cambios en Render
2. Configurar un servicio de keep-alive externo (recomendado)
3. Probar las consultas y verificar las mejoras de velocidad


