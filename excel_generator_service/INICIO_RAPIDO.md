# 🚀 Inicio Rápido - Servidor Excel Generator

## Iniciar el Servidor

### Linux/macOS
```bash
cd excel_generator_service
./start_server.sh
```

### Windows
```bash
cd excel_generator_service
start_server.bat
```

## Verificar que está funcionando

1. Abre tu navegador en: http://localhost:8001
2. Deberías ver un JSON con los endpoints disponibles
3. Visita http://localhost:8001/health para ver el estado de las plantillas

## Usar desde Flutter

El servicio está configurado para escuchar en `http://localhost:8001`.

Si necesitas cambiar la URL, edita:
- `lib/data/services/sdr_export_service.dart` - línea 9: `_excelServiceUrl`

## Solución de Problemas

### Error: "Connection refused"
- Verifica que el servidor esté corriendo
- Revisa que el puerto 8001 no esté en uso
- En Flutter, si usas un dispositivo móvil físico, cambia `localhost` por la IP de tu computadora

### Error: "Template not found"
- El servicio creará automáticamente archivos Excel aunque no existan las plantillas
- Si quieres usar plantillas personalizadas, colócalas en `excel_generator_service/assets/templates/`

### Error: "Module not found"
- Asegúrate de haber activado el entorno virtual
- Ejecuta: `pip install -r requirements.txt`

