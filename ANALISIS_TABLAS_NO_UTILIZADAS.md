# Análisis de Tablas No Utilizadas en la Base de Datos

## 📊 Resumen Ejecutivo

Este documento identifica las tablas de la base de datos que **NO están siendo utilizadas** en el código de la aplicación Flutter.

---

## ❌ Tablas NO Utilizadas (8 tablas)

### 1. `t_computo`
- **Estado**: ❌ No utilizada
- **Razón**: La aplicación usa `t_equipos_computo` en su lugar (a través de la vista `v_equipos_computo_completo`)
- **Observación**: Parece ser una tabla antigua o legacy que fue reemplazada por `t_equipos_computo`

### 2. `t_envios`
- **Estado**: ❌ No utilizada directamente
- **Razón**: Existen entidades y repositorios (`lib/domain/entities/envio.dart`, `lib/domain/repositories/sistema_repository.dart`) pero **no hay implementación real** que haga queries a esta tabla
- **Observación**: La funcionalidad de envíos está definida pero no implementada en la UI

### 3. `t_envios_detalles`
- **Estado**: ❌ No utilizada
- **Razón**: Depende de `t_envios` que tampoco se usa
- **Observación**: Tabla relacionada con la funcionalidad de envíos no implementada

### 4. `t_historial_asignaciones`
- **Estado**: ❌ No utilizada
- **Razón**: No hay ninguna referencia en el código
- **Observación**: Parece ser para tracking de asignaciones de equipos, pero no se está usando

### 5. `t_reportes`
- **Estado**: ❌ No utilizada
- **Razón**: No hay ninguna referencia en el código
- **Observación**: Tabla para almacenar reportes generados, pero no se está usando

### 6. `t_reportes_inventarios`
- **Estado**: ❌ No utilizada
- **Razón**: Depende de `t_reportes` que tampoco se usa
- **Observación**: Tabla relacionada con reportes de inventarios no implementada

### 7. `t_ubicaciones_administrativas`
- **Estado**: ❌ No utilizada
- **Razón**: No hay ninguna referencia en el código
- **Observación**: Aunque `t_equipos_computo` tiene FK a esta tabla (`id_ubicacion_admin`), no se está usando en la aplicación

### 8. `t_ubicaciones_computo`
- **Estado**: ❌ No utilizada directamente
- **Razón**: Aunque `t_equipos_computo` tiene FK a esta tabla (`id_ubicacion_fisica`), no se hacen queries directas a esta tabla
- **Observación**: Se accede a través de vistas o joins, pero no directamente

---

## ✅ Tablas SÍ Utilizadas (15 tablas)

1. ✅ `inventory_sessions` - Sesiones de inventario
2. ✅ `t_categorias` - Categorías de productos
3. ✅ `t_componentes_computo` - Componentes de equipos de cómputo (usada a través de vista)
4. ✅ `t_empleado_rol` - Relación empleados-roles
5. ✅ `t_empleados` - Empleados del sistema
6. ✅ `t_empleados_computo` - Empleados asignados a equipos
7. ✅ `t_equipos_computo` - Equipos de cómputo (usada a través de vista `v_equipos_computo_completo`)
8. ✅ `t_inventarios` - Inventario de productos
9. ✅ `t_jumper_contenedores` - Contenedores de jumpers
10. ✅ `t_movimientos_inventario` - Movimientos de inventario
11. ✅ `t_productos` - Productos
12. ✅ `t_productos_categorias` - Relación productos-categorías
13. ✅ `t_roles` - Roles del sistema
14. ✅ `t_tarjetas_red` - Tarjetas de red (SICOR)
15. ✅ `t_ubicaciones` - Ubicaciones generales

---

## 🔍 Detalles Adicionales

### Tablas con Uso Indirecto (a través de vistas)

- **`t_equipos_computo`**: Se usa a través de la vista `v_equipos_computo_completo`
- **`t_componentes_computo`**: Se usa a través de la vista `v_componentes_computo_completo`

### Funcionalidades Definidas pero No Implementadas

- **Sistema de Envíos**: Existen entidades y repositorios para `t_envios` y `t_envios_detalles`, pero no hay pantallas o funcionalidad implementada en la UI.

- **Sistema de Reportes**: Las tablas `t_reportes` y `t_reportes_inventarios` están definidas pero no se usan.

---

## 💡 Recomendaciones

### Opción 1: Eliminar Tablas No Utilizadas
Si estás seguro de que no las necesitarás en el futuro, puedes eliminarlas para simplificar el esquema:

```sql
-- ⚠️ ADVERTENCIA: Hacer backup antes de ejecutar
DROP TABLE IF EXISTS t_reportes_inventarios CASCADE;
DROP TABLE IF EXISTS t_reportes CASCADE;
DROP TABLE IF EXISTS t_historial_asignaciones CASCADE;
DROP TABLE IF EXISTS t_envios_detalles CASCADE;
DROP TABLE IF EXISTS t_envios CASCADE;
DROP TABLE IF EXISTS t_computo CASCADE;
```

### Opción 2: Mantener para Futuro Uso
Si planeas implementar estas funcionalidades en el futuro, mantener las tablas:
- Sistema de envíos (`t_envios`, `t_envios_detalles`)
- Sistema de reportes (`t_reportes`, `t_reportes_inventarios`)
- Historial de asignaciones (`t_historial_asignaciones`)

### Opción 3: Migrar Datos de `t_computo` a `t_equipos_computo`
Si `t_computo` tiene datos importantes, considera migrarlos a `t_equipos_computo` antes de eliminarla.

---

## 📝 Notas Finales

- Las tablas `t_ubicaciones_administrativas` y `t_ubicaciones_computo` tienen relaciones FK desde `t_equipos_computo`, pero no se están usando activamente. Podrías considerar si realmente las necesitas o si puedes simplificar el esquema.

- El sistema actual usa principalmente `t_ubicaciones` para ubicaciones generales, y las ubicaciones específicas de cómputo no se están aprovechando.

---

**Fecha de análisis**: 31 de diciembre de 2025
**Versión del código analizado**: Última versión en main

