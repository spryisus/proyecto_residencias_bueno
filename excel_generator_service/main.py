import io
import os
import logging
from datetime import datetime
from typing import List, Dict, Any, Optional

from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import Response, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from openpyxl import Workbook
from openpyxl.styles import Font, Alignment, Border, Side, PatternFill
from openpyxl.utils import get_column_letter
import openpyxl

app = FastAPI(title="Excel Generator Service")

# Configurar CORS para permitir requests desde web y móvil
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En producción, especifica los orígenes permitidos
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

ROOT = os.path.dirname(__file__)
# Buscar plantillas en la carpeta del servicio primero, luego en la raíz del proyecto
TEMPLATES_DIR = os.path.join(ROOT, "assets", "templates")
PROJECT_ROOT = os.path.dirname(os.path.dirname(ROOT))  # Subir dos niveles desde excel_generator_service
PROJECT_ASSETS_DIR = os.path.join(PROJECT_ROOT, "assets")

# Jumpers: buscar primero en templates del servicio, luego en assets del proyecto
TEMPLATE_PATH_JUMPERS = (
    os.path.join(TEMPLATES_DIR, "plantilla_jumpers.xlsx")
    if os.path.exists(os.path.join(TEMPLATES_DIR, "plantilla_jumpers.xlsx"))
    else (
        os.path.join(PROJECT_ASSETS_DIR, "templates", "plantilla_jumpers.xlsx")
        if os.path.exists(os.path.join(PROJECT_ASSETS_DIR, "templates", "plantilla_jumpers.xlsx"))
        else os.path.join(PROJECT_ASSETS_DIR, "plantilla_jumpers.xlsx")
    )
)
# Computo: buscar en assets/templates primero, luego en assets directamente
TEMPLATE_PATH_COMPUTO = (
    os.path.join(PROJECT_ASSETS_DIR, "templates", "plantilla_inventario_computo.xlsx")
    if os.path.exists(os.path.join(PROJECT_ASSETS_DIR, "templates", "plantilla_inventario_computo.xlsx"))
    else (
        os.path.join(PROJECT_ASSETS_DIR, "plantilla_inventario_computo.xlsx")
        if os.path.exists(os.path.join(PROJECT_ASSETS_DIR, "plantilla_inventario_computo.xlsx"))
        else os.path.join(TEMPLATES_DIR, "plantilla_inventario_computo.xlsx")
    )
)
# SDR: buscar primero en templates del servicio, luego en assets del proyecto
TEMPLATE_PATH_SDR = (
    os.path.join(TEMPLATES_DIR, "plantilla_sdr.xlsx")
    if os.path.exists(os.path.join(TEMPLATES_DIR, "plantilla_sdr.xlsx"))
    else os.path.join(PROJECT_ASSETS_DIR, "plantilla_SDR.xlsx")
)

LAST_GENERATED_FILE_CONTENT: bytes | None = None
LAST_GENERATED_FILENAME: str | None = None

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def _ensure_template(path: str):
    """Verifica que la plantilla exista, si no, crea una estructura básica"""
    if not os.path.exists(path):
        logger.warning(f"Template not found: {path}, creating basic structure")
        # No lanzamos error, crearemos la estructura básica
        return False
    return True


