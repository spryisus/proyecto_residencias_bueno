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
import '../inventory/completed_inventories_screen.dart';
import '../inventory/jumper_categories_screen.dart' show JumperCategories, JumperCategory, JumperCategoriesScreen;
import '../computo/inventario_computo_screen.dart';
import '../sicor/inventario_tarjetas_red_screen.dart';
import '../shipments/shipments_screen.dart';
import '../shipments/active_shipments_screen.dart';
import '../admin/admin_dashboard.dart';
import '../settings/settings_screen.dart';
import '../sdr/solicitud_sdr_screen.dart';
import '../../widgets/calendar_widget.dart';

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
      // El campo activo puede ser true, false o null
      final activo = empleado['activo'];
      if (activo == null || activo == false) {
        throw 'Usuario temporalmente desactivado. Contacte al administrador para más información.';
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

      // Autenticar en Supabase Auth para que las políticas RLS funcionen
      // Usamos un usuario de servicio o el email del usuario
      try {
        // Opción 1: Intentar autenticar con un usuario de servicio
        // (más seguro y no requiere crear usuarios individuales)
        const serviceEmail = 'service@telmex.local';
        const servicePassword = 'ServiceAuth2024!'; // Cambiar por una contraseña segura
        
        try {
          await supabase.auth.signInWithPassword(
            email: serviceEmail,
            password: servicePassword,
          );
          debugPrint('✅ Autenticado en Supabase Auth con usuario de servicio');
        } catch (serviceError) {
          debugPrint('⚠️ No se pudo autenticar con usuario de servicio: $serviceError');
          debugPrint('⚠️ Las políticas RLS pueden no funcionar correctamente');
          debugPrint('⚠️ Solución: Crear un usuario de servicio en Supabase Auth con email: $serviceEmail');
        }
      } catch (e) {
        debugPrint('⚠️ Error al autenticar en Supabase Auth: $e');
        debugPrint('⚠️ Continuando con login local...');
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
  String? _userName;
  String? _userRole;
  int _selectedIndex = 0; // Para el sidebar
  int _totalInventarios = 0;
  int _pendingInventarios = 0;
  int _activeShipments = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadSessions();
    _loadStats();
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
        _userName = userName ?? widget.username ?? 'Usuario';
        _userRole = userRole;
      });
    }
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('id_empleado');
      
      // Contar inventarios totales desde sesiones (solo del usuario)
      final allSessions = await _sessionStorage.getAllSessions();
      final userSessions = currentUserId != null
          ? allSessions.where((s) => s.ownerId == currentUserId).toList()
          : [];
      
      final totalInventarios = userSessions.length;
      final pendingInventarios = userSessions.where((s) => s.status == InventorySessionStatus.pending).length;

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
    if (!mounted) return;
    
    setState(() {
      _isLoadingSessions = true;
    });
    
    final sessions = await _sessionStorage.getAllSessions();
    
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

      // Verificar si es SICOR (antes que Jumpers)
      final categoriaNombreLower = categoria.nombre.toLowerCase();
      final isSicor = categoryNameLower.contains('sicor') || 
                     categoryNameLower.contains('medición') || 
                     categoryNameLower.contains('medicion') ||
                     categoriaNombreLower.contains('sicor') ||
                     categoriaNombreLower.contains('medición') ||
                     categoriaNombreLower.contains('medicion');
      
      if (isSicor) {
        // Navegar a la pantalla de inventario de tarjetas de red (SICOR)
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InventarioTarjetasRedScreen(
              sessionId: session.id,
            ),
          ),
        );
        await _loadSessions();
        return;
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
    return Scaffold(
      body: Row(
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
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
              if (mounted) {
                _loadSessions();
                _loadStats();
              }
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
                    MaterialPageRoute(builder: (_) => const InventoryTypeSelectionScreen()),
                  );
                  if (mounted) {
                    _loadSessions();
                    _loadStats();
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
                  if (mounted) {
                    _loadSessions();
                    _loadStats();
                  }
                },
              ),
              _buildSidebarItem(
                context,
                icon: Icons.description_outlined,
                title: 'Solicitudes SDR',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SolicitudSdrScreen()),
                  );
                  if (mounted) {
                    _loadSessions();
                  }
                },
              ),
            ],
          ),
          // Sección SESIONES GUARDADAS (solo si hay sesiones)
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ),
        ],
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
          // Tarjetas de estadísticas (solo 3 para usuarios normales)
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
                      child: _buildEnhancedClockWidget(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: const CalendarWidget(),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildEnhancedClockWidget(),
                    const SizedBox(height: 16),
                    const CalendarWidget(),
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
        final crossAxisCount = isMobile ? 1 : 3; // Solo 3 tarjetas para usuarios normales
        
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InventoryTypeSelectionScreen()),
                );
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CompletedInventoriesScreen()),
                );
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ActiveShipmentsScreen()),
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
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
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
