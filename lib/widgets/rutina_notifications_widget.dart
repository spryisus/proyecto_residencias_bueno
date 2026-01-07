import 'package:flutter/material.dart';
import '../domain/entities/rutina.dart';
import '../data/local/rutina_storage.dart';

/// Widget para mostrar avisos de rutinas con animación de parpadeo
class RutinaNotificationsWidget extends StatefulWidget {
  const RutinaNotificationsWidget({super.key});

  @override
  State<RutinaNotificationsWidget> createState() => _RutinaNotificationsWidgetState();
}

class _RutinaNotificationsWidgetState extends State<RutinaNotificationsWidget>
    with TickerProviderStateMixin {
  final RutinaStorage _storage = RutinaStorage();
  List<Rutina> _rutinas = [];
  bool _showNotifications = false;
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _loadRutinas();
    
    // Esperar 10 segundos antes de mostrar las notificaciones
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _showNotifications = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  Future<void> _loadRutinas() async {
    final rutinas = await _storage.getAllRutinas();
    
    if (mounted) {
      setState(() {
        _rutinas = rutinas.where((r) => r.fechaEstimada != null).toList();
      });
    }
    
    // Recargar cada minuto para actualizar los avisos
    Future.delayed(const Duration(minutes: 1), () {
      if (mounted) {
        _loadRutinas();
      }
    });
  }

  List<Rutina> _getRutinasConAvisos() {
    return _rutinas.where((rutina) {
      final dias = rutina.diasRestantes;
      return dias != null && dias >= 0;
    }).toList();
  }

  String _getMensajeAviso(Rutina rutina) {
    final dias = rutina.diasRestantes!;
    
    if (dias == 0 || dias == 1) {
      return 'Realizar ${rutina.nombre}';
    } else if (dias < 3) {
      return 'Faltan $dias días para ${rutina.nombre}';
    } else {
      return 'Faltan $dias días para ${rutina.nombre}';
    }
  }

  Color _getColorAviso(Rutina rutina) {
    return rutina.colorEstado;
  }

  @override
  Widget build(BuildContext context) {
    if (!_showNotifications) {
      return const SizedBox.shrink();
    }

    final rutinasConAvisos = _getRutinasConAvisos();
    
    if (rutinasConAvisos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: rutinasConAvisos.map((rutina) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: FadeTransition(
              opacity: _blinkController,
              child: _buildNotificationCard(rutina),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotificationCard(Rutina rutina) {
    final color = _getColorAviso(rutina);
    final mensaje = _getMensajeAviso(rutina);

    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            rutina.estado == EstadoRutina.urgente
                ? Icons.warning
                : Icons.notifications_active,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              mensaje,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

