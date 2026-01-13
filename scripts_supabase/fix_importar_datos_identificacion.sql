-- ============================================
-- SCRIPT: Solución para importar datos en t_computo_identificacion
-- ============================================
-- 
-- PROBLEMA: Al importar desde Supabase Dashboard, las celdas vacías se convierten
-- en cadenas vacías "" en lugar de NULL, causando error en campos BIGINT.
--
-- SOLUCIÓN: Este script permite importar datos y luego limpia los valores inválidos
-- ============================================

-- ============================================
-- OPCIÓN 1: Modificar temporalmente la tabla para permitir NULL
-- ============================================
-- Ejecuta esto ANTES de importar tus datos:

-- Permitir NULL temporalmente en id_equipo_computo
ALTER TABLE public.t_computo_identificacion 
ALTER COLUMN id_equipo_computo DROP NOT NULL;

-- Eliminar temporalmente el índice único (si existe) para permitir múltiples NULL
DROP INDEX IF EXISTS public.idx_computo_identificacion_equipo;

-- ============================================
-- IMPORTAR TUS DATOS DESDE SUPABASE DASHBOARD AQUÍ
-- ============================================

-- ============================================
-- OPCIÓN 2: Limpiar datos después de importar
-- ============================================
-- Ejecuta esto DESPUÉS de importar tus datos:

-- Eliminar registros con id_equipo_computo NULL o inválido
-- (Solo si realmente no deberían existir)
-- DELETE FROM public.t_computo_identificacion 
-- WHERE id_equipo_computo IS NULL;

-- O si prefieres mantenerlos pero necesitas asignarles un valor:
-- UPDATE public.t_computo_identificacion
-- SET id_equipo_computo = (SELECT MIN(id_equipo_computo) FROM public.t_computo_detalles_generales)
-- WHERE id_equipo_computo IS NULL;

-- ============================================
-- Restaurar las restricciones después de limpiar los datos
-- ============================================

-- Volver a hacer NOT NULL (solo si no hay valores NULL)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.t_computo_identificacion 
        WHERE id_equipo_computo IS NULL
    ) THEN
        ALTER TABLE public.t_computo_identificacion 
        ALTER COLUMN id_equipo_computo SET NOT NULL;
    END IF;
END $$;

-- Recrear el índice único
CREATE UNIQUE INDEX IF NOT EXISTS idx_computo_identificacion_equipo 
ON public.t_computo_identificacion(id_equipo_computo)
WHERE id_equipo_computo IS NOT NULL; -- Índice parcial que permite múltiples NULL

-- ============================================
-- ALTERNATIVA: Si prefieres mantener NULL permitido
-- ============================================
-- Si algunos registros pueden no tener id_equipo_computo, puedes mantenerlo como NULL
-- y solo recrear el índice parcial (ya está hecho arriba)

-- ============================================
-- VERIFICACIÓN
-- ============================================
-- Verifica que los datos se importaron correctamente:
-- SELECT 
--     id_identificacion,
--     id_equipo_computo,
--     tipo_uso,
--     nombre_equipo_dominio,
--     status
-- FROM public.t_computo_identificacion
-- ORDER BY id_identificacion;


