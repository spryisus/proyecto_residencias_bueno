# 🚀 Cómo Iniciar el Servidor Proxy DHL

## Comando Simple (Recomendado)

```bash
cd /home/spryisus/Flutter/Proyecto_Telmex/dhl_tracking_proxy
npm start
```

## Iniciar en Segundo Plano

Para que el servidor siga corriendo después de cerrar la terminal:

```bash
cd /home/spryisus/Flutter/Proyecto_Telmex/dhl_tracking_proxy
nohup npm start > /tmp/dhl_proxy.log 2>&1 &
```

Para ver los logs:
```bash
tail -f /tmp/dhl_proxy.log
```

## Verificar que el Servidor Está Corriendo

```bash
curl http://localhost:3000/health
```

Deberías ver:
```json
{"status":"ok","service":"DHL Tracking Proxy"}
```

## Detener el Servidor

```bash
# Buscar el proceso
ps aux | grep "node.*server.js"

# O detener directamente el puerto 3000
lsof -ti:3000 | xargs kill -9
```

## Estado Actual

✅ El servidor está corriendo ahora en: `http://localhost:3000`

## Nota Importante

- **Para aplicación de escritorio (Linux)**: Usa `http://localhost:3000`
- **Para aplicación móvil (Android/iOS)**: Usa `http://192.168.1.178:3000` (tu IP local)

El código ya está configurado para detectar automáticamente la plataforma y usar la URL correcta.


