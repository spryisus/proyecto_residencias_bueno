# ✅ Resumen de Configuración - Servicio Excel Generator

## 🎯 Problema Resuelto

La aplicación Flutter funciona en **web y móvil**, y cada plataforma necesita una URL diferente para conectarse al servidor Python:

- ✅ **Web**: `http://localhost:8001`
- ✅ **Móvil físico**: `http://[TU_IP]:8001` 
- ✅ **Emulador Android**: `http://10.0.2.2:8001`

## 🔧 Solución Implementada

### 1. Configuración Automática por Plataforma

Se creó `lib/app/config/excel_service_config.dart` que:
- Detecta automáticamente si es web, Android, iOS o desktop
- Selecciona la URL correcta según la plataforma
- Permite forzar producción o desarrollo

### 2. CORS Habilitado en el Servidor

El servidor Python ahora acepta requests desde cualquier origen (web y móvil).

### 3. Fallback Automático

Si el servidor Python no está disponible, la app usa la plantilla local desde assets.

## 📝 Pasos para Usar

### 1. Iniciar el Servidor Python

```bash
cd excel_generator_service
./start_server.sh  # Linux/macOS
# o
start_server.bat   # Windows
```

### 2. Configurar tu IP Local (Solo para móvil físico)

Si vas a usar la app en un dispositivo móvil físico:

1. Obtén tu IP local:
   ```bash
   # Linux/macOS
   hostname -I | awk '{print $1}'
   
   # Windows
   ipconfig | findstr "IPv4"
   ```

2. Edita `lib/app/config/excel_service_config.dart`:
   ```dart
   static const String localUrl = 'http://TU_IP_AQUI:8001';
   ```

### 3. Usar en la App

La app detectará automáticamente la plataforma y usará la URL correcta. No necesitas hacer nada más.

## 🧪 Verificar Configuración

Puedes verificar qué URL está usando la app:

```dart
import 'package:proyecto_telmex/app/config/excel_service_config.dart';

// En cualquier parte de tu código
print(ExcelServiceConfig.getConfigInfo());
```

Esto mostrará:
```json
{
  "currentUrl": "http://10.12.18.188:8001",
  "isProduction": false,
  "platform": "android",
  "productionUrl": "https://excel-generator-service.onrender.com",
  "localUrl": "http://10.12.18.188:8001"
}
```

## 🚀 Producción

Para producción, actualiza `productionUrl` en `excel_service_config.dart` y despliega el servidor Python en la nube (Render, Railway, etc.).

## ⚠️ Notas Importantes

1. **Misma Red WiFi**: Para móvil físico, tu computadora y móvil deben estar en la misma red WiFi
2. **Firewall**: Asegúrate de que el puerto 8001 no esté bloqueado
3. **IP Cambia**: Si cambias de red WiFi, actualiza la IP en la configuración

## 📚 Archivos Modificados/Creados

- ✅ `lib/app/config/excel_service_config.dart` - Configuración de URLs
- ✅ `lib/data/services/sdr_export_service.dart` - Usa la configuración automática
- ✅ `excel_generator_service/main.py` - CORS habilitado
- ✅ `excel_generator_service/CONFIGURACION_URL.md` - Guía detallada

