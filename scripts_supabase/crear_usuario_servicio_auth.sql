-- ============================================
-- CREAR USUARIO DE SERVICIO EN SUPABASE AUTH
-- ============================================
-- 
-- Este script crea un usuario de servicio en Supabase Auth
-- que se usará para autenticar automáticamente cuando
-- los usuarios hacen login en la aplicación.
--
-- IMPORTANTE: 
-- 1. Ejecuta este script en el SQL Editor de Supabase
-- 2. Después de ejecutarlo, actualiza la contraseña en login_screen.dart
-- 3. El email y contraseña deben coincidir con los del código
-- ============================================

-- Crear usuario de servicio en auth.users
-- NOTA: Esto debe hacerse desde el Dashboard de Supabase > Authentication > Users
-- O usando la API de Supabase Auth

-- ============================================
-- INSTRUCCIONES MANUALES:
-- ============================================
-- 
-- 1. Ve a Supabase Dashboard > Authentication > Users
-- 2. Haz clic en "Add user" > "Create new user"
-- 3. Ingresa:
--    - Email: service@telmex.local
--    - Password: ServiceAuth2024! (o la que prefieras)
--    - Auto Confirm User: ✅ (marcar)
-- 4. Haz clic en "Create user"
--
-- ============================================
-- ALTERNATIVA: Cambiar políticas RLS para permitir acceso anónimo
-- ============================================
--
-- Si prefieres no usar autenticación, puedes cambiar las políticas RLS
-- para permitir acceso anónimo (menos seguro pero más simple):
--
-- DROP POLICY IF EXISTS "usuarios_autenticados_pueden_leer_bitacora" ON public.t_bitacora_envios;
-- CREATE POLICY "anon_puede_leer_bitacora"
-- ON public.t_bitacora_envios
-- FOR SELECT
-- TO anon
-- USING (true);
--
-- ============================================





