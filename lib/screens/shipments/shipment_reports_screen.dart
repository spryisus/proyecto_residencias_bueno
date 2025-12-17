import 'package:flutter/material.dart';

class ShipmentReportsScreen extends StatelessWidget {
  const ShipmentReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes de Envíos'),
        centerTitle: true,
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reportes y Estadísticas de Envíos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Genera reportes detallados sobre el estado de los envíos:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 3;
                  if (constraints.maxWidth < 800) crossAxisCount = 2;
                  if (constraints.maxWidth < 600) crossAxisCount = 1;
                  
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.1,
                    children: [
                      _buildReportCard(
                        context,
                        icon: Icons.timeline,
                        title: 'Estado de Envíos',
                        subtitle: 'Resumen por estado actual',
                        color: Colors.blue,
                        onTap: () => _showReportDialog(context, 'Estado de Envíos'),
                      ),
                      _buildReportCard(
                        context,
                        icon: Icons.location_on,
                        title: 'Envíos por Ubicación',
                        subtitle: 'Distribución geográfica',
                        color: Colors.green,
                        onTap: () => _showReportDialog(context, 'Envíos por Ubicación'),
                      ),
                      _buildReportCard(
                        context,
                        icon: Icons.schedule,
                        title: 'Tiempos de Entrega',
                        subtitle: 'Análisis de tiempos promedio',
                        color: Colors.orange,
                        onTap: () => _showReportDialog(context, 'Tiempos de Entrega'),
                      ),
                      _buildReportCard(
                        context,
                        icon: Icons.trending_up,
                        title: 'Tendencias',
                        subtitle: 'Análisis de tendencias mensuales',
                        color: Colors.purple,
                        onTap: () => _showReportDialog(context, 'Tendencias'),
                      ),
                      _buildReportCard(
                        context,
                        icon: Icons.warning,
                        title: 'Envíos Retrasados',
                        subtitle: 'Lista de envíos con retrasos',
                        color: Colors.red,
                        onTap: () => _showReportDialog(context, 'Envíos Retrasados'),
                      ),
                      _buildReportCard(
                        context,
                        icon: Icons.file_download,
                        title: 'Exportar Datos',
                        subtitle: 'Descargar reportes en Excel/PDF',
                        color: Colors.teal,
                        onTap: () => _showReportDialog(context, 'Exportar Datos'),
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
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003366),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context, String reportType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Reporte: $reportType',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getReportIcon(reportType),
                  size: 64,
                  color: _getReportColor(reportType),
                ),
                const SizedBox(height: 16),
                Text(
                  'Generando reporte de $reportType',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Esta funcionalidad estará disponible próximamente. Aquí se mostrarán los datos específicos del reporte seleccionado.',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildSampleData(reportType),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _generateReport(context, reportType);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003366),
                foregroundColor: Colors.white,
              ),
              child: const Text('Generar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSampleData(String reportType) {
    switch (reportType) {
      case 'Estado de Envíos':
        return Column(
          children: [
            _buildDataRow('En tránsito', '45', Colors.blue),
            _buildDataRow('Entregado', '32', Colors.green),
            _buildDataRow('Retrasado', '8', Colors.red),
            _buildDataRow('Pendiente', '15', Colors.orange),
          ],
        );
      case 'Envíos por Ubicación':
        return Column(
          children: [
            _buildDataRow('CDMX', '28', Colors.blue),
            _buildDataRow('Guadalajara', '22', Colors.green),
            _buildDataRow('Monterrey', '18', Colors.orange),
            _buildDataRow('Puebla', '12', Colors.purple),
          ],
        );
      default:
        return const Text('Datos de muestra disponibles próximamente');
    }
  }

  Widget _buildDataRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getReportIcon(String reportType) {
    switch (reportType) {
      case 'Estado de Envíos':
        return Icons.timeline;
      case 'Envíos por Ubicación':
        return Icons.location_on;
      case 'Tiempos de Entrega':
        return Icons.schedule;
      case 'Tendencias':
        return Icons.trending_up;
      case 'Envíos Retrasados':
        return Icons.warning;
      case 'Exportar Datos':
        return Icons.file_download;
      default:
        return Icons.assessment;
    }
  }

  Color _getReportColor(String reportType) {
    switch (reportType) {
      case 'Estado de Envíos':
        return Colors.blue;
      case 'Envíos por Ubicación':
        return Colors.green;
      case 'Tiempos de Entrega':
        return Colors.orange;
      case 'Tendencias':
        return Colors.purple;
      case 'Envíos Retrasados':
        return Colors.red;
      case 'Exportar Datos':
        return Colors.teal;
      default:
        return const Color(0xFF003366);
    }
  }

  void _generateReport(BuildContext context, String reportType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generando reporte de $reportType...'),
        backgroundColor: const Color(0xFF003366),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
