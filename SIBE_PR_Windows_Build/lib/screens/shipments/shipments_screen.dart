import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../widgets/animated_card.dart';
import '../settings/settings_screen.dart';
import 'bitacora_screen.dart';
import 'active_shipments_screen.dart';
import 'tresguerras_tracking_screen.dart';

class ShipmentsScreen extends StatelessWidget {
  const ShipmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Envíos',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Módulo de Envíos',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Gestiona y consulta información sobre envíos:',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  final crossAxisCount = isMobile ? 1 : 3;
                  final maxWidth = isMobile ? constraints.maxWidth : 900.0;
                  
                  return Center(
                    child: SizedBox(
                      width: maxWidth,
                      child: GridView.count(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: isMobile ? 1.2 : 1.0,
                        children: [
                          _buildEnvioOptionCard(
                            context,
                            icon: Icons.local_shipping,
                            title: 'Rastrear Envío',
                            subtitle: 'Consulta el estado de tus envíos',
                            color: Colors.blue,
                            onTap: () => _navigateToTrackShipment(context),
                          ),
                          _buildEnvioOptionCard(
                            context,
                            icon: Icons.book,
                            title: 'Bitácora',
                            subtitle: 'Registra y consulta bitácoras de envíos',
                            color: Colors.green,
                            onTap: () => _navigateToBitacora(context),
                          ),
                          _buildEnvioOptionCard(
                            context,
                            icon: Icons.inventory_2,
                            title: 'Envíos Activos',
                            subtitle: 'Gestiona envíos en curso',
                            color: Colors.orange,
                            onTap: () => _navigateToActiveShipments(context),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvioOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _navigateToTrackShipment(BuildContext context) {
    // Mostrar diálogo para ingresar número de tracking
    showDialog(
      context: context,
      builder: (context) => _TrackingDialog(),
    );
  }

  void _navigateToBitacora(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BitacoraScreen(),
      ),
    );
    // Los cambios se reflejarán automáticamente cuando se regrese al dashboard
  }

  void _navigateToActiveShipments(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ActiveShipmentsScreen(),
      ),
    );
    // Los cambios se reflejarán automáticamente cuando se regrese al dashboard
  }
}

// Enum para las paqueterías disponibles
enum Paqueteria {
  dhl,
  tresguerras,
}

// Diálogo para seleccionar paquetería y rastrear envío
class _TrackingDialog extends StatefulWidget {
  @override
  State<_TrackingDialog> createState() => _TrackingDialogState();
}

class _TrackingDialogState extends State<_TrackingDialog> {
  final TextEditingController _trackingController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Paqueteria? _paqueteriaSeleccionada;

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  String _getTrackingUrl(String trackingNumber, Paqueteria paqueteria) {
    switch (paqueteria) {
      case Paqueteria.dhl:
        return 'https://www.dhl.com/mx-es/home/tracking/tracking.html?submit=1&tracking-id=$trackingNumber';
      case Paqueteria.tresguerras:
        // URL oficial de tracking de 3guerras
        return 'https://www.tresguerras.com.mx/3G/tracking.php?guia=$trackingNumber';
    }
  }

  String _getPaqueteriaNombre(Paqueteria paqueteria) {
    switch (paqueteria) {
      case Paqueteria.dhl:
        return 'DHL';
      case Paqueteria.tresguerras:
        return '3guerras';
    }
  }

  Future<void> _openTracking() async {
    if (_paqueteriaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una paquetería'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final trackingNumber = _trackingController.text.trim();
    
    // Cerrar el diálogo primero
    if (mounted) {
      Navigator.pop(context);
    }

    // Para 3guerras, usar WebView con JavaScript inyectado
    if (_paqueteriaSeleccionada == Paqueteria.tresguerras) {
      // Solo usar WebView en móvil (Android/iOS)
      if (Platform.isAndroid || Platform.isIOS) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TresguerrasTrackingScreen(
              trackingNumber: trackingNumber,
            ),
          ),
        );
      } else {
        // En escritorio, abrir en navegador externo
        final url = Uri.parse(_getTrackingUrl(trackingNumber, _paqueteriaSeleccionada!));
        try {
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo abrir el navegador'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Para DHL, usar url_launcher normalmente
      final url = Uri.parse(_getTrackingUrl(trackingNumber, _paqueteriaSeleccionada!));
      try {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir el navegador'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rastrear Envío'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selecciona la paquetería:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              // Opción DHL
              InkWell(
                onTap: () {
                  setState(() {
                    _paqueteriaSeleccionada = Paqueteria.dhl;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _paqueteriaSeleccionada == Paqueteria.dhl
                          ? const Color(0xFF003366)
                          : Colors.grey[300]!,
                      width: _paqueteriaSeleccionada == Paqueteria.dhl ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _paqueteriaSeleccionada == Paqueteria.dhl
                        ? const Color(0xFF003366).withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _paqueteriaSeleccionada == Paqueteria.dhl
                              ? Colors.yellow[700]!.withOpacity(0.2)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.local_shipping,
                          color: _paqueteriaSeleccionada == Paqueteria.dhl
                              ? Colors.yellow[700]
                              : Colors.grey[600],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'DHL',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_paqueteriaSeleccionada == Paqueteria.dhl)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF003366),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Opción 3guerras
              InkWell(
                onTap: () {
                  setState(() {
                    _paqueteriaSeleccionada = Paqueteria.tresguerras;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _paqueteriaSeleccionada == Paqueteria.tresguerras
                          ? const Color(0xFF003366)
                          : Colors.grey[300]!,
                      width: _paqueteriaSeleccionada == Paqueteria.tresguerras ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _paqueteriaSeleccionada == Paqueteria.tresguerras
                        ? const Color(0xFF003366).withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _paqueteriaSeleccionada == Paqueteria.tresguerras
                              ? Colors.orange[700]!.withOpacity(0.2)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.inventory_2,
                          color: _paqueteriaSeleccionada == Paqueteria.tresguerras
                              ? Colors.orange[700]
                              : Colors.grey[600],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '3guerras',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_paqueteriaSeleccionada == Paqueteria.tresguerras)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF003366),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Número de seguimiento:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _trackingController,
                decoration: InputDecoration(
                  labelText: 'Número de Guía',
                  hintText: _paqueteriaSeleccionada == null
                      ? 'Ej: 1234567890'
                      : _paqueteriaSeleccionada == Paqueteria.dhl
                          ? 'Ej: 1234567890'
                          : 'Ej: 3G123456789',
                  prefixIcon: const Icon(Icons.qr_code_scanner),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa un número de seguimiento';
                  }
                  return null;
                },
                autofocus: false,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _openTracking(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _openTracking,
          icon: const Icon(Icons.open_in_browser),
          label: Text(
            _paqueteriaSeleccionada == null
                ? 'Abrir'
                : 'Abrir en ${_getPaqueteriaNombre(_paqueteriaSeleccionada!)}',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF003366),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
