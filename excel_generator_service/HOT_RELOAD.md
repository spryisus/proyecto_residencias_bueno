# 🔄 Hot Reload - Recarga Automática del Servidor

El servicio de Python incluye **hot reload automático** que detecta cambios en los archivos y recarga el servidor sin necesidad de reiniciarlo manualmente.

## ✅ ¿Cómo funciona?

Cuando ejecutas `./start_server.sh` (Linux/macOS) o `start_server.bat` (Windows), el servidor se inicia con la opción `--reload` de uvicorn, que:

1. **Monitorea automáticamente** todos los archivos `.py` en el directorio actual
2. **Detecta cambios** cuando guardas un archivo modificado
3. **Recarga el servidor** automáticamente sin perder conexiones activas
4. **Muestra mensajes** en la consola cuando detecta cambios

## 📝 Mensajes en la consola

Cuando el servidor detecta un cambio, verás mensajes como:

```
WARNING:  WatchFiles detected changes in 'main.py'. Reloading...
INFO:     Shutting down
INFO:     Waiting for application shutdown.
INFO:     Application shutdown complete.
INFO:     Finished server process [XXXXX]
INFO:     Started server process [YYYYY]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

## 🎯 Archivos monitoreados

Por defecto, el servidor monitorea:
- Todos los archivos `.py` en el directorio `excel_generator_service/`
- Cambios en `main.py` y cualquier otro módulo Python

## ⚙️ Configuración

El hot reload está configurado en los scripts de inicio:

**Linux/macOS** (`start_server.sh`):
```bash
python -m uvicorn main:app \
    --host 0.0.0.0 \
    --port 8001 \
    --reload \
    --reload-dir . \
    --reload-include "*.py"
```

**Windows** (`start_server.bat`):
```batch
uvicorn main:app --host 0.0.0.0 --port 8001 --reload --reload-dir . --reload-include "*.py"
```

## 💡 Ventajas

- ✅ **No necesitas reiniciar** el servidor manualmente
- ✅ **Desarrollo más rápido** - Los cambios se aplican instantáneamente
- ✅ **Similar a Flutter** - Experiencia de desarrollo fluida
- ✅ **Sin pérdida de tiempo** - No hay que detener y volver a iniciar

## 🔍 Solución de problemas

### El servidor no se recarga automáticamente

1. **Verifica que estés usando `--reload`**: Asegúrate de ejecutar el script `start_server.sh` o `start_server.bat`, no uvicorn directamente sin la opción.

2. **Verifica los permisos**: En Linux/macOS, asegúrate de que el script tenga permisos de ejecución:
   ```bash
   chmod +x start_server.sh
   ```

3. **Revisa la consola**: Los mensajes de recarga aparecen en la terminal donde ejecutaste el script.

### El servidor se recarga demasiado rápido

Si el servidor se recarga constantemente sin hacer cambios, puede ser por:
- Archivos temporales siendo creados/eliminados
- Editores que guardan archivos automáticamente
- Considera usar `.gitignore` para excluir archivos temporales

## 📚 Referencias

- [Uvicorn Reload Documentation](https://www.uvicorn.org/settings/#reload)
- [WatchFiles (usado por uvicorn)](https://github.com/samuelcolvin/watchfiles)

