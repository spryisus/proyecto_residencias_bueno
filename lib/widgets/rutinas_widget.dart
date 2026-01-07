import 'package:flutter/material.dart';
import '../domain/entities/rutina.dart';
import '../data/local/rutina_storage.dart';
import 'package:intl/intl.dart';

/// Widget para mostrar y gestionar las rutinas
class RutinasWidget extends StatefulWidget {
  final Function(List<Rutina>)? onRutinasChanged;
  
  const RutinasWidget({super.key, this.onRutinasChanged});

  @override
  State<RutinasWidget> createState() => _RutinasWidgetState();
}

class _RutinasWidgetState extends State<RutinasWidget> {
  final RutinaStorage _storage = RutinaStorage();
  List<Rutina> _rutinas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRutinas();
  }

  Future<void> _loadRutinas() async {
    setState(() {
      _isLoading = true;
    });
    
    final rutinas = await _storage.getAllRutinas();
    
    if (mounted) {
      setState(() {
        _rutinas = rutinas;
        _isLoading = false;
      });
      // Notificar cambios
      widget.onRutinasChanged?.call(rutinas);
    }
  }

  Future<void> _updateRutinaFecha(Rutina rutina, DateTime? fecha) async {
    final rutinaActualizada = rutina.copyWith(fechaEstimada: fecha);
    await _storage.updateRutina(rutinaActualizada);
    await _loadRutinas();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.task_alt,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Rutinas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._rutinas.map((rutina) => _buildRutinaItem(rutina)),
          ],
        ),
      ),
    );
  }

  Widget _buildRutinaItem(Rutina rutina) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          // Indicador de color
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: rutina.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          // Nombre de la rutina
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rutina.nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rutina.fechaEstimada != null
                      ? 'Fecha: ${DateFormat('dd/MM/yyyy').format(rutina.fechaEstimada!)}'
                      : 'Sin fecha asignada',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Botón para seleccionar fecha
          IconButton(
            icon: const Icon(Icons.calendar_today, size: 18),
            onPressed: () async {
              final fecha = await showDatePicker(
                context: context,
                initialDate: rutina.fechaEstimada ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                locale: const Locale('es', 'ES'),
              );
              
              if (fecha != null) {
                await _updateRutinaFecha(rutina, fecha);
              }
            },
            tooltip: 'Asignar fecha',
          ),
        ],
      ),
    );
  }
}

