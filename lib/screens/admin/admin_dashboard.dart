import 'package:flutter/material.dart';
import '../../core/di/injection_container.dart';
import '../../data/local/inventory_session_storage.dart';
import '../../domain/entities/inventory_session.dart';
import '../settings/settings_screen.dart';
import 'reports_screen.dart';
import '../auth/login_screen.dart';
import '../inventory/inventory_screen.dart';
import '../shipments/shipments_screen.dart';
import '../sdr/solicitud_sdr_screen.dart';
import '../../widgets/clock_widget.dart';
import '../../widgets/calendar_widget.dart';
import '../../widgets/quick_stats_widget.dart';
import 'users_management_screen.dart';

class AdminDashboard extends StatefulWidget {
  final String? username;
  const AdminDashboard({super.key, this.username});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final InventorySessionStorage _sessionStorage = serviceLocator.get<InventorySessionStorage>();
  List<InventorySession> _sessions = [];
  List<InventorySession> _allSessions = [];
  bool _isLoadingSessions = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessions = await _sessionStorage.getAllSessions();
    _allSessions = sessions;
    // Filtrar solo inventarios pendientes
    final pendingSessions = sessions.where((s) => s.status == InventorySessionStatus.pending).toList();
    if (!mounted) return;
    setState(() {
      _sessions = pendingSessions;
      _isLoadingSessions = false;
    });
  }

  void _openSession(InventorySession session) {
    showDialog(
      context: context,
      builder: (context) => _SessionDetailDialog(
        session: session,
        formatDate: _formatDate,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.username;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoadingSessions ? null : () async {
              await _loadSessions();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Datos actualizados'),
                  duration: Duration(seconds: 1),
                  backgroundColor: Colors.green,
                ),
              );
            },
            tooltip: 'Refrescar',
          ),
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (username != null && username.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.person, 
                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7), 
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            username,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined, size: 24),
              title: Text(
                'Inventario',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              minVerticalPadding: 16,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InventoryScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping_outlined, size: 24),
              title: Text(
                'Envíos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              minVerticalPadding: 16,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ShipmentsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add_outlined, size: 24),
              title: Text(
                'Gestión de usuarios',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              minVerticalPadding: 16,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UsersManagementScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics_outlined, size: 24),
              title: Text(
                'Actividad de usuarios',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              minVerticalPadding: 16,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserActivityPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assessment_outlined, size: 24),
              title: Text(
                'Reportes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              minVerticalPadding: 16,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined, size: 24),
              title: Text(
                'Solicitud SDR',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              minVerticalPadding: 16,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SolicitudSdrScreen()),
                );
              },
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.logout, size: 24),
              title: Text(
                'Cerrar sesión',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              minVerticalPadding: 16,
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard de Administrador',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Widgets en grid responsive
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWideScreen = constraints.maxWidth > 900;
                  
                  if (isWideScreen) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              const ClockWidget(),
                              const SizedBox(height: 16),
                              const QuickStatsWidget(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: const CalendarWidget(),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        const ClockWidget(),
                        const SizedBox(height: 16),
                        const CalendarWidget(),
                        const SizedBox(height: 16),
                        const QuickStatsWidget(),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
              _buildSessionSection(),
              const SizedBox(height: 24),
              Text(
                'Accesos Rápidos',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive: Ajustar columnas según el tamaño de pantalla
                  int crossAxisCount = 2;
                  double childAspectRatio = 1.2;
                  
                  if (constraints.maxWidth < 600) {
                    // Móvil: 1 columna
                    crossAxisCount = 1;
                    childAspectRatio = 2.5;
                  } else if (constraints.maxWidth < 900) {
                    // Tablet: 2 columnas
                    crossAxisCount = 2;
                    childAspectRatio = 1.3;
                  } else {
                    // Desktop: 4 columnas
                    crossAxisCount = 4;
                    childAspectRatio = 1.1;
                  }
                  
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: childAspectRatio,
                    children: [
                  _buildStatCard(
                    context,
                    'Inventario',
                    'Gestionar productos y stock',
                    Icons.inventory_2_outlined,
                    Colors.blue,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const InventoryScreen()),
                      );
                    },
                  ),
                  _buildStatCard(
                    context,
                    'Envíos',
                    'Rastrear envíos',
                    Icons.local_shipping_outlined,
                    Colors.green,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ShipmentsScreen()),
                      );
                    },
                  ),
                  _buildStatCard(
                    context,
                    'Reportes',
                    'Generar reportes',
                    Icons.assessment_outlined,
                    Colors.orange,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReportsScreen()),
                      );
                    },
                  ),
                  _buildStatCard(
                    context,
                    'Usuarios',
                    'Gestionar empleados',
                    Icons.group_outlined,
                    Colors.purple,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UsersManagementScreen()),
                      );
                    },
                    ),
                  ],
                );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 12,
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

  Widget _buildSessionSection() {
    if (_isLoadingSessions) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_sessions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inventarios guardados',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        ..._sessions.map(_buildSessionCard),
      ],
    );
  }

  Widget _buildSessionCard(InventorySession session) {
    final isPending = session.status == InventorySessionStatus.pending;
    final Color chipColor = isPending ? Colors.orange : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _openSession(session),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: chipColor.withValues(alpha: 0.15),
                child: Icon(
                  isPending ? Icons.pause_circle_outline : Icons.check_circle_outline,
                  color: chipColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      session.categoryName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Actualizado: ${_formatDate(session.updatedAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isPending && session.ownerEmail != null && session.ownerEmail!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              session.ownerEmail!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isPending ? 'Pendiente' : 'Terminado',
                  style: TextStyle(
                    color: chipColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _SessionDetailDialog extends StatelessWidget {
  final InventorySession session;
  final String Function(DateTime) formatDate;

  const _SessionDetailDialog({
    required this.session,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Detalles del inventario'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Categoría', session.categoryName, context),
            const SizedBox(height: 8),
            _buildInfoRow('Estado', session.status == InventorySessionStatus.pending ? 'Pendiente' : 'Terminado', context),
            const SizedBox(height: 8),
            _buildInfoRow('Última actualización', formatDate(session.updatedAt), context),
            const SizedBox(height: 8),
            if (session.ownerEmail != null && session.ownerEmail!.isNotEmpty)
              _buildInfoRow('Empleado', session.ownerEmail!, context),
            if (session.ownerName != null && session.ownerName != session.ownerEmail)
              _buildInfoRow('Responsable', session.ownerName!, context),
            const SizedBox(height: 16),
            Text(
              'Productos capturados (${session.quantities.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView(
                children: session.quantities.entries.map((entry) {
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('Producto ID #${entry.key}'),
                    trailing: Text(
                      '${entry.value}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class UserActivityPage extends StatelessWidget {
  const UserActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actividad de usuarios'),
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
      body: Center(
        child: Text(
          'Métricas/actividad de usuarios (pendiente)',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
