import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget que muestra la hora actual en tiempo real
class ClockWidget extends StatefulWidget {
  final bool showDate;
  final TextStyle? timeStyle;
  final TextStyle? dateStyle;

  const ClockWidget({
    super.key,
    this.showDate = true,
    this.timeStyle,
    this.dateStyle,
  });

  @override
  State<ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
  DateTime _currentTime = DateTime.now();
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _currentTime = DateTime.now();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm:ss');
    final dateFormat = DateFormat('EEEE, d \'de\' MMMM \'de\' yyyy', 'es_ES');
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  timeFormat.format(_currentTime),
                  style: widget.timeStyle ??
                      Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                ),
              ],
            ),
            if (widget.showDate) ...[
              const SizedBox(height: 8),
              Text(
                dateFormat.format(_currentTime),
                style: widget.dateStyle ??
                    Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