def _safe_set_cell_value(ws, row: int, col: int, value: Any):
    """Escribe un valor en una celda de forma segura, evitando celdas combinadas"""
    try:
        cell = ws.cell(row=row, column=col)
        cell_coordinate = cell.coordinate
        
        # Verificar si la celda está en un rango combinado
        # openpyxl usa merged_cells que es un objeto MultiCellRange
        for merged_range in list(ws.merged_cells.ranges):
            # Convertir el rango a string para comparar
            range_str = str(merged_range)
            # Verificar si nuestra celda está en este rango
            if cell_coordinate in range_str or _is_cell_in_range(cell_coordinate, merged_range):
                # Si está en un merge, obtener la celda principal (top-left del rango)
                # El rango tiene formato como "A1:B2", la primera celda es la principal
                range_parts = range_str.split(':')
                if range_parts:
                    top_left = range_parts[0]  # Ej: "A1"
                    # Convertir coordenada de letra a número (ej: "A1" -> row=1, col=1)
                    from openpyxl.utils import coordinate_from_string, column_index_from_string
                    coord_tuple = coordinate_from_string(top_left)
                    top_row = coord_tuple[1]
                    top_col = column_index_from_string(coord_tuple[0])
                    # Solo escribir si estamos en la celda principal
                    if row == top_row and col == top_col:
                        cell.value = value
                    # Si no, no escribir nada (la celda está en el merge pero no es la principal)
                    return
        
        # Si no está en un merge, escribir normalmente
        cell.value = value
    except Exception as e:
        logger.warning(f"Error al escribir en celda ({row}, {col}): {e}, intentando método directo")
        # Intentar escribir directamente en la celda si falla
        try:
            ws.cell(row=row, column=col).value = value
        except Exception as e2:
            logger.error(f"Error crítico al escribir en celda ({row}, {col}): {e2}")


def _is_cell_in_range(cell_coordinate: str, merged_range) -> bool:
    """Verifica si una celda está dentro de un rango combinado"""
    try:
        from openpyxl.utils import range_boundaries
        min_col, min_row, max_col, max_row = range_boundaries(str(merged_range))
        from openpyxl.utils import coordinate_from_string, column_index_from_string
        coord_tuple = coordinate_from_string(cell_coordinate)
        cell_row = coord_tuple[1]
        cell_col = column_index_from_string(coord_tuple[0])
        return min_row <= cell_row <= max_row and min_col <= cell_col <= max_col
    except:
        return False


def _save_workbook_to_bytes(wb: Workbook) -> bytes:
    output = io.BytesIO()
    wb.save(output)
    output.seek(0)
    return output.read()


def _get_month_year() -> str:
    """Obtiene el mes y año en español"""
    now = datetime.now()
    months = [
        'ENERO', 'FEBRERO', 'MARZO', 'ABRIL', 'MAYO', 'JUNIO',
        'JULIO', 'AGOSTO', 'SEPTIEMBRE', 'OCTUBRE', 'NOVIEMBRE', 'DICIEMBRE'
    ]
    return f'{months[now.month - 1]} {now.year}'


def _get_jumper_category_color(tipo: str) -> Optional[str]:
    """Obtiene el color hexadecimal para una categoría de jumper según el tipo"""
    if not tipo:
        return None
    
    tipo_upper = tipo.upper().strip()
    
    # Mapeo de categorías a colores (mismos colores que en el frontend)
    color_map = {
        'FC-FC': 'FF2196F3',      # Colors.blue
        'FC-LC': 'FF3F51B5',      # Colors.indigo
        'FC-SC': 'FF673AB7',      # Colors.deepPurple
        'LC-FC': 'FF4CAF50',      # Colors.green
        'LC-LC': 'FFFF9800',      # Colors.orange
        'SC-FC': 'FF9C27B0',      # Colors.purple
        'SC-LC': 'FFF44336',      # Colors.red
        'SC-SC': 'FF009688',      # Colors.teal
    }
    
    # Buscar coincidencia exacta o parcial
    for category, color in color_map.items():
        if category in tipo_upper or tipo_upper in category:
            return color
    
    return None


def _apply_cell_style(cell, bold: bool = False, center: bool = True):
    """Aplica estilo a una celda"""
    if bold:
        cell.font = Font(bold=True)
    if center:
        cell.alignment = Alignment(horizontal='center', vertical='center')
    # Bordes delgados
    thin_border = Border(
        left=Side(style='thin'),
        right=Side(style='thin'),
        top=Side(style='thin'),
        bottom=Side(style='thin')
    )
    cell.border = thin_border


