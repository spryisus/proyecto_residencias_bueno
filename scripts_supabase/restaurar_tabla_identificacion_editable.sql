-- ============================================
-- RESTAURAR TABLA: Permitir ediciones futuras en campos vacíos
-- ============================================
-- 
-- Este script restaura la estructura de la tabla pero mantiene
-- la capacidad de editar campos vacíos (NULL) en el futuro
-- ============================================

-- PASO 1: Limpiar datos - Convertir cadenas vacías a NULL
UPDATE public.t_computo_identificacion
SET id_equipo_computo = NULL
WHERE id_equipo_computo = '' 
   OR id_equipo_computo IS NULL
   OR TRIM(id_equipo_computo) = '';

-- PASO 2: Eliminar registros con valores inválidos (que no son números)
DELETE FROM public.t_computo_identificacion
WHERE id_equipo_computo IS NOT NULL
  AND id_equipo_computo !~ '^\d+$'; -- Solo números enteros

-- PASO 3: Convertir la columna de vuelta a BIGINT (permitiendo NULL)
ALTER TABLE public.t_computo_identificacion 
ALTER COLUMN id_equipo_computo TYPE BIGINT 
USING CASE 
    WHEN id_equipo_computo IS NULL OR id_equipo_computo = '' THEN NULL
    WHEN id_equipo_computo ~ '^\d+$' THEN id_equipo_computo::BIGINT
    ELSE NULL
END;

-- PASO 4: Restaurar la foreign key (permitiendo NULL)
-- Esto permite que id_equipo_computo sea NULL, pero si tiene valor, debe ser válido
ALTER TABLE public.t_computo_identificacion
ADD CONSTRAINT fk_equipo_computo_identificacion 
    FOREIGN KEY (id_equipo_computo) 
    REFERENCES public.t_computo_detalles_generales(id_equipo_computo) 
    ON DELETE CASCADE;

-- PASO 5: Crear índice parcial único (permite múltiples NULL, pero valores únicos)
-- Esto permite tener varios registros con id_equipo_computo = NULL
-- pero garantiza que cada id_equipo_computo no NULL sea único
CREATE UNIQUE INDEX IF NOT EXISTS idx_computo_identificacion_equipo 
ON public.t_computo_identificacion(id_equipo_computo)
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
FROM public.t_computo_identificacion;



