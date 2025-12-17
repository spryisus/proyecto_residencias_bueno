import 'package:flutter/material.dart';
import '../../widgets/animated_card.dart';
import '../settings/settings_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Módulo de Reportes',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Ajustar el número de columnas según el ancho disponible
                  int crossAxisCount = 3;
                  if (constraints.maxWidth < 800) crossAxisCount = 2;
                  if (constraints.maxWidth < 600) crossAxisCount = 1;
                  
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.2, // Hacer las tarjetas menos altas
                    children: [
                      _buildReportCard(
                        context,
                        icon: Icons.inventory_2_outlined,
                        title: 'Reporte de Inventarios',
                        subtitle: 'Estado actual del inventario',
                        color: Colors.blue,
                        onTap: () => _showReportDialog(context, 'Inventarios'),
                      ),
                      _buildReportCard(
                        context,
                        icon: Icons.local_shipping_outlined,
                        title: 'Reporte de Envíos',
                        subtitle: 'Seguimiento de envíos',
                        color: Colors.green,
                        onTap: () => _showReportDialog(context, 'Envíos'),
                      ),
                      _buildReportCard(
                        context,
                        icon: Icons.people_outline,
                        title: 'Reporte de Usuarios',
                        subtitle: 'Actividad de usuarios',
                        color: Colors.orange,
                        onTap: () => _showReportDialog(context, 'Usuarios'),
                      ),
                      _buildReportCard(
                        context,
                        icon: Icons.trending_up_outlined,
                        title: 'Reporte de Estadísticas',
                        subtitle: 'Métricas generales',
                        color: Colors.purple,
                        onTap: () => _showReportDialog(context, 'Estadísticas'),
                      ),
                      _buildReportCard(
                        context,
                        icon: Icons.file_download_outlined,
                        title: 'Exportar Datos',
                        subtitle: 'Exportar a Excel/PDF',
                        color: Colors.red,
                        onTap: () => _showReportDialog(context, 'Exportar'),
                      ),
                      _buildReportCard(
                        context,
                        icon: Icons.schedule_outlined,
                        title: 'Reportes Programados',
                        subtitle: 'Configurar reportes automáticos',
                        color: Colors.teal,
                        onTap: () => _showReportDialog(context, 'Programados'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(
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

  void _showReportDialog(BuildContext context, String reportType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Reporte de $reportType',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 400, // Ancho fijo para escritorio
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '¿Qué tipo de reporte deseas generar?',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _generateReport(context, reportType, 'Vista Previa');
                    },
                    icon: const Icon(Icons.visibility, size: 20),
                    label: const Text('Vista Previa', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003366),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _generateReport(context, reportType, 'PDF');
                    },
                    icon: const Icon(Icons.picture_as_pdf, size: 20),
                    label: const Text('Exportar PDF', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _generateReport(context, reportType, 'Excel');
                    },
                    icon: const Icon(Icons.table_chart, size: 20),
                    label: const Text('Exportar Excel', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  void _generateReport(BuildContext context, String reportType, String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generando reporte de $reportType en formato $format...'),
        backgroundColor: const Color(0xFF003366),
        duration: const Duration(seconds: 2),
      ),
    );
    
    // Aquí iría la lógica real para generar el reporte
    // Por ahora solo mostramos un mensaje
  }

}