def _create_jumpers_excel(items: List[Dict[str, Any]]) -> Workbook:
    """Crea un archivo Excel para jumpers con el formato correcto"""
    wb = Workbook()
    ws = wb.active
    ws.title = "Inventario"
    
    # Eliminar hoja por defecto si existe otra
    if "Sheet" in wb.sheetnames and ws.title != "Sheet":
        wb.remove(wb["Sheet"])
    
    # Título (fila 0, columna C - índice 2)
    title_cell = ws.cell(row=1, column=3, value=f'INVENTARIO JUMPERS {_get_month_year()}')
    title_cell.font = Font(bold=True, size=14)
    title_cell.alignment = Alignment(horizontal='center', vertical='center')
    
    # Fila vacía (fila 1)
    ws.append([])
    
    # Encabezados (fila 2)
    headers = ['TIPO', 'TAMAÑO (metros)', 'CANTIDAD', 'RACK', 'CONTENEDOR']
    ws.append(headers)
    
    # Aplicar estilo a encabezados
    for col in range(1, len(headers) + 1):
        cell = ws.cell(row=3, column=col)
        _apply_cell_style(cell, bold=True, center=True)
    
    # Datos (fila 3 en adelante)
    for item in items:
        row_data = [
            item.get("tipo", item.get("categoryName", "")),
            item.get("tamano", item.get("size", "")),
            item.get("cantidad", item.get("quantity", 0)),
            item.get("rack", ""),
            item.get("contenedor", item.get("container", ""))
        ]
        ws.append(row_data)
        
        # Aplicar estilo a datos
        row_num = ws.max_row
        for col in range(1, len(row_data) + 1):
            cell = ws.cell(row=row_num, column=col)
            _apply_cell_style(cell, bold=False, center=True)
    
    # Ajustar ancho de columnas
    ws.column_dimensions['A'].width = 25.0  # TIPO
    ws.column_dimensions['B'].width = 12.0  # TAMAÑO
    ws.column_dimensions['C'].width = 12.0  # CANTIDAD
    ws.column_dimensions['D'].width = 15.0  # RACK
    ws.column_dimensions['E'].width = 15.0  # CONTENEDOR
    
    return wb


