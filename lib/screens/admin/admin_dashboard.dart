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
import '../inventory/completed_inventory_detail_screen.dart';
import '../../domain/entities/categoria.dart';
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
  Rutina? _rutinaEnAnimacion; // Rutina actualmente en animación en el calendario

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

  Future<void> _openSession(InventorySession session) async {
    try {
      final InventarioRepository _inventarioRepository = serviceLocator.get<InventarioRepository>();
      
      // Obtener la categoría para mostrar los detalles
      Categoria? categoria;
      
      // Si es inventario de cómputo (categoryId == -1), crear una categoría dummy
      if (session.categoryId == -1) {
        categoria = Categoria(
          idCategoria: -1,
          nombre: 'Equipo de Cómputo',
          descripcion: 'Equipos de cómputo',
        );
      } else {
        // Obtener la categoría de la base de datos
        categoria = await _inventarioRepository.getCategoriaById(session.categoryId);
      }
      
      if (categoria == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La categoría asociada ya no existe'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Mostrar los detalles de la sesión sin redirigir al inventario
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CompletedInventoryDetailScreen(
              session: session,
              categoria: categoria!,
            ),
          ),
        );
        // Recargar sesiones al volver
        await _loadSessions();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al mostrar detalles: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    if (isMobile) {
      // Versión móvil con Drawer
      return Scaffold(
        drawer: _buildDrawer(context),
        body: Stack(
          children: [
            Column(
              children: [
                // Header superior
                _buildHeader(context),
                // Contenido scrollable
                Expanded(
                  child: _buildMainContent(context),
                ),
              ],
            ),
            // Widget de notificaciones de rutinas (parte inferior derecha)
            RutinaNotificationsWidget(
              rutinaEnAnimacion: _rutinaEnAnimacion,
            ),
          ],
        ),
      );
    } else {
      // Versión escritorio con sidebar permanente
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
            RutinaNotificationsWidget(
              rutinaEnAnimacion: _rutinaEnAnimacion,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildHeader(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(top: topPadding),
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
      child: Container(
        height: isMobile ? 70 : 70,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 24,
          vertical: isMobile ? 8 : 12,
        ),
        child: Row(
          children: [
            // Logo y título
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width < 600 ? 32 : 40,
                    height: MediaQuery.of(context).size.width < 600 ? 32 : 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF003366),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.inventory_2,
                      color: Colors.white,
                      size: MediaQuery.of(context).size.width < 600 ? 20 : 24,
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width < 600 ? 8 : 12),
                  Flexible(
                    child: isMobile
                        ? Text(
                            'Gestor de Refacciones y Envios',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF003366),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Gestor de Refacciones y Envios',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF003366),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Sistema de Larga Distancia',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          if (MediaQuery.of(context).size.width >= 600) const Spacer(),
          // Botón de menú hamburguesa (solo móvil)
          if (MediaQuery.of(context).size.width < 600)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                tooltip: 'Menú',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          if (MediaQuery.of(context).size.width < 600)
            const SizedBox(width: 8),
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
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          SizedBox(width: MediaQuery.of(context).size.width < 600 ? 8 : 12),
          // Avatar y usuario
          if (MediaQuery.of(context).size.width >= 600)
            Row(
              mainAxisSize: MainAxisSize.min,
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
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _userName ?? 'Usuario',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _userRole ?? 'Usuario',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          else
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF003366),
              child: Text(
                _userName?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      width: 280,
      child: Column(
        children: [
          // Header del Drawer
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            decoration: BoxDecoration(
              color: const Color(0xFF003366),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    _userName?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      color: Color(0xFF003366),
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _userName ?? 'Usuario',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _userRole ?? 'Usuario',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Sección PRINCIPAL
                _buildDrawerSection(
                  context,
                  'PRINCIPAL',
                  [
                    _buildDrawerItem(
                      context,
                      icon: Icons.home_outlined,
                      title: 'Dashboard',
                      isSelected: _selectedIndex == 0,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _selectedIndex = 0);
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.inventory_2_outlined,
                      title: 'Inventarios',
                      badge: _pendingInventarios > 0 ? _pendingInventarios.toString() : null,
                      badgeColor: Colors.orange,
                      onTap: () async {
                        Navigator.pop(context);
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
                    _buildDrawerItem(
                      context,
                      icon: Icons.local_shipping_outlined,
                      title: 'Envíos',
                      badge: _activeShipments > 0 ? _activeShipments.toString() : null,
                      badgeColor: Colors.orange,
                      onTap: () async {
                        Navigator.pop(context);
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
                    _buildDrawerItem(
                      context,
                      icon: Icons.description_outlined,
                      title: 'Solicitudes SDR',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SolicitudSdrScreen()),
                        );
                      },
                    ),
                  ],
                ),
                // Sección GESTIÓN
                _buildDrawerSection(
                  context,
                  'GESTIÓN',
                  [
                    _buildDrawerItem(
                      context,
                      icon: Icons.group_outlined,
                      title: 'Usuarios',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const UsersManagementScreen()),
                        );
                      },
                    ),
                  ],
                ),
                // Sección SESIONES GUARDADAS con contenedor scrollable
                if (_sessions.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Text(
                      'SESIONES GUARDADAS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _sessions.length,
                      itemBuilder: (context, index) {
                        final session = _sessions[index];
                        final isPending = session.status == InventorySessionStatus.pending;
                        return _buildDrawerItem(
                          context,
                          icon: isPending ? Icons.pause_circle_outline : Icons.check_circle_outline,
                          title: session.categoryName,
                          subtitle: _formatTimeAgo(session.updatedAt),
                          iconColor: isPending ? Colors.orange : Colors.green,
                          onTap: () {
                            Navigator.pop(context);
                            _openSession(session);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          // Cerrar Sesión
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildDrawerItem(
              context,
              icon: Icons.logout,
              title: 'Cerrar Sesión',
              iconColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
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
          // Sección SESIONES GUARDADAS con contenedor scrollable
          if (_sessions.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                'SESIONES GUARDADAS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    final isPending = session.status == InventorySessionStatus.pending;
                    return _buildSidebarItem(
                      context,
                      icon: isPending ? Icons.pause_circle_outline : Icons.check_circle_outline,
                      title: session.categoryName,
                      subtitle: _formatTimeAgo(session.updatedAt),
                      iconColor: isPending ? Colors.orange : Colors.green,
                      onTap: () => _openSession(session),
                    );
                  },
                ),
              ),
            ),
          ],
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

  Widget _buildDrawerSection(BuildContext context, String title, List<Widget> items) {
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

  Widget _buildDrawerItem(
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
    return ListTile(
      leading: Icon(
        icon,
        size: 24,
        color: isSelected
            ? const Color(0xFF003366)
            : iconColor ?? Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? const Color(0xFF003366) : Colors.grey[800],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor ?? Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      selected: isSelected,
      selectedTileColor: const Color(0xFF003366).withOpacity(0.1),
      onTap: onTap,
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
              fontSize: 14,
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
                      fontSize: 16,
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
                        fontSize: 13,
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
                    fontSize: 13,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenido 👋',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Panel de administración - Sistema de Larga Distancia',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
                      child: RutinasWidget(
                        onRutinasChanged: (rutinas) {
                          setState(() {
                            _rutinas = rutinas;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: CalendarWidget(
                        key: const ValueKey('calendar_wide'),
                        rutinas: _rutinas,
                        enableBlinkAnimation: true,
                        onRutinaAnimacionChanged: (rutina) {
                          setState(() {
                            _rutinaEnAnimacion = rutina;
                          });
                        },
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    RutinasWidget(
                      onRutinasChanged: (rutinas) {
                        setState(() {
                          _rutinas = rutinas;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    CalendarWidget(
                      key: const ValueKey('calendar_narrow'),
                      rutinas: _rutinas,
                      enableBlinkAnimation: true,
                      onRutinaAnimacionChanged: (rutina) {
                        setState(() {
                          _rutinaEnAnimacion = rutina;
                        });
                      },
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
        final crossAxisCount = isMobile ? 2 : 4; // 4 columnas en desktop para las 4 tarjetas
        
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: isMobile ? 8 : 16,
          mainAxisSpacing: isMobile ? 8 : 16,
          childAspectRatio: isMobile ? 1.0 : 1.4, // Ajustado para 4 columnas
          padding: EdgeInsets.all(isMobile ? 8 : 16),
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
              badge: _pendingInventarios > 0 ? _pendingInventarios.toString() : null,
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
            // Tarjeta adicional solo para administradores
            _buildStatCard(
              context,
              icon: Icons.group,
              title: 'Usuarios Activos',
              value: _activeUsers.toString(),
              badge: _activeUsers > 0 ? _activeUsers.toString() : null,
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ClipRect(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 10 : 20,
              vertical: isMobile ? 8 : 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isMobile ? 6 : 12),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: iconColor, size: isMobile ? 28 : 48),
                    ),
                    if (badge != null)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 6 : 10,
                          vertical: isMobile ? 3 : 5,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 10 : 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  value,
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isMobile ? 22 : 30,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                Text(
                                  title,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                    fontSize: isMobile ? 10 : 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
