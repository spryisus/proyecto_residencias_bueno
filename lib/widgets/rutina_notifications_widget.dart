import 'package:flutter/material.dart';
import '../domain/entities/rutina.dart';

/// Widget para mostrar avisos de rutinas sincronizados con el calendario
class RutinaNotificationsWidget extends StatefulWidget {
  final Rutina? rutinaEnAnimacion; // Rutina que está siendo animada en el calendario

  const RutinaNotificationsWidget({
    super.key,
    this.rutinaEnAnimacion,
  });

  @override
  State<RutinaNotificationsWidget> createState() => _RutinaNotificationsWidgetState();
}

class _RutinaNotificationsWidgetState extends State<RutinaNotificationsWidget> {
  @override
  Widget build(BuildContext context) {
    // Solo mostrar notificación si hay una rutina en animación
    if (widget.rutinaEnAnimacion == null) {
      return const SizedBox.shrink();
    }
    
    final rutina = widget.rutinaEnAnimacion!;
    
    // Verificar que la rutina tenga fecha y días restantes válidos
    final dias = rutina.diasRestantes;
    if (dias == null || dias < 0) {
      return const SizedBox.shrink();
    }
    
    return Positioned(
      bottom: 16,
      right: 16,
      child: _buildNotificationCard(rutina),
    );
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
