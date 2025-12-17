import 'package:flutter/material.dart';
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
      _fechaController.clear();
      _descripcionAvisoController.clear();
      _grupoPlanificadorController.clear();
      _puestoTrabajoResponsableController.clear();
      _autorAvisoController.clear();
      _motivoIntervencionController.clear();
      _modeloDanoController.clear();
      _causaAveriaController.clear();
      _repercusionFuncionamientoController.clear();
      _estadoInstalacionController.clear();
      _motivoIntervencionAfectacionController.clear();
      _atencionDanoController.clear();
      _prioridadController.clear();
      _centroEmplazamientoController.clear();
      _areaEmpresaController.clear();
      _puestoTrabajoEmplazamientoController.clear();
      _divisionController.clear();
      _estadoInstalacionLugarController.clear();
      _datosDisponiblesController.clear();
      _emplazamiento1Controller.clear();
      _emplazamiento2Controller.clear();
      _localController.clear();
      _campoClasificacionController.clear();
      _tipoUnidadDanadaController.clear();
      _noSerieUnidadDanadaController.clear();
      _tipoUnidadMontadaController.clear();
      _noSerieUnidadMontadaController.clear();
    });
  }

  void _autollenarFormulario() {
    // Usar Future.microtask para asegurar que el widget esté completamente montado
    Future.microtask(() {
      if (!mounted) return;
      
      setState(() {
        try {
          // Datos de Falla de aviso (basados en ejemplo real)
          _fechaController.text = '2025-09-05';
          _descripcionAvisoController.text = 'FALLA DE RECTIFICADOR (RECTIFIER FAILURE)';
          _grupoPlanificadorController.text = 'LD. 70';
          _puestoTrabajoResponsableController.text = 'PTAZ O&M L.D.';
          _autorAvisoController.text = '719964';
          _motivoIntervencionController.text = 'RECTIFICADOR DAÑADO (DAMAGED RECTIFIER)';
          _modeloDanoController.text = 'EN OPERACIÓN (IN OPERATION)';
          _causaAveriaController.text = 'FAN FAIL';
          _repercusionFuncionamientoController.text = 'SIN UNIDAD (WITHOUT UNIT)';
          _estadoInstalacionController.text = 'NA';
          _motivoIntervencionAfectacionController.text = 'SIN AFECTACION (NO AFFECTATION)';
          _atencionDanoController.text = '';
          _prioridadController.text = 'MENOR (MINOR)';
          
          // Lugar del Daño
          _centroEmplazamientoController.text = 'LDTX';
          _areaEmpresaController.text = 'PTAZ POZA RICA';
          _puestoTrabajoEmplazamientoController.text = 'COM-PUE';
          _divisionController.text = '70';
          _estadoInstalacionLugarController.text = 'CON SUSTITUCION DE RECTIFICADOR (WITH RECTIFIER REPLACEMENT)';
          _datosDisponiblesController.text = 'REGRESA A POZA RICA (RETURNS TO POZA RICA)';
          _emplazamiento1Controller.text = 'PTAZ POZA RICA';
          _emplazamiento2Controller.text = 'PTAZ POZA RICA';
          _localController.text = 'SIN TIN';
          _campoClasificacionController.text = '';
          
          // Datos de la unidad Dañada
          _tipoUnidadDanadaController.text = 'CORDEX HP 48 4KW / 010623-20-XXX';
          _noSerieUnidadDanadaController.text = '201037364 / 0516';
          
          // Datos de la unidad que se montó
          _tipoUnidadMontadaController.text = 'CORDEX HP 48 4KW /010623-20-XXX';
          _noSerieUnidadMontadaController.text = '201105450/0821';
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
      body: SingleChildScrollView(
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

  // Sección 1: Datos de Falla de aviso (Móvil)
  Widget _buildMobileFormSection1() {
    return Column(
      children: [
        TextFormField(
          controller: _fechaController,
          decoration: const InputDecoration(
            labelText: 'Fecha *',
            border: OutlineInputBorder(),
            hintText: 'YYYY-MM-DD',
            helperText: 'Dejar vacío para fecha actual',
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descripcionAvisoController,
          decoration: const InputDecoration(
            labelText: 'Descripción del Aviso *',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Este campo es requerido';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _grupoPlanificadorController,
          decoration: const InputDecoration(
            labelText: 'Grupo planificador',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _puestoTrabajoResponsableController,
          decoration: const InputDecoration(
            labelText: 'Puesto de trabajo responsable',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _autorAvisoController,
          decoration: const InputDecoration(
            labelText: 'Autor de aviso',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _motivoIntervencionController,
          decoration: const InputDecoration(
            labelText: 'Motivo de intervención',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _modeloDanoController,
          decoration: const InputDecoration(
            labelText: 'Modelo del Daño',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _causaAveriaController,
          decoration: const InputDecoration(
            labelText: 'Causa de la avería',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _repercusionFuncionamientoController,
          decoration: const InputDecoration(
            labelText: 'Repercusión en el funcionamiento',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _estadoInstalacionController,
          decoration: const InputDecoration(
            labelText: 'Estado de la Instalación',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _motivoIntervencionAfectacionController,
          decoration: const InputDecoration(
            labelText: 'Motivo de Intervención (AFECTACION)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _atencionDanoController,
          decoration: const InputDecoration(
            labelText: 'Atención del Daño',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _prioridadController,
          decoration: const InputDecoration(
            labelText: 'Prioridad',
            border: OutlineInputBorder(),
          ),
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
              child: TextFormField(
                controller: _fechaController,
                decoration: const InputDecoration(
                  labelText: 'Fecha *',
                  border: OutlineInputBorder(),
                  hintText: 'YYYY-MM-DD',
                  helperText: 'Dejar vacío para fecha actual',
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _prioridadController,
                decoration: const InputDecoration(
                  labelText: 'Prioridad',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descripcionAvisoController,
          decoration: const InputDecoration(
            labelText: 'Descripción del Aviso *',
            border: OutlineInputBorder(),
          ),
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
              child: TextFormField(
                controller: _grupoPlanificadorController,
                decoration: const InputDecoration(
                  labelText: 'Grupo planificador',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _puestoTrabajoResponsableController,
                decoration: const InputDecoration(
                  labelText: 'Puesto de trabajo responsable',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _autorAvisoController,
          decoration: const InputDecoration(
            labelText: 'Autor de aviso',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _motivoIntervencionController,
          decoration: const InputDecoration(
            labelText: 'Motivo de intervención',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _modeloDanoController,
                decoration: const InputDecoration(
                  labelText: 'Modelo del Daño',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _causaAveriaController,
                decoration: const InputDecoration(
                  labelText: 'Causa de la avería',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _repercusionFuncionamientoController,
          decoration: const InputDecoration(
            labelText: 'Repercusión en el funcionamiento',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _estadoInstalacionController,
                decoration: const InputDecoration(
                  labelText: 'Estado de la Instalación',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _motivoIntervencionAfectacionController,
                decoration: const InputDecoration(
                  labelText: 'Motivo de Intervención (AFECTACION)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _atencionDanoController,
          decoration: const InputDecoration(
            labelText: 'Atención del Daño',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  // Sección 2: Lugar del Daño (Móvil)
  Widget _buildMobileFormSection2() {
    return Column(
      children: [
        TextFormField(
          controller: _centroEmplazamientoController,
          decoration: const InputDecoration(
            labelText: 'Centro Emplazamiento',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _areaEmpresaController,
          decoration: const InputDecoration(
            labelText: 'Área de empresa',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _puestoTrabajoEmplazamientoController,
          decoration: const InputDecoration(
            labelText: 'Puesto trabajo de emplazamiento',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _divisionController,
          decoration: const InputDecoration(
            labelText: 'División',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _estadoInstalacionLugarController,
          decoration: const InputDecoration(
            labelText: 'Estado de Instalación',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _datosDisponiblesController,
          decoration: const InputDecoration(
            labelText: 'Datos disponibles',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emplazamiento1Controller,
          decoration: const InputDecoration(
            labelText: 'Emplazamiento',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emplazamiento2Controller,
          decoration: const InputDecoration(
            labelText: 'Emplazamiento',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _localController,
          decoration: const InputDecoration(
            labelText: 'Local',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _campoClasificacionController,
          decoration: const InputDecoration(
            labelText: 'Campo de clasificación',
            border: OutlineInputBorder(),
          ),
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
              child: TextFormField(
                controller: _centroEmplazamientoController,
                decoration: const InputDecoration(
                  labelText: 'Centro Emplazamiento',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _areaEmpresaController,
                decoration: const InputDecoration(
                  labelText: 'Área de empresa',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _puestoTrabajoEmplazamientoController,
                decoration: const InputDecoration(
                  labelText: 'Puesto trabajo de emplazamiento',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _divisionController,
                decoration: const InputDecoration(
                  labelText: 'División',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _estadoInstalacionLugarController,
                decoration: const InputDecoration(
                  labelText: 'Estado de Instalación',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _datosDisponiblesController,
                decoration: const InputDecoration(
                  labelText: 'Datos disponibles',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _emplazamiento1Controller,
                decoration: const InputDecoration(
                  labelText: 'Emplazamiento',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _emplazamiento2Controller,
                decoration: const InputDecoration(
                  labelText: 'Emplazamiento',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _localController,
                decoration: const InputDecoration(
                  labelText: 'Local',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _campoClasificacionController,
                decoration: const InputDecoration(
                  labelText: 'Campo de clasificación',
                  border: OutlineInputBorder(),
                ),
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
        TextFormField(
          controller: _tipoUnidadDanadaController,
          decoration: const InputDecoration(
            labelText: 'Tipo',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _noSerieUnidadDanadaController,
          decoration: const InputDecoration(
            labelText: 'No de serie',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  // Sección 3: Datos de la unidad Dañada (Desktop)
  Widget _buildDesktopFormSection3() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _tipoUnidadDanadaController,
            decoration: const InputDecoration(
              labelText: 'Tipo',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _noSerieUnidadDanadaController,
            decoration: const InputDecoration(
              labelText: 'No de serie',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  // Sección 4: Datos de la unidad que se montó (Móvil)
  Widget _buildMobileFormSection4() {
    return Column(
      children: [
        TextFormField(
          controller: _tipoUnidadMontadaController,
          decoration: const InputDecoration(
            labelText: 'Tipo',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _noSerieUnidadMontadaController,
          decoration: const InputDecoration(
            labelText: 'No de serie',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  // Sección 4: Datos de la unidad que se montó (Desktop)
  Widget _buildDesktopFormSection4() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _tipoUnidadMontadaController,
            decoration: const InputDecoration(
              labelText: 'Tipo',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _noSerieUnidadMontadaController,
            decoration: const InputDecoration(
              labelText: 'No de serie',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}
