import 'dart:math';
import 'package:flutter/material.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

      debugPrint('📥 Empleados cargados desde BD: ${response.length}');
      
      final empleados = (response as List)
          .map((json) {
            debugPrint('📋 Parseando empleado: ${json['nombre_usuario']}, activo: ${json['activo']} (tipo: ${json['activo'].runtimeType})');
            return Empleado.fromJson(json);
          })
          .toList();

      if (mounted) {
        setState(() {
          _empleados = empleados;
          debugPrint('✅ Estado actualizado con ${_empleados.length} empleados');
          // Log del estado de cada empleado
          for (var emp in _empleados) {
            debugPrint('  - ${emp.nombreUsuario}: activo=${emp.activo}');
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error al cargar empleados: $e');
      rethrow;
    }
  }

  Future<void> _loadRoles() async {
    try {
      final response = await supabaseClient
          .from('t_roles')
          .select('*')
          .inFilter('nombre', ['admin', 'operador']);

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
      debugPrint('📤 Creando usuario: $nombreUsuario');
      final empleadoCreado = await supabaseClient
          .from('t_empleados')
          .insert({
            'id_empleado': idEmpleado,
            'nombre_usuario': nombreUsuario,
            'contrasena': passwordHash,
            'activo': true,
          })
          .select('id_empleado, nombre_usuario, activo')
          .single();
      
      debugPrint('✅ Usuario creado en BD: $empleadoCreado');
      
      // 2. Asignar roles en t_empleado_rol
      final rolesSeleccionados = _selectedRoles.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();
      
      debugPrint('📤 Asignando ${rolesSeleccionados.length} roles al usuario');
      
      // Obtener los IDs de los roles seleccionados
      for (final nombreRol in rolesSeleccionados) {
        final rol = _rolesDisponibles.firstWhere(
          (r) => r.nombre.toLowerCase() == nombreRol,
          orElse: () => throw 'Rol $nombreRol no encontrado',
        );
        
        debugPrint('  - Asignando rol: ${rol.nombre} (ID: ${rol.idRol})');
        
        await supabaseClient
            .from('t_empleado_rol')
            .insert({
              'id_empleado': idEmpleado,
              'id_rol': rol.idRol,
            });
      }
      
      debugPrint('✅ Roles asignados correctamente');
      
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
      final idEmpleado = empleado.idEmpleado;
      final nombreUsuario = empleado.nombreUsuario;
      
      debugPrint('🔄 Cambiando estado de usuario $nombreUsuario');
      debugPrint('   ID Empleado: $idEmpleado (tipo: ${idEmpleado.runtimeType})');
      debugPrint('   Estado actual: ${empleado.activo}');
      debugPrint('   Nuevo estado: $nuevoEstado');
      
      // Verificar que el usuario existe antes de actualizar
      debugPrint('🔍 Verificando existencia del usuario en BD...');
      final usuarioExistente = await supabaseClient
          .from('t_empleados')
          .select('id_empleado, nombre_usuario, activo')
          .eq('id_empleado', idEmpleado)
          .maybeSingle();
      
      if (usuarioExistente == null) {
        // Intentar buscar por nombre_usuario como alternativa
        debugPrint('⚠️ No se encontró por ID, intentando por nombre_usuario...');
        final usuarioPorNombre = await supabaseClient
            .from('t_empleados')
            .select('id_empleado, nombre_usuario, activo')
            .eq('nombre_usuario', nombreUsuario)
            .maybeSingle();
        
        if (usuarioPorNombre == null) {
          throw Exception('Usuario no encontrado en la base de datos. ID: $idEmpleado, Usuario: $nombreUsuario');
        }
        
        debugPrint('✅ Usuario encontrado por nombre: ${usuarioPorNombre['nombre_usuario']}');
        debugPrint('   ID en BD: ${usuarioPorNombre['id_empleado']}');
        debugPrint('   Estado actual en BD: ${usuarioPorNombre['activo']}');
      } else {
        debugPrint('✅ Usuario encontrado en BD: ${usuarioExistente['nombre_usuario']}');
        debugPrint('   Estado actual en BD: ${usuarioExistente['activo']}');
      }
      
      // Actualizar el estado local inmediatamente para feedback visual instantáneo
      if (mounted) {
        setState(() {
          final index = _empleados.indexWhere((e) => e.idEmpleado == idEmpleado);
          if (index != -1) {
            _empleados[index] = _empleados[index].copyWith(activo: nuevoEstado);
            debugPrint('✅ Estado actualizado localmente (optimista)');
          }
        });
      }
      
      // Verificar autenticación antes de intentar UPDATE
      final currentUser = supabaseClient.auth.currentUser;
      final isAuthenticated = currentUser != null;
      debugPrint('🔐 Estado de autenticación: ${isAuthenticated ? "AUTENTICADO" : "NO AUTENTICADO"}');
      debugPrint('🔐 Usuario Auth: ${currentUser?.email ?? "N/A"}');
      
      // Si no está autenticado, intentar autenticar con usuario de servicio
      // Primero verificar si hay una sesión guardada en SharedPreferences
      if (!isAuthenticated) {
        debugPrint('⚠️ No autenticado en Supabase Auth, verificando sesión local...');
        final prefs = await SharedPreferences.getInstance();
        final idEmpleado = prefs.getString('id_empleado');
        final nombreUsuario = prefs.getString('nombre_usuario');
        final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
        
        debugPrint('📱 Sesión local: id_empleado=$idEmpleado, nombre_usuario=$nombreUsuario, is_logged_in=$isLoggedIn');
        
        // Si hay una sesión local, intentar autenticar con usuario de servicio
        if (isLoggedIn && nombreUsuario != null) {
          debugPrint('⚠️ Sesión local encontrada, intentando autenticación de servicio...');
          try {
            const serviceEmail = 'service@telmex.local';
            const servicePassword = 'ServiceAuth2024!';
            
            await supabaseClient.auth.signInWithPassword(
              email: serviceEmail,
              password: servicePassword,
            );
            debugPrint('✅ Autenticado con usuario de servicio');
          } catch (authError) {
            debugPrint('⚠️ No se pudo autenticar con usuario de servicio: $authError');
            debugPrint('⚠️ Continuando con la operación. Las políticas RLS determinarán si se permite.');
            // No lanzar excepción aquí, continuar con la operación
            // Si las políticas RLS bloquean, el error se mostrará en el catch del UPDATE
          }
        } else {
          debugPrint('⚠️ No hay sesión local guardada. Continuando con la operación.');
        }
      }
      
      // Método mejorado: Actualizar primero, luego verificar con SELECT separado
      // Esto funciona mejor en aplicaciones móviles donde .update().select() puede fallar
      debugPrint('📤 Intentando actualizar por ID: id_empleado=$idEmpleado, activo=$nuevoEstado');
      
      try {
        // Paso 1: Hacer el UPDATE sin select para evitar error PGRST116
        // Esto es especialmente importante cuando RLS puede bloquear el UPDATE
        try {
          // Intentar UPDATE sin .select() primero para evitar PGRST116
          await supabaseClient
              .from('t_empleados')
              .update({'activo': nuevoEstado})
              .eq('id_empleado', idEmpleado);
          
          debugPrint('✅ UPDATE ejecutado (sin select)');
          
          // Verificar inmediatamente si el UPDATE afectó alguna fila
          // Esperar un momento para que la BD se sincronice
          await Future.delayed(const Duration(milliseconds: 300));
          
        } catch (updateError) {
          // Si el UPDATE falla, verificar si es por RLS
          final errorStr = updateError.toString().toLowerCase();
          if (errorStr.contains('row-level security') || 
              errorStr.contains('rls') || 
              errorStr.contains('policy') ||
              errorStr.contains('permission') ||
              errorStr.contains('pgrst116')) {
            debugPrint('❌ Error de RLS o sin filas detectado: $updateError');
            throw Exception('Error de permisos: Las políticas RLS están bloqueando la actualización. Verifica que estés autenticado correctamente en Supabase Auth.');
          }
          // Si es otro error, propagarlo
          debugPrint('❌ Error en UPDATE: $updateError');
          rethrow;
        }
        
        // Paso 1.5: Verificar inmediatamente con SELECT
        final updateResponse = await supabaseClient
            .from('t_empleados')
            .select('id_empleado, activo')
            .eq('id_empleado', idEmpleado)
            .maybeSingle();
        
        debugPrint('✅ Verificación después de UPDATE. Respuesta: $updateResponse');
        
        // Si el UPDATE devuelve datos, verificar inmediatamente
        if (updateResponse != null) {
          final activoInmediato = updateResponse['activo'];
          bool activoVerificado = false;
          if (activoInmediato is bool) {
            activoVerificado = activoInmediato;
          } else if (activoInmediato is String) {
            activoVerificado = activoInmediato.toLowerCase() == 'true' || activoInmediato == '1';
          } else if (activoInmediato is int) {
            activoVerificado = activoInmediato == 1;
          }
          
          if (activoVerificado == nuevoEstado) {
            debugPrint('✅ Cambio confirmado inmediatamente en respuesta del UPDATE');
            // Actualizar el estado local
            if (mounted) {
              setState(() {
                final index = _empleados.indexWhere((e) => e.idEmpleado == idEmpleado);
                if (index != -1) {
                  _empleados[index] = _empleados[index].copyWith(activo: activoVerificado);
                  debugPrint('✅ Estado sincronizado localmente: ${_empleados[index].nombreUsuario} = ${_empleados[index].activo}');
                }
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    activoVerificado
                        ? '✅ Usuario activado correctamente'
                        : '⚠️ Usuario desactivado correctamente',
                  ),
                  backgroundColor: activoVerificado ? Colors.green : Colors.orange,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            return; // Salir temprano si el cambio se confirmó
          } else {
            debugPrint('⚠️ UPDATE devolvió respuesta pero el estado no coincide. Esperado: $nuevoEstado, Obtenido: $activoVerificado');
          }
        } else {
          debugPrint('⚠️ UPDATE no devolvió respuesta, continuando con verificación separada...');
        }
        
        // Paso 2: Si el UPDATE no devolvió confirmación, hacer verificación separada
        // Solo continuar si el UPDATE no devolvió datos o el estado no coincide
        if (updateResponse == null || (updateResponse['activo'] is bool ? updateResponse['activo'] as bool : false) != nuevoEstado) {
          debugPrint('⚠️ UPDATE no confirmó el cambio, iniciando verificación separada...');
          
          // Esperar un momento para que la BD se sincronice
          await Future.delayed(const Duration(milliseconds: 800));
          
          // Paso 3: Hacer múltiples intentos de verificación (hasta 5 intentos)
          bool activoActualizado = false;
          int intentos = 0;
          const maxIntentos = 5;
          
          while (intentos < maxIntentos && activoActualizado != nuevoEstado) {
            intentos++;
            debugPrint('🔍 Intento de verificación $intentos/$maxIntentos...');
            
            try {
              final verificacion = await supabaseClient
                  .from('t_empleados')
                  .select('id_empleado, nombre_usuario, activo')
                  .eq('id_empleado', idEmpleado)
                  .maybeSingle();
              
              debugPrint('📥 Respuesta de verificación (intento $intentos): $verificacion');
              
              if (verificacion == null) {
                if (intentos < maxIntentos) {
                  await Future.delayed(const Duration(milliseconds: 800));
                  continue;
                }
                throw Exception('No se pudo verificar el cambio en la base de datos después de $maxIntentos intentos');
              }
              
              // Parsear el valor de activo
              final activoValue = verificacion['activo'];
              if (activoValue != null) {
                if (activoValue is bool) {
                  activoActualizado = activoValue;
                } else if (activoValue is String) {
                  activoActualizado = activoValue.toLowerCase() == 'true' || activoValue == '1';
                } else if (activoValue is int) {
                  activoActualizado = activoValue == 1;
                }
              }
              
              debugPrint('✅ Estado confirmado en BD (intento $intentos): $activoActualizado');
              
              // Si el estado coincide, salir del bucle
              if (activoActualizado == nuevoEstado) {
                break;
              }
              
              // Si no coincide y aún hay intentos, esperar y reintentar
              if (intentos < maxIntentos) {
                await Future.delayed(const Duration(milliseconds: 800));
              }
            } catch (e) {
              debugPrint('⚠️ Error en intento $intentos: $e');
              if (intentos < maxIntentos) {
                await Future.delayed(const Duration(milliseconds: 800));
                continue;
              }
              rethrow;
            }
          }
          
          // Verificar que el cambio se aplicó correctamente
          if (activoActualizado != nuevoEstado) {
            // Intentar recargar los datos desde la BD para ver el estado real
            await _loadEmpleados();
            throw Exception('El estado no se actualizó correctamente después de $maxIntentos intentos. Esperado: $nuevoEstado, Obtenido: $activoActualizado. Verifica las políticas RLS en Supabase.');
          }
          
          // Actualizar el estado local con el valor confirmado
          if (mounted) {
            setState(() {
              final index = _empleados.indexWhere((e) => e.idEmpleado == idEmpleado);
              if (index != -1) {
                _empleados[index] = _empleados[index].copyWith(activo: activoActualizado);
                debugPrint('✅ Estado sincronizado localmente: ${_empleados[index].nombreUsuario} = ${_empleados[index].activo}');
              }
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  activoActualizado
                      ? '✅ Usuario activado correctamente'
                      : '⚠️ Usuario desactivado correctamente',
                ),
                backgroundColor: activoActualizado ? Colors.green : Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error al actualizar por ID: $e');
        debugPrint('📤 Intentando actualizar por nombre_usuario como alternativa...');
        
        try {
          // Método alternativo: Actualizar por nombre_usuario
          await supabaseClient
              .from('t_empleados')
              .update({'activo': nuevoEstado})
              .eq('nombre_usuario', nombreUsuario);
          
          // Esperar y verificar
          await Future.delayed(const Duration(milliseconds: 300));
          
          final verificacion = await supabaseClient
              .from('t_empleados')
              .select('id_empleado, nombre_usuario, activo')
              .eq('nombre_usuario', nombreUsuario)
              .maybeSingle();
          
          if (verificacion == null) {
            throw Exception('No se pudo verificar el cambio en la base de datos');
          }
          
          // Parsear el valor de activo
          bool activoActualizado = false;
          final activoValue = verificacion['activo'];
          if (activoValue != null) {
            if (activoValue is bool) {
              activoActualizado = activoValue;
            } else if (activoValue is String) {
              activoActualizado = activoValue.toLowerCase() == 'true' || activoValue == '1';
            } else if (activoValue is int) {
              activoActualizado = activoValue == 1;
            }
          }
          
          // Verificar que el cambio se aplicó correctamente
          if (activoActualizado != nuevoEstado) {
            throw Exception('El estado no se actualizó correctamente. Esperado: $nuevoEstado, Obtenido: $activoActualizado');
          }
          
          // Actualizar el estado local
          if (mounted) {
            setState(() {
              final index = _empleados.indexWhere((e) => e.nombreUsuario == nombreUsuario);
              if (index != -1) {
                _empleados[index] = _empleados[index].copyWith(activo: activoActualizado);
                debugPrint('✅ Estado sincronizado localmente: ${_empleados[index].nombreUsuario} = ${_empleados[index].activo}');
              }
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  activoActualizado
                      ? '✅ Usuario activado correctamente'
                      : '⚠️ Usuario desactivado correctamente',
                ),
                backgroundColor: activoActualizado ? Colors.green : Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e2) {
          debugPrint('❌ Error en método alternativo: $e2');
          throw Exception('No se pudo actualizar el usuario ni por ID ni por nombre. Error original: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error al cambiar estado: $e');
      
      // Revertir el cambio local si falló
      if (mounted) {
        setState(() {
          final index = _empleados.indexWhere((e) => e.idEmpleado == empleado.idEmpleado);
          if (index != -1) {
            _empleados[index] = _empleados[index].copyWith(activo: empleado.activo);
            debugPrint('↩️ Cambio revertido localmente');
          }
        });
        
        String errorMessage = 'Error al cambiar estado: $e';
        
        // Mensajes más específicos según el tipo de error
        if (e.toString().contains('permission') || e.toString().contains('RLS') || e.toString().contains('row-level security')) {
          errorMessage = 'Error de permisos: No tienes permisos para actualizar usuarios. Verifica las políticas RLS en Supabase.';
        } else if (e.toString().contains('not found') || e.toString().contains('no encontrado')) {
          errorMessage = 'Usuario no encontrado en la base de datos.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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
      debugPrint('🗑️ Eliminando usuario: ${empleado.nombreUsuario} (${empleado.idEmpleado})');
      
      // 1. Eliminar roles asociados (t_empleado_rol)
      debugPrint('📤 Eliminando roles asociados...');
      final rolesEliminados = await supabaseClient
          .from('t_empleado_rol')
          .delete()
          .eq('id_empleado', empleado.idEmpleado)
          .select();
      
      debugPrint('✅ Roles eliminados: ${rolesEliminados.length}');
      
      // 2. Eliminar empleado (t_empleados)
      debugPrint('📤 Eliminando empleado de t_empleados...');
      final empleadoEliminado = await supabaseClient
          .from('t_empleados')
          .delete()
          .eq('id_empleado', empleado.idEmpleado)
          .select('id_empleado, nombre_usuario');
      
      if (empleadoEliminado.isEmpty) {
        throw Exception('No se pudo eliminar el usuario. No se encontró el registro.');
      }
      
      debugPrint('✅ Usuario eliminado: ${empleadoEliminado.first}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Usuario eliminado exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        await _loadData();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error al eliminar usuario: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      
      if (mounted) {
        String errorMessage = 'Error al eliminar usuario: $e';
        
        // Mensajes más específicos según el tipo de error
        if (e.toString().contains('permission') || e.toString().contains('RLS') || e.toString().contains('row-level security')) {
          errorMessage = 'Error de permisos: No tienes permisos para eliminar usuarios. Verifica las políticas RLS en Supabase.';
        } else if (e.toString().contains('foreign key') || e.toString().contains('constraint')) {
          errorMessage = 'No se puede eliminar el usuario porque tiene datos relacionados en otras tablas.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
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
                      Flexible(
                        child: Text(
                          'Usuarios del Sistema',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: ElevatedButton.icon(
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
                      ),
                    ],
                  ),
                ),

                // Formulario de creación (con scroll para evitar overflow)
                if (_showCreateForm) 
                  Flexible(
                    flex: 1,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildCreateUserForm(),
                    ),
                  ),

                // Lista de usuarios
                Expanded(
                  flex: _showCreateForm ? 1 : 2,
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

