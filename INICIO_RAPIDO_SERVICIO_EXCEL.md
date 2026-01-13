# 🚀 Inicio Rápido - Servicio de Excel

## ⚠️ Error: "Conexión rehusada"

Si ves el error **"Conexión rehusada"** al exportar bitácoras, significa que el servicio Python no está corriendo.

## ✅ Solución Rápida

### Opción 1: Usar el script (Recomendado)

```bash
./iniciar_servicio_excel.sh
```

### Opción 2: Manual

```bash
cd excel_generator_service
python3 -m uvicorn main:app --host 0.0.0.0 --port 8001 --reload
```

## 📋 Verificar que el Servicio Está Corriendo

Deberías ver algo como:

```
INFO:     Uvicorn running on http://0.0.0.0:8001 (Press CTRL+C to quit)
INFO:     Started reloader process
INFO:     Started server process
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

## 🔍 Verificar el Puerto

Si el puerto 8001 está ocupado, puedes verificar con:

```bash
lsof -i :8001
```

## 🛑 Detener el Servicio

Presiona `Ctrl+C` en la terminal donde está corriendo el servicio.

## 📝 Notas

- El servicio debe estar corriendo **antes** de intentar exportar
- Mantén la terminal abierta mientras uses la aplicación
- El servicio se reinicia automáticamente cuando cambias el código (gracias a `--reload`)

## 🔧 Requisitos

- Python 3.7 o superior
- Dependencias instaladas:
  ```bash
  cd excel_generator_service
  pip3 install -r requirements.txt
  ```










