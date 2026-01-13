# 🔐 Políticas RLS para Bitácora de Envíos

## 📋 Problema

Si ves el error "0 registros" o "Error de permisos" al cargar la bitácora en la aplicación (escritorio o móvil), es porque las políticas RLS (Row Level Security) no están configuradas correctamente.

## ✅ Solución

Ejecuta el script SQL `politica_rls_bitacora_completa.sql` en Supabase para crear políticas que funcionen tanto para usuarios autenticados como anónimos.

## 🚀 Pasos para Aplicar la Solución

### 1. Abre Supabase Dashboard
- Ve a tu proyecto en [Supabase Dashboard](https://app.supabase.com)
- Navega a **SQL Editor** (en el menú lateral izquierdo)

### 2. Ejecuta el Script
- Haz clic en **New Query** (o abre una nueva pestaña)
- Abre el archivo `scripts_supabase/politica_rls_bitacora_completa.sql`
- Copia todo el contenido del archivo
- Pega el contenido en el SQL Editor de Supabase
- Haz clic en **Run** (o presiona `Ctrl+Enter` / `Cmd+Enter`)

### 3. Verifica que Funcionó
- Deberías ver un mensaje de éxito
- Ve a **Authentication > Policies** en el menú lateral
- Busca la tabla `t_bitacora_envios`
- Deberías ver **8 políticas** en total:
  - 4 para `authenticated` (SELECT, INSERT, UPDATE, DELETE)
  - 4 para `anon` (SELECT, INSERT, UPDATE, DELETE)

### 4. Prueba la Aplicación
- Reinicia la aplicación Flutter (escritorio o móvil)
- Ve a **Envíos > Bitácora**
- Deberías ver los registros cargándose correctamente

## 🔍 Verificar Políticas Manualmente

Si quieres verificar las políticas ejecutando SQL directamente:

```sql
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  cmd,
  roles
FROM pg_policies 
WHERE tablename = 't_bitacora_envios'
ORDER BY cmd, roles;
```

Deberías ver 8 filas (4 comandos × 2 roles).

## 📝 Notas Importantes

1. **Seguridad**: Estas políticas permiten acceso completo a usuarios autenticados y anónimos. Tu aplicación Flutter ya valida que solo usuarios válidos puedan acceder a través del login con `t_empleados`.

2. **Funciona en ambos**: Estas políticas funcionan tanto en la aplicación de escritorio como en la aplicación móvil.

3. **Si aún no funciona**: 
   - Verifica que RLS esté habilitado: `ALTER TABLE public.t_bitacora_envios ENABLE ROW LEVEL SECURITY;`
   - Verifica que las políticas se crearon correctamente usando el SQL de verificación arriba
   - Revisa los logs de la aplicación para ver mensajes de error específicos

## 🆘 Solución Alternativa

Si prefieres usar solo políticas para usuarios autenticados (más seguro), puedes usar el script `t_bitacora_envios.sql` que crea políticas solo para `authenticated`. Sin embargo, esto requiere que todos los usuarios se autentiquen en Supabase Auth.











