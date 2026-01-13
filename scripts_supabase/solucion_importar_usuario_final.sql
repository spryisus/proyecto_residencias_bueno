-- ============================================
-- SOLUCIÓN: Importar datos en t_computo_usuario_final
-- ============================================
-- 
-- Este script resuelve el error: "invalid input syntax for type bigint: """
-- que ocurre cuando importas datos con celdas vacías desde Supabase Dashboard
-- ============================================

-- PASO 1: Eliminar el índice único y la foreign key temporalmente
DROP INDEX IF EXISTS public.idx_computo_usuario_final_equipo;
ALTER TABLE public.t_computo_usuario_final 
DROP CONSTRAINT IF EXISTS fk_equipo_computo_usuario_final;

-- PASO 2: Cambiar temporalmente id_equipo_computo a TEXT para permitir importar cadenas vacías
ALTER TABLE public.t_computo_usuario_final 
ALTER COLUMN id_equipo_computo TYPE TEXT USING id_equipo_computo::TEXT;

-- PASO 3: Permitir NULL
ALTER TABLE public.t_computo_usuario_final 
ALTER COLUMN id_equipo_computo DROP NOT NULL;

-- ============================================
-- AHORA IMPORTA TUS DATOS DESDE SUPABASE DASHBOARD
-- ============================================
-- Ve a Table Editor > t_computo_usuario_final > Import data
-- Selecciona tu archivo y importa. Ahora debería funcionar sin errores.
-- ============================================

-- PASO 4: Después de importar, ejecuta estas líneas para convertir y restaurar:

-- Convertir cadenas vacías y valores inválidos a NULL
UPDATE public.t_computo_usuario_final
SET id_equipo_computo = NULL
WHERE id_equipo_computo = '' 
   OR id_equipo_computo IS NULL
   OR TRIM(id_equipo_computo) = '';

-- Eliminar registros con valores que no se pueden convertir a BIGINT
DELETE FROM public.t_computo_usuario_final
WHERE id_equipo_computo IS NOT NULL
  AND id_equipo_computo !~ '^\d+$'; -- Solo números enteros

-- Convertir la columna de vuelta a BIGINT
ALTER TABLE public.t_computo_usuario_final 
ALTER COLUMN id_equipo_computo TYPE BIGINT 
USING CASE 
    WHEN id_equipo_computo IS NULL OR id_equipo_computo = '' THEN NULL
    WHEN id_equipo_computo ~ '^\d+$' THEN id_equipo_computo::BIGINT
    ELSE NULL
END;

-- Restaurar la foreign key (permitiendo NULL)
ALTER TABLE public.t_computo_usuario_final
ADD CONSTRAINT fk_equipo_computo_usuario_final 
    FOREIGN KEY (id_equipo_computo) 
    REFERENCES public.t_computo_detalles_generales(id_equipo_computo) 
    ON DELETE CASCADE;

-- PASO 5: Crear índice parcial único (permite múltiples NULL, pero valores únicos)
CREATE UNIQUE INDEX IF NOT EXISTS idx_computo_usuario_final_equipo 
ON public.t_computo_usuario_final(id_equipo_computo)
WHERE id_equipo_computo IS NOT NULL;

-- ============================================
-- RESULTADO
-- ============================================
-- Ahora la tabla:
-- ✅ id_equipo_computo es BIGINT (tipo correcto)
-- ✅ Permite NULL (puedes dejar campos vacíos)
-- ✅ Tiene foreign key (valida valores cuando los insertas)
-- ✅ Permite múltiples registros con NULL
-- ✅ Garantiza unicidad cuando hay valor
-- ✅ Puedes editar campos vacíos en el futuro sin problemas
-- ============================================

-- VERIFICACIÓN
SELECT 
    COUNT(*) as total_registros,
    COUNT(id_equipo_computo) as con_id_equipo,
    COUNT(*) - COUNT(id_equipo_computo) as sin_id_equipo,
    'Tabla lista para editar campos vacíos' as estado
FROM public.t_computo_usuario_final;


