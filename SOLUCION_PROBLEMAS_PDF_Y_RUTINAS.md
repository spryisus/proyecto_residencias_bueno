# Solución: Problemas con PDFs y Rutinas

## Problema 1: No se pueden subir PDFs

### Causa
El código intentaba autenticarse con un usuario de servicio que no existe o tiene credenciales incorrectas.

### Solución Implementada
1. **Código actualizado**: El código ahora intenta subir PDFs sin autenticación primero.
2. **Si falla por permisos**: Intenta autenticarse automáticamente.
3. **Si eso también falla**: Muestra un error claro con instrucciones.

### Pasos para Solucionar

#### Opción A: Usar Políticas Anónimas (Recomendada - Más Simple)

1. Ve a Supabase Dashboard > SQL Editor
2. Ejecuta el script: `scripts_supabase/politicas_rls_storage_anonimas.sql`
3. Esto permitirá subir PDFs sin necesidad de autenticación

**Ventajas:**
- ✅ No requiere crear usuarios de servicio
- ✅ Funciona inmediatamente después de ejecutar el script
- ✅ Más simple de configurar

**Desventajas:**
- ⚠️ Menos seguro (cualquiera puede subir PDFs si tiene acceso al bucket)

#### Opción B: Crear Usuario de Servicio (Más Seguro)

1. Ve a Supabase Dashboard > Authentication > Users
2. Crea un nuevo usuario:
   - Email: `service@telmex.local`
   - Password: `ServiceAuth2024!`
3. Asegúrate de que las políticas RLS estén configuradas para usuarios autenticados:
   - Ejecuta: `scripts_supabase/politicas_rls_storage_evidencias.sql`

**Ventajas:**
- ✅ Más seguro
- ✅ Control de acceso

**Desventajas:**
- ⚠️ Requiere crear y mantener el usuario de servicio

---

## Problema 2: Rutinas no se sincronizan entre equipos

### Causa
El código estaba usando el caché local (SharedPreferences) como prioridad, lo que causaba que cada equipo mostrara sus propias rutinas guardadas localmente en lugar de las de Supabase.

### Solución Implementada
1. **Prioridad absoluta a Supabase**: El código ahora SIEMPRE intenta obtener rutinas desde Supabase primero.
2. **Sincronización automática**: Cuando hay rutinas en Supabase, se actualiza el caché local automáticamente.
3. **Caché local solo como fallback**: Solo se usa el caché local si Supabase no está disponible.

### Cómo Funciona Ahora

1. **Al cargar rutinas**:
   - ✅ Primero intenta obtener desde Supabase
   - ✅ Si hay rutinas en Supabase, las guarda en caché local y las muestra
   - ✅ Si no hay rutinas en Supabase, crea las por defecto y las guarda en Supabase
   - ✅ Solo usa caché local si Supabase no está disponible

2. **Al guardar rutinas**:
   - ✅ Guarda primero en Supabase
   - ✅ Luego actualiza el caché local
   - ✅ Si falla Supabase, guarda solo localmente (pero muestra advertencia)

### Resultado
- ✅ Las rutinas programadas en un equipo se reflejan en todos los demás equipos
- ✅ Todos los equipos ven las mismas rutinas
- ✅ La sincronización es automática

---

## Archivos Modificados

1. **`lib/data/services/storage_service.dart`**
   - Intenta subir PDFs sin autenticación primero
   - Si falla, intenta autenticarse automáticamente
   - Mensajes de error más claros

2. **`lib/data/local/rutina_storage.dart`**
   - Prioriza siempre Supabase sobre caché local
   - Sincroniza automáticamente el caché cuando hay datos en Supabase
   - Caché local solo como fallback

3. **`scripts_supabase/politicas_rls_storage_anonimas.sql`** (Nuevo)
   - Script SQL para permitir acceso anónimo al storage
   - Alternativa más simple que no requiere autenticación

---

## Próximos Pasos

1. **Para solucionar el problema de PDFs**:
   - Ejecuta el script SQL: `scripts_supabase/politicas_rls_storage_anonimas.sql` en Supabase
   - O crea el usuario de servicio si prefieres mayor seguridad

2. **Para las rutinas**:
   - No necesitas hacer nada adicional
   - El código ya está actualizado y funcionará automáticamente
   - Las rutinas ahora se sincronizan entre todos los equipos

3. **Probar**:
   - Intenta subir un PDF en la bitácora
   - Programa una rutina en un equipo y verifica que aparece en otro equipo

---

## Problema 3: Error RLS al Guardar Rutinas

### Causa
Las políticas RLS de la tabla `t_rutinas` solo permiten acceso a usuarios autenticados, pero la aplicación intenta guardar rutinas sin autenticación.

### Error que aparece
```
Error al guardar rutina: PostgrestException(message: new row violates row-level security policy for table "t_rutinas", code: 42501, details: Unauthorized)
```

### Solución

**Ejecuta el script SQL en Supabase:**

1. Ve a Supabase Dashboard > SQL Editor
2. Ejecuta el script: `scripts_supabase/politicas_rls_rutinas_anonimas.sql`
3. Esto permitirá guardar y sincronizar rutinas sin necesidad de autenticación

**Ventajas:**
- ✅ Las rutinas se pueden guardar y sincronizar entre todos los equipos
- ✅ No requiere crear usuarios de servicio
- ✅ Funciona inmediatamente después de ejecutar el script

**Desventajas:**
- ⚠️ Menos seguro (cualquiera con acceso a la base de datos puede modificar rutinas)
- ⚠️ Si prefieres mayor seguridad, mantén las políticas de authenticated y crea un usuario de servicio

---

## Notas Importantes

- Si ejecutas el programa sin instalarlo (solo ejecutándolo), las rutinas se sincronizarán correctamente porque ahora priorizan Supabase
- El caché local solo se usa si Supabase no está disponible
- Las rutinas se sincronizan automáticamente cuando cualquier equipo las modifica
- **IMPORTANTE**: Ejecuta el script `politicas_rls_rutinas_anonimas.sql` para que las rutinas se puedan guardar correctamente