def _create_computo_excel(items: List[Dict[str, Any]]) -> Workbook:
    """Crea un archivo Excel para inventarios de cómputo con todos los campos del esquema SQL"""
    wb = Workbook()
    ws = wb.active
    ws.title = "Inventario Cómputo"
    
    if "Sheet" in wb.sheetnames and ws.title != "Sheet":
        wb.remove(wb["Sheet"])
    
    # Título
    title_cell = ws.cell(row=1, column=1, value=f'INVENTARIO EQUIPO DE CÓMPUTO {_get_month_year()}')
    title_cell.font = Font(bold=True, size=16)
    title_cell.alignment = Alignment(horizontal='center', vertical='center')
    ws.merge_cells(start_row=1, start_column=1, end_row=1, end_column=21)
    
    ws.append([])
    
    # Encabezados completos basados en t_equipos_computo
    headers = [
        'INVENTARIO', 'EQUIPO PM', 'FECHA REGISTRO', 'TIPO EQUIPO', 'MARCA', 'MODELO', 
        'PROCESADOR', 'NÚMERO SERIE', 'DISCO DURO', 'MEMORIA', 
        'SISTEMA OPERATIVO', 'ETIQUETA SO', 'OFFICE INSTALADO', 'TIPO USO', 
        'NOMBRE EQUIPO DOMINIO', 'STATUS', 
        'UBICACIÓN FÍSICA', 'UBICACIÓN ADMINISTRATIVA', 
        'EMPLEADO ASIGNADO', 'EMPLEADO RESPONSABLE', 'OBSERVACIONES'
    ]
    ws.append(headers)
    
    # Aplicar estilo a encabezados
    for col in range(1, len(headers) + 1):
        cell = ws.cell(row=3, column=col)
        _apply_cell_style(cell, bold=True, center=True)
        cell.fill = PatternFill(start_color="366092", end_color="366092", fill_type="solid")
        cell.font = Font(bold=True, color="FFFFFF", size=10)
    
    # Datos
    for item in items:
        row_data = [
            item.get("inventario", item.get("inventario", "")),
            item.get("equipo_pm", item.get("equipo_pm", "")),
            item.get("fecha_registro", item.get("fecha_registro", "")),
            item.get("tipo_equipo", item.get("tipo_equipo", "")),
            item.get("marca", item.get("marca", "")),
            item.get("modelo", item.get("modelo", "")),
            item.get("procesador", item.get("procesador", "")),
            item.get("numero_serie", item.get("numero_serie", item.get("serie", ""))),
            item.get("disco_duro", item.get("disco_duro", "")),
            item.get("memoria", item.get("memoria", "")),
            item.get("sistema_operativo", item.get("sistema_operativo_instalado", "")),
            item.get("etiqueta_so", item.get("etiqueta_sistema_operativo", "")),
            item.get("office_instalado", item.get("office_instalado", "")),
            item.get("tipo_uso", item.get("tipo_uso", "")),
            item.get("nombre_dominio", item.get("nombre_equipo_dominio", "")),
            item.get("status", item.get("status", "ASIGNADO")),
            item.get("ubicacion_fisica", item.get("ubicacion_fisica", "")),
            item.get("ubicacion_admin", item.get("ubicacion_administrativa", "")),
            item.get("empleado_asignado", item.get("empleado_asignado", "")),
            item.get("empleado_responsable", item.get("empleado_responsable", "")),
            item.get("observaciones", item.get("observaciones", ""))
        ]
        ws.append(row_data)
        
        row_num = ws.max_row
        for col in range(1, len(row_data) + 1):
            cell = ws.cell(row=row_num, column=col)
            _apply_cell_style(cell, bold=False, center=False)
            # Alternar colores de fila para mejor legibilidad
            if row_num % 2 == 0:
                cell.fill = PatternFill(start_color="F2F2F2", end_color="F2F2F2", fill_type="solid")
    
    # Ajustar ancho de columnas
    column_widths = [15.0, 12.0, 12.0, 15.0, 12.0, 15.0, 15.0, 18.0, 12.0, 10.0, 
                     18.0, 12.0, 15.0, 12.0, 20.0, 12.0, 20.0, 20.0, 20.0, 20.0, 30.0]
    for idx, width in enumerate(column_widths, start=1):
        ws.column_dimensions[get_column_letter(idx)].width = width
    
    # Congelar paneles (fijar encabezados)
    ws.freeze_panes = 'A3'
    
    return wb


def _create_sdr_excel(items: List[Dict[str, Any]]) -> Workbook:
    """Crea un archivo Excel para formatos SDR"""
    wb = Workbook()
    ws = wb.active
    ws.title = "Inventario"
    
    if "Sheet" in wb.sheetnames and ws.title != "Sheet":
        wb.remove(wb["Sheet"])
    
    # Título
    title_cell = ws.cell(row=1, column=2, value=f'INVENTARIO SDR {_get_month_year()}')
    title_cell.font = Font(bold=True, size=14)
    title_cell.alignment = Alignment(horizontal='center', vertical='center')
    
    ws.append([])
    
    # Encabezados para SDR
    headers = ['CÓDIGO', 'DESCRIPCIÓN', 'CANTIDAD', 'UBICACIÓN', 'FECHA', 'OBSERVACIONES']
    ws.append(headers)
    
    # Aplicar estilo a encabezados
    for col in range(1, len(headers) + 1):
        cell = ws.cell(row=3, column=col)
        _apply_cell_style(cell, bold=True, center=True)
    
    # Datos
    for item in items:
        row_data = [
            item.get("codigo", item.get("code", "")),
            item.get("descripcion", item.get("description", "")),
            item.get("cantidad", item.get("quantity", 0)),
            item.get("ubicacion", item.get("location", "")),
            item.get("fecha", item.get("date", "")),
            item.get("observaciones", item.get("notes", ""))
        ]
        ws.append(row_data)
        
        row_num = ws.max_row
        for col in range(1, len(row_data) + 1):
            cell = ws.cell(row=row_num, column=col)
            _apply_cell_style(cell, bold=False, center=True)
    
    # Ajustar ancho de columnas
    column_widths = [15.0, 30.0, 12.0, 15.0, 12.0, 25.0]
    for idx, width in enumerate(column_widths, start=1):
        ws.column_dimensions[get_column_letter(idx)].width = width
    
    return wb


