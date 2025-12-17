import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bcrypt/bcrypt.dart';
import '../../base_conexion/conexion_db.dart';
import '../../core/di/injection_container.dart';
import '../../data/local/inventory_session_storage.dart';
import '../../domain/entities/inventory_session.dart';
import '../../domain/repositories/inventario_repository.dart';
import '../../app/config/supabase_client.dart' show supabaseClient;
import '../inventory/inventory_type_selection_screen.dart';
import '../inventory/category_inventory_screen.dart';
import '../inventory/jumper_categories_screen.dart' show JumperCategories, JumperCategory, JumperCategoriesScreen;
import '../computo/inventario_computo_screen.dart';
import '../shipments/shipments_screen.dart';
import '../admin/admin_dashboard.dart';
import '../settings/settings_screen.dart';
import '../sdr/solicitud_sdr_screen.dart';
import '../../widgets/clock_widget.dart';
import '../../widgets/calendar_widget.dart';
import '../../widgets/quick_stats_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isTestingConnection = false;
  bool _isLoggingIn = false;

  /// Guarda la sesión del usuario en SharedPreferences
  Future<void> _saveSession(String idEmpleado, String nombreUsuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('id_empleado', idEmpleado);
    await prefs.setString('nombre_usuario', nombreUsuario);
    await prefs.setBool('is_logged_in', true);
  }

  /// Valida la contraseña (soporta texto plano y bcrypt)
  bool _validatePassword(String inputPassword, String storedPassword) {
    // Si la contraseña almacenada parece un hash bcrypt (empieza con $2a$ o $2b$)
    if (storedPassword.startsWith('\$2a\$') || storedPassword.startsWith('\$2b\$') || storedPassword.startsWith('\$2y\$')) {
      try {
        // bcrypt 1.1.3 usa BCrypt.checkpw
        return BCrypt.checkpw(inputPassword, storedPassword);
      } catch (e) {
        print('Error al verificar bcrypt: $e');
        return false;
      }
    }
    // Si no es bcrypt, comparar directamente (texto plano)
    return inputPassword == storedPassword;
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
    });

    try {
      final isConnected = await testSupabaseConnection();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isConnected 
                ? '✅ Conexión a Supabase exitosa!' 
                : '❌ Error de conexión a Supabase',
            ),
            backgroundColor: isConnected ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Cerrar',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTestingConnection = false;
        });
      }
    }
  }

  Future<void> _login() async {
    final currentState = _formKey.currentState;
    if (currentState == null) return;
    if (!currentState.validate()) return;

    setState(() {
      _isLoggingIn = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final nombreUsuario = _usernameController.text.trim();
      final password = _passwordController.text;

      // Buscar el empleado por nombre_usuario
      final empleado = await supabase
          .from('t_empleados')
          .select('id_empleado, nombre_usuario, contrasena, activo')
          .eq('nombre_usuario', nombreUsuario)
          .maybeSingle();

      if (empleado == null) {
        throw 'Usuario o contraseña incorrectos';
      }

      // Verificar que el usuario esté activo
      if (empleado['activo'] != true) {
        throw 'Usuario inactivo en el sistema';
      }

      // Validar la contraseña
      final storedPassword = empleado['contrasena'] as String;
      if (!_validatePassword(password, storedPassword)) {
        throw 'Usuario o contraseña incorrectos';
      }

      // Obtener los roles del empleado
      final empleadoId = empleado['id_empleado'] as String;
      final roles = await supabase
          .from('t_empleado_rol')
          .select('t_roles!inner(nombre)')
          .eq('id_empleado', empleadoId);

      if (roles.isEmpty) {
        throw 'Usuario sin roles asignados';
      }

      // Verificar que tenga al menos uno de los roles permitidos
      final rolesPermitidos = ['admin', 'operador', 'auditor'];
      final tieneRolPermitido = roles.any((rol) => 
          rolesPermitidos.contains(rol['t_roles']['nombre']?.toString().toLowerCase()));

      if (!tieneRolPermitido) {
        throw 'Usuario sin permisos suficientes';
      }

      // Guardar sesión
      await _saveSession(empleadoId, nombreUsuario);

      if (!mounted) return;
      
      // Determinar el rol principal del usuario
      final rolPrincipal = roles.first['t_roles']['nombre']?.toString().toLowerCase() ?? 'usuario';
      
      // Notificación breve y navegación según rol
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Sesión iniciada correctamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
      
      // Usar un pequeño delay y verificar mounted antes de navegar
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      
      // Navegar usando WidgetsBinding para asegurar que el frame se complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        
        if (rolPrincipal == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => AdminDashboard(username: nombreUsuario),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => WelcomePage(username: nombreUsuario),
            ),
          );
        }
      });
    } on PostgrestException catch (e) {
      String mensaje = 'Error de conexión con la base de datos';
      if (e.code == 'PGRST116') {
        mensaje = 'Usuario o contraseña incorrectos';
      } else {
        mensaje = e.message.isNotEmpty ? e.message : mensaje;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $mensaje'),
            backgroundColor: const Color.fromRGBO(244, 67, 54, 1),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al iniciar sesión: $e'),
            backgroundColor: const Color.fromRGBO(244, 67, 54, 1),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      // Usar un pequeño delay antes de actualizar el estado para evitar problemas de dependencias
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          setState(() {
            _isLoggingIn = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio de sesión Larga Distancia'),
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.lock_outline,
                size: 84,
                color: Color(0xFF003366),
              ),
              const SizedBox(height: 12),
              const Text(
                'Ingreso al Sistema',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003366),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _usernameController,
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            labelText: 'Correo de usuario',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) return 'Ingresa tu correo';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final text = value ?? '';
                            if (text.isEmpty) return 'Ingresa tu contraseña';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoggingIn ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003366),
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoggingIn
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Iniciar sesión'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _isTestingConnection ? null : _testConnection,
                          child: Text(
                            'Probar Conexión Supabase',
                            style: TextStyle(
                              inherit: false,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _isTestingConnection 
                                ? Theme.of(context).disabledColor 
                                : Theme.of(context).colorScheme.primary,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ),
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

class WelcomePage extends StatefulWidget {
  final String? username;
  const WelcomePage({super.key, this.username});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final InventorySessionStorage _sessionStorage = serviceLocator.get<InventorySessionStorage>();
  final InventarioRepository _inventarioRepository = serviceLocator.get<InventarioRepository>();
  List<InventorySession> _sessions = [];
  bool _isLoadingSessions = true;
  List<InventorySession> _allSessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingSessions = true;
    });
    
    final sessions = await _sessionStorage.getAllSessions();
    _allSessions = sessions;
    
    // Verificar si el usuario es admin
    final isAdmin = await _checkIsAdmin();
    
    // Obtener el id_empleado del usuario actual
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('id_empleado');
    
    // Filtrar SOLO inventarios pendientes
    var pendingSessions = sessions.where((s) {
      // Asegurarse de que solo se incluyan los que tienen estado pending
      final isPending = s.status == InventorySessionStatus.pending;
      if (!isPending) return false;
      
      // Si es admin, mostrar todos los pendientes
      // Si no es admin, solo mostrar los del usuario actual
      if (isAdmin) {
        return true;
      } else {
        // Solo mostrar inventarios del usuario actual
        return s.ownerId == currentUserId;
      }
    }).toList();
    
    if (!mounted) return;
    setState(() {
      _sessions = pendingSessions;
      _isLoadingSessions = false;
    });
  }

  Future<void> _openSession(InventorySession session) async {
    try {
      // Verificar si es inventario de cómputo (categoryId == -1 o nombre contiene "comput")
      final categoryNameLower = session.categoryName.toLowerCase();
      if (session.categoryId == -1 || categoryNameLower.contains('comput')) {
        // Navegar directamente a la pantalla de inventario de cómputo
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const InventarioComputoScreen(),
          ),
        );
        await _loadSessions();
        return;
      }

      // Obtener la categoría para otros tipos de inventario
      final categoria = await _inventarioRepository.getCategoriaById(session.categoryId);
      if (categoria == null) {
        throw 'La categoría asociada ya no existe.';
      }

      // Verificar si es Jumpers y si tiene subcategoría en el nombre
      if (categoryNameLower.contains('jumper')) {
        // Intentar detectar si hay una subcategoría en el nombre (ej: "Jumpers FC-FC")
        JumperCategory? detectedJumperCategory;
        for (final jumperCategory in JumperCategories.all) {
          if (session.categoryName.contains(jumperCategory.displayName)) {
            detectedJumperCategory = jumperCategory;
            break;
          }
        }

        if (detectedJumperCategory != null) {
          // Si hay subcategoría, navegar directamente a la pantalla de inventario con el filtro
          final isAdmin = await _checkIsAdmin();
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryInventoryScreen(
                categoria: categoria,
                categoriaNombre: session.categoryName,
                sessionId: session.id,
                isAdmin: isAdmin,
                jumperCategoryFilter: detectedJumperCategory,
              ),
            ),
          );
        } else {
          // Si no hay subcategoría, navegar a la pantalla de categorías de jumpers
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JumperCategoriesScreen(
                categoria: categoria,
                categoriaNombre: session.categoryName,
                sessionId: session.id, // Pasar el sessionId para cargar la sesión pendiente
              ),
            ),
          );
        }
      } else {
        // Para otras categorías, navegar directamente a la pantalla de inventario
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryInventoryScreen(
              categoria: categoria,
              categoriaNombre: session.categoryName,
              sessionId: session.id,
            ),
          ),
        );
      }
      await _loadSessions();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo abrir el inventario guardado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteSession(InventorySession session) async {
    await _sessionStorage.deleteSession(session.id);
    await _loadSessions();
  }

  Future<bool> _checkIsAdmin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idEmpleado = prefs.getString('id_empleado');
      
      if (idEmpleado == null) {
        return false;
      }
      
      final roles = await supabaseClient
          .from('t_empleado_rol')
          .select('t_roles!inner(nombre)')
          .eq('id_empleado', idEmpleado);
      
      final isAdmin = roles.any((rol) => 
          rol['t_roles']['nombre']?.toString().toLowerCase() == 'admin');
      
      return isAdmin;
    } catch (e) {
      debugPrint('Error al verificar rol de admin: $e');
      return false;
    }
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
        title: const Text('Bienvenido'),
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
            icon: const Icon(Icons.cloud_done),
            onPressed: () async {
              // Reusar test de conexión desde la pantalla de bienvenida
              final isConnected = await testSupabaseConnection();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isConnected
                        ? '✅ Conexión a Supabase activa'
                        : '❌ Sin conexión a Supabase',
                  ),
                  backgroundColor: isConnected ? Colors.green : Colors.red,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Probar conexión',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
              // Recargar sesiones cuando se vuelve
              if (mounted) {
                _loadSessions();
              }
            },
            tooltip: 'Configuración',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Menú',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (username != null && username.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.white70, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            username,
                            style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.inventory_2_outlined, 
                size: 24,
                color: Theme.of(context).iconTheme.color,
              ),
              title: Text(
                'Inventarios',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              minVerticalPadding: 16,
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InventoryTypeSelectionScreen()),
                );
                // Recargar sesiones cuando se vuelve de la pantalla de inventarios
                if (mounted) {
                  _loadSessions();
                }
              },
            ),
            ListTile(
              leading: Icon(
                Icons.local_shipping_outlined, 
                size: 24,
                color: Theme.of(context).iconTheme.color,
              ),
              title: Text(
                'Envíos',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              minVerticalPadding: 16,
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ShipmentsScreen()),
                );
                // Recargar sesiones cuando se vuelve
                if (mounted) {
                  _loadSessions();
                }
              },
            ),
            ListTile(
              leading: Icon(
                Icons.description_outlined, 
                size: 24,
                color: Theme.of(context).iconTheme.color,
              ),
              title: Text(
                'Solicitud SDR',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              minVerticalPadding: 16,
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SolicitudSdrScreen()),
                );
                // Recargar sesiones cuando se vuelve
                if (mounted) {
                  _loadSessions();
                }
              },
            ),
            const Divider(height: 24),
            ListTile(
              leading: Icon(
                Icons.settings_outlined, 
                size: 24,
                color: Theme.of(context).iconTheme.color,
              ),
              title: Text(
                'Ajustes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              minVerticalPadding: 16,
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
                // Recargar sesiones cuando se vuelve
                if (mounted) {
                  _loadSessions();
                }
              },
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 800;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'BIENVENIDO AL SISTEMA DE LARGA DISTANCIA',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Widgets en grid responsive
                if (isWideScreen)
                  Row(
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
                  )
                else
                  Column(
                    children: [
                      const ClockWidget(),
                      const SizedBox(height: 16),
                      const CalendarWidget(),
                      const SizedBox(height: 16),
                      const QuickStatsWidget(),
                    ],
                  ),
                const SizedBox(height: 24),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout, size: 24),
                      label: Text(
                        'Volver al login',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSessionSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionSection() {
    if (_isLoadingSessions) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: CircularProgressIndicator(),
      );
    }
    if (_sessions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Inventarios guardados',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
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
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: chipColor.withValues(alpha: 0.15),
          child: Icon(
            isPending ? Icons.pause_circle_outline : Icons.check_circle_outline,
            color: chipColor,
          ),
        ),
        title: Text(
          session.categoryName,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        subtitle: Text(
          'Actualizado: ${_formatDate(session.updatedAt)}',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.red[300],
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _deleteSession(session),
            ),
          ],
        ),
        isThreeLine: false,
        onTap: () => _openSession(session),
      ),
    );
  }
}
