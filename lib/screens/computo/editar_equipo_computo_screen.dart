import 'package:flutter/material.dart';
import '../../app/config/supabase_client.dart' show supabaseClient;

class EditarEquipoComputoScreen extends StatefulWidget {
  final Map<String, dynamic> equipo;
  final List<Map<String, dynamic>> componentes;

  const EditarEquipoComputoScreen({
    super.key,
    required this.equipo,
    required this.componentes,
  });

  @override
  State<EditarEquipoComputoScreen> createState() => _EditarEquipoComputoScreenState();
}

class _EditarEquipoComputoScreenState extends State<EditarEquipoComputoScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Controladores para el equipo
  late TextEditingController _inventarioController;
  late TextEditingController _equipoPmController;
  late TextEditingController _tipoEquipoController;
  late TextEditingController _marcaController;
  late TextEditingController _modeloController;
  late TextEditingController _procesadorController;
  late TextEditingController _numeroSerieController;
  late TextEditingController _discoDuroController;
  late TextEditingController _memoriaController;
  late TextEditingController _sistemaOperativoController;
  late TextEditingController _etiquetaSoController;
  late TextEditingController _officeInstaladoController;
  late TextEditingController _tipoUsoController;
  late TextEditingController _nombreEquipoDominioController;
  late TextEditingController _statusController;
  late TextEditingController _ubicacionFisicaController;
  late TextEditingController _ubicacionAdministrativaController;
  late TextEditingController _empleadoAsignadoController;
  late TextEditingController _empleadoResponsableController;
  late TextEditingController _observacionesController;

  // Lista de componentes editables
  List<Map<String, dynamic>> _componentesEditables = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeComponentes();
  }

  void _initializeControllers() {
    _inventarioController = TextEditingController(text: widget.equipo['inventario']?.toString() ?? '');
    _equipoPmController = TextEditingController(text: widget.equipo['equipo_pm']?.toString() ?? '');
    _tipoEquipoController = TextEditingController(text: widget.equipo['tipo_equipo']?.toString() ?? '');
    _marcaController = TextEditingController(text: widget.equipo['marca']?.toString() ?? '');
    _modeloController = TextEditingController(text: widget.equipo['modelo']?.toString() ?? '');
    _procesadorController = TextEditingController(text: widget.equipo['procesador']?.toString() ?? '');
    _numeroSerieController = TextEditingController(text: widget.equipo['numero_serie']?.toString() ?? '');
    _discoDuroController = TextEditingController(text: widget.equipo['disco_duro']?.toString() ?? '');
    _memoriaController = TextEditingController(text: widget.equipo['memoria']?.toString() ?? '');
    _sistemaOperativoController = TextEditingController(text: widget.equipo['sistema_operativo']?.toString() ?? '');
    _etiquetaSoController = TextEditingController(text: widget.equipo['etiqueta_so']?.toString() ?? '');
    _officeInstaladoController = TextEditingController(text: widget.equipo['office_instalado']?.toString() ?? '');
    _tipoUsoController = TextEditingController(text: widget.equipo['tipo_uso']?.toString() ?? '');
    _nombreEquipoDominioController = TextEditingController(text: widget.equipo['nombre_equipo_dominio']?.toString() ?? '');
    _statusController = TextEditingController(text: widget.equipo['status']?.toString() ?? '');
    _ubicacionFisicaController = TextEditingController(text: widget.equipo['ubicacion_fisica']?.toString() ?? '');
    _ubicacionAdministrativaController = TextEditingController(text: widget.equipo['ubicacion_administrativa']?.toString() ?? '');
    _empleadoAsignadoController = TextEditingController(text: widget.equipo['empleado_asignado']?.toString() ?? '');
    _empleadoResponsableController = TextEditingController(text: widget.equipo['empleado_responsable']?.toString() ?? '');
    _observacionesController = TextEditingController(text: widget.equipo['observaciones']?.toString() ?? '');
  }

  void _initializeComponentes() {
    _componentesEditables = widget.componentes.map((comp) => {
      'id_componente': comp['id_componente'],
      'tipo_componente': comp['tipo_componente']?.toString() ?? '',
      'marca': comp['marca']?.toString() ?? '',
      'modelo': comp['modelo']?.toString() ?? '',
      'numero_serie': comp['numero_serie']?.toString() ?? '',
      'estado': comp['estado']?.toString() ?? '',
      'isNew': false,
    }).toList();
  }

  @override
  void dispose() {
    _inventarioController.dispose();
    _equipoPmController.dispose();
    _tipoEquipoController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _procesadorController.dispose();
    _numeroSerieController.dispose();
    _discoDuroController.dispose();
    _memoriaController.dispose();
    _sistemaOperativoController.dispose();
    _etiquetaSoController.dispose();
    _officeInstaladoController.dispose();
    _tipoUsoController.dispose();
    _nombreEquipoDominioController.dispose();
    _statusController.dispose();
    _ubicacionFisicaController.dispose();
    _ubicacionAdministrativaController.dispose();
    _empleadoAsignadoController.dispose();
    _empleadoResponsableController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Actualizar equipo
      await supabaseClient
          .from('t_equipos_computo')
          .update({
            'equipo_pm': _equipoPmController.text.trim().isEmpty ? null : _equipoPmController.text.trim(),
            'tipo_equipo': _tipoEquipoController.text.trim().isEmpty ? null : _tipoEquipoController.text.trim(),
            'marca': _marcaController.text.trim().isEmpty ? null : _marcaController.text.trim(),
            'modelo': _modeloController.text.trim().isEmpty ? null : _modeloController.text.trim(),
            'procesador': _procesadorController.text.trim().isEmpty ? null : _procesadorController.text.trim(),
            'numero_serie': _numeroSerieController.text.trim().isEmpty ? null : _numeroSerieController.text.trim(),
            'disco_duro': _discoDuroController.text.trim().isEmpty ? null : _discoDuroController.text.trim(),
            'memoria': _memoriaController.text.trim().isEmpty ? null : _memoriaController.text.trim(),
            'sistema_operativo': _sistemaOperativoController.text.trim().isEmpty ? null : _sistemaOperativoController.text.trim(),
            'etiqueta_so': _etiquetaSoController.text.trim().isEmpty ? null : _etiquetaSoController.text.trim(),
            'office_instalado': _officeInstaladoController.text.trim().isEmpty ? null : _officeInstaladoController.text.trim(),
            'tipo_uso': _tipoUsoController.text.trim().isEmpty ? null : _tipoUsoController.text.trim(),
            'nombre_equipo_dominio': _nombreEquipoDominioController.text.trim().isEmpty ? null : _nombreEquipoDominioController.text.trim(),
            'status': _statusController.text.trim().isEmpty ? null : _statusController.text.trim(),
            'ubicacion_fisica': _ubicacionFisicaController.text.trim().isEmpty ? null : _ubicacionFisicaController.text.trim(),
            'ubicacion_administrativa': _ubicacionAdministrativaController.text.trim().isEmpty ? null : _ubicacionAdministrativaController.text.trim(),
            'empleado_asignado': _empleadoAsignadoController.text.trim().isEmpty ? null : _empleadoAsignadoController.text.trim(),
            'empleado_responsable': _empleadoResponsableController.text.trim().isEmpty ? null : _empleadoResponsableController.text.trim(),
            'observaciones': _observacionesController.text.trim().isEmpty ? null : _observacionesController.text.trim(),
          })
          .eq('inventario', _inventarioController.text.trim());

      // Actualizar componentes existentes
      for (var componente in _componentesEditables) {
        if (!componente['isNew'] && componente['id_componente'] != null) {
          final tipoComponente = componente['tipo_componente']?.toString().trim() ?? '';
          final marca = componente['marca']?.toString().trim() ?? '';
          final modelo = componente['modelo']?.toString().trim() ?? '';
          final numeroSerie = componente['numero_serie']?.toString().trim() ?? '';
          final estado = componente['estado']?.toString().trim() ?? '';
          
          await supabaseClient
              .from('t_componentes_computo')
              .update({
                'tipo_componente': tipoComponente.isEmpty ? null : tipoComponente,
                'marca': marca.isEmpty ? null : marca,
                'modelo': modelo.isEmpty ? null : modelo,
                'numero_serie': numeroSerie.isEmpty ? null : numeroSerie,
                'estado': estado.isEmpty ? null : estado,
              })
              .eq('id_componente', componente['id_componente']);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Equipo actualizado correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true); // Retornar true para indicar que se guardó
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _editarComponente(int index) {
    final componente = _componentesEditables[index];
    showDialog(
      context: context,
      builder: (context) => _ComponenteDialog(
        componente: Map<String, dynamic>.from(componente),
        onSave: (updated) {
          setState(() {
            _componentesEditables[index] = updated;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Equipo de Cómputo'),
        centerTitle: true,
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Guardar cambios',
              onPressed: _guardarCambios,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Información del Equipo
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.computer, color: Color(0xFF003366)),
                        const SizedBox(width: 8),
                        const Text(
                          'Información del Equipo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003366),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField('Inventario', _inventarioController, enabled: false, icon: Icons.inventory_2),
                    _buildTextField('Equipo PM', _equipoPmController, icon: Icons.tag),
                    _buildTextField('Tipo de Equipo', _tipoEquipoController, icon: Icons.category),
                    _buildTextField('Marca', _marcaController, icon: Icons.branding_watermark),
                    _buildTextField('Modelo', _modeloController, icon: Icons.model_training),
                    _buildTextField('Procesador', _procesadorController, icon: Icons.memory),
                    _buildTextField('Número de Serie', _numeroSerieController, icon: Icons.qr_code),
                    _buildTextField('Disco Duro', _discoDuroController, icon: Icons.storage),
                    _buildTextField('Memoria', _memoriaController, icon: Icons.ramp_right),
                    _buildTextField('Sistema Operativo', _sistemaOperativoController, icon: Icons.desktop_windows),
                    _buildTextField('Etiqueta SO', _etiquetaSoController, icon: Icons.label),
                    _buildTextField('Office Instalado', _officeInstaladoController, icon: Icons.description),
                    _buildTextField('Tipo de Uso', _tipoUsoController, icon: Icons.work),
                    _buildTextField('Nombre Equipo Dominio', _nombreEquipoDominioController, icon: Icons.dns),
                    _buildTextField('Status', _statusController, icon: Icons.info),
                    _buildTextField('Ubicación Física', _ubicacionFisicaController, icon: Icons.location_on),
                    _buildTextField('Ubicación Administrativa', _ubicacionAdministrativaController, icon: Icons.business),
                    _buildTextField('Empleado Asignado (Usuario Final)', _empleadoAsignadoController, isRequired: true, icon: Icons.person),
                    _buildTextField('Empleado Responsable', _empleadoResponsableController, icon: Icons.person_outline),
                    _buildTextField('Observaciones', _observacionesController, maxLines: 3, icon: Icons.note),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Componentes
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.extension, color: Color(0xFF003366)),
                        const SizedBox(width: 8),
                        const Text(
                          'Componentes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003366),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_componentesEditables.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No hay componentes registrados',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ..._componentesEditables.asMap().entries.map((entry) {
                        final index = entry.key;
                        final componente = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(_getComponentIcon(componente['tipo_componente'])),
                            title: Text(componente['tipo_componente'] ?? 'Componente'),
                            subtitle: Text(
                              '${componente['marca'] ?? ''} ${componente['modelo'] ?? ''}'.trim(),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editarComponente(index),
                            ),
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Botón guardar
            ElevatedButton(
              onPressed: _isLoading ? null : _guardarCambios,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Guardar Cambios',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool enabled = true, bool isRequired = false, int maxLines = 1, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF003366),
          ),
          prefixIcon: icon != null ? Icon(icon, color: enabled ? const Color(0xFF003366) : Colors.grey) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF003366)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF003366), width: 2),
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[200],
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
        style: TextStyle(
          color: enabled ? Colors.black87 : Colors.grey[600],
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        validator: isRequired
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Este campo es requerido';
                }
                return null;
              }
            : null,
      ),
    );
  }

  IconData _getComponentIcon(String? tipo) {
    if (tipo == null) return Icons.extension;
    final tipoLower = tipo.toLowerCase();
    if (tipoLower.contains('teclado') || tipoLower.contains('keyboard')) {
      return Icons.keyboard;
    } else if (tipoLower.contains('mouse') || tipoLower.contains('ratón')) {
      return Icons.mouse;
    } else if (tipoLower.contains('monitor') || tipoLower.contains('pantalla')) {
      return Icons.monitor;
    } else if (tipoLower.contains('cable') || tipoLower.contains('cableado')) {
      return Icons.cable;
    } else if (tipoLower.contains('cargador') || tipoLower.contains('power')) {
      return Icons.battery_charging_full;
    } else {
      return Icons.extension;
    }
  }
}

class _ComponenteDialog extends StatefulWidget {
  final Map<String, dynamic> componente;
  final Function(Map<String, dynamic>) onSave;

  const _ComponenteDialog({
    required this.componente,
    required this.onSave,
  });

  @override
  State<_ComponenteDialog> createState() => _ComponenteDialogState();
}

class _ComponenteDialogState extends State<_ComponenteDialog> {
  late TextEditingController _tipoController;
  late TextEditingController _marcaController;
  late TextEditingController _modeloController;
  late TextEditingController _numeroSerieController;
  late TextEditingController _estadoController;

  @override
  void initState() {
    super.initState();
    _tipoController = TextEditingController(text: widget.componente['tipo_componente']?.toString() ?? '');
    _marcaController = TextEditingController(text: widget.componente['marca']?.toString() ?? '');
    _modeloController = TextEditingController(text: widget.componente['modelo']?.toString() ?? '');
    _numeroSerieController = TextEditingController(text: widget.componente['numero_serie']?.toString() ?? '');
    _estadoController = TextEditingController(text: widget.componente['estado']?.toString() ?? '');
  }

  @override
  void dispose() {
    _tipoController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _numeroSerieController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  void _guardar() {
    widget.onSave({
      ...widget.componente,
      'tipo_componente': _tipoController.text.trim(),
      'marca': _marcaController.text.trim(),
      'modelo': _modeloController.text.trim(),
      'numero_serie': _numeroSerieController.text.trim(),
      'estado': _estadoController.text.trim(),
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Componente'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _tipoController,
              decoration: InputDecoration(
                labelText: 'Tipo de Componente',
                prefixIcon: const Icon(Icons.extension, color: Color(0xFF003366)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _marcaController,
              decoration: InputDecoration(
                labelText: 'Marca',
                prefixIcon: const Icon(Icons.branding_watermark, color: Color(0xFF003366)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _modeloController,
              decoration: InputDecoration(
                labelText: 'Modelo',
                prefixIcon: const Icon(Icons.model_training, color: Color(0xFF003366)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _numeroSerieController,
              decoration: InputDecoration(
                labelText: 'Número de Serie',
                prefixIcon: const Icon(Icons.qr_code, color: Color(0xFF003366)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _estadoController,
              decoration: InputDecoration(
                labelText: 'Estado',
                prefixIcon: const Icon(Icons.check_circle_outline, color: Color(0xFF003366)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
                hintText: 'Ej: Bueno, Regular, Malo',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF003366),
            foregroundColor: Colors.white,
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