@app.get("/", tags=["root"])
def root():
    return {
        "ok": True,
        "endpoints": [
            "/api/generate-jumpers-excel",
            "/api/generate-computo-excel",
            "/api/generate-sdr-excel",
            "/api/debug-last-file",
            "/health"
        ]
    }


@app.get("/health", tags=["health"])
def health():
    try:
        templates_status = {
            "jumpers": os.path.exists(TEMPLATE_PATH_JUMPERS),
            "computo": os.path.exists(TEMPLATE_PATH_COMPUTO),
            "sdr": os.path.exists(TEMPLATE_PATH_SDR)
        }
        return {"ok": True, "templates": templates_status}
    except Exception as e:
        return JSONResponse(status_code=500, content={"ok": False, "error": str(e)})


@app.post("/api/generate-jumpers-excel")
async def generate_jumpers_excel(request: Request):
    payload = await request.json()
    items: List[Dict[str, Any]] = payload.get("items") or []
    if not isinstance(items, list) or len(items) == 0:
        raise HTTPException(status_code=400, detail="items must be a non-empty list")

    try:
        # Intentar usar plantilla si existe
        if _ensure_template(TEMPLATE_PATH_JUMPERS):
            wb = openpyxl.load_workbook(TEMPLATE_PATH_JUMPERS)
            ws = wb.active
            
            # Los datos empiezan en la fila 5 según la plantilla
            # Columnas: B=TIPO, C=TAMAÑO, D=CANTIDAD, E=RACK, F=CONTENEDOR (o #)
            start_row = 5
            
            # Obtener formato de referencia de la fila 5
            reference_cells = {}
            for col in range(2, 7):  # Columnas B-F
                ref_cell = ws.cell(row=start_row, column=col)
                reference_cells[col] = {
                    'font': ref_cell.font.copy() if ref_cell.font else None,
                    'fill': ref_cell.fill.copy() if ref_cell.fill else None,
                    'border': ref_cell.border.copy() if ref_cell.border else None,
                    'alignment': ref_cell.alignment.copy() if ref_cell.alignment else None,
                    'number_format': ref_cell.number_format,
                }
            
            # Insertar datos empezando desde la fila 5
            for idx, item in enumerate(items, start=0):
                row = start_row + idx
                
                # Obtener el tipo para determinar el color
                tipo = item.get("tipo", item.get("categoryName", ""))
                tipo_color = _get_jumper_category_color(tipo)
                
                # Col B: TIPO
                _safe_set_cell_value(ws, row, 2, tipo)
                # Col C: TAMAÑO (metros)
                _safe_set_cell_value(ws, row, 3, item.get("tamano", item.get("size", "")))
                # Col D: CANTIDAD
                _safe_set_cell_value(ws, row, 4, item.get("cantidad", item.get("quantity", 0)))
                # Col E: RACK
                _safe_set_cell_value(ws, row, 5, item.get("rack", ""))
                # Col F: CONTENEDOR (o #)
                _safe_set_cell_value(ws, row, 6, item.get("contenedor", item.get("container", "")))
                
                # Aplicar formato de la fila 5 a cada celda
                for col in range(2, 7):
                    cell = ws.cell(row=row, column=col)
                    ref_format = reference_cells[col]
                    
                    if ref_format['font']:
                        cell.font = ref_format['font']
                    if ref_format['fill']:
                        # Para la columna TIPO (columna B, índice 2), aplicar color según categoría
                        if col == 2 and tipo_color:
                            cell.fill = PatternFill(start_color=tipo_color, end_color=tipo_color, fill_type="solid")
                        else:
                            cell.fill = ref_format['fill']
                    if ref_format['border']:
                        cell.border = ref_format['border']
                    if ref_format['alignment']:
                        cell.alignment = ref_format['alignment']
                    if ref_format['number_format']:
                        cell.number_format = ref_format['number_format']
        else:
            # Crear desde cero con formato correcto si no hay plantilla
            wb = _create_jumpers_excel(items)

        file_bytes = _save_workbook_to_bytes(wb)
        if not file_bytes:
            raise RuntimeError("Generated file is empty")

        global LAST_GENERATED_FILE_CONTENT, LAST_GENERATED_FILENAME
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        filename = f"inventario_jumpers_{timestamp}.xlsx"
        LAST_GENERATED_FILE_CONTENT = file_bytes
        LAST_GENERATED_FILENAME = filename

        logger.info(f"📦 Tamaño del archivo generado: {len(file_bytes)} bytes")

        return Response(content=file_bytes,
                        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                        headers={"Content-Disposition": f"attachment; filename=\"{filename}\""})

    except Exception as e:
        logger.exception("Error generating jumpers excel")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/generate-computo-excel")
