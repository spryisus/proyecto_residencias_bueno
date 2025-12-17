-- Script para crear la tabla de sesiones de inventario en Supabase
-- Esta tabla permite sincronizar los inventarios entre dispositivos (escritorio y móvil)

CREATE TABLE IF NOT EXISTS public.inventory_sessions (
    id TEXT PRIMARY KEY,
    category_id INTEGER NOT NULL,
    category_name TEXT NOT NULL,
    quantities JSONB NOT NULL DEFAULT '{}'::jsonb,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed')),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    owner_id TEXT,
    owner_name TEXT,
    owner_email TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Índices para mejorar el rendimiento de las consultas
CREATE INDEX IF NOT EXISTS idx_inventory_sessions_owner_id ON public.inventory_sessions(owner_id);
CREATE INDEX IF NOT EXISTS idx_inventory_sessions_status ON public.inventory_sessions(status);
CREATE INDEX IF NOT EXISTS idx_inventory_sessions_updated_at ON public.inventory_sessions(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_inventory_sessions_category_id ON public.inventory_sessions(category_id);

-- NOTA: Como el sistema usa autenticación personalizada (no Supabase Auth),
-- las políticas de RLS se simplifican. La seguridad se maneja a nivel de aplicación.
-- Si deseas habilitar RLS más estricto, necesitarías implementar Supabase Auth.

-- Opción 1: Deshabilitar RLS (recomendado para este caso)
-- La aplicación manejará la seguridad filtrando por owner_id
ALTER TABLE public.inventory_sessions DISABLE ROW LEVEL SECURITY;

-- Opción 2: Si prefieres habilitar RLS básico (comentar la línea anterior y descomentar estas):
-- ALTER TABLE public.inventory_sessions ENABLE ROW LEVEL SECURITY;
-- 
-- -- Política básica: Permitir todas las operaciones (la app filtra por owner_id)
-- CREATE POLICY "Allow all operations for authenticated service role"
--     ON public.inventory_sessions
--     FOR ALL
--     USING (true)
--     WITH CHECK (true);

-- Comentarios para documentación
COMMENT ON TABLE public.inventory_sessions IS 'Almacena las sesiones de inventario para sincronización entre dispositivos';
COMMENT ON COLUMN public.inventory_sessions.id IS 'ID único de la sesión (UUID)';
COMMENT ON COLUMN public.inventory_sessions.category_id IS 'ID de la categoría de inventario';
COMMENT ON COLUMN public.inventory_sessions.category_name IS 'Nombre de la categoría';
COMMENT ON COLUMN public.inventory_sessions.quantities IS 'Mapa de cantidades por producto (JSON: {producto_id: cantidad})';
COMMENT ON COLUMN public.inventory_sessions.status IS 'Estado de la sesión: pending o completed';
COMMENT ON COLUMN public.inventory_sessions.updated_at IS 'Fecha y hora de última actualización';
COMMENT ON COLUMN public.inventory_sessions.owner_id IS 'ID del empleado que creó la sesión';
COMMENT ON COLUMN public.inventory_sessions.owner_name IS 'Nombre del empleado que creó la sesión';
COMMENT ON COLUMN public.inventory_sessions.owner_email IS 'Email del empleado que creó la sesión';

