# 🔄 Backup de URLs del Servicio de Excel

## 📝 URLs Guardadas

### URL de Producción (Render)
```
https://generador-excel.onrender.com
```

### URL Local (Desarrollo)
```
http://localhost:8001  (para web y desktop)
http://192.168.1.67:8001  (para móvil físico en red local)
http://10.0.2.2:8001  (para emulador Android)
```

## 🔧 Cómo Cambiar Entre Local y Producción

### Para Usar Local (Pruebas)
En `lib/app/config/excel_service_config.dart`, cambiar:
```dart
static const bool useProductionByDefault = false;
```

### Para Usar Producción (Render)
En `lib/app/config/excel_service_config.dart`, cambiar:
```dart
static const bool useProductionByDefault = true;
```

## 📅 Fecha de Última Modificación
- **Fecha**: 05 de enero de 2026
- **Estado Actual**: ✅ **PRODUCCIÓN** - Usando Render (`useProductionByDefault = true`)
- **Último cambio a producción**: 05 de enero de 2026

## ⚠️ Recordatorio
- **Para pruebas locales**: Cambiar `useProductionByDefault` a `false`
- **Para producción**: Mantener `useProductionByDefault` en `true` (estado actual)

