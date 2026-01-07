# Guía para Importar Datos de Bitácora con Fechas Numéricas

## Problema

Al intentar importar datos desde Supabase Dashboard, las fechas en formato numérico (ej: `180105`, `180115`) causan el error:
```
ERROR: 22008: date/time field value out of range: "181315"
```

## Solución

### Opción 1: Importar y luego convertir (Recomendado)

1. **Ejecuta la función de conversión:**
   - Ve a SQL Editor en Supabase
   - Ejecuta: `funcion_convertir_fecha_bitacora.sql`

2. **Importa los datos desde Dashboard:**
   - Ve a Table Editor > `t_bitacora_envios`
   - Haz clic en "Import data"
   - Selecciona tu archivo CSV/Excel
   - **IMPORTANTE:** Si falla la importación, no te preocupes, los datos se importarán pero con errores en la columna `fecha`

3. **Convierte las fechas:**
   - Ve a SQL Editor
   - Ejecuta: `importar_datos_bitacora_con_fechas_numericas.sql`
   - Esto convertirá todas las fechas numéricas a formato DATE válido

### Opción 2: Cambiar temporalmente el tipo de dato

Si la opción 1 no funciona:

1. **Cambia temporalmente `fecha` a TEXT:**
```sql
ALTER TABLE public.t_bitacora_envios 
ALTER COLUMN fecha TYPE TEXT USING fecha::TEXT;
```

2. **Importa tus datos** (ahora debería funcionar sin errores)

3. **Convierte las fechas:**
```sql
UPDATE public.t_bitacora_envios
SET fecha = convertir_fecha_numerica(fecha)::DATE
WHERE fecha ~ '^\d{6}$';
```

4. **Vuelve a cambiar el tipo a DATE:**
```sql
ALTER TABLE public.t_bitacora_envios 
ALTER COLUMN fecha TYPE DATE USING fecha::DATE;
```

### Opción 3: Preparar el CSV antes de importar

1. Abre tu archivo CSV/Excel
2. Convierte la columna `fecha` de formato numérico a formato fecha:
   - Si es `180105` → `2018-01-05`
   - Si es `180115` → `2018-01-15`
3. Guarda el archivo
4. Importa normalmente desde Supabase Dashboard

## Formato de Fecha Esperado

La función `convertir_fecha_numerica` espera fechas en formato **YYMMDD**:
- `180105` = 05 de enero de 2018
- `180115` = 15 de enero de 2018
- `181315` = 13 de enero de 2018 (si el mes es válido)

Si tus fechas están en otro formato (ej: YYDDMM), necesitarás ajustar la función.

## Verificación

Después de importar, verifica que las fechas se convirtieron correctamente:

```sql
SELECT consecutivo, fecha, tecnico 
FROM public.t_bitacora_envios 
WHERE fecha >= '2018-01-01' AND fecha < '2019-01-01'
ORDER BY fecha
LIMIT 10;
```

Las fechas deberían aparecer en formato estándar: `2018-01-05`, `2018-01-15`, etc.