async def generate_computo_excel(request: Request):
    payload = await request.json()
    items: List[Dict[str, Any]] = payload.get("items") or []
    if not isinstance(items, list) or len(items) == 0:
        raise HTTPException(status_code=400, detail="items must be a non-empty list")

    try:
        # Usar plantilla si existe
        if _ensure_template(TEMPLATE_PATH_COMPUTO):
            logger.info(f"📄 Usando plantilla: {TEMPLATE_PATH_COMPUTO}")
            wb = openpyxl.load_workbook(TEMPLATE_PATH_COMPUTO)
            ws = wb.active
            
            # La inserción empieza en la fila 7
            start_row = 7
            
            # Buscar la primera fila vacía desde la fila 7
            while ws.cell(row=start_row, column=1).value is not None:
                start_row += 1
            
            logger.info(f"📝 Escribiendo {len(items)} equipos desde la fila {start_row}")
            
            # Obtener el formato de la fila 7 (fila de referencia)
            # La plantilla tiene 14 columnas según los encabezados:
            # 1: ID, 2: TIPO DE EQUIPO, 3: MARCA, 4: MODELO, 5: PROCESADOR,
            # 6: NUMERO DE SERIE, 7: DISCO DURO, 8: MEMORIA, 9: COMPONENTES,
            # 10: SISTEMA OPERATIVO INSTALADO, 11: OFFICE INSTALADO, 12: USUARIO ASIGNADO,
            # 13: UBICACIÓN, 14: OBSERVACIONES
            reference_row = 7
            reference_cells = {}
            for col in range(1, 15):  # Columnas A-N (14 columnas)
                ref_cell = ws.cell(row=reference_row, column=col)
                reference_cells[col] = {
                    'font': ref_cell.font.copy() if ref_cell.font else None,
                    'fill': ref_cell.fill.copy() if ref_cell.fill else None,
                    'border': ref_cell.border.copy() if ref_cell.border else None,
                    'alignment': ref_cell.alignment.copy() if ref_cell.alignment else None,
                    'number_format': ref_cell.number_format,
                }
            
            # Escribir cada equipo en una fila usando función segura y copiando formato
            for idx, item in enumerate(items, start=0):
                row = start_row + idx
                
                # Mapear campos según la plantilla (14 columnas en el orden correcto)
                # Col 1: ID -> inventario
                _safe_set_cell_value(ws, row, 1, item.get("inventario", ""))
                # Col 2: TIPO DE EQUIPO -> tipo_equipo
                _safe_set_cell_value(ws, row, 2, item.get("tipo_equipo", ""))
                # Col 3: MARCA -> marca
                _safe_set_cell_value(ws, row, 3, item.get("marca", ""))
                # Col 4: MODELO -> modelo
                _safe_set_cell_value(ws, row, 4, item.get("modelo", ""))
                # Col 5: PROCESADOR -> procesador
                _safe_set_cell_value(ws, row, 5, item.get("procesador", ""))
                # Col 6: NUMERO DE SERIE -> numero_serie
                _safe_set_cell_value(ws, row, 6, item.get("numero_serie", ""))
                # Col 7: DISCO DURO -> disco_duro
                _safe_set_cell_value(ws, row, 7, item.get("disco_duro", ""))
                # Col 8: MEMORIA -> memoria
                _safe_set_cell_value(ws, row, 8, item.get("memoria", ""))
                # Col 9: COMPONENTES -> componentes (formateados)
                _safe_set_cell_value(ws, row, 9, item.get("componentes", ""))
                # Col 10: SISTEMA OPERATIVO INSTALADO -> sistema_operativo_instalado
                _safe_set_cell_value(ws, row, 10, item.get("sistema_operativo_instalado", item.get("sistema_operativo", "")))
                # Col 11: OFFICE INSTALADO -> office_instalado
                _safe_set_cell_value(ws, row, 11, item.get("office_instalado", ""))
                # Col 12: USUARIO ASIGNADO -> empleado_asignado (nombre)
                _safe_set_cell_value(ws, row, 12, item.get("empleado_asignado", ""))
                # Col 13: UBICACIÓN -> direccion_fisica o ubicacion_fisica
                ubicacion = item.get("direccion_fisica", item.get("ubicacion_fisica", ""))
                _safe_set_cell_value(ws, row, 13, ubicacion)
                # Col 14: OBSERVACIONES -> observaciones
                _safe_set_cell_value(ws, row, 14, item.get("observaciones", ""))
                
                # Aplicar formato de la fila 7 a cada celda
                for col in range(1, 15):
                    cell = ws.cell(row=row, column=col)
                    ref_format = reference_cells[col]
                    
                    if ref_format['font']:
                        cell.font = ref_format['font']
                    if ref_format['fill']:
                        cell.fill = ref_format['fill']
                    if ref_format['border']:
                        cell.border = ref_format['border']
                    if ref_format['alignment']:
                        cell.alignment = ref_format['alignment']
                    if ref_format['number_format']:
                        cell.number_format = ref_format['number_format']
        else:
            # Crear desde cero con formato correcto
            wb = _create_computo_excel(items)

        file_bytes = _save_workbook_to_bytes(wb)
        if not file_bytes:
            raise RuntimeError("Generated file is empty")

        global LAST_GENERATED_FILE_CONTENT, LAST_GENERATED_FILENAME
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        filename = f"inventario_computo_{timestamp}.xlsx"
        LAST_GENERATED_FILE_CONTENT = file_bytes
        LAST_GENERATED_FILENAME = filename

        logger.info(f"📦 Tamaño del archivo generado: {len(file_bytes)} bytes")

        return Response(content=file_bytes,
                        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                        headers={"Content-Disposition": f"attachment; filename=\"{filename}\""})

    except Exception as e:
        logger.exception("Error generating computo excel")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/generate-sdr-excel")
