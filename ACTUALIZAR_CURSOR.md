# 🔄 Cómo Actualizar Cursor IDE

## 📝 Nota Importante

**Auto (el asistente de IA)** no se actualiza desde la terminal. Es parte de Cursor IDE y se actualiza automáticamente junto con la aplicación.

## 🚀 Actualizar Cursor IDE

### Opción 1: Actualización Automática (Recomendado)

Cursor se actualiza automáticamente cuando hay nuevas versiones:
1. Cursor verifica actualizaciones automáticamente
2. Te notifica cuando hay una actualización disponible
3. Solo necesitas aceptar la actualización y reiniciar

### Opción 2: Verificar Actualizaciones Manualmente

**En Linux (tu caso):**

1. Abre Cursor
2. Ve al menú: **Help** → **Check for Updates**
3. Si hay una actualización disponible, aparecerá un diálogo
4. Haz clic en **"Download Update"** o **"Restart to Update"**

**Desde la terminal (Linux):**

```bash
# Verificar si hay actualización disponible
# Cursor generalmente está en:
~/.local/share/cursor-updater/cursor-updater

# O puedes reinstalar desde el sitio oficial
# Si instalaste desde snap:
snap refresh cursor

# Si instalaste desde .deb:
# Descargar nueva versión desde: https://cursor.sh
# Y reinstalar con:
sudo dpkg -i cursor_*.deb
```

### Opción 3: Reinstalar desde el Sitio Oficial

1. Ve a [cursor.sh](https://cursor.sh)
2. Descarga la última versión
3. Instala sobre la versión anterior

## 📱 Verificar Versión Actual

**En Cursor:**
- **Help** → **About Cursor**
- Verás la versión instalada

**Desde terminal:**
```bash
cursor --version
# O
cursor --help
```

## 🔄 Reiniciar Cursor

Después de actualizar:
1. Cierra todas las ventanas de Cursor
2. Reinicia Cursor
3. Las nuevas características estarán disponibles

## 💡 Sobre el Asistente de IA

- **Auto** (el asistente) se actualiza automáticamente con Cursor
- No necesitas hacer nada especial para actualizarlo
- Siempre tienes acceso a la última versión cuando Cursor está actualizado

## ⚠️ Si Tienes Problemas

Si Cursor no se actualiza automáticamente:

1. **Verifica conexión a internet**
2. **Revisa permisos de escritura** en el directorio de instalación
3. **Descarga manualmente** desde cursor.sh
4. **Reinstala** si es necesario

## 🎯 Resumen

- ✅ Cursor se actualiza automáticamente
- ✅ Verifica en: **Help → Check for Updates**
- ✅ No hay comando de terminal para actualizar el asistente IA
- ✅ El asistente se actualiza junto con Cursor


