-- Script para verificar qué ubicaciones existen en la tabla
-- ============================================

-- Ver todas las ubicaciones existentes
SELECT 
    id_ubicacion,
    direccion_fisica,
    estado,
    ciudad,
    tipo_edificio,
    nombre_edificio
FROM public.t_computo_ubicacion
ORDER BY id_ubicacion;

-- Contar cuántas ubicaciones hay
SELECT 
    COUNT(*) as total_ubicaciones
FROM public.t_computo_ubicacion;









