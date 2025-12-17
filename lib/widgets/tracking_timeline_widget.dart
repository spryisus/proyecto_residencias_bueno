import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../domain/entities/tracking_event.dart';
import '../app/theme/app_theme.dart';

class TrackingTimelineWidget extends StatelessWidget {
  final List<TrackingEvent> events;
  final String currentStatus;

  const TrackingTimelineWidget({
    super.key,
    required this.events,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No hay eventos de seguimiento disponibles',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final isLast = index == events.length - 1;
        final isFirst = index == 0;

        return _TimelineItem(
          event: event,
          isLast: isLast,
          isFirst: isFirst,
          isActive: isFirst, // El evento más reciente está activo
        );
      },
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final TrackingEvent event;
  final bool isLast;
  final bool isFirst;
  final bool isActive;

  const _TimelineItem({
    required this.event,
    required this.isLast,
    required this.isFirst,
    required this.isActive,
  });

  Color _getStatusColor() {
    final description = event.description.toLowerCase();
    if (description.contains('entregado') || description.contains('delivered')) {
      return AppTheme.successGreen;
    } else if (description.contains('en tránsito') || description.contains('in transit')) {
      return AppTheme.warningOrange;
    } else if (description.contains('recolectado') || description.contains('picked up')) {
      return AppTheme.infoBlue;
    } else {
      return AppTheme.primaryBlue;
    }
  }

  IconData _getStatusIcon() {
    final description = event.description.toLowerCase();
    if (description.contains('entregado') || description.contains('delivered')) {
      return Icons.check_circle;
    } else if (description.contains('en tránsito') || description.contains('in transit')) {
      return Icons.local_shipping;
    } else if (description.contains('recolectado') || description.contains('picked up')) {
      return Icons.inventory;
    } else {
      return Icons.radio_button_checked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();
    
    // Hacer responsive el tamaño del punto según el tamaño de pantalla
    final isMobile = MediaQuery.of(context).size.width < 600;
    final pointSize = isMobile ? 20.0 : 24.0;
    final iconSize = isMobile ? 12.0 : 14.0;
    final spacing = isMobile ? 12.0 : 16.0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Línea vertical y punto
          Column(
            children: [
              // Punto del evento
              Container(
                width: pointSize,
                height: pointSize,
                decoration: BoxDecoration(
                  color: isActive ? statusColor : Colors.grey[300],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive ? statusColor : Colors.grey[400]!,
                    width: isMobile ? 2 : 3,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: statusColor.withOpacity(0.3),
                            blurRadius: isMobile ? 6 : 8,
                            spreadRadius: isMobile ? 1 : 2,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  statusIcon,
                  size: iconSize,
                  color: isActive ? Colors.white : Colors.grey[600],
                ),
              ),
              // Línea vertical
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: EdgeInsets.symmetric(vertical: isMobile ? 2 : 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: spacing),
          // Contenido del evento
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : (isMobile ? 16 : 24)),
              child: _EventCard(
                event: event,
                statusColor: statusColor,
                isActive: isActive,
                isMobile: isMobile,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final TrackingEvent event;
  final Color statusColor;
  final bool isActive;
  final bool isMobile;

  const _EventCard({
    required this.event,
    required this.statusColor,
    required this.isActive,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    final padding = isMobile ? 12.0 : 16.0;
    final fontSize = isMobile ? 14.0 : 16.0;
    final smallFontSize = isMobile ? 12.0 : 14.0;
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: isActive
            ? statusColor.withOpacity(0.1)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? statusColor.withOpacity(0.3) : Colors.grey[300]!,
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: statusColor.withOpacity(0.1),
                  blurRadius: isMobile ? 6 : 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estado
          Row(
            children: [
              Expanded(
                child: Text(
                  event.description,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    color: isActive ? statusColor : Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: isMobile ? 3 : null, // Mostrar más líneas en móvil
                  overflow: isMobile ? TextOverflow.visible : null,
                ),
              ),
              if (isActive) ...[
                SizedBox(width: isMobile ? 4 : 8),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 6 : 8,
                    vertical: isMobile ? 3 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'ACTUAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 9 : 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: isMobile ? 6 : 8),
          // Ubicación
          if (event.location != null && event.location!.isNotEmpty)
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: isMobile ? 14 : 16,
                  color: Colors.grey[600],
                ),
                SizedBox(width: isMobile ? 4 : 4),
                Expanded(
                  child: Text(
                    event.location!,
                    style: TextStyle(
                      fontSize: smallFontSize,
                      color: Colors.grey[700],
                    ),
                    maxLines: isMobile ? 3 : null, // Mostrar más líneas en móvil
                    overflow: isMobile ? TextOverflow.visible : null,
                  ),
                ),
              ],
            ),
          if (event.location != null && event.location!.isNotEmpty)
            SizedBox(height: isMobile ? 6 : 8),
          // Fecha y hora
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: isMobile ? 14 : 16,
                color: Colors.grey[600],
              ),
              SizedBox(width: isMobile ? 4 : 4),
              Flexible(
                child: Text(
                  '${dateFormat.format(event.timestamp)} - ${timeFormat.format(event.timestamp)}',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

