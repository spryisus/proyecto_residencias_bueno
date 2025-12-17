import 'dart:math';
import 'package:flutter/material.dart';
import 'package:bcrypt/bcrypt.dart';
import '../../app/config/supabase_client.dart' show supabaseClient;
import '../../domain/entities/empleado.dart';
import '../../domain/entities/rol.dart';
import '../settings/settings_screen.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  List<Empleado> _empleados = [];
  List<Rol> _rolesDisponibles = [];
  bool _isLoading = true;
  bool _isCreatingUser = false;
  bool _showCreateForm = false;

  // Controllers para el formulario de creación
  final _formKey = GlobalKey<FormState>();
  final _nombreUsuarioController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _confirmarContrasenaController = TextEditingController();
  final Map<String, bool> _selectedRoles = {
    'admin': false,
    'operador': false,
    'auditor': false,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nombreUsuarioController.dispose();
    _contrasenaController.dispose();
    _confirmarContrasenaController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadEmpleados(),
        _loadRoles(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadEmpleados() async {
    try {
      final response = await supabaseClient
          .from('t_empleados')
          .select('*')
          .order('creado_en', ascending: false);

      final empleados = (response as List)
          .map((json) => Empleado.fromJson(json))
          .toList();

      if (mounted) {
        setState(() {
          _empleados = empleados;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar empleados: $e');
      rethrow;
    }
  }

  Future<void> _loadRoles() async {
    try {
      final response = await supabaseClient
          .from('t_roles')
          .select('*')
          .inFilter('nombre', ['admin', 'operador', 'auditor']);

      final roles = (response as List)
          .map((json) => Rol.fromJson(json))
          .toList();

      if (mounted) {
        setState(() {
          _rolesDisponibles = roles;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar roles: $e');
      rethrow;
    }
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar que al menos un rol esté seleccionado
    if (!_selectedRoles.values.any((selected) => selected)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar al menos un rol'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isCreatingUser = true;
    });

    try {
      final nombreUsuario = _nombreUsuarioController.text.trim();
      final password = _contrasenaController.text;
      
      // Verificar que el usuario no exista
      final usuarioExistente = await supabaseClient
          .from('t_empleados')
          .select('id_empleado')
          .eq('nombre_usuario', nombreUsuario)
          .maybeSingle();
      
      if (usuarioExistente != null) {
        throw 'El usuario ya existe';
      }
      
      // Generar UUID v4 para el nuevo empleado
      final idEmpleado = _generateUuid();
      
      // Hashear la contraseña con bcrypt
      final passwordHash = BCrypt.hashpw(password, BCrypt.gensalt());
      
      // 1. Insertar en t_empleados
      await supabaseClient
          .from('t_empleados')
          .insert({
            'id_empleado': idEmpleado,
            'nombre_usuario': nombreUsuario,
            'contrasena': passwordHash,
            'activo': true,
          });
      
      // 2. Asignar roles en t_empleado_rol
      final rolesSeleccionados = _selectedRoles.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();
      
      // Obtener los IDs de los roles seleccionados
      for (final nombreRol in rolesSeleccionados) {
        final rol = _rolesDisponibles.firstWhere(
          (r) => r.nombre.toLowerCase() == nombreRol,
          orElse: () => throw 'Rol $nombreRol no encontrado',
        );
        
        await supabaseClient
            .from('t_empleado_rol')
            .insert({
              'id_empleado': idEmpleado,
              'id_rol': rol.idRol,
            });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Limpiar formulario
        _nombreUsuarioController.clear();
        _contrasenaController.clear();
        _confirmarContrasenaController.clear();
        _selectedRoles.updateAll((key, value) => false);
        _showCreateForm = false;
        
        // Recargar lista
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear usuario: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingUser = false;
        });
      }
    }
  }

  Future<void> _toggleUserStatus(Empleado empleado) async {
    try {
      final nuevoEstado = !empleado.activo;
      
      await supabaseClient
          .from('t_empleados')
          .update({'activo': nuevoEstado})
          .eq('id_empleado', empleado.idEmpleado);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nuevoEstado
                  ? 'Usuario activado'
                  : 'Usuario desactivado',
            ),
            backgroundColor: nuevoEstado ? Colors.green : Colors.orange,
          ),
        );
        // Recargar datos para reflejar el cambio
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar estado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteUser(Empleado empleado) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar al usuario "${empleado.nombreUsuario}"?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // 1. Eliminar roles asociados (t_empleado_rol)
      await supabaseClient
          .from('t_empleado_rol')
          .delete()
          .eq('id_empleado', empleado.idEmpleado);
      
      // 2. Eliminar empleado (t_empleados)
      await supabaseClient
          .from('t_empleados')
          .delete()
          .eq('id_empleado', empleado.idEmpleado);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar usuario: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<List<Rol>> _getUserRoles(String idEmpleado) async {
    try {
      final response = await supabaseClient
          .from('t_empleado_rol')
          .select('t_roles!inner(*)')
          .eq('id_empleado', idEmpleado);

      return (response as List)
          .map((json) => Rol.fromJson(json['t_roles']))
          .toList();
    } catch (e) {
      debugPrint('Error al cargar roles del usuario: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Botón para crear nuevo usuario
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Usuarios del Sistema',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showCreateForm = !_showCreateForm;
                            if (!_showCreateForm) {
                              _nombreUsuarioController.clear();
                              _contrasenaController.clear();
                              _confirmarContrasenaController.clear();
                              _selectedRoles.updateAll((key, value) => false);
                            }
                          });
                        },
                        icon: Icon(_showCreateForm ? Icons.close : Icons.person_add),
                        label: Text(_showCreateForm ? 'Cancelar' : 'Nuevo Usuario'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Formulario de creación
                if (_showCreateForm) _buildCreateUserForm(),

                // Lista de usuarios
                Expanded(
                  child: _empleados.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay usuarios registrados',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _empleados.length,
                          itemBuilder: (context, index) {
                            return _buildUserCard(_empleados[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildCreateUserForm() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Crear Nuevo Usuario',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nombreUsuarioController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de Usuario',
                  hintText: 'ejemplo@telmex.com',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre de usuario es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contrasenaController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La contraseña es requerida';
                  }
                  if (value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmarContrasenaController,
                decoration: const InputDecoration(
                  labelText: 'Confirmar Contraseña',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value != _contrasenaController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Roles',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _rolesDisponibles.map((rol) {
                  return FilterChip(
                    label: Text(rol.nombre.toUpperCase()),
                    selected: _selectedRoles[rol.nombre.toLowerCase()] ?? false,
                    onSelected: (selected) {
                      setState(() {
                        _selectedRoles[rol.nombre.toLowerCase()] = selected;
                      });
                    },
                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isCreatingUser ? null : _createUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isCreatingUser
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Crear Usuario'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(Empleado empleado) {
    return FutureBuilder<List<Rol>>(
      future: _getUserRoles(empleado.idEmpleado),
      builder: (context, snapshot) {
        final userRoles = snapshot.data ?? [];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            leading: CircleAvatar(
              backgroundColor: empleado.activo
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.red[100],
              child: Icon(
                empleado.activo ? Icons.person : Icons.person_off,
                color: empleado.activo
                    ? Theme.of(context).colorScheme.primary
                    : Colors.red[700],
              ),
            ),
            title: Text(
              empleado.nombreUsuario,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: empleado.activo ? null : TextDecoration.lineThrough,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: userRoles.map((rol) {
                    Color chipColor;
                    switch (rol.nombre.toLowerCase()) {
                      case 'admin':
                        chipColor = Colors.red;
                        break;
                      case 'operador':
                        chipColor = Colors.blue;
                        break;
                      case 'auditor':
                        chipColor = Colors.orange;
                        break;
                      default:
                        chipColor = Colors.grey;
                    }
                    return Chip(
                      label: Text(
                        rol.nombre.toUpperCase(),
                        style: const TextStyle(fontSize: 11, color: Colors.white),
                      ),
                      backgroundColor: chipColor,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 4),
                Text(
                  'Creado: ${_formatDate(empleado.creadoEn)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    empleado.activo ? Icons.toggle_on : Icons.toggle_off,
                    color: empleado.activo ? Colors.green : Colors.red,
                    size: 32,
                  ),
                  onPressed: () => _toggleUserStatus(empleado),
                  tooltip: empleado.activo ? 'Desactivar' : 'Activar',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red[300],
                  onPressed: () => _deleteUser(empleado),
                  tooltip: 'Eliminar',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    return '$day/$month/$year';
  }

  /// Genera un UUID v4
  String _generateUuid() {
    final random = Random();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    
    // Establecer la versión (4) y la variante
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // Versión 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variante 10
    
    // Convertir a formato UUID: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }
}

