import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../domain/entities/rutina.dart';

/// Widget de calendario interactivo
class CalendarWidget extends StatefulWidget {
  final Function(DateTime)? onDaySelected;
  final DateTime? selectedDay;
  final DateTime? focusedDay;
  final List<Rutina>? rutinas;
  final bool enableBlinkAnimation;

  const CalendarWidget({
    super.key,
    this.onDaySelected,
    this.selectedDay,
    this.focusedDay,
    this.rutinas,
    this.enableBlinkAnimation = false,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget>
    with TickerProviderStateMixin {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.focusedDay ?? DateTime.now();
    _selectedDay = widget.selectedDay ?? DateTime.now();
    
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    if (widget.enableBlinkAnimation) {
      // Esperar 10 segundos antes de iniciar la animación
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted) {
          _blinkController.repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  /// Obtiene la rutina para una fecha específica
  Rutina? _getRutinaForDate(DateTime date) {
    if (widget.rutinas == null) return null;
    
    for (var rutina in widget.rutinas!) {
      if (rutina.fechaEstimada != null &&
          isSameDay(rutina.fechaEstimada!, date)) {
        return rutina;
      }
    }
    return null;
  }

  /// Verifica si una fecha debe parpadear (desde hoy hasta la fecha de la rutina)
  bool _shouldBlink(DateTime date) {
    if (!widget.enableBlinkAnimation) return false;
    if (widget.rutinas == null) return false;
    
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final fecha = DateTime(date.year, date.month, date.day);
    
    // Verificar si esta fecha está entre hoy y alguna fecha de rutina
    for (var rutina in widget.rutinas!) {
      if (rutina.fechaEstimada != null) {
        final fechaRutina = DateTime(
          rutina.fechaEstimada!.year,
          rutina.fechaEstimada!.month,
          rutina.fechaEstimada!.day,
        );
        
        // Si la fecha está entre hoy y la fecha de la rutina (inclusive)
        if (fecha.isAfter(hoy.subtract(const Duration(days: 1))) &&
            (fecha.isBefore(fechaRutina.add(const Duration(days: 1))) ||
             isSameDay(fecha, fechaRutina))) {
          return true;
        }
      }
    }
    
    return false;
  }

  /// Obtiene todas las rutinas que afectan una fecha (para parpadeo)
  List<Rutina> _getRutinasForDateRange(DateTime date) {
    if (widget.rutinas == null) return [];
    
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final fecha = DateTime(date.year, date.month, date.day);
    
    return widget.rutinas!.where((rutina) {
      if (rutina.fechaEstimada == null) return false;
      
      final fechaRutina = DateTime(
        rutina.fechaEstimada!.year,
        rutina.fechaEstimada!.month,
        rutina.fechaEstimada!.day,
      );
      
      // Si la fecha está entre hoy y la fecha de la rutina (inclusive)
      return fecha.isAfter(hoy.subtract(const Duration(days: 1))) &&
             (fecha.isBefore(fechaRutina.add(const Duration(days: 1))) ||
              isSameDay(fecha, fechaRutina));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Calendario',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      onPressed: () {
                        setState(() {
                          _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                        });
                      },
                      tooltip: 'Mes anterior',
                    ),
                    Text(
                      DateFormat('MMMM yyyy', 'es_ES').format(_focusedDay),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      onPressed: () {
                        setState(() {
                          _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                        });
                      },
                      tooltip: 'Mes siguiente',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              calendarFormat: _calendarFormat,
              startingDayOfWeek: StartingDayOfWeek.monday,
              locale: 'es_ES',
              headerVisible: false,
              availableGestures: AvailableGestures.all,
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  widget.onDaySelected?.call(selectedDay);
                }
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
              ),
              eventLoader: (day) {
                final rutina = _getRutinaForDate(day);
                if (rutina != null) {
                  return [rutina]; // Retornar la rutina como evento
                }
                return [];
              },
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, date, focusedDay) {
                  final rutina = _getRutinaForDate(date);
                  final rutinasEnRango = _getRutinasForDateRange(date);
                  
                  // Si hay una rutina exacta en esta fecha, marcarla
                  if (rutina != null) {
                    final shouldBlink = _shouldBlink(date);
                    final color = rutina.colorEstado;
                    
                    Widget dayWidget = Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                    
                    if (shouldBlink) {
                      dayWidget = FadeTransition(
                        opacity: _blinkController,
                        child: dayWidget,
                      );
                    }
                    
                    return dayWidget;
                  }
                  
                  // Si la fecha está en el rango de parpadeo pero no es la fecha exacta
                  if (rutinasEnRango.isNotEmpty && _shouldBlink(date)) {
                    final primeraRutina = rutinasEnRango.first;
                    final color = primeraRutina.colorEstado;
                    
                    return FadeTransition(
                      opacity: _blinkController,
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  
                  return null;
                },
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                weekendStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Hoy: ${DateFormat('d \'de\' MMMM', 'es_ES').format(DateTime.now())}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



