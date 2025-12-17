# 🌐 Guía para Servir la Aplicación Web

Esta guía te ayudará a compilar y servir tu aplicación Flutter para web, accesible desde otras máquinas en tu red local.

## 🚀 Método Rápido (Recomendado)

### 1. Ejecutar el script automático:

```bash
cd /home/spryisus/Flutter/Proyecto_Telmex
./servir_web.sh
```

El script:
- ✅ Compila la aplicación para web
- ✅ Inicia un servidor HTTP
- ✅ Muestra la IP local para acceder desde otras máquinas
- ✅ Configura el servidor para ser accesible desde la red (0.0.0.0)

### 2. Acceder desde otra máquina:

1. **Obtén la IP que muestra el script** (ejemplo: `192.168.1.178`)
2. **En la otra máquina (Windows 7)**, abre el navegador
3. **Ve a**: `http://192.168.1.178:8080`

## 📋 Método Manual

Si prefieres hacerlo paso a paso:

### Paso 1: Compilar para web

```bash
cd /home/spryisus/Flutter/Proyecto_Telmex
flutter pub get
flutter build web --release
```

### Paso 2: Obtener tu IP local

```bash
# En Linux
hostname -I
# O
ip addr show | grep "inet " | grep -v 127.0.0.1
```

### Paso 3: Servir la aplicación

**Opción A: Con Python 3 (Recomendado)**
```bash
cd build/web
python3 -m http.server 8080 --bind 0.0.0.0
```

**Opción B: Con PHP**
```bash
cd build/web
php -S 0.0.0.0:8080
```

**Opción C: Con Node.js (npx serve)**
```bash
cd build/web
npx serve -l 8080 --host 0.0.0.0
```

### Paso 4: Acceder desde otra máquina

- **Local**: `http://localhost:8080`
- **Red local**: `http://TU_IP_LOCAL:8080` (ejemplo: `http://192.168.1.178:8080`)

## 🔥 Configurar Firewall (Si es necesario)

Si no puedes acceder desde otra máquina, puede ser un problema del firewall:

### Linux (UFW):
```bash
sudo ufw allow 8080/tcp
```

### Linux (firewalld):
```bash
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```

### Linux (iptables):
```bash
sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
```

## ⚠️ Notas Importantes

1. **Misma red**: Ambas máquinas deben estar en la misma red local (WiFi o Ethernet)

2. **Navegador compatible**: La máquina con Windows 7 debe tener un navegador moderno:
   - Chrome 90+ (recomendado)
   - Firefox 88+
   - Edge (si está actualizado)

3. **Proxy DHL**: Si usas el proxy DHL, asegúrate de que también esté accesible desde la red:
   ```bash
   cd dhl_tracking_proxy
   npm start
   ```
   Y actualiza la URL en la configuración si es necesario.

4. **HTTPS**: Para producción, considera usar HTTPS con un certificado SSL.

## 🐛 Solución de Problemas

### No puedo acceder desde otra máquina:

1. **Verifica el firewall**: Asegúrate de que el puerto 8080 esté abierto
2. **Verifica la IP**: Usa `hostname -I` para confirmar tu IP local
3. **Verifica la red**: Ambas máquinas deben estar en la misma red
4. **Prueba localmente primero**: Accede desde `http://localhost:8080` en la misma máquina

### Error al compilar:

```bash
# Limpiar y recompilar
flutter clean
flutter pub get
flutter build web --release
```

### El servidor no inicia:

- Verifica que el puerto 8080 no esté en uso: `lsof -i :8080`
- Cambia el puerto en el script si es necesario

## 📱 Acceso desde Móvil

También puedes acceder desde tu teléfono si está en la misma red WiFi:
- Abre el navegador en tu móvil
- Ve a: `http://TU_IP_LOCAL:8080`

## ✅ Verificación

Para verificar que todo funciona:

1. **En la máquina servidor**: Deberías ver el servidor corriendo
2. **En la otra máquina**: Abre el navegador y ve a la IP mostrada
3. **Deberías ver**: La pantalla de login de tu aplicación

¡Listo! 🎉


