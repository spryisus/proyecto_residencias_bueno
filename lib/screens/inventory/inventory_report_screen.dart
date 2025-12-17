import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'qr_scanner_screen.dart';

class InventoryReportScreen extends StatelessWidget {
  final String category;
  
  const InventoryReportScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reporte - $category'),
        centerTitle: true,
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getCategoryIcon(category),
                  size: 32,
                  color: _getCategoryColor(category),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inventario de $category',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003366),
                        ),
                      ),
                      Text(
                        'Consulta y reportes del inventario actual',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Botón de escaneo QR solo en dispositivos móviles
            if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS))
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const QRScannerScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner, size: 20),
                  label: Text(
                    'Escanear QR - $category',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getCategoryColor(category),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 2;
                  if (constraints.maxWidth < 600) crossAxisCount = 1;
                  
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.3,
                    children: [
                      _buildReportOptionCard(
                        context,
                        icon: Icons.visibility,
                        title: 'Vista General',
                        subtitle: 'Ver inventario completo',
                        color: Colors.blue,
                        onTap: () => _showInventoryData(context, 'Vista General'),
                      ),
                      _buildReportOptionCard(
                        context,
                        icon: Icons.search,
                        title: 'Buscar Items',
                        subtitle: 'Buscar elementos específicos',
                        color: Colors.green,
                        onTap: () => _showInventoryData(context, 'Buscar Items'),
                      ),
                      _buildReportOptionCard(
                        context,
                        icon: Icons.analytics,
                        title: 'Estadísticas',
                        subtitle: 'Métricas y análisis',
                        color: Colors.orange,
                        onTap: () => _showInventoryData(context, 'Estadísticas'),
                      ),
                      _buildReportOptionCard(
                        context,
                        icon: Icons.file_download,
                        title: 'Exportar',
                        subtitle: 'Descargar reporte',
                        color: Colors.purple,
                        onTap: () => _showInventoryData(context, 'Exportar'),
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

  Widget _buildReportOptionCard(
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Jumpers':
        return Icons.cable;
      case 'Computadoras':
        return Icons.computer;
      case 'Tarjetas':
        return Icons.memory;
      case 'Equipos de Red':
        return Icons.router;
      case 'Telefonía':
        return Icons.phone;
      case 'Energía':
        return Icons.power;
      case 'Almacenamiento':
        return Icons.storage;
      case 'Seguridad':
        return Icons.security;
      case 'Herramientas':
        return Icons.build;
      default:
        return Icons.inventory_2;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Jumpers':
        return Colors.blue;
      case 'Computadoras':
        return Colors.green;
      case 'Tarjetas':
        return Colors.orange;
      case 'Equipos de Red':
        return Colors.purple;
      case 'Telefonía':
        return Colors.teal;
      case 'Energía':
        return Colors.red;
      case 'Almacenamiento':
        return Colors.indigo;
      case 'Seguridad':
        return Colors.brown;
      case 'Herramientas':
        return Colors.grey;
      default:
        return const Color(0xFF003366);
    }
  }

  void _showInventoryData(BuildContext context, String option) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '$option - $category',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getCategoryIcon(category),
                  size: 64,
                  color: _getCategoryColor(category),
                ),
                const SizedBox(height: 16),
                Text(
                  'Categoría: $category',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Opción seleccionada: $option',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Esta funcionalidad estará disponible próximamente. Aquí se mostrarán los datos específicos del inventario seleccionado.',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cerrar',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }
}
