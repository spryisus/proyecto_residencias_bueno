# 🔧 Configuración de URL para Web y Móvil

## Problema

Cuando la aplicación Flutter se ejecuta en diferentes plataformas (web, móvil Android/iOS), necesita diferentes URLs para conectarse al servidor Python:

- **Web**: `http://localhost:8001` (mismo dispositivo)
- **Móvil físico**: `http://[IP_DE_TU_COMPUTADORA]:8001` (necesita la IP de tu red local)
- **Emulador Android**: `http://10.0.2.2:8001` (IP especial del emulador)

## Solución

El servicio ya está configurado para detectar automáticamente la plataforma y usar la URL correcta. Solo necesitas actualizar la IP local en el archivo de configuración.

## Pasos para Configurar

### 1. Obtener tu IP Local

**Linux/macOS:**
```bash
# Opción 1: Usando ip
ip addr show | grep "inet " | grep -v 127.0.0.1

# Opción 2: Usando ifconfig
ifconfig | grep "inet " | grep -v 127.0.0.1

# Opción 3: Más simple
hostname -I | awk '{print $1}'
```

**Windows:**
```bash
ipconfig | findstr "IPv4"
```

Busca la IP que no sea `127.0.0.1` (normalmente algo como `192.168.x.x` o `10.x.x.x`)

### 2. Actualizar la Configuración

Edita el archivo: `lib/app/config/excel_service_config.dart`

Busca la línea:
```dart
static const String localUrl = 'http://10.12.18.188:8001';
```

Y reemplaza `10.12.18.188` con tu IP local.

### 3. Verificar la Configuración

Puedes verificar qué URL está usando la app ejecutando:

```dart
print(ExcelServiceConfig.getConfigInfo());
```

Esto mostrará:
- URL actual
- Si es producción o desarrollo
- Plataforma detectada
- URLs configuradas

## Configuración por Ambiente

### Desarrollo Local

Para desarrollo, la app detecta automáticamente:
- **Web**: `localhost:8001`
- **Móvil**: Usa `localUrl` (tu IP)
- **Emulador**: `10.0.2.2:8001`

### Producción

Para producción, actualiza `productionUrl` en `excel_service_config.dart`:

```dart
static const String productionUrl = 'https://tu-servidor.onrender.com';
```

Y fuerza el uso de producción:

```dart
ExcelServiceConfig.getServiceUrl(useProduction: true)
```

## Solución de Problemas

### Error: "Connection refused" en móvil

1. Verifica que el servidor Python esté corriendo
2. Verifica que tu computadora y móvil estén en la misma red WiFi
3. Verifica que el firewall no esté bloqueando el puerto 8001
4. Actualiza la IP en `excel_service_config.dart`

### Error: "Failed host lookup" en web

1. Asegúrate de que el servidor esté corriendo en `localhost:8001`
2. Verifica que no haya problemas de CORS (el servidor Python debe permitir requests desde el origen web)

### Cambiar de Red WiFi

Si cambias de red, necesitas actualizar la IP en `excel_service_config.dart` porque tu IP local cambiará.

## Nota sobre CORS (Web)

Si usas la app web, el servidor Python debe permitir requests desde el origen web. El servidor ya está configurado para aceptar requests desde cualquier origen, pero si tienes problemas, verifica que el servidor esté corriendo con:

```bash
uvicorn main:app --host 0.0.0.0 --port 8001 --reload
```

El `--host 0.0.0.0` es importante para que acepte conexiones desde otros dispositivos en la red.

