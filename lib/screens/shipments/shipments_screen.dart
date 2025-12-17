import 'package:flutter/material.dart';
import '../../widgets/animated_card.dart';
import '../settings/settings_screen.dart';
import 'track_shipment_screen.dart';
import 'shipment_reports_screen.dart';

class ShipmentsScreen extends StatelessWidget {
  const ShipmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Envíos'),
        centerTitle: true,
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
                  if (constraints.maxWidth < 600) {
                    // Una columna en pantallas pequeñas (centrada)
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _buildEnvioOptionCard(
                            context,
                            icon: Icons.local_shipping,
                            title: 'Rastrear Envío',
                            subtitle: 'Consulta el estado de tus envíos',
                            color: Colors.blue,
                            onTap: () => _navigateToTrackShipment(context),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: _buildEnvioOptionCard(
                            context,
                            icon: Icons.assessment,
                            title: 'Reportes de Envíos',
                            subtitle: 'Genera reportes y estadísticas',
                            color: Colors.green,
                            onTap: () => _navigateToShipmentReports(context),
                          ),
                        ),
                      ],
                    );
                  } else {
                    // Dos columnas centradas en pantallas medianas y grandes
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 1,
                          child: _buildEnvioOptionCard(
                            context,
                            icon: Icons.local_shipping,
                            title: 'Rastrear Envío',
                            subtitle: 'Consulta el estado de tus envíos',
                            color: Colors.blue,
                            onTap: () => _navigateToTrackShipment(context),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 1,
                          child: _buildEnvioOptionCard(
                            context,
                            icon: Icons.assessment,
                            title: 'Reportes de Envíos',
                            subtitle: 'Genera reportes y estadísticas',
                            color: Colors.green,
                            onTap: () => _navigateToShipmentReports(context),
                          ),
                        ),
                      ],
                    );
                  }
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TrackShipmentScreen(),
      ),
    );
  }

  void _navigateToShipmentReports(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ShipmentReportsScreen(),
      ),
    );
  }
}
