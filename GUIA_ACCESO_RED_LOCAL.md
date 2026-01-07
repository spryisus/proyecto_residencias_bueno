# 🌐 Guía de Acceso desde Red Local

Esta guía te ayudará a configurar tu aplicación Flutter para que sea accesible desde otras computadoras en la misma red local.

## 🚀 Inicio Rápido

### Opción 1: Script Automático (Recomendado)

Ejecuta el script maestro que inicia todo automáticamente:

```bash
./iniciar_servidor_red_local.sh
```

Este script:
- ✅ Detecta automáticamente tu IP local
- ✅ Configura el firewall
- ✅ Inicia todos los servicios backend (FastAPI, Excel Service, DHL Proxy)
- ✅ Compila y sirve la aplicación Flutter web
- ✅ Muestra las URLs de acceso

### Opción 2: Manual

Si prefieres iniciar los servicios manualmente:

1. **Iniciar FastAPI Tracking Service:**
   ```bash
   cd fastapi_tracking_service
   source venv/bin/activate
   PORT=8000 uvicorn main:app --host 0.0.0.0 --port 8000
   ```

2. **Iniciar Excel Generator Service:**
   ```bash
   cd excel_generator_service
   source venv/bin/activate
   uvicorn main:app --host 0.0.0.0 --port 8001
   ```

3. **Iniciar DHL Proxy:**
   ```bash
   cd dhl_tracking_proxy
   PORT=3000 node server.js
   ```

4. **Compilar y servir aplicación Flutter:**
   ```bash
   flutter build web --release
   cd build/web
   python3 -m http.server 8080 --bind 0.0.0.0
   ```

## 📱 Acceso desde Otra Computadora

1. **Obtén tu IP local:**
   ```bash
   hostname -I | awk '{print $1}'
   ```

2. **En la otra computadora**, abre el navegador y ve a:
   ```
   http://TU_IP_LOCAL:8080
   ```
   
   Por ejemplo: `http://10.12.18.190:8080`

## 🔧 Verificar Servicios

Para verificar que todos los servicios estén funcionando:

```bash
./verificar_servicios.sh
```

Este script verifica:
- ✅ Que todos los puertos estén activos
- ✅ Que todos los servicios HTTP respondan correctamente
- ✅ Muestra las URLs de acceso

## 🔥 Configurar Firewall

Si no puedes acceder desde otra computadora, puede ser un problema del firewall:

### Linux (UFW):
```bash
sudo ufw allow 8080/tcp
sudo ufw allow 8000/tcp
sudo ufw allow 8001/tcp
sudo ufw allow 3000/tcp
```

### Linux (firewalld):
```bash
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-port=8000/tcp
sudo firewall-cmd --permanent --add-port=8001/tcp
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --reload
```

## 🔄 Actualizar IP en Configuración

Si tu IP local cambia, actualiza la configuración automáticamente:

```bash
./actualizar_ip_config.sh
```

Este script:
- ✅ Detecta tu IP local actual
- ✅ Actualiza automáticamente `lib/app/config/dhl_proxy_config.dart`
- ✅ Actualiza las URLs de FastAPI y DHL Proxy

## 📋 Puertos Utilizados

| Servicio | Puerto | URL Local | URL Red |
|----------|--------|-----------|---------|
| Aplicación Web | 8080 | http://localhost:8080 | http://TU_IP:8080 |
| FastAPI Tracking | 8000 | http://localhost:8000 | http://TU_IP:8000 |
| Excel Generator | 8001 | http://localhost:8001 | http://TU_IP:8001 |
| DHL Proxy | 3000 | http://localhost:3000 | http://TU_IP:3000 |

## 🐛 Solución de Problemas

### No puedo acceder desde otra computadora:

1. **Verifica el firewall:**
   ```bash
   sudo ufw status
   # o
   sudo firewall-cmd --list-all
   ```

2. **Verifica que los servicios estén corriendo:**
   ```bash
   ./verificar_servicios.sh
   ```

3. **Verifica que ambas máquinas estén en la misma red:**
   - Ambas deben estar conectadas al mismo router/WiFi
   - Verifica que las IPs estén en el mismo rango (ej: 10.12.18.x)

4. **Prueba desde la misma máquina primero:**
   ```bash
   curl http://localhost:8080
   ```

### Los servicios no inician:

1. **Verifica que los puertos no estén en uso:**
   ```bash
   lsof -i :8080
   lsof -i :8000
   lsof -i :8001
   lsof -i :3000
   ```

2. **Mata procesos en puertos ocupados:**
   ```bash
   kill -9 $(lsof -ti:8080)
   kill -9 $(lsof -ti:8000)
   kill -9 $(lsof -ti:8001)
   kill -9 $(lsof -ti:3000)
   ```

3. **Revisa los logs:**
   - FastAPI: `/tmp/fastapi_service.log`
   - Excel: `/tmp/excel_service.log`
   - DHL Proxy: `/tmp/dhl_proxy.log`
   - Web: `/tmp/web_server.log`

### Error al compilar Flutter:

```bash
flutter clean
flutter pub get
flutter build web --release
```

## 📝 Notas Importantes

1. **Misma red:** Ambas computadoras deben estar en la misma red local (WiFi o Ethernet)

2. **Navegador compatible:** La computadora remota debe tener un navegador moderno:
   - Chrome 90+
   - Firefox 88+
   - Edge (actualizado)

3. **IP dinámica:** Si tu IP cambia frecuentemente, ejecuta `./actualizar_ip_config.sh` y recompila la aplicación

4. **Seguridad:** Este modo es solo para desarrollo/pruebas. Para producción, usa HTTPS y autenticación adecuada.

## ✅ Verificación Final

Para asegurarte de que todo funciona:

1. Ejecuta `./iniciar_servidor_red_local.sh`
2. Espera a que todos los servicios inicien
3. Ejecuta `./verificar_servicios.sh` en otra terminal
4. Abre `http://TU_IP:8080` desde otra computadora
5. Deberías ver la pantalla de login de tu aplicación

¡Listo! 🎉

















