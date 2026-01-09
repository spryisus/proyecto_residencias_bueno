import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/config/supabase_client.dart' show supabaseClient;
import '../../data/services/sdr_export_service.dart';

class SolicitudSdrScreen extends StatefulWidget {
  const SolicitudSdrScreen({super.key});

  @override
  State<SolicitudSdrScreen> createState() => _SolicitudSdrScreenState();
}

class _SolicitudSdrScreenState extends State<SolicitudSdrScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para Datos de Falla de aviso
  final _fechaController = TextEditingController();
  final _descripcionAvisoController = TextEditingController();
  final _grupoPlanificadorController = TextEditingController();
  final _puestoTrabajoResponsableController = TextEditingController();
  final _autorAvisoController = TextEditingController();
  final _motivoIntervencionController = TextEditingController();
  final _modeloDanoController = TextEditingController();
  final _causaAveriaController = TextEditingController();
  final _repercusionFuncionamientoController = TextEditingController();
  String? _repercusionFuncionamientoSeleccionada;
  String? _atencionDanoSeleccionada;
  String? _areaEmpresaSeleccionada;
  final _estadoInstalacionController = TextEditingController();
  final _motivoIntervencionAfectacionController = TextEditingController();
  final _atencionDanoController = TextEditingController();
  final _prioridadController = TextEditingController();
  
  // Controladores para Lugar del Daño
  final _centroEmplazamientoController = TextEditingController();
  final _areaEmpresaController = TextEditingController();
  final _puestoTrabajoEmplazamientoController = TextEditingController();
  final _divisionController = TextEditingController();
  final _estadoInstalacionLugarController = TextEditingController();
  final _datosDisponiblesController = TextEditingController();
  final _emplazamiento1Controller = TextEditingController();
  final _emplazamiento2Controller = TextEditingController();
  final _localController = TextEditingController();
  final _campoClasificacionController = TextEditingController();
  
  // Controladores para Datos de la unidad Dañada
  final _tipoUnidadDanadaController = TextEditingController();
  final _noSerieUnidadDanadaController = TextEditingController();
  
  // Controladores para Datos de la unidad que se montó
  final _tipoUnidadMontadaController = TextEditingController();
  final _noSerieUnidadMontadaController = TextEditingController();
  
  bool _isLoadingFixedData = true;
  Map<String, String> _fixedDataMap = {};

  @override
  void initState() {
    super.initState();
    _loadFixedData();
  }

  @override
  void dispose() {
    _fechaController.dispose();
    _descripcionAvisoController.dispose();
    _grupoPlanificadorController.dispose();
    _puestoTrabajoResponsableController.dispose();
    _autorAvisoController.dispose();
    _motivoIntervencionController.dispose();
    _modeloDanoController.dispose();
    _causaAveriaController.dispose();
    _repercusionFuncionamientoController.dispose();
    _estadoInstalacionController.dispose();
    _motivoIntervencionAfectacionController.dispose();
    _atencionDanoController.dispose();
    _prioridadController.dispose();
    _centroEmplazamientoController.dispose();
    _areaEmpresaController.dispose();
    _puestoTrabajoEmplazamientoController.dispose();
    _divisionController.dispose();
    _estadoInstalacionLugarController.dispose();
    _datosDisponiblesController.dispose();
    _emplazamiento1Controller.dispose();
    _emplazamiento2Controller.dispose();
    _localController.dispose();
    _campoClasificacionController.dispose();
    _tipoUnidadDanadaController.dispose();
    _noSerieUnidadDanadaController.dispose();
    _tipoUnidadMontadaController.dispose();
    _noSerieUnidadMontadaController.dispose();
    super.dispose();
  }

  /// Carga los datos fijos desde la base de datos
  Future<void> _loadFixedData() async {
    try {
      setState(() {
        _isLoadingFixedData = true;
      });

      final response = await supabaseClient
          .from('t_datos_fijos_sdr')
          .select('campo_nombre, valor')
          .order('campo_nombre');

      final dataMap = <String, String>{};
      for (var row in response) {
        dataMap[row['campo_nombre'] as String] = row['valor'] as String;
      }

      // Asignar valores a los controladores
      _grupoPlanificadorController.text = dataMap['grupo_planificador'] ?? 'LD. 70';
      _puestoTrabajoResponsableController.text = dataMap['puesto_trabajo_responsable'] ?? 'PTAZ POZA RICA';
      _autorAvisoController.text = dataMap['autor_aviso'] ?? '0117';
      _centroEmplazamientoController.text = dataMap['centro_emplazamiento'] ?? 'LDTX';
      _puestoTrabajoEmplazamientoController.text = dataMap['puesto_trabajo_emplazamiento'] ?? 'COM-PUE';
      _divisionController.text = dataMap['division'] ?? '70';
      _emplazamiento1Controller.text = dataMap['emplazamiento_1'] ?? 'PTAZ PORZA RICA';

      if (mounted) {
        setState(() {
          _fixedDataMap = dataMap;
          _isLoadingFixedData = false;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar datos fijos SDR: $e');
      // Usar valores por defecto si falla la carga
      _grupoPlanificadorController.text = 'LD. 70';
      _puestoTrabajoResponsableController.text = 'PTAZ POZA RICA';
      _autorAvisoController.text = '0117';
      _centroEmplazamientoController.text = 'LDTX';
      _puestoTrabajoEmplazamientoController.text = 'COM-PUE';
      _divisionController.text = '70';
      _emplazamiento1Controller.text = 'PTAZ PORZA RICA';
      
      if (mounted) {
        setState(() {
          _isLoadingFixedData = false;
        });
      }
    }
  }

  /// Guarda un dato fijo en la base de datos
  Future<void> _saveFixedData(String campoNombre, String valor) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nombreUsuario = prefs.getString('nombre_usuario') ?? 'Sistema';

      // Actualizar o insertar el valor
      await supabaseClient
          .from('t_datos_fijos_sdr')
          .upsert({
            'campo_nombre': campoNombre,
            'valor': valor,
            'actualizado_en': DateTime.now().toIso8601String(),
            'actualizado_por': nombreUsuario,
          }, onConflict: 'campo_nombre');

      // Actualizar el mapa local
      _fixedDataMap[campoNombre] = valor;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Campo "$campoNombre" actualizado. Todos los usuarios verán el cambio.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al guardar dato fijo SDR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Map<String, dynamic> _getFormData() {
    return {
      // Datos de Falla de aviso
      'fecha': _fechaController.text.isEmpty 
          ? DateTime.now().toString().split(' ')[0]
          : _fechaController.text,
      'descripcion_aviso': _descripcionAvisoController.text,
      'grupo_planificador': _grupoPlanificadorController.text,
      'puesto_trabajo_responsable': _puestoTrabajoResponsableController.text,
      'autor_aviso': _autorAvisoController.text,
      'motivo_intervencion': _motivoIntervencionController.text,
      'modelo_dano': _modeloDanoController.text,
      'causa_averia': _causaAveriaController.text,
      'repercusion_funcionamiento': _repercusionFuncionamientoController.text,
      'estado_instalacion': _estadoInstalacionController.text,
      'motivo_intervencion_afectacion': _motivoIntervencionAfectacionController.text,
      'atencion_dano': _atencionDanoController.text,
      'prioridad': _prioridadController.text,
      
      // Lugar del Daño
      'centro_emplazamiento': _centroEmplazamientoController.text,
      'area_empresa': _areaEmpresaController.text,
      'puesto_trabajo_emplazamiento': _puestoTrabajoEmplazamientoController.text,
      'division': _divisionController.text,
      'estado_instalacion_lugar': _estadoInstalacionLugarController.text,
      'datos_disponibles': _datosDisponiblesController.text,
      'emplazamiento_1': _emplazamiento1Controller.text,
      'emplazamiento_2': _emplazamiento2Controller.text,
      'local': _localController.text,
      'campo_clasificacion': _campoClasificacionController.text,
      
      // Datos de la unidad Dañada
      'tipo_unidad_danada': _tipoUnidadDanadaController.text,
      'no_serie_unidad_danada': _noSerieUnidadDanadaController.text,
      
      // Datos de la unidad que se montó
      'tipo_unidad_montada': _tipoUnidadMontadaController.text,
      'no_serie_unidad_montada': _noSerieUnidadMontadaController.text,
    };
  }

  Future<void> _exportarSDR() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa los campos requeridos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mostrar diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final formData = _getFormData();
      
      // Convertir a formato que espera el servicio (lista de items)
      // Como es un solo formulario, creamos un item con todos los datos
      final items = [formData];

      final filePath = await SdrExportService.exportSdrToExcel(items);

      if (!mounted) return;
      Navigator.pop(context); // Cerrar diálogo de carga

      if (filePath != null) {
        _showSuccessDialog(filePath);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Cerrar diálogo de carga
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar SDR: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showSuccessDialog(String filePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Exportación Exitosa'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('La solicitud SDR se ha exportado correctamente.'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  filePath,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Limpiar formulario después de exportar
                _limpiarFormulario();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _limpiarFormulario() {
    setState(() {
      // Limpiar campos editables
      _fechaController.clear();
      _descripcionAvisoController.clear();
      _motivoIntervencionController.clear();
      _modeloDanoController.clear();
      _causaAveriaController.clear();
      _repercusionFuncionamientoController.clear();
      _repercusionFuncionamientoSeleccionada = null;
      _estadoInstalacionController.clear();
      _motivoIntervencionAfectacionController.clear();
      _atencionDanoController.clear();
      _atencionDanoSeleccionada = null;
      _prioridadController.clear();
      _areaEmpresaController.clear();
      _areaEmpresaSeleccionada = null;
      _estadoInstalacionLugarController.clear();
      _datosDisponiblesController.clear();
      _emplazamiento2Controller.clear();
      _localController.clear();
      _campoClasificacionController.clear();
      _tipoUnidadDanadaController.clear();
      _noSerieUnidadDanadaController.clear();
      _tipoUnidadMontadaController.clear();
      _noSerieUnidadMontadaController.clear();
      
      // Restaurar valores fijos (NO limpiar estos campos)
      _grupoPlanificadorController.text = 'LD. 70';
      _puestoTrabajoResponsableController.text = 'PTAZ POZA RICA';
      _autorAvisoController.text = '0117';
      _centroEmplazamientoController.text = 'LDTX';
      _puestoTrabajoEmplazamientoController.text = 'COM-PUE';
      _divisionController.text = '70';
      _emplazamiento1Controller.text = 'PTAZ PORZA RICA';
    });
  }

  void _autollenarFormulario() {
    // Usar Future.microtask para asegurar que el widget esté completamente montado
    Future.microtask(() {
      if (!mounted) return;
      
      setState(() {
        try {
          // Datos de Falla de aviso (basados en ejemplo real)
          // Solo llenar campos vacíos, no sobrescribir valores fijos
          if (_fechaController.text.isEmpty) {
            _fechaController.text = '2025-09-05';
          }
          if (_descripcionAvisoController.text.isEmpty) {
            _descripcionAvisoController.text = 'FALLA DE RECTIFICADOR (RECTIFIER FAILURE)';
          }
          // NO llenar campos fijos: _grupoPlanificadorController, _puestoTrabajoResponsableController, _autorAvisoController
          if (_motivoIntervencionController.text.isEmpty) {
            _motivoIntervencionController.text = 'RECTIFICADOR DAÑADO (DAMAGED RECTIFIER)';
          }
          if (_modeloDanoController.text.isEmpty) {
            _modeloDanoController.text = 'EN OPERACIÓN (IN OPERATION)';
          }
          if (_causaAveriaController.text.isEmpty) {
            _causaAveriaController.text = 'FAN FAIL';
          }
          if (_repercusionFuncionamientoSeleccionada == null || _repercusionFuncionamientoController.text.isEmpty) {
            _repercusionFuncionamientoSeleccionada = 'CON SUSTITUCION DE TARJETA';
            _repercusionFuncionamientoController.text = 'CON SUSTITUCION DE TARJETA';
          }
          if (_estadoInstalacionController.text.isEmpty) {
            _estadoInstalacionController.text = 'NA';
          }
          if (_motivoIntervencionAfectacionController.text.isEmpty) {
            _motivoIntervencionAfectacionController.text = 'SIN AFECTACION (NO AFFECTATION)';
          }
          if (_atencionDanoSeleccionada == null || _atencionDanoController.text.isEmpty) {
            _atencionDanoSeleccionada = 'MENOR';
            _atencionDanoController.text = 'MENOR';
          }
          if (_prioridadController.text.isEmpty) {
            _prioridadController.text = 'MENOR (MINOR)';
          }
          
          // Lugar del Daño
          // NO llenar campos fijos: _centroEmplazamientoController, _puestoTrabajoEmplazamientoController, _divisionController
          if (_areaEmpresaSeleccionada == null || _areaEmpresaController.text.isEmpty) {
            _areaEmpresaSeleccionada = 'PTAZ';
            _areaEmpresaController.text = 'PTAZ';
          }
          if (_estadoInstalacionLugarController.text.isEmpty) {
            _estadoInstalacionLugarController.text = 'CON SUSTITUCION DE RECTIFICADOR (WITH RECTIFIER REPLACEMENT)';
          }
          if (_datosDisponiblesController.text.isEmpty) {
            _datosDisponiblesController.text = 'REGRESA A POZA RICA (RETURNS TO POZA RICA)';
          }
          // NO llenar campo fijo: _emplazamiento1Controller
          if (_emplazamiento2Controller.text.isEmpty) {
            _emplazamiento2Controller.text = 'PTAZ POZA RICA';
          }
          if (_localController.text.isEmpty) {
            _localController.text = 'SIN TIN';
          }
          // _campoClasificacionController se deja vacío intencionalmente
          
          // Datos de la unidad Dañada
          if (_tipoUnidadDanadaController.text.isEmpty) {
            _tipoUnidadDanadaController.text = 'CORDEX HP 48 4KW / 010623-20-XXX';
          }
          if (_noSerieUnidadDanadaController.text.isEmpty) {
            _noSerieUnidadDanadaController.text = '201037364 / 0516';
          }
          
          // Datos de la unidad que se montó
          if (_tipoUnidadMontadaController.text.isEmpty) {
            _tipoUnidadMontadaController.text = 'CORDEX HP 48 4KW /010623-20-XXX';
          }
          if (_noSerieUnidadMontadaController.text.isEmpty) {
            _noSerieUnidadMontadaController.text = '201105450/0821';
          }
        } catch (e) {
          // Si hay un error, mostrar mensaje pero no fallar
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al autollenar: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Formulario autollenado con datos de prueba'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitud SDR'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_fix_high),
            tooltip: 'Autollenar formulario (Prueba)',
            onPressed: _autollenarFormulario,
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Exportar a Excel',
            onPressed: _exportarSDR,
          ),
        ],
      ),
      body: _isLoadingFixedData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Text(
                'Formato para realizar Solicitud de Reparación de Unidades (SDR)',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // Sección 1: Datos de Falla de aviso
              _buildSectionCard(
                context,
                title: 'Datos de Falla de aviso',
                icon: Icons.warning_amber_rounded,
                color: Colors.orange,
                children: [
                  if (isMobile)
                    _buildMobileFormSection1()
                  else
                    _buildDesktopFormSection1(),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Sección 2: Lugar del Daño
              _buildSectionCard(
                context,
                title: 'Lugar del Daño',
                icon: Icons.location_on,
                color: Colors.blue,
                children: [
                  if (isMobile)
                    _buildMobileFormSection2()
                  else
                    _buildDesktopFormSection2(),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Sección 3: Datos de la unidad Dañada
              _buildSectionCard(
                context,
                title: 'Datos de la unidad Dañada',
                icon: Icons.build_circle_outlined,
                color: Colors.red,
                children: [
                  if (isMobile)
                    _buildMobileFormSection3()
                  else
                    _buildDesktopFormSection3(),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Sección 4: Datos de la unidad que se montó
              _buildSectionCard(
                context,
                title: 'Datos de la unidad que se montó (con la que se reparó la falla)',
                icon: Icons.check_circle_outline,
                color: Colors.green,
                children: [
                  if (isMobile)
                    _buildMobileFormSection4()
                  else
                    _buildDesktopFormSection4(),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Botón de exportar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _exportarSDR,
                  icon: const Icon(Icons.file_download, size: 24),
                  label: const Text(
                    'Exportar Solicitud SDR a Excel',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  // Helper para construir campos con label fuera y hintText dentro
  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    int? maxLines,
    String? Function(String?)? validator,
    String? helperText,
    bool readOnly = false,
    String? fixedDataField, // Nombre del campo en la BD para datos fijos
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            if (fixedDataField != null)
              Tooltip(
                message: 'Campo compartido: los cambios serán visibles para todos los usuarios',
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.blue[600],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onChanged: fixedDataField != null
              ? (value) {
                  // Guardar automáticamente cuando cambie un campo fijo
                  _saveFixedData(fixedDataField, value);
                }
              : null,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
            border: const OutlineInputBorder(),
            helperText: helperText ?? (fixedDataField != null 
                ? 'Campo compartido: los cambios se guardan automáticamente'
                : null),
            filled: readOnly,
            fillColor: readOnly ? Colors.grey[100] : null,
            suffixIcon: fixedDataField != null
                ? Icon(Icons.cloud_upload_outlined, size: 18, color: Colors.blue[600])
                : null,
          ),
          maxLines: maxLines ?? 1,
          validator: validator,
        ),
      ],
    );
  }

  // Helper para construir dropdown con label fuera
  Widget _buildDropdownField({
    required String label,
    required String hintText,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
            border: const OutlineInputBorder(),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
          isExpanded: true,
          selectedItemBuilder: (BuildContext context) {
            return items.map((String item) {
              return Text(
                item,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList();
          },
        ),
      ],
    );
  }

  // Sección 1: Datos de Falla de aviso (Móvil)
  Widget _buildMobileFormSection1() {
    return Column(
      children: [
        _buildFormField(
          controller: _fechaController,
          label: 'Fecha *',
          hintText: 'Ingrese la fecha en formato YYYY-MM-DD (dejar vacío para fecha actual)',
          helperText: 'Dejar vacío para fecha actual',
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _descripcionAvisoController,
          label: 'Descripción del Aviso *',
          hintText: 'Ingrese la descripción del aviso',
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Este campo es requerido';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _grupoPlanificadorController,
          label: 'Grupo planificador',
          hintText: 'Ingrese el grupo planificador',
          fixedDataField: 'grupo_planificador',
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _puestoTrabajoResponsableController,
          label: 'Puesto de trabajo responsable',
          hintText: 'Ingrese el puesto de trabajo responsable',
          fixedDataField: 'puesto_trabajo_responsable',
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _autorAvisoController,
          label: 'Autor de aviso',
          hintText: 'Ingrese el autor del aviso',
          fixedDataField: 'autor_aviso',
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _motivoIntervencionController,
          label: 'Motivo de intervención',
          hintText: 'Ingrese el motivo de intervención',
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _modeloDanoController,
          label: 'Modelo del Daño',
          hintText: 'Ingrese el modelo del daño',
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _causaAveriaController,
          label: 'Causa de la avería',
          hintText: 'Ingrese la causa de la avería',
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Repercusión en el funcionamiento',
          hintText: 'Seleccione la repercusión en el funcionamiento',
          value: _repercusionFuncionamientoSeleccionada,
          items: const [
            'CON SUSTITUCION DE TARJETA',
            'ARREGLO PROVISIONAL',
            'SIN UNIDAD',
          ],
          onChanged: (String? value) {
            setState(() {
              _repercusionFuncionamientoSeleccionada = value;
              _repercusionFuncionamientoController.text = value ?? '';
            });
          },
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _estadoInstalacionController,
          label: 'Estado de la Instalación',
          hintText: 'Ingrese el estado de la instalación',
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _motivoIntervencionAfectacionController,
          label: 'Motivo de Intervención (AFECTACION)',
          hintText: 'Ingrese el motivo de intervención por afectación',
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Atención del Daño',
          hintText: 'Seleccione la atención del daño',
          value: _atencionDanoSeleccionada,
          items: const [
            'URGENTE',
            'MAYOR',
            'MENOR',
          ],
          onChanged: (String? value) {
            setState(() {
              _atencionDanoSeleccionada = value;
              _atencionDanoController.text = value ?? '';
            });
          },
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _prioridadController,
          label: 'Prioridad',
          hintText: 'Ingrese la prioridad',
        ),
      ],
    );
  }

  // Sección 1: Datos de Falla de aviso (Desktop)
  Widget _buildDesktopFormSection1() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFormField(
                controller: _fechaController,
                label: 'Fecha *',
                hintText: 'Ingrese la fecha en formato YYYY-MM-DD (dejar vacío para fecha actual)',
                helperText: 'Dejar vacío para fecha actual',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFormField(
                controller: _prioridadController,
                label: 'Prioridad',
                hintText: 'Ingrese la prioridad',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _descripcionAvisoController,
          label: 'Descripción del Aviso *',
          hintText: 'Ingrese la descripción del aviso',
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Este campo es requerido';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildFormField(
                controller: _grupoPlanificadorController,
                label: 'Grupo planificador',
                hintText: 'Ingrese el grupo planificador',
                fixedDataField: 'grupo_planificador',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFormField(
                controller: _puestoTrabajoResponsableController,
                label: 'Puesto de trabajo responsable',
                hintText: 'Ingrese el puesto de trabajo responsable',
                fixedDataField: 'puesto_trabajo_responsable',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _autorAvisoController,
          label: 'Autor de aviso',
          hintText: 'Ingrese el autor del aviso',
          fixedDataField: 'autor_aviso',
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _motivoIntervencionController,
          label: 'Motivo de intervención',
          hintText: 'Ingrese el motivo de intervención',
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildFormField(
                controller: _modeloDanoController,
                label: 'Modelo del Daño',
                hintText: 'Ingrese el modelo del daño',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFormField(
                controller: _causaAveriaController,
                label: 'Causa de la avería',
                hintText: 'Ingrese la causa de la avería',
                maxLines: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Repercusión en el funcionamiento',
          hintText: 'Seleccione la repercusión en el funcionamiento',
          value: _repercusionFuncionamientoSeleccionada,
          items: const [
            'CON SUSTITUCION DE TARJETA',
            'ARREGLO PROVISIONAL',
            'SIN UNIDAD',
          ],
          onChanged: (String? value) {
            setState(() {
              _repercusionFuncionamientoSeleccionada = value;
              _repercusionFuncionamientoController.text = value ?? '';
            });
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildFormField(
                controller: _estadoInstalacionController,
                label: 'Estado de la Instalación',
                hintText: 'Ingrese el estado de la instalación',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFormField(
                controller: _motivoIntervencionAfectacionController,
                label: 'Motivo de Intervención (AFECTACION)',
                hintText: 'Ingrese el motivo de intervención por afectación',
                maxLines: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Atención del Daño',
          hintText: 'Seleccione la atención del daño',
          value: _atencionDanoSeleccionada,
          items: const [
            'URGENTE',
            'MAYOR',
            'MENOR',
          ],
          onChanged: (String? value) {
            setState(() {
              _atencionDanoSeleccionada = value;
              _atencionDanoController.text = value ?? '';
            });
          },
        ),
      ],
    );
  }

  // Sección 2: Lugar del Daño (Móvil)
  Widget _buildMobileFormSection2() {
    return Column(
      children: [
        _buildFormField(
          controller: _centroEmplazamientoController,
          label: 'Centro Emplazamiento',
          hintText: 'Ingrese el centro de emplazamiento',
          fixedDataField: 'centro_emplazamiento',
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Área de empresa',
          hintText: 'Seleccione el área de empresa',
          value: _areaEmpresaSeleccionada,
          items: const [
            'COM',
            'PTAZ',
            'CCE',
            'RMO',
            'RFO',
          ],
          onChanged: (String? value) {
            setState(() {
              _areaEmpresaSeleccionada = value;
              _areaEmpresaController.text = value ?? '';
            });
          },
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _puestoTrabajoEmplazamientoController,
          label: 'Puesto trabajo de emplazamiento',
          hintText: 'Ingrese el puesto de trabajo de emplazamiento',
          fixedDataField: 'puesto_trabajo_emplazamiento',
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _divisionController,
          label: 'División',
          hintText: 'Ingrese la división',
          fixedDataField: 'division',
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _estadoInstalacionLugarController,
          label: 'Estado de Instalación',
          hintText: 'Ingrese el estado de instalación',
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _datosDisponiblesController,
          label: 'Datos disponibles',
          hintText: 'Ingrese los datos disponibles',
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _emplazamiento1Controller,
          label: 'Emplazamiento',
          hintText: 'Ingrese el emplazamiento',
          fixedDataField: 'emplazamiento_1',
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _emplazamiento2Controller,
          label: 'Emplazamiento',
          hintText: 'Ingrese el emplazamiento',
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _localController,
          label: 'Local',
          hintText: 'Ingrese el local',
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _campoClasificacionController,
          label: 'Campo de clasificación',
          hintText: 'Ingrese el campo de clasificación',
        ),
      ],
    );
  }

  // Sección 2: Lugar del Daño (Desktop)
  Widget _buildDesktopFormSection2() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFormField(
                controller: _centroEmplazamientoController,
                label: 'Centro Emplazamiento',
                hintText: 'Ingrese el centro de emplazamiento',
                fixedDataField: 'centro_emplazamiento',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                label: 'Área de empresa',
                hintText: 'Seleccione el área de empresa',
                value: _areaEmpresaSeleccionada,
                items: const [
                  'COM',
                  'PTAZ',
                  'CCE',
                  'RMO',
                  'RFO',
                ],
                onChanged: (String? value) {
                  setState(() {
                    _areaEmpresaSeleccionada = value;
                    _areaEmpresaController.text = value ?? '';
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildFormField(
                controller: _puestoTrabajoEmplazamientoController,
                label: 'Puesto trabajo de emplazamiento',
                hintText: 'Ingrese el puesto de trabajo de emplazamiento',
                fixedDataField: 'puesto_trabajo_emplazamiento',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFormField(
                controller: _divisionController,
                label: 'División',
                hintText: 'Ingrese la división',
                fixedDataField: 'division',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildFormField(
                controller: _estadoInstalacionLugarController,
                label: 'Estado de Instalación',
                hintText: 'Ingrese el estado de instalación',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFormField(
                controller: _datosDisponiblesController,
                label: 'Datos disponibles',
                hintText: 'Ingrese los datos disponibles',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildFormField(
                controller: _emplazamiento1Controller,
                label: 'Emplazamiento',
                hintText: 'Ingrese el emplazamiento',
                fixedDataField: 'emplazamiento_1',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFormField(
                controller: _emplazamiento2Controller,
                label: 'Emplazamiento',
                hintText: 'Ingrese el emplazamiento',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildFormField(
                controller: _localController,
                label: 'Local',
                hintText: 'Ingrese el local',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFormField(
                controller: _campoClasificacionController,
                label: 'Campo de clasificación',
                hintText: 'Ingrese el campo de clasificación',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Sección 3: Datos de la unidad Dañada (Móvil)
  Widget _buildMobileFormSection3() {
    return Column(
      children: [
        _buildFormField(
          controller: _tipoUnidadDanadaController,
          label: 'Tipo',
          hintText: 'Ingrese el tipo de unidad dañada',
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _noSerieUnidadDanadaController,
          label: 'No de serie',
          hintText: 'Ingrese el número de serie de la unidad dañada',
        ),
      ],
    );
  }

  // Sección 3: Datos de la unidad Dañada (Desktop)
  Widget _buildDesktopFormSection3() {
    return Row(
      children: [
        Expanded(
          child: _buildFormField(
            controller: _tipoUnidadDanadaController,
            label: 'Tipo',
            hintText: 'Ingrese el tipo de unidad dañada',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildFormField(
            controller: _noSerieUnidadDanadaController,
            label: 'No de serie',
            hintText: 'Ingrese el número de serie de la unidad dañada',
          ),
        ),
      ],
    );
  }

  // Sección 4: Datos de la unidad que se montó (Móvil)
  Widget _buildMobileFormSection4() {
    return Column(
      children: [
        _buildFormField(
          controller: _tipoUnidadMontadaController,
          label: 'Tipo',
          hintText: 'Ingrese el tipo de unidad montada',
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _noSerieUnidadMontadaController,
          label: 'No de serie',
          hintText: 'Ingrese el número de serie de la unidad montada',
        ),
      ],
    );
  }

  // Sección 4: Datos de la unidad que se montó (Desktop)
  Widget _buildDesktopFormSection4() {
    return Row(
      children: [
        Expanded(
          child: _buildFormField(
            controller: _tipoUnidadMontadaController,
            label: 'Tipo',
            hintText: 'Ingrese el tipo de unidad montada',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildFormField(
            controller: _noSerieUnidadMontadaController,
            label: 'No de serie',
            hintText: 'Ingrese el número de serie de la unidad montada',
          ),
        ),
      ],
    );
  }
}
