-- ============================================
-- RESTAURAR TABLA: t_computo_observaciones después de importar
-- ============================================
-- 
-- Ejecuta este script DESPUÉS de haber importado tus datos
-- ============================================

-- PASO 1: Convertir cadenas vacías y valores inválidos a NULL en id_equipo_computo
UPDATE public.t_computo_observaciones
SET id_equipo_computo = NULL
WHERE id_equipo_computo = '' 
   OR id_equipo_computo IS NULL
   OR TRIM(id_equipo_computo) = '';

-- PASO 2: Eliminar registros con valores que no se pueden convertir a BIGINT
DELETE FROM public.t_computo_observaciones
WHERE id_equipo_computo IS NOT NULL
  AND id_equipo_computo !~ '^\d+$'; -- Solo números enteros

-- PASO 3: Convertir la columna de vuelta a BIGINT
ALTER TABLE public.t_computo_observaciones 
ALTER COLUMN id_equipo_computo TYPE BIGINT 
USING CASE 
    WHEN id_equipo_computo IS NULL OR id_equipo_computo = '' THEN NULL
    WHEN id_equipo_computo ~ '^\d+$' THEN id_equipo_computo::BIGINT
    ELSE NULL
END;

-- PASO 4: Restaurar la foreign key (permitiendo NULL)
ALTER TABLE public.t_computo_observaciones
ADD CONSTRAINT fk_equipo_computo_observaciones 
    FOREIGN KEY (id_equipo_computo) 
    REFERENCES public.t_computo_detalles_generales(id_equipo_computo) 
    ON DELETE CASCADE;

-- PASO 5: Crear índice parcial único (permite múltiples NULL, pero valores únicos)
CREATE UNIQUE INDEX IF NOT EXISTS idx_computo_observaciones_equipo 
ON public.t_computo_observaciones(id_equipo_computo)
WHERE id_equipo_computo IS NOT NULL;

-- ============================================
-- VERIFICACIÓN
-- ============================================
SELECT 
    COUNT(*) as total_registros,
    COUNT(id_equipo_computo) as con_id_equipo,
    COUNT(*) - COUNT(id_equipo_computo) as sin_id_equipo,
    'Tabla lista para editar campos vacíos' as estado
FROM public.t_computo_observaciones;