async def generate_sdr_excel(request: Request):
    payload = await request.json()
    items: List[Dict[str, Any]] = payload.get("items") or []
    if not isinstance(items, list) or len(items) == 0:
        raise HTTPException(status_code=400, detail="items must be a non-empty list")

    try:
        # Intentar usar plantilla si existe, sino crear desde cero
        if _ensure_template(TEMPLATE_PATH_SDR):
            wb = openpyxl.load_workbook(TEMPLATE_PATH_SDR)
            ws = wb.active
            
            # Tomar el primer item (ya que es un formulario único, no una lista de items)
            item = items[0] if items else {}
            
            # Mapear campos a las filas correspondientes de la plantilla
            # Las columnas B y C están combinadas, así que escribimos en B
            # Datos de Falla de aviso
            ws.cell(row=9, column=2, value=item.get("fecha", item.get("date", "")))  # Fecha
            ws.cell(row=10, column=2, value=item.get("descripcion_aviso", item.get("descripcion_del_aviso", "")))  # Descripción del Aviso
            ws.cell(row=11, column=2, value=item.get("grupo_planificador", ""))  # Grupo planificador
            ws.cell(row=12, column=2, value=item.get("puesto_trabajo_responsable", ""))  # Puesto de trabajo responsable
            ws.cell(row=13, column=2, value=item.get("autor_aviso", ""))  # Autor de aviso
            ws.cell(row=14, column=2, value=item.get("motivo_intervencion", ""))  # Motivo de intervención
            ws.cell(row=15, column=2, value=item.get("modelo_dano", item.get("modelo_del_dano", "")))  # Modelo del Daño
            ws.cell(row=16, column=2, value=item.get("causa_averia", ""))  # Causa de la avería
            ws.cell(row=17, column=2, value=item.get("repercusion_funcionamiento", ""))  # Repercusión en el funcionamiento
            ws.cell(row=18, column=2, value=item.get("estado_instalacion", ""))  # Estado de la Instalación
            ws.cell(row=19, column=2, value=item.get("motivo_intervencion_afectacion", ""))  # Motivo de Intervención (AFECTACION)
            ws.cell(row=21, column=2, value=item.get("atencion_dano", ""))  # Atención del Daño
            ws.cell(row=22, column=2, value=item.get("prioridad", ""))  # Prioridad
            
            # Lugar del Daño
            ws.cell(row=25, column=2, value=item.get("centro_emplazamiento", ""))  # Centro Emplazamiento
            ws.cell(row=26, column=2, value=item.get("area_empresa", ""))  # Área de empresa
            ws.cell(row=27, column=2, value=item.get("puesto_trabajo_emplazamiento", ""))  # Puesto trabajo de emplazamiento
            ws.cell(row=28, column=2, value=item.get("division", ""))  # División
            ws.cell(row=29, column=2, value=item.get("estado_instalacion_lugar", ""))  # Estado de Instalación
            ws.cell(row=30, column=2, value=item.get("datos_disponibles", ""))  # Datos disponibles
            ws.cell(row=32, column=2, value=item.get("emplazamiento_1", item.get("emplazamiento", "")))  # Emplazamiento (primera ocurrencia)
            ws.cell(row=33, column=2, value=item.get("emplazamiento_2", item.get("emplazamiento", "")))  # Emplazamiento (segunda ocurrencia)
            ws.cell(row=34, column=2, value=item.get("local", ""))  # Local
            ws.cell(row=35, column=2, value=item.get("campo_clasificacion", ""))  # Campo de clasificación
            
            # Datos de la unidad Dañada
            ws.cell(row=38, column=2, value=item.get("tipo_unidad_danada", ""))  # Tipo
            ws.cell(row=39, column=2, value=item.get("no_serie_unidad_danada", ""))  # No de serie
            
            # Datos de la unidad que se montó
            ws.cell(row=42, column=2, value=item.get("tipo_unidad_montada", ""))  # Tipo
            ws.cell(row=43, column=2, value=item.get("no_serie_unidad_montada", ""))  # No de serie
            
        else:
            # Crear desde cero con formato correcto
            wb = _create_sdr_excel(items)

        file_bytes = _save_workbook_to_bytes(wb)
        if not file_bytes:
            raise RuntimeError("Generated file is empty")

        global LAST_GENERATED_FILE_CONTENT, LAST_GENERATED_FILENAME
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        filename = f"solicitud_sdr_{timestamp}.xlsx"
        LAST_GENERATED_FILE_CONTENT = file_bytes
        LAST_GENERATED_FILENAME = filename

        logger.info(f"📦 Tamaño del archivo generado: {len(file_bytes)} bytes")

        return Response(content=file_bytes,
                        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                        headers={"Content-Disposition": f"attachment; filename=\"{filename}\""})

    except Exception as e:
        logger.exception("Error generating SDR excel")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/debug-last-file")
def debug_last_file():
    if not LAST_GENERATED_FILE_CONTENT or not LAST_GENERATED_FILENAME:
        raise HTTPException(status_code=404, detail="No generated file in memory")

    tmp_path = os.path.join("/tmp", LAST_GENERATED_FILENAME)
    try:
        with open(tmp_path, "wb") as f:
            f.write(LAST_GENERATED_FILE_CONTENT)
        size = os.path.getsize(tmp_path)
        return {"ok": True, "path": tmp_path, "size": size}
    except Exception as e:
        logger.exception("Failed to write debug file")
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("excel_generator_service.main:app", host="0.0.0.0", port=8001, reload=True)
