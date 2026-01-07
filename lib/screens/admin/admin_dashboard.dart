import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/di/injection_container.dart';
import '../../data/local/inventory_session_storage.dart';
import '../../domain/entities/inventory_session.dart';
import '../../domain/repositories/inventario_repository.dart';
import '../settings/settings_screen.dart';
import '../auth/login_screen.dart';
import '../inventory/inventory_screen.dart';
import '../inventory/inventory_type_selection_screen.dart';
import '../inventory/completed_inventories_screen.dart';
import '../shipments/shipments_screen.dart';
import '../shipments/active_shipments_screen.dart';
import '../sdr/solicitud_sdr_screen.dart';
import '../../widgets/calendar_widget.dart';
import '../../widgets/rutinas_widget.dart';
import '../../widgets/rutina_notifications_widget.dart';
import '../../app/config/supabase_client.dart' show supabaseClient;
import '../../domain/entities/rutina.dart';
import '../../data/local/rutina_storage.dart';
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
  String? _userName;
  String? _userRole;
  int _selectedIndex = 0; // Para el sidebar
  int _totalInventarios = 0;
  int _pendingInventarios = 0;
  int _activeShipments = 0;
  int _activeUsers = 0;
  bool _isLoadingStats = true;
  final RutinaStorage _rutinaStorage = RutinaStorage();
  List<Rutina> _rutinas = [];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadSessions();
    _loadStats();
    _loadRutinas();
  }

  Future<void> _loadRutinas() async {
    final rutinas = await _rutinaStorage.getAllRutinas();
    if (mounted) {
      setState(() {
        _rutinas = rutinas;
      });
    }
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('nombre_usuario');
    
    // Obtener rol del usuario
    String? userRole = 'Usuario';
    try {
      final idEmpleado = prefs.getString('id_empleado');
      if (idEmpleado != null) {
        final roles = await supabaseClient
            .from('t_empleado_rol')
            .select('t_roles!inner(nombre)')
            .eq('id_empleado', idEmpleado);
        
        if (roles.isNotEmpty) {
          final roleName = roles.first['t_roles']['nombre']?.toString().toLowerCase();
          if (roleName == 'admin') {
            userRole = 'Administrador';
          } else if (roleName == 'operador') {
            userRole = 'Operador';
          } else if (roleName == 'auditor') {
            userRole = 'Auditor';
          }
        }
      }
    } catch (e) {
      debugPrint('Error al cargar rol: $e');
    }
    
    if (mounted) {
      setState(() {
        _userName = userName ?? 'Usuario';
        _userRole = userRole;
      });
    }
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      // Contar inventarios totales desde sesiones
      final allSessions = await _sessionStorage.getAllSessions();
      final totalInventarios = allSessions.length;
      final pendingInventarios = allSessions.where((s) => s.status == InventorySessionStatus.pending).length;

      // Contar envíos activos (solo ENVIADO y EN_TRANSITO, agrupados por código)
      try {
        final bitacoras = await supabaseClient
            .from('t_bitacora_envios')
            .select('codigo, estado')
            .inFilter('estado', ['ENVIADO', 'EN_TRANSITO']);
        
        // Agrupar por código para contar envíos únicos activos
        final codigosActivos = <String>{};
        for (final bitacora in bitacoras) {
          final codigo = bitacora['codigo'] as String?;
          if (codigo != null && codigo.isNotEmpty) {
            codigosActivos.add(codigo);
          }
        }
        _activeShipments = codigosActivos.length;
      } catch (e) {
        debugPrint('Error al contar envíos activos: $e');
        _activeShipments = 0;
      }

      // Contar usuarios activos
      try {
        final usuarios = await supabaseClient
            .from('t_empleados')
            .select('id_empleado')
            .eq('activo', true);
        _activeUsers = usuarios.length;
      } catch (e) {
        debugPrint('Error al contar usuarios: $e');
        _activeUsers = 0;
      }

      if (mounted) {
        setState(() {
          _totalInventarios = totalInventarios;
          _pendingInventarios = pendingInventarios;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar estadísticas: $e');
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _loadSessions() async {
    final sessions = await _sessionStorage.getAllSessions();
    // Filtrar solo inventarios pendientes
    final pendingSessions = sessions.where((s) => s.status == InventorySessionStatus.pending).toList();
    if (!mounted) return;
    setState(() {
      _sessions = pendingSessions;
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
    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              // Sidebar permanente
              _buildSidebar(context),
              // Contenido principal
              Expanded(
                child: Column(
                  children: [
                    // Header superior
                    _buildHeader(context),
                    // Contenido scrollable
                    Expanded(
                      child: _buildMainContent(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Widget de notificaciones de rutinas (parte inferior derecha)
          const RutinaNotificationsWidget(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          // Logo y título
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF003366),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Gestor de Refacciones y Envios',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003366),
                    ),
                  ),
                  Text(
                    'Sistema de Larga Distancia',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Iconos de acción
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            tooltip: 'Configuración',
          ),
          const SizedBox(width: 12),
          // Avatar y usuario
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF003366),
                child: Text(
                  _userName?.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _userName ?? 'Usuario',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _userRole ?? 'Usuario',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Sección PRINCIPAL
          _buildSidebarSection(
            context,
            'PRINCIPAL',
            [
              _buildSidebarItem(
                context,
                icon: Icons.home_outlined,
                title: 'Dashboard',
                isSelected: _selectedIndex == 0,
                onTap: () => setState(() => _selectedIndex = 0),
              ),
              _buildSidebarItem(
                context,
                icon: Icons.inventory_2_outlined,
                title: 'Inventarios',
                badge: _pendingInventarios > 0 ? _pendingInventarios.toString() : null,
                badgeColor: Colors.orange,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InventoryScreen()),
                  );
                  // Refrescar estadísticas al regresar
                  if (mounted) {
                    _loadStats();
                    _loadSessions();
                  }
                },
              ),
              _buildSidebarItem(
                context,
                icon: Icons.local_shipping_outlined,
                title: 'Envíos',
                badge: _activeShipments > 0 ? _activeShipments.toString() : null,
                badgeColor: Colors.orange,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ShipmentsScreen()),
                  );
                  // Refrescar estadísticas al regresar
                  if (mounted) {
                    _loadStats();
                  }
                },
              ),
              _buildSidebarItem(
                context,
                icon: Icons.description_outlined,
                title: 'Solicitudes SDR',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SolicitudSdrScreen()),
                  );
                },
              ),
            ],
          ),
          // Sección GESTIÓN
          _buildSidebarSection(
            context,
            'GESTIÓN',
            [
              _buildSidebarItem(
                context,
                icon: Icons.group_outlined,
                title: 'Usuarios',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UsersManagementScreen()),
                  );
                },
              ),
            ],
          ),
          // Sección SESIONES GUARDADAS
          if (_sessions.isNotEmpty)
            _buildSidebarSection(
              context,
              'SESIONES GUARDADAS',
              _sessions.take(2).map((session) {
                final isPending = session.status == InventorySessionStatus.pending;
                return _buildSidebarItem(
                  context,
                  icon: isPending ? Icons.pause_circle_outline : Icons.check_circle_outline,
                  title: session.categoryName,
                  subtitle: _formatTimeAgo(session.updatedAt),
                  iconColor: isPending ? Colors.orange : Colors.green,
                  onTap: () => _openSession(session),
                );
              }).toList(),
            ),
          const Spacer(),
          // Cerrar Sesión
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildSidebarItem(
              context,
              icon: Icons.logout,
              title: 'Cerrar Sesión',
              iconColor: Colors.red,
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSidebarItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    String? badge,
    Color? badgeColor,
    Color? iconColor,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF003366).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: const Color(0xFF003366), width: 1)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? const Color(0xFF003366)
                  : iconColor ?? Colors.grey[700],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? const Color(0xFF003366) : Colors.grey[800],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor ?? Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return 'Actualizado hace ${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return 'Actualizado hace ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'Actualizado hace ${difference.inMinutes}m';
    } else {
      return 'Actualizado ahora';
    }
  }

  Widget _buildMainContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mensaje de bienvenida
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenido 👋',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Panel de administración - Sistema de Larga Distancia',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Tarjetas de estadísticas
          _buildStatsCards(context),
          const SizedBox(height: 32),
          // Widgets en grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWideScreen = constraints.maxWidth > 900;
              
              if (isWideScreen) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          _buildEnhancedClockWidget(),
                          const SizedBox(height: 16),
                          RutinasWidget(
                            onRutinasChanged: (rutinas) {
                              setState(() {
                                _rutinas = rutinas;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: CalendarWidget(
                        rutinas: _rutinas,
                        enableBlinkAnimation: true,
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildEnhancedClockWidget(),
                    const SizedBox(height: 16),
                    RutinasWidget(
                      onRutinasChanged: (rutinas) {
                        setState(() {
                          _rutinas = rutinas;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    CalendarWidget(
                      rutinas: _rutinas,
                      enableBlinkAnimation: true,
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context) {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final crossAxisCount = isMobile ? 1 : 4;
        
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isMobile ? 2.5 : 1.2,
          children: [
            _buildStatCard(
              context,
              icon: Icons.inventory_2,
              title: 'Inventarios',
              value: _totalInventarios.toString(),
              badge: '+12%',
              badgeColor: Colors.green,
              iconColor: Colors.blue,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InventoryTypeSelectionScreen()),
                );
                // Refrescar estadísticas al regresar
                if (mounted) {
                  _loadStats();
                  _loadSessions();
                }
              },
            ),
            _buildStatCard(
              context,
              icon: Icons.pending_outlined,
              title: 'Inventarios pendientes',
              value: _pendingInventarios.toString(),
              badge: _pendingInventarios.toString(),
              badgeColor: Colors.orange,
              iconColor: Colors.orange,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CompletedInventoriesScreen()),
                );
                // Refrescar estadísticas al regresar
                if (mounted) {
                  _loadStats();
                  _loadSessions();
                }
              },
            ),
            _buildStatCard(
              context,
              icon: Icons.local_shipping,
              title: 'Envíos Activos',
              value: _activeShipments.toString(),
              badge: _activeShipments > 0 ? _activeShipments.toString() : null,
              badgeColor: Colors.orange,
              iconColor: Colors.green,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ActiveShipmentsScreen()),
                );
                // Refrescar estadísticas al regresar
                if (mounted) {
                  _loadStats();
                }
              },
            ),
            _buildStatCard(
              context,
              icon: Icons.group,
              title: 'Usuarios Activos',
              value: _activeUsers.toString(),
              badge: _activeUsers.toString(),
              badgeColor: Colors.purple,
              iconColor: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UsersManagementScreen()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    String? badge,
    required Color badgeColor,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 48),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedClockWidget() {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF003366),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'HORA ACTUAL',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<DateTime>(
              stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
              builder: (context, snapshot) {
                final now = snapshot.data ?? DateTime.now();
                final timeFormat = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                return Text(
                  timeFormat,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            StreamBuilder<DateTime>(
              stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
              builder: (context, snapshot) {
                final now = snapshot.data ?? DateTime.now();
                final dateFormat = '${_getDayName(now.weekday)}, ${now.day} ${_getMonthName(now.month)} ${now.year}';
                return Text(
                  dateFormat,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            const Text(
              'Ciudad de México, México',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 
                    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    return months[month - 1];
  }

}


class _SessionDetailDialog extends StatefulWidget {
  final InventorySession session;
  final String Function(DateTime) formatDate;

  const _SessionDetailDialog({
    required this.session,
    required this.formatDate,
  });

  @override
  State<_SessionDetailDialog> createState() => _SessionDetailDialogState();
}

class _SessionDetailDialogState extends State<_SessionDetailDialog> {
  final InventarioRepository _inventarioRepository = serviceLocator.get<InventarioRepository>();
  Map<int, String> _productNames = {};
  bool _isLoadingNames = true;

  @override
  void initState() {
    super.initState();
    _loadProductNames();
  }

  Future<void> _loadProductNames() async {
    try {
      final Map<int, String> names = {};
      
      // Cargar nombres y tamaños de todos los productos en la sesión
      for (final productId in widget.session.quantities.keys) {
        try {
          final producto = await _inventarioRepository.getProductoById(productId);
          if (producto != null) {
            // Formatear nombre con tamaño si está disponible
            String displayName = producto.nombre;
            if (producto.tamano != null) {
              displayName = '$displayName - ${producto.tamano} m';
            }
            names[productId] = displayName;
          } else {
            names[productId] = 'Producto ID #$productId (no encontrado)';
          }
        } catch (e) {
          names[productId] = 'Producto ID #$productId (error al cargar)';
        }
      }
      
      if (mounted) {
        setState(() {
          _productNames = names;
          _isLoadingNames = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingNames = false;
          // Si falla, usar IDs como fallback
          _productNames = {
            for (final id in widget.session.quantities.keys)
              id: 'Producto ID #$id'
          };
        });
      }
    }
  }

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
            _buildInfoRow('Categoría', widget.session.categoryName, context),
            const SizedBox(height: 8),
            _buildInfoRow('Estado', widget.session.status == InventorySessionStatus.pending ? 'Pendiente' : 'Terminado', context),
            const SizedBox(height: 8),
            _buildInfoRow('Última actualización', widget.formatDate(widget.session.updatedAt), context),
            const SizedBox(height: 8),
            if (widget.session.ownerEmail != null && widget.session.ownerEmail!.isNotEmpty)
              _buildInfoRow('Empleado', widget.session.ownerEmail!, context),
            if (widget.session.ownerName != null && widget.session.ownerName != widget.session.ownerEmail)
              _buildInfoRow('Responsable', widget.session.ownerName!, context),
            const SizedBox(height: 16),
            Text(
              'Productos capturados (${widget.session.quantities.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: _isLoadingNames
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      children: widget.session.quantities.entries.map((entry) {
                        final productName = _productNames[entry.key] ?? 'Producto ID #${entry.key}';
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(productName),
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
