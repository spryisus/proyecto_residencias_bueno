import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import '../../app/config/supabase_client.dart' show supabaseClient;
import '../../data/services/computo_export_service.dart';
import '../../domain/entities/inventory_session.dart';
import '../../data/local/inventory_session_storage.dart';
import '../../core/di/injection_container.dart';

class InventarioComputoScreen extends StatefulWidget {
  const InventarioComputoScreen({super.key});

  @override
  State<InventarioComputoScreen> createState() => _InventarioComputoScreenState();
}

class _InventarioComputoScreenState extends State<InventarioComputoScreen> {
  final InventorySessionStorage _sessionStorage = serviceLocator.get<InventorySessionStorage>();
  // GlobalKey para ScaffoldMessenger - SOLUCIÓN DEFINITIVA
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  
  List<Map<String, dynamic>> _equipos = [];
  List<Map<String, dynamic>> _equiposFiltrados = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _modoInventario = false;
  Set<String> _equiposCompletados = {}; // Set de inventarios completados
  String? _pendingSessionId; // ID de la sesión pendiente actual
  InventorySession? _pendingSession; // Sesión pendiente completa
  bool _isAdmin = false; // Permisos de administrador
  
  // Opciones de filtros (agrupación y vista de grid eliminadas)
  String? _filtroUbicacion;
  String? _filtroStatus;
  String? _filtroEmpleado;
  bool _mostrarFiltros = false;

  @override
  void initState() {
    super.initState();
    print('🚀 InventarioComputoScreen inicializada');
    _checkAdminStatus();
    _loadEquipos();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idEmpleado = prefs.getString('id_empleado');
      
      if (idEmpleado != null) {
        final roles = await supabaseClient
            .from('t_empleado_rol')
            .select('t_roles!inner(nombre)')
            .eq('id_empleado', idEmpleado);
        
        final isAdmin = roles.any((rol) => 
            rol['t_roles']['nombre']?.toString().toLowerCase() == 'admin');
        
        if (mounted) {
          setState(() {
            _isAdmin = isAdmin;
          });
        }
      }
    } catch (e) {
      debugPrint('Error al verificar rol de admin: $e');
      if (mounted) {
        setState(() {
          _isAdmin = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper para llamadas seguras a Supabase que evita errores cuando el widget está desmontado
  // SOLUCIÓN RADICAL: Ignorar COMPLETAMENTE todos los errores si el widget está desmontado
  // NO re-lanzar errores para evitar que el error handler interno de Supabase use context
  Future<T?> _safeSupabaseCall<T>(Future<T> Function() call) async {
    if (!mounted) return null;
    
    try {
      final result = await call();
      if (!mounted) return null;
      return result;
    } catch (e) {
      // SIEMPRE ignorar el error si el widget está desmontado
      // NO re-lanzar, NO hacer nada, solo retornar null
      if (!mounted) {
        // No hacer debugPrint para evitar cualquier uso de context
        return null;
      }
      // Si el widget sigue montado, también ignorar el error para evitar
      // que el error handler interno de Supabase intente usar context
      // En lugar de re-lanzar, simplemente retornar null
      debugPrint('Error de Supabase (ignorado para evitar uso de context): $e');
      return null;
    }
  }

  Future<void> _loadEquipos() async {
    if (!mounted) return;
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('🔄 Iniciando carga de equipos de cómputo...');

      // Cargar equipos de cómputo desde la vista completa que incluye nombres de empleados
      final equiposResponse = await _safeSupabaseCall(() => 
        supabaseClient.from('v_equipos_computo_completo').select('*')
      );
      
      if (equiposResponse == null || !mounted) return;

      print('📦 Respuesta de Supabase recibida');
      
      // Ordenar manualmente si es necesario
      final equiposList = List<Map<String, dynamic>>.from(equiposResponse);
      equiposList.sort((a, b) {
        final invA = (a['inventario'] ?? '').toString();
        final invB = (b['inventario'] ?? '').toString();
        return invA.compareTo(invB);
      });
      
      final equipos = equiposList;
      
      print('✅ Equipos cargados: ${equipos.length}');
      
      if (equipos.isEmpty) {
        print('⚠️ No se encontraron equipos en la base de datos');
      } else {
        print('📋 Primer equipo: ${equipos.first['inventario']}');
        // Debug: mostrar campos disponibles en el primer equipo
        print('🔍 Campos disponibles: ${equipos.first.keys.toList()}');
        // Debug: verificar datos de ubicación y usuario final
        final primerEquipo = equipos.first;
        print('📍 Ubicación - direccion_fisica: ${primerEquipo['direccion_fisica']}');
        print('📍 Ubicación - estado_ubicacion: ${primerEquipo['estado_ubicacion']}');
        print('📍 Ubicación - ciudad: ${primerEquipo['ciudad']}');
        print('👤 Usuario Final - nombre_final: ${primerEquipo['nombre_final']}');
        print('👤 Usuario Final - empleado_asignado_nombre: ${primerEquipo['empleado_asignado_nombre']}');
        print('👤 Usuario Final - expediente_final: ${primerEquipo['expediente_final']}');
      }
      
      // Cargar componentes y obtener nombres de empleados desde la vista
      for (var equipo in equipos) {
        // Verificar si el widget sigue montado antes de continuar
        if (!mounted) {
          return; // Salir si el widget se desmontó
        }
        
        try {
          // Intentar cargar componentes desde la vista completa
          // La relación es por inventario_equipo (inventario del equipo, no del componente)
          final inventarioEquipo = equipo['inventario']?.toString() ?? '';
          final idEquipoComputo = equipo['id_equipo_computo'];
          
          if (idEquipoComputo != null) {
            try {
              // Cargar accesorios desde t_accesorios_equipos
              final accesoriosResponse = await _safeSupabaseCall(() => 
                supabaseClient
                    .from('t_accesorios_equipos')
                    .select('*')
                    .eq('id_equipo_computo', idEquipoComputo)
              );
              
              if (accesoriosResponse != null && mounted) {
                // Convertir accesorios al formato esperado
                equipo['t_componentes_computo'] = (accesoriosResponse as List).map((accesorio) {
                  return {
                    'tipo_componente': accesorio['tipo_equipo'] ?? 'Accesorio',
                    'marca': accesorio['marca'],
                    'modelo': accesorio['modelo'],
                    'numero_serie': accesorio['numero_serie'],
                    'inventario': accesorio['inventario'],
                  };
                }).toList();
                print('✅ Accesorios cargados para equipo ${idEquipoComputo}: ${equipo['t_componentes_computo'].length}');
              } else {
                equipo['t_componentes_computo'] = [];
              }
            } catch (e) {
              if (!mounted) return;
              debugPrint('Error al cargar accesorios para ${inventarioEquipo}: $e');
                  equipo['t_componentes_computo'] = [];
            }
          } else {
            equipo['t_componentes_computo'] = [];
          }
          
          // Usar el nombre completo del usuario final de la vista si existe, sino construirlo
          String nombreCompletoFinal = equipo['empleado_asignado_nombre']?.toString() ?? '';
          if (nombreCompletoFinal.isEmpty) {
            // Si la vista no lo tiene, construirlo desde los campos individuales
            final nombreFinal = equipo['nombre_final']?.toString() ?? '';
            final apellidoPaternoFinal = equipo['apellido_paterno_final']?.toString() ?? '';
            final apellidoMaternoFinal = equipo['apellido_materno_final']?.toString() ?? '';
            
            if (nombreFinal.isNotEmpty || apellidoPaternoFinal.isNotEmpty || apellidoMaternoFinal.isNotEmpty) {
              final partes = [
                nombreFinal,
                apellidoPaternoFinal,
                apellidoMaternoFinal
              ].where((p) => p.isNotEmpty).toList();
              nombreCompletoFinal = partes.join(' ');
            }
          }
          equipo['empleado_asignado_nombre'] = nombreCompletoFinal;
          
          // Construir nombre completo del usuario responsable desde los campos de la vista
          final nombreResponsable = equipo['nombre_responsable']?.toString() ?? '';
          final apellidoPaternoResponsable = equipo['apellido_paterno_responsable']?.toString() ?? '';
          final apellidoMaternoResponsable = equipo['apellido_materno_responsable']?.toString() ?? '';
          
          String nombreCompletoResponsable = '';
          if (nombreResponsable.isNotEmpty || apellidoPaternoResponsable.isNotEmpty || apellidoMaternoResponsable.isNotEmpty) {
            final partes = [
              nombreResponsable,
              apellidoPaternoResponsable,
              apellidoMaternoResponsable
            ].where((p) => p.isNotEmpty).toList();
            nombreCompletoResponsable = partes.join(' ');
          }
          equipo['empleado_responsable_nombre'] = nombreCompletoResponsable;
        } catch (e) {
          if (!mounted) return; // Verificar después de error
          
          // Si no hay componentes o falla, dejar lista vacía (no es crítico)
          equipo['t_componentes_computo'] = [];
          debugPrint('Error al cargar componentes para ${equipo['inventario']}: $e');
        }
      }

      if (mounted) {
        setState(() {
          _equipos = equipos;
          _equiposFiltrados = equipos;
          _isLoading = false;
        });
        
        print('✅ Total equipos procesados y mostrados: ${_equipos.length}');
      }
    } catch (e, stackTrace) {
      print('❌ Error al cargar equipos: $e');
      print('📚 Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _error = 'Error al cargar equipos: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _filterEquipos(String query) {
    setState(() {
      _searchQuery = query.toLowerCase().trim();
      _aplicarFiltros();
    });
  }

  void _aplicarFiltros() {
    List<Map<String, dynamic>> equiposFiltrados = List.from(_equipos);

    // Aplicar búsqueda de texto
    if (_searchQuery.isNotEmpty) {
      equiposFiltrados = equiposFiltrados.where((equipo) {
        try {
          final inventario = (equipo['inventario'] ?? '').toString().toLowerCase();
          final marca = (equipo['marca'] ?? '').toString().toLowerCase();
          final modelo = (equipo['modelo'] ?? '').toString().toLowerCase();
          final numeroSerie = (equipo['numero_serie'] ?? '').toString().toLowerCase();
          final ubicacionFisica = (equipo['ubicacion_fisica'] ?? '').toString().toLowerCase();
          final empleadoAsignado = ((equipo['empleado_asignado_nombre']?.toString() ?? equipo['empleado_asignado']?.toString() ?? '')).toLowerCase();
          
          return (inventario.isNotEmpty && inventario.contains(_searchQuery)) ||
                 (marca.isNotEmpty && marca.contains(_searchQuery)) ||
                 (modelo.isNotEmpty && modelo.contains(_searchQuery)) ||
                 (numeroSerie.isNotEmpty && numeroSerie.contains(_searchQuery)) ||
                 (ubicacionFisica.isNotEmpty && ubicacionFisica.contains(_searchQuery)) ||
                 (empleadoAsignado.isNotEmpty && empleadoAsignado.contains(_searchQuery));
        } catch (e) {
          debugPrint('Error al filtrar equipo: $e');
          return false;
        }
      }).toList();
    }

    // Aplicar filtros avanzados
    if (_filtroUbicacion != null && _filtroUbicacion!.isNotEmpty) {
      equiposFiltrados = equiposFiltrados.where((equipo) {
        return (equipo['ubicacion_fisica']?.toString() ?? '').trim() == _filtroUbicacion;
      }).toList();
    }

    if (_filtroStatus != null && _filtroStatus!.isNotEmpty) {
      equiposFiltrados = equiposFiltrados.where((equipo) {
        return (equipo['status']?.toString() ?? '').trim() == _filtroStatus;
      }).toList();
    }

    if (_filtroEmpleado != null && _filtroEmpleado!.isNotEmpty) {
      equiposFiltrados = equiposFiltrados.where((equipo) {
        final nombreEmpleado = (equipo['empleado_asignado_nombre']?.toString() ?? equipo['empleado_asignado']?.toString() ?? '').trim();
        return nombreEmpleado == _filtroEmpleado;
      }).toList();
    }

    setState(() {
      _equiposFiltrados = equiposFiltrados;
    });
  }

  // Obtener valores únicos para filtros
  List<String> _obtenerUbicacionesUnicas() {
    final ubicaciones = _equipos
        .map((e) => (e['ubicacion_fisica']?.toString() ?? '').trim())
        .where((u) => u.isNotEmpty)
        .toSet()
        .toList();
    ubicaciones.sort();
    return ubicaciones;
  }

  List<String> _obtenerStatusUnicos() {
    final status = _equipos
        .map((e) => (e['status']?.toString() ?? '').trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    status.sort();
    return status;
  }

  List<String> _obtenerEmpleadosUnicos() {
    final empleados = _equipos
        .map((e) => (e['empleado_asignado_nombre']?.toString() ?? e['empleado_asignado']?.toString() ?? '').trim())
        .where((emp) => emp.isNotEmpty)
        .toSet()
        .toList();
    empleados.sort();
    return empleados;
  }

  // Agrupar equipos
  Map<String, List<Map<String, dynamic>>> _agruparEquipos() {
    // Siempre sin agrupación - función simplificada
    return {'Todos': _equiposFiltrados};
  }

  Future<void> _exportarInventario() async {
    if (_equiposFiltrados.isEmpty) {
      if (mounted && _scaffoldMessengerKey.currentState != null) {
        _scaffoldMessengerKey.currentState!.showSnackBar(
          const SnackBar(
            content: Text('No hay equipos para exportar'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Guardar messenger ANTES de operaciones asíncronas (SOLUCIÓN 2)
    if (!mounted || _scaffoldMessengerKey.currentState == null) return;

    try {
      // Preparar datos para exportación: equipo principal + accesorios como filas separadas
      final itemsToExport = <Map<String, dynamic>>[];
      
      for (var equipo in _equiposFiltrados) {
        final idEquipoComputo = equipo['id_equipo_computo'];
        final equipoPm = equipo['equipo_pm']?.toString() ?? '';
        final inventarioPrincipal = equipo['inventario']?.toString() ?? '';
        
        // Debug: Verificar datos de ubicación y usuario final antes de exportar
        if (itemsToExport.isEmpty) {
          print('🔍 DEBUG EXPORT - Primer equipo antes de exportar:');
          print('  📍 direccion_fisica: ${equipo['direccion_fisica']}');
          print('  📍 estado_ubicacion: ${equipo['estado_ubicacion']}');
          print('  📍 ciudad: ${equipo['ciudad']}');
          print('  📍 tipo_edificio: ${equipo['tipo_edificio']}');
          print('  📍 nombre_edificio: ${equipo['nombre_edificio']}');
          print('  👤 nombre_final: ${equipo['nombre_final']}');
          print('  👤 apellido_paterno_final: ${equipo['apellido_paterno_final']}');
          print('  👤 apellido_materno_final: ${equipo['apellido_materno_final']}');
          print('  👤 empleado_asignado_nombre: ${equipo['empleado_asignado_nombre']}');
          print('  👤 expediente_final: ${equipo['expediente_final']}');
          print('  👤 empresa_final: ${equipo['empresa_final']}');
          print('  👤 puesto_final: ${equipo['puesto_final']}');
          print('  📋 TODOS LOS CAMPOS DEL EQUIPO: ${equipo.keys.toList()}');
          print('  📋 VALORES COMPLETOS: $equipo');
        }
        
        // 1. Agregar el equipo principal como primera fila con TODOS los campos
        itemsToExport.add({
          'id': idEquipoComputo,
          'inventario': inventarioPrincipal,
          'equipo_pm': equipoPm,
          'fecha_registro': equipo['fecha_registro']?.toString() ?? '',
          'tipo_equipo': equipo['tipo_equipo']?.toString() ?? '',
          'marca': equipo['marca']?.toString() ?? '',
          'modelo': equipo['modelo']?.toString() ?? '',
          'procesador': equipo['procesador']?.toString() ?? '',
          'numero_serie': equipo['numero_serie']?.toString() ?? '',
          'disco_duro': equipo['disco_duro']?.toString() ?? '',
          'memoria': equipo['memoria_ram']?.toString() ?? equipo['memoria']?.toString() ?? '',
          'sistema_operativo_instalado': equipo['sistema_operativo_instalado']?.toString() ?? equipo['sistema_operativo']?.toString() ?? '',
          'etiqueta_sistema_operativo': equipo['etiqueta_sistema_operativo']?.toString() ?? '',
          'office_instalado': equipo['office_instalado']?.toString() ?? '',
          'direccion_fisica': equipo['direccion_fisica']?.toString() ?? equipo['ubicacion_fisica']?.toString() ?? '',
          'estado': equipo['estado_ubicacion']?.toString() ?? '',
          'ciudad': equipo['ciudad']?.toString() ?? '',
          'tipo_edificio': equipo['tipo_edificio']?.toString() ?? '',
          'nombre_edificio': equipo['nombre_edificio']?.toString() ?? '',
          'tipo_uso': equipo['tipo_uso']?.toString() ?? '',
          'nombre_equipo_dominio': equipo['nombre_equipo_dominio']?.toString() ?? '',
          'status': equipo['status']?.toString() ?? '',
          'direccion_administrativa': equipo['direccion_administrativa']?.toString() ?? '',
          'subdireccion': equipo['subdireccion']?.toString() ?? '',
          'gerencia': equipo['gerencia']?.toString() ?? '',
          // Usuario Final
          'expediente_final': equipo['expediente_final']?.toString() ?? '',
          'nombre_completo_final': equipo['empleado_asignado_nombre']?.toString() ?? '',
          'apellido_paterno_final': equipo['apellido_paterno_final']?.toString() ?? '',
          'apellido_materno_final': equipo['apellido_materno_final']?.toString() ?? '',
          'nombre_final': equipo['nombre_final']?.toString() ?? '',
          'empresa_final': equipo['empresa_final']?.toString() ?? '',
          'puesto_final': equipo['puesto_final']?.toString() ?? '',
          // Usuario Responsable
          'expediente_responsable': equipo['expediente_responsable']?.toString() ?? '',
          'nombre_completo_responsable': '${equipo['nombre_responsable'] ?? ''} ${equipo['apellido_paterno_responsable'] ?? ''} ${equipo['apellido_materno_responsable'] ?? ''}'.trim(),
          'apellido_paterno_responsable': equipo['apellido_paterno_responsable']?.toString() ?? '',
          'apellido_materno_responsable': equipo['apellido_materno_responsable']?.toString() ?? '',
          'nombre_responsable': equipo['nombre_responsable']?.toString() ?? '',
          'empresa_responsable': equipo['empresa_responsable']?.toString() ?? '',
          'puesto_responsable': equipo['puesto_responsable']?.toString() ?? '',
          'observaciones': equipo['observaciones']?.toString() ?? '',
        });
        
        // 2. Agregar cada accesorio como una fila separada con el mismo ID y EQUIPO PM
        final accesorios = equipo['t_componentes_computo'] as List<dynamic>? ?? [];
        for (var accesorio in accesorios) {
          itemsToExport.add({
            'id': idEquipoComputo, // Mismo ID que el equipo principal
            'inventario': accesorio['inventario']?.toString() ?? 'S/N',
            'equipo_pm': equipoPm, // Mismo EQUIPO PM
            'fecha_registro': accesorio['fecha_registro']?.toString() ?? equipo['fecha_registro']?.toString() ?? '',
            'tipo_equipo': accesorio['tipo_componente']?.toString().toUpperCase() ?? accesorio['tipo_equipo']?.toString().toUpperCase() ?? '',
            'marca': accesorio['marca']?.toString() ?? '',
            'modelo': accesorio['modelo']?.toString() ?? '',
            'procesador': '', // Los accesorios no tienen procesador
            'numero_serie': accesorio['numero_serie']?.toString() ?? '',
            'disco_duro': '', // Los accesorios no tienen disco duro
            'memoria': '', // Los accesorios no tienen memoria
            'sistema_operativo_instalado': '', // Los accesorios no tienen SO
            'etiqueta_sistema_operativo': '', // Los accesorios no tienen etiqueta SO
            'office_instalado': '', // Los accesorios no tienen Office
            'direccion_fisica': equipo['direccion_fisica']?.toString() ?? equipo['ubicacion_fisica']?.toString() ?? '',
            'estado': equipo['estado_ubicacion']?.toString() ?? '',
            'ciudad': equipo['ciudad']?.toString() ?? '',
            'tipo_edificio': equipo['tipo_edificio']?.toString() ?? '',
            'nombre_edificio': equipo['nombre_edificio']?.toString() ?? '',
            'tipo_uso': equipo['tipo_uso']?.toString() ?? '',
            'nombre_equipo_dominio': equipo['nombre_equipo_dominio']?.toString() ?? '',
            'status': equipo['status']?.toString() ?? '',
            'direccion_administrativa': equipo['direccion_administrativa']?.toString() ?? '',
            'subdireccion': equipo['subdireccion']?.toString() ?? '',
            'gerencia': equipo['gerencia']?.toString() ?? '',
            // Usuario Final (mismo que el equipo principal)
            'expediente_final': equipo['expediente_final']?.toString() ?? '',
            'nombre_completo_final': equipo['empleado_asignado_nombre']?.toString() ?? '',
            'apellido_paterno_final': equipo['apellido_paterno_final']?.toString() ?? '',
            'apellido_materno_final': equipo['apellido_materno_final']?.toString() ?? '',
            'nombre_final': equipo['nombre_final']?.toString() ?? '',
            'empresa_final': equipo['empresa_final']?.toString() ?? '',
            'puesto_final': equipo['puesto_final']?.toString() ?? '',
            // Usuario Responsable (mismo que el equipo principal)
            'expediente_responsable': equipo['expediente_responsable']?.toString() ?? '',
            'nombre_completo_responsable': '${equipo['nombre_responsable'] ?? ''} ${equipo['apellido_paterno_responsable'] ?? ''} ${equipo['apellido_materno_responsable'] ?? ''}'.trim(),
            'apellido_paterno_responsable': equipo['apellido_paterno_responsable']?.toString() ?? '',
            'apellido_materno_responsable': equipo['apellido_materno_responsable']?.toString() ?? '',
            'nombre_responsable': equipo['nombre_responsable']?.toString() ?? '',
            'empresa_responsable': equipo['empresa_responsable']?.toString() ?? '',
            'puesto_responsable': equipo['puesto_responsable']?.toString() ?? '',
            'observaciones': accesorio['observaciones']?.toString() ?? '',
          });
        }
      }

      final filePath = await ComputoExportService.exportComputoToExcel(itemsToExport);

      if (filePath != null && mounted && _scaffoldMessengerKey.currentState != null) {
        _scaffoldMessengerKey.currentState!.showSnackBar(
          SnackBar(
            content: Text('Inventario exportado: $filePath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted && _scaffoldMessengerKey.currentState != null) {
        _scaffoldMessengerKey.currentState!.showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 InventarioComputoScreen build - Equipos: ${_equipos.length}, Filtrados: ${_equiposFiltrados.length}, Loading: $_isLoading');
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Inventario de Equipo de Cómputo',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        actions: [
          // Botón Agregar (verde como en la segunda imagen) - Solo para admins
          if (!_modoInventario && _isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton.icon(
                onPressed: _mostrarAgregarEquipoDialog,
                icon: const Icon(Icons.add, size: 20, color: Colors.white),
                label: const Text(
                  'Agregar',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
          if (!_modoInventario && _equiposFiltrados.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.file_download),
              tooltip: 'Exportar a Excel',
              onPressed: _exportarInventario,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _loadEquipos,
          ),
        ],
      ),
      floatingActionButton: !_modoInventario && _equiposFiltrados.isNotEmpty && !_isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                // DESHABILITADO: Cargar progreso guardado automáticamente
                // Esto causa errores con el error handler interno de Supabase
                // El usuario puede cargar el progreso manualmente si lo necesita
                // try {
                //   await _cargarProgresoInventario();
                // } catch (e) {
                //   debugPrint('Error al cargar progreso (ignorado): $e');
                // }
                if (mounted) {
                  setState(() {
                    _modoInventario = true;
                  });
                }
              },
              backgroundColor: const Color(0xFF003366),
              icon: const Icon(Icons.inventory_2, color: Colors.white),
              label: const Text(
                'Realizar Inventario',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: Column(
        children: [
          // Barra de búsqueda mejorada
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[50]!, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por inventario, marca, modelo, serie, ubicación o empleado...',
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF003366),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.search, color: Colors.white, size: 20),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _filterEquipos('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF003366), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              onChanged: _filterEquipos,
            ),
          ),

          // Mensaje de reanudación de inventario pendiente
          if (_pendingSession != null && _modoInventario) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.playlist_add_check_circle, color: Theme.of(context).colorScheme.tertiary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reanudando inventario guardado el ${_formatSessionDate(_pendingSession!.updatedAt)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (_pendingSession != null) {
                        await _sessionStorage.deleteSession(_pendingSession!.id);
                        if (!mounted) return;
                        setState(() {
                          _pendingSession = null;
                          _pendingSessionId = null;
                          _equiposCompletados.clear();
                        });
                        // Guardar messenger ANTES del await (SOLUCIÓN 2)
                        if (!mounted || _scaffoldMessengerKey.currentState == null) return;
                        
                        await _limpiarProgresoInventario();
                        if (mounted && _scaffoldMessengerKey.currentState != null) {
                          _scaffoldMessengerKey.currentState!.showSnackBar(
                            const SnackBar(
                              content: Text('Inventario pendiente descartado'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Descartar'),
                  ),
                ],
              ),
            ),
          ],

          // Panel de filtros avanzados
          if (_mostrarFiltros && !_modoInventario)
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.tune, color: Color(0xFF003366)),
                      const SizedBox(width: 8),
                      const Text(
                        'Filtros Avanzados',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003366),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _filtroUbicacion = null;
                            _filtroStatus = null;
                            _filtroEmpleado = null;
                            _aplicarFiltros();
                          });
                        },
                        child: const Text('Limpiar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      // Filtro por Ubicación
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _filtroUbicacion != null ? Colors.blue : Colors.grey[300]!,
                            width: _filtroUbicacion != null ? 2 : 1,
                          ),
                        ),
                        child: DropdownButton<String>(
                          value: _filtroUbicacion,
                          hint: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on, size: 16),
                              SizedBox(width: 4),
                              Text('Ubicación'),
                            ],
                          ),
                          underline: Container(),
                          isDense: true,
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Todas'),
                            ),
                            ..._obtenerUbicacionesUnicas().map((ubicacion) {
                              return DropdownMenuItem<String>(
                                value: ubicacion,
                                child: Text(ubicacion),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filtroUbicacion = value;
                              _aplicarFiltros();
                            });
                          },
                        ),
                      ),
                      // Filtro por Status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _filtroStatus != null ? Colors.blue : Colors.grey[300]!,
                            width: _filtroStatus != null ? 2 : 1,
                          ),
                        ),
                        child: DropdownButton<String>(
                          value: _filtroStatus,
                          hint: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info, size: 16),
                              SizedBox(width: 4),
                              Text('Status'),
                            ],
                          ),
                          underline: Container(),
                          isDense: true,
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Todos'),
                            ),
                            ..._obtenerStatusUnicos().map((status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Text(status),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filtroStatus = value;
                              _aplicarFiltros();
                            });
                          },
                        ),
                      ),
                      // Filtro por Empleado
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _filtroEmpleado != null ? Colors.blue : Colors.grey[300]!,
                            width: _filtroEmpleado != null ? 2 : 1,
                          ),
                        ),
                        child: DropdownButton<String>(
                          value: _filtroEmpleado,
                          hint: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person, size: 16),
                              SizedBox(width: 4),
                              Text('Empleado'),
                            ],
                          ),
                          underline: Container(),
                          isDense: true,
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Todos'),
                            ),
                            ..._obtenerEmpleadosUnicos().map((empleado) {
                              return DropdownMenuItem<String>(
                                value: empleado,
                                child: Text(empleado),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filtroEmpleado = value;
                              _aplicarFiltros();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Contador y estadísticas mejorado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                if (_modoInventario) {
                  if (isMobile) {
                    // Layout móvil: columna vertical
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green[200]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Completados: ${_equiposCompletados.length}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.orange[200]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.pending, color: Colors.orange, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Faltantes: ${_calcularFaltantes()}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Botones en columna para móvil
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                    onPressed: () async {
                      // Guardar messenger ANTES del await (SOLUCIÓN 2)
                      if (!mounted || _scaffoldMessengerKey.currentState == null) return;
                      
                      await _guardarProgresoInventario();
                      if (mounted && _scaffoldMessengerKey.currentState != null) {
                        _scaffoldMessengerKey.currentState!.showSnackBar(
                          const SnackBar(
                            content: Text('Progreso del inventario guardado. Puedes continuar más tarde.'),
                            backgroundColor: Colors.blue,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        setState(() {
                          _modoInventario = false;
                        });
                      }
                    },
                            icon: const Icon(Icons.pause_circle_outline, size: 18),
                            label: const Text('Terminar más tarde'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[50],
                              foregroundColor: Colors.orange[700],
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Botón "Finalizar inventario"
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                      if (_equiposCompletados.isEmpty) {
                        if (mounted && _scaffoldMessengerKey.currentState != null) {
                          _scaffoldMessengerKey.currentState!.showSnackBar(
                            const SnackBar(
                              content: Text('Debes completar al menos un equipo para finalizar el inventario.'),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                        return;
                      }
                      
                      final isMobile = MediaQuery.of(context).size.width < 600;
                      final confirmar = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Finalizar Inventario', style: TextStyle(fontSize: isMobile ? 18 : 20)),
                          contentPadding: EdgeInsets.all(isMobile ? 16 : 24),
                          content: Text(
                            '¿Estás seguro de que deseas finalizar el inventario?\n\n'
                            'Completados: ${_equiposCompletados.length}\n'
                            'Faltantes: ${_calcularFaltantes()}',
                            style: TextStyle(fontSize: isMobile ? 14 : 16),
                          ),
                          actions: [
                            if (isMobile)
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Finalizar'),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancelar'),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Finalizar'),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                      
                      if (confirmar == true && mounted) {
                        // Usar GlobalKey en lugar de context (SOLUCIÓN DEFINITIVA)
                        if (!mounted || _scaffoldMessengerKey.currentState == null) return;
                        
                        await _finalizarInventario();
                        if (mounted && _scaffoldMessengerKey.currentState != null) {
                          _scaffoldMessengerKey.currentState!.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Inventario finalizado. ${_equiposCompletados.length} equipo(s) completado(s).',
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          setState(() {
                            _modoInventario = false;
                            _equiposCompletados.clear();
                          });
                        }
                      }
                    },
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Finalizar inventario'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            // Botón "Cancelar"
                            onPressed: () {
                              setState(() {
                                _modoInventario = false;
                                _equiposCompletados.clear();
                              });
                            },
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Cancelar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[50],
                              foregroundColor: Colors.red[700],
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    // Layout desktop cuando está en modo inventario: fila horizontal
                    return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              'Completados: ${_equiposCompletados.length}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.pending, color: Colors.orange, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              'Faltantes: ${_calcularFaltantes()}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Botón "Terminar más tarde"
                      ElevatedButton.icon(
                        onPressed: () async {
                          // Guardar messenger ANTES del await (SOLUCIÓN 2)
                          if (!mounted || _scaffoldMessengerKey.currentState == null) return;
                          
                          await _guardarProgresoInventario();
                          if (mounted && _scaffoldMessengerKey.currentState != null) {
                            _scaffoldMessengerKey.currentState!.showSnackBar(
                              const SnackBar(
                                content: Text('Progreso del inventario guardado. Puedes continuar más tarde.'),
                                backgroundColor: Colors.blue,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            setState(() {
                              _modoInventario = false;
                            });
                          }
                        },
                        icon: const Icon(Icons.pause_circle_outline, size: 18),
                        label: const Text('Terminar más tarde'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[50],
                          foregroundColor: Colors.orange[700],
                          elevation: 0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Botón "Finalizar inventario"
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (_equiposCompletados.isEmpty) {
                            if (mounted && _scaffoldMessengerKey.currentState != null) {
                              _scaffoldMessengerKey.currentState!.showSnackBar(
                                const SnackBar(
                                  content: Text('Debes completar al menos un equipo para finalizar el inventario.'),
                                  backgroundColor: Colors.orange,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                            return;
                          }
                          
                          final isMobile = MediaQuery.of(context).size.width < 600;
                          final confirmar = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Finalizar Inventario', style: TextStyle(fontSize: isMobile ? 18 : 20)),
                              contentPadding: EdgeInsets.all(isMobile ? 16 : 24),
                              content: Text(
                                '¿Estás seguro de que deseas finalizar el inventario?\n\n'
                                'Completados: ${_equiposCompletados.length}\n'
                                'Faltantes: ${_calcularFaltantes()}',
                                style: TextStyle(fontSize: isMobile ? 14 : 16),
                              ),
                              actions: [
                                if (isMobile)
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Finalizar'),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancelar'),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Finalizar'),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          );
                          
                          if (confirmar == true && mounted) {
                            // Usar GlobalKey en lugar de context (SOLUCIÓN DEFINITIVA)
                            if (!mounted || _scaffoldMessengerKey.currentState == null) return;
                            
                            await _finalizarInventario();
                            if (mounted && _scaffoldMessengerKey.currentState != null) {
                              _scaffoldMessengerKey.currentState!.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Inventario finalizado. ${_equiposCompletados.length} equipo(s) completado(s).',
                                  ),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                              setState(() {
                                _modoInventario = false;
                                _equiposCompletados.clear();
                              });
                            }
                          }
                        },
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Finalizar inventario'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Botón "Cancelar"
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _modoInventario = false;
                            _equiposCompletados.clear();
                          });
                        },
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Cancelar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[50],
                          foregroundColor: Colors.red[700],
                          elevation: 0,
                        ),
                      ),
                    ],
                  );
                  }
                } else {
                  // Cuando no está en modo inventario, mostrar información normal
                  return Row(
                    children: [
                      const Icon(Icons.computer, color: Color(0xFF003366), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Total: ${_equiposFiltrados.length} equipo${_equiposFiltrados.length != 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003366),
                        ),
                      ),
                      const Spacer(),
                      if (_searchQuery.isNotEmpty)
                        Text(
                          'Filtrados: ${_equiposFiltrados.length} de ${_equipos.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  );
                }
              },
            ),
          ),

          // Lista de equipos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error al cargar equipos',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32.0),
                              child: Text(
                                _error!,
                                style: TextStyle(color: Colors.red[600]),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadEquipos,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _equiposFiltrados.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.computer_outlined,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No se encontraron equipos con ese criterio'
                                      : 'No hay equipos de cómputo registrados',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _buildEquiposView(),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildEquiposView() {
    // Siempre mostrar en vista de lista sin agrupación
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _equiposFiltrados.length,
      itemBuilder: (context, index) {
        final equipo = _equiposFiltrados[index];
        final componentes = equipo['t_componentes_computo'] as List<dynamic>? ?? [];
        return _buildEquipoCard(context, equipo, componentes);
      },
    );
  }

  Widget _buildEquipoCardCompact(BuildContext context, Map<String, dynamic> equipo, List<dynamic> componentes) {
    final empleadoAsignado = (equipo['empleado_asignado_nombre']?.toString() ?? equipo['empleado_asignado']?.toString() ?? '').trim();
    final inventario = (equipo['inventario']?.toString() ?? '').trim();
    final estaCompletado = inventario.isNotEmpty && _equiposCompletados.contains(inventario);
    
    return Card(
      elevation: estaCompletado ? 6 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: estaCompletado
            ? const BorderSide(color: Colors.green, width: 2)
            : BorderSide(color: Colors.grey[300]!),
      ),
      child: InkWell(
        onTap: () {
          // Mostrar detalles en un diálogo o navegar
          _mostrarDetallesEquipo(context, equipo, componentes);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con checkbox o icono
              Row(
                children: [
                  if (_modoInventario)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: estaCompletado,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _equiposCompletados.add(inventario);
                            } else {
                              _equiposCompletados.remove(inventario);
                            }
                          });
                        },
                        activeColor: Colors.green,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF003366).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.computer, color: Color(0xFF003366), size: 16),
                    ),
                  const Spacer(),
                  // Mostrar nombre del empleado asignado en lugar de "ASIGNADO"
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(equipo['status']),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      (equipo['empleado_asignado_nombre']?.toString() ?? equipo['status'] ?? 'N/A').trim().isEmpty 
                        ? (equipo['status'] ?? 'N/A')
                        : (equipo['empleado_asignado_nombre']?.toString() ?? equipo['status'] ?? 'N/A'),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Inventario
              Text(
                inventario,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003366),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Usuario Final
              if (empleadoAsignado.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person, size: 10, color: Colors.blue),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          empleadoAsignado,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              // Marca/Modelo
              if (equipo['marca'] != null || equipo['modelo'] != null)
                Text(
                  '${equipo['marca'] ?? ''} ${equipo['modelo'] ?? ''}'.trim(),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              // Botón de editar
              if (!_modoInventario)
                Align(
                  alignment: Alignment.centerRight,
                  child: _isAdmin
                      ? IconButton(
                          icon: const Icon(Icons.edit, size: 14),
                          color: const Color(0xFF003366),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _editarEquipo(context, equipo),
                        )
                      : const SizedBox.shrink(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetallesEquipo(BuildContext context, Map<String, dynamic> equipo, List<dynamic> componentes) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF003366),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.computer, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        equipo['inventario'] ?? 'Sin inventario',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Contenido
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Información de t_computo_detalles_generales
                      _buildInfoRow('Inventario', equipo['inventario']),
                      _buildInfoRow('Fecha de Registro', equipo['fecha_registro']?.toString()),
                      _buildInfoRow('Tipo Equipo', equipo['tipo_equipo']),
                      _buildInfoRow('Marca', equipo['marca']),
                      _buildInfoRow('Modelo', equipo['modelo']),
                      _buildInfoRow('Procesador', equipo['procesador']),
                      _buildInfoRow('Número Serie', equipo['numero_serie']),
                      _buildInfoRow('Disco Duro', equipo['disco_duro']),
                      _buildInfoRow('Memoria RAM', equipo['memoria_ram']),
                      
                      // Información de t_computo_software
                      if (equipo['sistema_operativo_instalado'] != null || equipo['sistema_operativo'] != null) ...[
                        const Divider(height: 24),
                        const Text(
                          'Software',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003366),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      _buildInfoRow('Sistema Operativo Instalado', equipo['sistema_operativo_instalado'] ?? equipo['sistema_operativo']),
                      _buildInfoRow('Etiqueta Sistema Operativo', equipo['etiqueta_sistema_operativo']),
                      _buildInfoRow('Office Instalado', equipo['office_instalado']),
                      
                      // Información de t_computo_identificacion
                      if (equipo['tipo_uso'] != null || equipo['nombre_equipo_dominio'] != null || equipo['status'] != null) ...[
                        const Divider(height: 24),
                        const Text(
                          'Identificación',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003366),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      _buildInfoRow('Tipo de Uso', equipo['tipo_uso']),
                      _buildInfoRow('Nombre Equipo/Dominio', equipo['nombre_equipo_dominio']),
                      _buildInfoRow('Status', equipo['status']),
                      _buildInfoRow('Dirección Administrativa', equipo['direccion_administrativa']),
                      _buildInfoRow('Subdirección', equipo['subdireccion']),
                      _buildInfoRow('Gerencia', equipo['gerencia']),
                      
                      // Información de t_computo_ubicacion
                      if (equipo['direccion_fisica'] != null || equipo['estado_ubicacion'] != null) ...[
                        const Divider(height: 24),
                        const Text(
                          'Ubicación',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003366),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      _buildInfoRow('Dirección Física', equipo['direccion_fisica'] ?? equipo['ubicacion_fisica']),
                      _buildInfoRow('Estado', equipo['estado_ubicacion']),
                      _buildInfoRow('Ciudad', equipo['ciudad']),
                      _buildInfoRow('Tipo de Edificio', equipo['tipo_edificio']),
                      _buildInfoRow('Nombre del Edificio', equipo['nombre_edificio']),
                      
                      // Información de t_computo_usuario_responsable
                      if (equipo['nombre_responsable'] != null) ...[
                        const Divider(height: 24),
                        const Text(
                          'Usuario Responsable',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003366),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      _buildInfoRow('Nombre Responsable', equipo['nombre_responsable'] != null 
                        ? '${equipo['nombre_responsable']} ${equipo['apellido_paterno_responsable'] ?? ''} ${equipo['apellido_materno_responsable'] ?? ''}'.trim()
                        : null),
                      _buildInfoRow('Expediente Responsable', equipo['expediente_responsable']),
                      _buildInfoRow('Empresa Responsable', equipo['empresa_responsable']),
                      _buildInfoRow('Puesto Responsable', equipo['puesto_responsable']),
                      
                      // Información de t_computo_usuario_final
                      if (equipo['nombre_final'] != null || equipo['empleado_asignado_nombre'] != null) ...[
                        const Divider(height: 24),
                        const Text(
                          'Usuario Final',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003366),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      _buildInfoRow('Usuario Asignado', equipo['empleado_asignado_nombre'] ?? 
                        (equipo['nombre_final'] != null 
                          ? '${equipo['nombre_final']} ${equipo['apellido_paterno_final'] ?? ''} ${equipo['apellido_materno_final'] ?? ''}'.trim()
                          : null)),
                      _buildInfoRow('Expediente Final', equipo['expediente_final']),
                      _buildInfoRow('Empresa Final', equipo['empresa_final']),
                      _buildInfoRow('Puesto Final', equipo['puesto_final']),
                      
                      // Información de t_computo_observaciones
                      if (equipo['observaciones'] != null && equipo['observaciones'].toString().isNotEmpty) ...[
                        const Divider(height: 24),
                        const Text(
                          'Observaciones',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003366),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow('Observaciones', equipo['observaciones']),
                      ],
                      
                      // Componentes/Accesorios
                      if (componentes.isNotEmpty) ...[
                        const Divider(height: 32),
                        Row(
                          children: [
                            const Icon(Icons.extension, color: Color(0xFF003366), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Componentes/Accesorios (${componentes.length})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF003366),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...componentes.asMap().entries.map((entry) {
                          final componente = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _getComponentIcon(componente['tipo_componente']),
                                  size: 20,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        componente['tipo_componente'] ?? 'Componente',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (componente['marca'] != null || componente['modelo'] != null)
                                        Text(
                                          '${componente['marca'] ?? ''} ${componente['modelo'] ?? ''}'.trim(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      if (componente['numero_serie'] != null)
                                        Text(
                                          'Serie: ${componente['numero_serie']}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ],
                  ),
                ),
              ),
              // Footer con botón de editar
              // Botón Editar Equipo solo para admins
              if (_isAdmin)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _editarEquipo(context, equipo);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar Equipo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEquipoCard(BuildContext context, Map<String, dynamic> equipo, List<dynamic> componentes) {
    final empleadoAsignado = (equipo['empleado_asignado_nombre']?.toString() ?? equipo['empleado_asignado']?.toString() ?? '').trim();
    final inventario = (equipo['inventario']?.toString() ?? '').trim();
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    final estaCompletado = inventario.isNotEmpty && _equiposCompletados.contains(inventario);
    
    return Card(
      elevation: estaCompletado ? 6 : 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: estaCompletado
            ? const BorderSide(color: Colors.green, width: 2)
            : BorderSide(color: Colors.grey[300]!),
      ),
      child: ExpansionTile(
        key: ValueKey('equipo_$inventario'),
        leading: SizedBox(
          width: 40,
          child: _modoInventario
              ? Checkbox(
                  value: estaCompletado,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _equiposCompletados.add(inventario);
                      } else {
                        _equiposCompletados.remove(inventario);
                      }
                    });
                  },
                  activeColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF003366).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.computer, color: Color(0xFF003366), size: 28),
                ),
        ),
        title: isMobile
            ? Text(
                equipo['inventario'] ?? 'Sin inventario',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003366),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    equipo['inventario'] ?? 'Sin inventario',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003366),
                    ),
                  ),
                  // Usuario Final destacado - más visible
                  if (empleadoAsignado.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[400]!, Colors.blue[600]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.person_pin_circle, size: 18, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Usuario Final: $empleadoAsignado',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
        subtitle: isMobile
            ? (empleadoAsignado.isNotEmpty
                ? Row(
                    children: [
                      Icon(Icons.person, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          empleadoAsignado,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : (equipo['direccion_fisica'] != null || equipo['ubicacion_fisica'] != null)
                    ? Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              equipo['direccion_fisica'] ?? equipo['ubicacion_fisica'] ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    : null)
            : (equipo['marca'] != null || equipo['modelo'] != null || equipo['numero_serie'] != null)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (equipo['marca'] != null || equipo['modelo'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(Icons.branding_watermark, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${equipo['marca'] ?? ''} ${equipo['modelo'] ?? ''}'.trim(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (equipo['numero_serie'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(Icons.qr_code, size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Serie: ${equipo['numero_serie']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  )
                : null,
        trailing: _modoInventario
            ? (estaCompletado
                ? ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Completo',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink())
            : isMobile
                ? (_isAdmin
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Color(0xFF003366), size: 20),
                            tooltip: 'Editar equipo',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            onPressed: () => _editarEquipo(context, equipo),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            tooltip: 'Eliminar equipo',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            onPressed: () => _eliminarEquipo(context, equipo),
                          ),
                        ],
                      )
                    : null)
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(equipo['status']),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _getStatusColor(equipo['status']).withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getStatusIcon(equipo['status']),
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    (equipo['empleado_asignado_nombre']?.toString() ?? equipo['status'] ?? 'N/A').trim().isEmpty 
                                      ? (equipo['status'] ?? 'N/A')
                                      : (equipo['empleado_asignado_nombre']?.toString() ?? equipo['status'] ?? 'N/A'),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Botones de editar y eliminar solo para admins
                        if (_isAdmin) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Color(0xFF003366), size: 20),
                            tooltip: 'Editar equipo',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _editarEquipo(context, equipo),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            tooltip: 'Eliminar equipo',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _eliminarEquipo(context, equipo),
                          ),
                        ],
                      ],
                    ),
                  ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información de t_computo_detalles_generales
                _buildInfoRow('Inventario', equipo['inventario']),
                _buildInfoRow('Fecha de Registro', equipo['fecha_registro']?.toString()),
                _buildInfoRow('Tipo Equipo', equipo['tipo_equipo']),
                _buildInfoRow('Marca', equipo['marca']),
                _buildInfoRow('Modelo', equipo['modelo']),
                _buildInfoRow('Procesador', equipo['procesador']),
                _buildInfoRow('Número Serie', equipo['numero_serie']),
                _buildInfoRow('Disco Duro', equipo['disco_duro']),
                _buildInfoRow('Memoria RAM', equipo['memoria_ram']),
                
                // Información de t_computo_software
                if (equipo['sistema_operativo_instalado'] != null || equipo['sistema_operativo'] != null) ...[
                  const Divider(height: 24),
                  const Text(
                    'Software',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003366),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                _buildInfoRow('Sistema Operativo Instalado', equipo['sistema_operativo_instalado'] ?? equipo['sistema_operativo']),
                _buildInfoRow('Etiqueta Sistema Operativo', equipo['etiqueta_sistema_operativo']),
                _buildInfoRow('Office Instalado', equipo['office_instalado']),
                
                // Información de t_computo_identificacion
                if (equipo['tipo_uso'] != null || equipo['nombre_equipo_dominio'] != null || equipo['status'] != null) ...[
                  const Divider(height: 24),
                  const Text(
                    'Identificación',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003366),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                _buildInfoRow('Tipo de Uso', equipo['tipo_uso']),
                _buildInfoRow('Nombre Equipo/Dominio', equipo['nombre_equipo_dominio']),
                _buildInfoRow('Status', equipo['status']),
                _buildInfoRow('Dirección Administrativa', equipo['direccion_administrativa']),
                _buildInfoRow('Subdirección', equipo['subdireccion']),
                _buildInfoRow('Gerencia', equipo['gerencia']),
                
                // Información de t_computo_ubicacion
                if (equipo['direccion_fisica'] != null || equipo['estado_ubicacion'] != null) ...[
                  const Divider(height: 24),
                  const Text(
                    'Ubicación',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003366),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                _buildInfoRow('Dirección Física', equipo['direccion_fisica'] ?? equipo['ubicacion_fisica']),
                _buildInfoRow('Estado', equipo['estado_ubicacion']),
                _buildInfoRow('Ciudad', equipo['ciudad']),
                _buildInfoRow('Tipo de Edificio', equipo['tipo_edificio']),
                _buildInfoRow('Nombre del Edificio', equipo['nombre_edificio']),
                
                // Información de t_computo_usuario_responsable
                if (equipo['nombre_responsable'] != null) ...[
                  const Divider(height: 24),
                  const Text(
                    'Usuario Responsable',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003366),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                _buildInfoRow('Nombre Responsable', equipo['nombre_responsable'] != null 
                  ? '${equipo['nombre_responsable']} ${equipo['apellido_paterno_responsable'] ?? ''} ${equipo['apellido_materno_responsable'] ?? ''}'.trim()
                  : null),
                _buildInfoRow('Expediente Responsable', equipo['expediente_responsable']),
                _buildInfoRow('Empresa Responsable', equipo['empresa_responsable']),
                _buildInfoRow('Puesto Responsable', equipo['puesto_responsable']),
                
                // Información de t_computo_usuario_final
                if (equipo['nombre_final'] != null || equipo['empleado_asignado_nombre'] != null) ...[
                  const Divider(height: 24),
                  const Text(
                    'Usuario Final',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003366),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                _buildInfoRow('Usuario Asignado', equipo['empleado_asignado_nombre'] ?? 
                  (equipo['nombre_final'] != null 
                    ? '${equipo['nombre_final']} ${equipo['apellido_paterno_final'] ?? ''} ${equipo['apellido_materno_final'] ?? ''}'.trim()
                    : null)),
                _buildInfoRow('Expediente Final', equipo['expediente_final']),
                _buildInfoRow('Empresa Final', equipo['empresa_final']),
                _buildInfoRow('Puesto Final', equipo['puesto_final']),
                
                // Información de t_computo_observaciones
                if (equipo['observaciones'] != null && equipo['observaciones'].toString().isNotEmpty) ...[
                  const Divider(height: 24),
                  const Text(
                    'Observaciones',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003366),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Observaciones', equipo['observaciones']),
                ],

                // Componentes
                if (componentes.isNotEmpty) ...[
                  const Divider(height: 32),
                  Row(
                    children: [
                      const Icon(Icons.extension, color: Color(0xFF003366), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Componentes (${componentes.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003366),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...componentes.asMap().entries.map((entry) {
                    final componente = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getComponentIcon(componente['tipo_componente']),
                            size: 20,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  componente['tipo_componente'] ?? 'Componente',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                if (componente['marca'] != null || componente['modelo'] != null)
                                  Text(
                                    '${componente['marca'] ?? ''} ${componente['modelo'] ?? ''}'.trim(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                if (componente['numero_serie'] != null)
                                  Text(
                                    'Serie: ${componente['numero_serie']}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (componente['estado'] != null && componente['estado'].toString().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getEstadoColor(componente['estado']),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                componente['estado'].toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Sin estado',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          // Botones de editar y eliminar componente solo para admins
                          if (_isAdmin) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              color: const Color(0xFF003366),
                              tooltip: 'Editar componente',
                              onPressed: () => _mostrarEditarComponenteDialog(context, equipo, componente),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18),
                              color: Colors.red,
                              tooltip: 'Eliminar componente',
                              onPressed: () => _eliminarComponente(context, componente),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                  // Botón para agregar más componentes (siempre visible si es admin)
                  if (_isAdmin) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Agregar componente'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF003366),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _mostrarAgregarComponenteDialog(context, equipo),
                      ),
                    ),
                  ],
                ] else ...[
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          children: [
                            const Icon(Icons.extension, color: Colors.grey, size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Sin componentes registrados',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Botón agregar componente solo para admins
                      if (_isAdmin)
                        Flexible(
                          child: TextButton.icon(
                            onPressed: () => _mostrarAgregarComponenteDialog(context, equipo),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Agregar componente'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF003366),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toUpperCase()) {
      case 'ASIGNADO':
        return Colors.green;
      case 'DISPONIBLE':
        return Colors.blue;
      case 'MANTENIMIENTO':
        return Colors.orange;
      case 'BAJA':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getEstadoColor(String? estado) {
    if (estado == null) return Colors.grey;
    switch (estado.toUpperCase()) {
      case 'BUENO':
      case 'FUNCIONAL':
        return Colors.green;
      case 'REGULAR':
        return Colors.orange;
      case 'MALO':
      case 'DAÑADO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getComponentIcon(String? tipo) {
    if (tipo == null || tipo.toString().isEmpty) return Icons.extension;
    try {
      final tipoLower = tipo.toString().toLowerCase();
      if (tipoLower.contains('teclado') || tipoLower.contains('keyboard')) {
        return Icons.keyboard;
      } else if (tipoLower.contains('mouse') || tipoLower.contains('ratón')) {
        return Icons.mouse;
      } else if (tipoLower.contains('monitor') || tipoLower.contains('pantalla')) {
        return Icons.monitor;
      } else if (tipoLower.contains('cable') || tipoLower.contains('cableado')) {
        return Icons.cable;
      } else if (tipoLower.contains('cargador') || tipoLower.contains('power')) {
        return Icons.battery_charging_full;
      } else {
        return Icons.extension;
      }
    } catch (e) {
      debugPrint('Error al obtener icono de componente: $e');
      return Icons.extension;
    }
  }

  IconData _getStatusIcon(String? status) {
    if (status == null) return Icons.help_outline;
    switch (status.toUpperCase()) {
      case 'ASIGNADO':
        return Icons.person;
      case 'DISPONIBLE':
        return Icons.check_circle;
      case 'MANTENIMIENTO':
        return Icons.build;
      case 'BAJA':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  int _calcularFaltantes() {
    if (!_modoInventario) return 0;
    try {
      final completadosEnFiltrados = _equiposFiltrados.where((equipo) {
        final inv = (equipo['inventario']?.toString() ?? '').trim();
        return inv.isNotEmpty && _equiposCompletados.contains(inv);
      }).length;
      return (_equiposFiltrados.length - completadosEnFiltrados).clamp(0, _equiposFiltrados.length);
    } catch (e) {
      debugPrint('Error al calcular faltantes: $e');
      return 0;
    }
  }

  // Guardar progreso del inventario
  Future<void> _guardarProgresoInventario() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ownerId = prefs.getString('id_empleado');
      final ownerEmail = prefs.getString('nombre_usuario');
      
      const categoryName = 'Equipo de Cómputo';
      const categoryId = -1; // ID especial para Equipo de Cómputo
      
      // Crear mapa de quantities usando hash del inventario como clave
      // Valor 1 = completado, 0 = no completado
      final quantities = <int, int>{};
      for (var equipo in _equipos) {
        final inventario = (equipo['inventario']?.toString() ?? '').trim();
        if (inventario.isNotEmpty) {
          final inventarioHash = inventario.hashCode.abs();
          quantities[inventarioHash] = _equiposCompletados.contains(inventario) ? 1 : 0;
        }
      }
      
      // Determinar el ID de la sesión
      String sessionId;
      if (_pendingSessionId != null) {
        // Verificar que la sesión existente sea pending antes de actualizarla
        final existingSession = await _sessionStorage.getSessionById(_pendingSessionId!);
        if (existingSession != null && existingSession.status == InventorySessionStatus.pending) {
          sessionId = _pendingSessionId!;
        } else {
          // Si la sesión está completada o no existe, crear una nueva
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final categoryNameHash = categoryName.hashCode.abs();
          sessionId = 'computo_${timestamp}_${categoryNameHash}_${ownerId ?? 'unknown'}';
        }
      } else {
        // Crear un nuevo ID único
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final categoryNameHash = categoryName.hashCode.abs();
        sessionId = 'computo_${timestamp}_${categoryNameHash}_${ownerId ?? 'unknown'}';
      }
      
      final session = InventorySession(
        id: sessionId,
        categoryId: categoryId,
        categoryName: categoryName,
        quantities: quantities,
        status: InventorySessionStatus.pending,
        updatedAt: DateTime.now(),
        ownerId: ownerId,
        ownerName: ownerEmail,
        ownerEmail: ownerEmail,
      );
      
      await _sessionStorage.saveSession(session);
      
      setState(() {
        _pendingSessionId = sessionId;
      });
      
      // También guardar en SharedPreferences para compatibilidad
      final equiposCompletadosList = _equiposCompletados.toList();
      await prefs.setString(
        'inventario_computo_pendiente',
        jsonEncode({
          'equipos_completados': equiposCompletadosList,
          'fecha_guardado': DateTime.now().toIso8601String(),
          'total_equipos': _equipos.length,
          'session_id': sessionId,
        }),
      );
      
      print('✅ Progreso del inventario guardado en historial: ${equiposCompletadosList.length} equipos');
    } catch (e) {
      debugPrint('Error al guardar progreso del inventario: $e');
      rethrow;
    }
  }

  // Cargar progreso del inventario guardado
  Future<void> _cargarProgresoInventario() async {
    if (!mounted) return; // Verificar al inicio
    
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return; // Verificar después de await
      
      final ownerId = prefs.getString('id_empleado');
      
      // Primero intentar cargar desde el historial de sesiones
      // Envolver en try-catch adicional para capturar errores del error handler interno
      try {
        List<InventorySession> allSessions;
        try {
          allSessions = await _sessionStorage.getAllSessions();
        } catch (storageError) {
          // Si falla el storage (puede ser por error handler interno de Supabase), simplemente retornar
          if (!mounted) return;
          debugPrint('Error al obtener sesiones (ignorado): $storageError');
          return; // Salir sin cargar progreso
        }
        
        if (!mounted) return; // Verificar después de await
        
        final computoSessions = allSessions.where((s) => 
          s.categoryName == 'Equipo de Cómputo' && 
          s.status == InventorySessionStatus.pending &&
          (ownerId == null || s.ownerId == ownerId)
        ).toList();
        
        if (computoSessions.isNotEmpty) {
          // Usar la sesión más reciente
          computoSessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          final latestSession = computoSessions.first;
          
          // Convertir quantities de vuelta a inventarios completados
          final equiposCompletados = <String>{};
          for (var equipo in _equipos) {
            if (!mounted) return; // Verificar en cada iteración
            final inventario = (equipo['inventario']?.toString() ?? '').trim();
            if (inventario.isNotEmpty) {
              final inventarioHash = inventario.hashCode.abs();
              if (latestSession.quantities[inventarioHash] == 1) {
                equiposCompletados.add(inventario);
              }
            }
          }
          
          if (!mounted) return; // Verificar antes de setState
          
          setState(() {
            _equiposCompletados = equiposCompletados;
            _pendingSessionId = latestSession.id;
            _pendingSession = latestSession; // Guardar la sesión completa
          });
          
          // Verificar mounted ANTES de usar context y guardar messenger (SOLUCIÓN 2)
          if (equiposCompletados.isNotEmpty && mounted) {
            try {
              if (_scaffoldMessengerKey.currentState != null) {
                _scaffoldMessengerKey.currentState!.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Progreso anterior cargado: ${equiposCompletados.length} equipo(s) completado(s)',
                    ),
                    backgroundColor: Colors.blue,
                    duration: const Duration(seconds: 2),
                    action: SnackBarAction(
                      label: 'Limpiar',
                      textColor: Colors.white,
                      onPressed: () {
                        if (mounted) {
                          setState(() {
                            _equiposCompletados.clear();
                          });
                          _limpiarProgresoInventario();
                        }
                      },
                    ),
                  ),
                );
              }
            } catch (e) {
              // Si falla al mostrar el SnackBar (widget desmontado), simplemente ignorar
              if (mounted) rethrow;
            }
          }
          return;
        }
      } catch (e) {
        // Si el widget está desmontado, ignorar el error completamente
        if (!mounted) return;
        debugPrint('Error al cargar desde historial: $e');
      }
      
      // Fallback: cargar desde SharedPreferences (compatibilidad)
      final progresoJson = prefs.getString('inventario_computo_pendiente');
      if (progresoJson != null && progresoJson.isNotEmpty) {
        final progreso = jsonDecode(progresoJson) as Map<String, dynamic>;
        final equiposCompletadosList = (progreso['equipos_completados'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ?? [];
        final sessionId = progreso['session_id']?.toString();
        
        // Verificar que los equipos completados aún existan en la lista actual
        final equiposValidos = equiposCompletadosList.where((inv) {
          return _equipos.any((equipo) => (equipo['inventario']?.toString() ?? '').trim() == inv);
        }).toSet();
        
        // Intentar cargar la sesión completa si hay sessionId
        InventorySession? sessionFromStorage;
        if (sessionId != null) {
          try {
            try {
              sessionFromStorage = await _sessionStorage.getSessionById(sessionId);
            } catch (storageError) {
              // Si falla el storage (puede ser por error handler interno de Supabase), simplemente ignorar
              if (!mounted) return;
              debugPrint('Error al obtener sesión del storage (ignorado): $storageError');
              sessionFromStorage = null; // Continuar sin sesión
            }
            if (!mounted) return; // Verificar después de await
          } catch (e) {
            if (!mounted) return; // Verificar después de error
            debugPrint('Error al obtener sesión del storage: $e');
            sessionFromStorage = null; // Continuar sin sesión
          }
        }
        
        if (!mounted) return; // Verificar antes de setState
        
        setState(() {
          _equiposCompletados = equiposValidos;
          if (sessionId != null) {
            _pendingSessionId = sessionId;
          }
          if (sessionFromStorage != null) {
            _pendingSession = sessionFromStorage;
          }
        });
        
        if (equiposValidos.isNotEmpty && mounted) {
          try {
            if (_scaffoldMessengerKey.currentState != null) {
              _scaffoldMessengerKey.currentState!.showSnackBar(
                SnackBar(
                  content: Text(
                    'Progreso anterior cargado: ${equiposValidos.length} equipo(s) completado(s)',
                  ),
                  backgroundColor: Colors.blue,
                  duration: const Duration(seconds: 2),
                  action: SnackBarAction(
                    label: 'Limpiar',
                    textColor: Colors.white,
                    onPressed: () {
                      if (mounted) {
                        setState(() {
                          _equiposCompletados.clear();
                        });
                        _limpiarProgresoInventario();
                      }
                    },
                  ),
                ),
              );
            }
          } catch (e) {
            // Si falla al mostrar el SnackBar (widget desmontado), simplemente ignorar
            if (mounted) rethrow;
          }
        }
      }
    } catch (e) {
      debugPrint('Error al cargar progreso del inventario: $e');
    }
  }

  // Limpiar progreso guardado
  Future<void> _limpiarProgresoInventario() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('inventario_computo_pendiente');
      
      // Eliminar la sesión del storage si existe
      if (_pendingSessionId != null) {
        try {
          await _sessionStorage.deleteSession(_pendingSessionId!);
        } catch (e) {
          debugPrint('Error al eliminar sesión del storage: $e');
        }
      }
      
      print('✅ Progreso del inventario limpiado');
    } catch (e) {
      debugPrint('Error al limpiar progreso del inventario: $e');
    }
  }

  // Formatear fecha de sesión
  String _formatSessionDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  // Finalizar inventario
  Future<void> _finalizarInventario() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ownerId = prefs.getString('id_empleado');
      final ownerEmail = prefs.getString('nombre_usuario');
      
      const categoryName = 'Equipo de Cómputo';
      const categoryId = -1; // ID especial para Equipo de Cómputo
      
      // Crear mapa de quantities con TODOS los equipos
      // Valor 1 = completado, 0 = no completado
      final quantities = <int, int>{};
      for (var equipo in _equipos) {
        final inventario = (equipo['inventario']?.toString() ?? '').trim();
        if (inventario.isNotEmpty) {
          final inventarioHash = inventario.hashCode.abs();
          quantities[inventarioHash] = _equiposCompletados.contains(inventario) ? 1 : 0;
        }
      }
      
      // Determinar el ID de la sesión
      String sessionId;
      if (_pendingSessionId != null) {
        // Actualizar la sesión pendiente existente
        sessionId = _pendingSessionId!;
      } else {
        // Crear un nuevo ID único
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final categoryNameHash = categoryName.hashCode.abs();
        sessionId = 'computo_${timestamp}_${categoryNameHash}_${ownerId ?? 'unknown'}';
      }
      
      final session = InventorySession(
        id: sessionId,
        categoryId: categoryId,
        categoryName: categoryName,
        quantities: quantities,
        status: InventorySessionStatus.completed,
        updatedAt: DateTime.now(),
        ownerId: ownerId,
        ownerName: ownerEmail,
        ownerEmail: ownerEmail,
      );
      
      await _sessionStorage.saveSession(session);
      
      print('✅ Inventario finalizado y guardado en historial: ${_equiposCompletados.length} equipos completados');
      
      // Limpiar el progreso guardado ya que el inventario está finalizado
      await _limpiarProgresoInventario();
      
      setState(() {
        _pendingSessionId = null;
        _pendingSession = null;
      });
    } catch (e) {
      debugPrint('Error al finalizar inventario: $e');
      rethrow;
    }
  }

  // Método para mostrar el diálogo de agregar equipo
  void _mostrarAgregarEquipoDialog() {
    showDialog(
      context: context,
      builder: (context) => _EquipoDialog(
        equipo: {}, // Equipo vacío para crear uno nuevo
        onSave: (nuevoEquipo) async {
          // Crear nuevo equipo en la base de datos usando las nuevas tablas
          try {
            // Generar inventario automáticamente si no se proporciona
            String inventario = nuevoEquipo['inventario']?.toString().trim() ?? '';
            if (inventario.isEmpty) {
              final numeroSerie = nuevoEquipo['numero_serie']?.toString().trim() ?? '';
              if (numeroSerie.isNotEmpty) {
              inventario = 'AUTO-$numeroSerie';
            } else {
              final ahora = DateTime.now();
              inventario = 'AUTO-${ahora.year}${ahora.month.toString().padLeft(2, '0')}${ahora.day.toString().padLeft(2, '0')}-${ahora.hour.toString().padLeft(2, '0')}${ahora.minute.toString().padLeft(2, '0')}${ahora.second.toString().padLeft(2, '0')}';
              }
            }

            // 1. Crear o obtener equipo_pm en t_computo_equipos_principales
            final equipoPm = inventario; // Usar inventario como equipo_pm inicialmente
            dynamic idEquipoPrincipal;
            
            // Verificar si ya existe un equipo principal con este inventario
            final equipoPrincipalExistente = await _safeSupabaseCall(() => 
              supabaseClient
                  .from('t_computo_equipos_principales')
                  .select('id_equipo_principal')
                  .eq('equipo_pm', equipoPm)
                  .maybeSingle()
            );
            
            if (equipoPrincipalExistente != null && equipoPrincipalExistente['id_equipo_principal'] != null) {
              idEquipoPrincipal = equipoPrincipalExistente['id_equipo_principal'];
            } else {
              // Crear nuevo equipo principal
              final nuevoEquipoPrincipal = await _safeSupabaseCall(() => 
                supabaseClient
                    .from('t_computo_equipos_principales')
                    .insert({'equipo_pm': equipoPm})
                    .select('id_equipo_principal')
                    .single()
              );
              if (nuevoEquipoPrincipal == null) {
                throw Exception('No se pudo crear el equipo principal');
              }
              idEquipoPrincipal = nuevoEquipoPrincipal['id_equipo_principal'];
            }

            // 2. Insertar en t_computo_detalles_generales
            final datosDetalles = <String, dynamic>{
              'equipo_pm': idEquipoPrincipal,
              'inventario': inventario,
              'tipo_equipo': nuevoEquipo['tipo_equipo']?.toString().trim() ?? '',
            };
            if (nuevoEquipo['marca']?.toString().trim().isNotEmpty ?? false) {
              datosDetalles['marca'] = nuevoEquipo['marca']?.toString().trim();
            }
            if (nuevoEquipo['modelo']?.toString().trim().isNotEmpty ?? false) {
              datosDetalles['modelo'] = nuevoEquipo['modelo']?.toString().trim();
            }
            if (nuevoEquipo['procesador']?.toString().trim().isNotEmpty ?? false) {
              datosDetalles['procesador'] = nuevoEquipo['procesador']?.toString().trim();
            }
            if (nuevoEquipo['numero_serie']?.toString().trim().isNotEmpty ?? false) {
              datosDetalles['numero_serie'] = nuevoEquipo['numero_serie']?.toString().trim();
            }
            if (nuevoEquipo['disco_duro']?.toString().trim().isNotEmpty ?? false) {
              datosDetalles['disco_duro'] = nuevoEquipo['disco_duro']?.toString().trim();
            }
            if (nuevoEquipo['memoria_ram']?.toString().trim().isNotEmpty ?? false) {
              datosDetalles['memoria_ram'] = nuevoEquipo['memoria_ram']?.toString().trim();
            }

            final resultadoDetalles = await _safeSupabaseCall(() => 
              supabaseClient
                  .from('t_computo_detalles_generales')
                  .insert(datosDetalles)
                  .select('id_equipo_computo')
                  .single()
            );
            
            if (resultadoDetalles == null || resultadoDetalles['id_equipo_computo'] == null) {
              throw Exception('No se pudo insertar el equipo en la base de datos');
            }
            
            final idEquipoComputo = resultadoDetalles['id_equipo_computo'];
            debugPrint('✅ Equipo insertado correctamente con ID: $idEquipoComputo');

            // 3. Insertar en t_computo_software si hay datos
            if ((nuevoEquipo['sistema_operativo_instalado']?.toString().trim().isNotEmpty ?? false) ||
                (nuevoEquipo['etiqueta_sistema_operativo']?.toString().trim().isNotEmpty ?? false) ||
                (nuevoEquipo['office_instalado']?.toString().trim().isNotEmpty ?? false)) {
              final datosSoftware = <String, dynamic>{'id_equipo_computo': idEquipoComputo};
              if (nuevoEquipo['sistema_operativo_instalado']?.toString().trim().isNotEmpty ?? false) {
                datosSoftware['sistema_operativo_instalado'] = nuevoEquipo['sistema_operativo_instalado']?.toString().trim();
              }
              if (nuevoEquipo['etiqueta_sistema_operativo']?.toString().trim().isNotEmpty ?? false) {
                datosSoftware['etiqueta_sistema_operativo'] = nuevoEquipo['etiqueta_sistema_operativo']?.toString().trim();
              }
              if (nuevoEquipo['office_instalado']?.toString().trim().isNotEmpty ?? false) {
                datosSoftware['office_instalado'] = nuevoEquipo['office_instalado']?.toString().trim();
              }
              await _safeSupabaseCall(() => 
                supabaseClient
                    .from('t_computo_software')
                    .insert(datosSoftware)
              );
            }

            // 4. Insertar en t_computo_identificacion si hay datos
            if ((nuevoEquipo['tipo_uso']?.toString().trim().isNotEmpty ?? false) ||
                (nuevoEquipo['nombre_equipo_dominio']?.toString().trim().isNotEmpty ?? false) ||
                (nuevoEquipo['status']?.toString().trim().isNotEmpty ?? false)) {
              final datosIdentificacion = <String, dynamic>{'id_equipo_computo': idEquipoComputo};
              if (nuevoEquipo['tipo_uso']?.toString().trim().isNotEmpty ?? false) {
                datosIdentificacion['tipo_uso'] = nuevoEquipo['tipo_uso']?.toString().trim();
              }
              if (nuevoEquipo['nombre_equipo_dominio']?.toString().trim().isNotEmpty ?? false) {
                datosIdentificacion['nombre_equipo_dominio'] = nuevoEquipo['nombre_equipo_dominio']?.toString().trim();
              }
              if (nuevoEquipo['status']?.toString().trim().isNotEmpty ?? false) {
                datosIdentificacion['status'] = nuevoEquipo['status']?.toString().trim();
              }
              if (nuevoEquipo['direccion_administrativa']?.toString().trim().isNotEmpty ?? false) {
                datosIdentificacion['direccion_administrativa'] = nuevoEquipo['direccion_administrativa']?.toString().trim();
              }
              if (nuevoEquipo['subdireccion']?.toString().trim().isNotEmpty ?? false) {
                datosIdentificacion['subdireccion'] = nuevoEquipo['subdireccion']?.toString().trim();
              }
              if (nuevoEquipo['gerencia']?.toString().trim().isNotEmpty ?? false) {
                datosIdentificacion['gerencia'] = nuevoEquipo['gerencia']?.toString().trim();
              }
              await _safeSupabaseCall(() => 
                supabaseClient
                    .from('t_computo_identificacion')
                    .insert(datosIdentificacion)
              );
            }

            // 5. Insertar en t_computo_observaciones si hay datos
            if (nuevoEquipo['observaciones']?.toString().trim().isNotEmpty ?? false) {
              await _safeSupabaseCall(() => 
                supabaseClient
                    .from('t_computo_observaciones')
                    .insert({
                      'id_equipo_computo': idEquipoComputo,
                      'observaciones': nuevoEquipo['observaciones']?.toString().trim(),
                    })
              );
            }
            
            if (!mounted) return;

            // Recargar los equipos
            if (mounted) {
              await _loadEquipos();
              if (mounted && _scaffoldMessengerKey.currentState != null) {
                _scaffoldMessengerKey.currentState!.showSnackBar(
                  const SnackBar(
                    content: Text('Equipo agregado correctamente'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            }
          } catch (e) {
            debugPrint('Error al agregar equipo: $e');
            if (mounted && _scaffoldMessengerKey.currentState != null) {
              _scaffoldMessengerKey.currentState!.showSnackBar(
                SnackBar(
                  content: Text('Error al agregar equipo: $e'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }
        },
      ),
    );
  }

  // Método para abrir el diálogo de edición de equipo
  void _editarEquipo(BuildContext context, Map<String, dynamic> equipo) {
    showDialog(
      context: context,
      builder: (context) => _EquipoDialog(
        equipo: Map<String, dynamic>.from(equipo),
        onSave: (updated) async {
          // Guardar cambios en la base de datos
          try {
            final idEquipoComputo = equipo['id_equipo_computo'];
            if (idEquipoComputo == null) {
              throw Exception('ID del equipo no encontrado');
            }

            // Actualizar el equipo en la base de datos
            await _safeSupabaseCall(() => 
              supabaseClient
                  .from('t_equipos_computo')
                  .update({
                    'tipo_equipo': updated['tipo_equipo'],
                    'marca': updated['marca'],
                    'modelo': updated['modelo'],
                    'procesador': updated['procesador'],
                    'numero_serie': updated['numero_serie'],
                    'disco_duro': updated['disco_duro'],
                    'memoria': updated['memoria'],
                    'sistema_operativo_instalado': updated['sistema_operativo_instalado'] ?? updated['sistema_operativo'],
                    'office_instalado': updated['office_instalado'],
                    // NOTA: ubicacion_fisica no existe directamente en la tabla
                    // Se maneja a través de id_ubicacion_fisica (FK a t_ubicaciones_computo)
                    'observaciones': updated['observaciones'],
                  })
                  .eq('id_equipo_computo', idEquipoComputo)
            );
            
            if (!mounted) return;

            // Guardar el messenger ANTES de operaciones asíncronas (SOLUCIÓN 2)
            if (mounted && _scaffoldMessengerKey.currentState != null) {
              _loadEquipos();
              _scaffoldMessengerKey.currentState!.showSnackBar(
                const SnackBar(
                  content: Text('Equipo actualizado correctamente'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            if (mounted && _scaffoldMessengerKey.currentState != null) {
              _scaffoldMessengerKey.currentState!.showSnackBar(
                SnackBar(
                  content: Text('Error al guardar: $e'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }
        },
      ),
    );
  }

  // Eliminar equipo de cómputo
  Future<void> _eliminarEquipo(BuildContext context, Map<String, dynamic> equipo) async {
    final inventario = equipo['inventario']?.toString() ?? 'este equipo';
    
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar el equipo $inventario? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      final idEquipoComputo = equipo['id_equipo_computo'];
      if (idEquipoComputo == null) {
        throw Exception('ID del equipo no encontrado');
      }

      // Eliminar primero los componentes asociados
      await _safeSupabaseCall(() => 
        supabaseClient
            .from('t_componentes_computo')
            .delete()
            .eq('id_equipo_computo', idEquipoComputo)
      );

      // Eliminar el equipo
      await _safeSupabaseCall(() => 
        supabaseClient
            .from('t_equipos_computo')
            .delete()
            .eq('id_equipo_computo', idEquipoComputo)
      );

      if (!mounted) return;

      // Recargar la lista
      await _loadEquipos();

      if (mounted && _scaffoldMessengerKey.currentState != null) {
        _scaffoldMessengerKey.currentState!.showSnackBar(
          const SnackBar(
            content: Text('Equipo eliminado correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted && _scaffoldMessengerKey.currentState != null) {
        _scaffoldMessengerKey.currentState!.showSnackBar(
          SnackBar(
            content: Text('Error al eliminar equipo: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Mostrar diálogo para agregar componente
  void _mostrarAgregarComponenteDialog(BuildContext context, Map<String, dynamic> equipo) {
    _mostrarComponenteDialog(context, equipo, null);
  }

  // Mostrar diálogo para editar componente
  void _mostrarEditarComponenteDialog(BuildContext context, Map<String, dynamic> equipo, Map<String, dynamic> componente) {
    _mostrarComponenteDialog(context, equipo, componente);
  }

  // Diálogo para agregar/editar componente
  void _mostrarComponenteDialog(BuildContext context, Map<String, dynamic> equipo, Map<String, dynamic>? componente) {
    final isNuevo = componente == null;
    final tipoController = TextEditingController(text: componente?['tipo_componente']?.toString() ?? '');
    final marcaController = TextEditingController(text: componente?['marca']?.toString() ?? '');
    final modeloController = TextEditingController(text: componente?['modelo']?.toString() ?? '');
    final numeroSerieController = TextEditingController(text: componente?['numero_serie']?.toString() ?? '');
    final inventarioController = TextEditingController(text: componente?['inventario']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isNuevo ? 'Agregar Componente' : 'Editar Componente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tipoController,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Componente *',
                  hintText: 'Ej: Teclado, Mouse, Monitor',
                  prefixIcon: Icon(Icons.extension, color: Color(0xFF003366)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: marcaController,
                decoration: const InputDecoration(
                  labelText: 'Marca',
                  prefixIcon: Icon(Icons.branding_watermark, color: Color(0xFF003366)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: modeloController,
                decoration: const InputDecoration(
                  labelText: 'Modelo',
                  prefixIcon: Icon(Icons.info, color: Color(0xFF003366)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: numeroSerieController,
                decoration: const InputDecoration(
                  labelText: 'Número de Serie',
                  prefixIcon: Icon(Icons.qr_code, color: Color(0xFF003366)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: inventarioController,
                decoration: const InputDecoration(
                  labelText: 'Inventario',
                  prefixIcon: Icon(Icons.inventory, color: Color(0xFF003366)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (tipoController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('El tipo de componente es requerido'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                final idEquipoComputo = equipo['id_equipo_computo'];
                if (idEquipoComputo == null) {
                  throw Exception('ID del equipo no encontrado');
                }

                final datosComponente = {
                  'id_equipo_computo': idEquipoComputo,
                  'tipo_componente': tipoController.text.trim(),
                  'marca': marcaController.text.trim().isEmpty ? null : marcaController.text.trim(),
                  'modelo': modeloController.text.trim().isEmpty ? null : modeloController.text.trim(),
                  'numero_serie': numeroSerieController.text.trim().isEmpty ? null : numeroSerieController.text.trim(),
                  'inventario': inventarioController.text.trim().isEmpty ? null : inventarioController.text.trim(),
                };

                if (isNuevo) {
                  // Insertar nuevo componente
                  await _safeSupabaseCall(() => 
                    supabaseClient
                        .from('t_componentes_computo')
                        .insert(datosComponente)
                  );
                } else {
                  // Actualizar componente existente
                  final idComponente = componente['id_componente_computo'];
                  if (idComponente == null) {
                    throw Exception('ID del componente no encontrado');
                  }
                  await _safeSupabaseCall(() => 
                    supabaseClient
                        .from('t_componentes_computo')
                        .update(datosComponente)
                        .eq('id_componente_computo', idComponente)
                  );
                }

                if (!mounted) return;

                // Cerrar diálogo y recargar
                Navigator.pop(context); // Cerrar diálogo de componente
                Navigator.pop(context); // Cerrar diálogo de detalles si está abierto
                await _loadEquipos();

                if (mounted && _scaffoldMessengerKey.currentState != null) {
                  _scaffoldMessengerKey.currentState!.showSnackBar(
                    SnackBar(
                      content: Text(isNuevo ? 'Componente agregado correctamente' : 'Componente actualizado correctamente'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (mounted && _scaffoldMessengerKey.currentState != null) {
                  _scaffoldMessengerKey.currentState!.showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366)),
            child: Text(isNuevo ? 'Agregar' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  // Eliminar componente
  Future<void> _eliminarComponente(BuildContext context, Map<String, dynamic> componente) async {
    final tipoComponente = componente['tipo_componente']?.toString() ?? 'este componente';
    
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar $tipoComponente? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      final idComponente = componente['id_componente_computo'];
      if (idComponente == null) {
        throw Exception('ID del componente no encontrado');
      }

      await _safeSupabaseCall(() => 
        supabaseClient
            .from('t_componentes_computo')
            .delete()
            .eq('id_componente_computo', idComponente)
      );

      if (!mounted) return;

      // Cerrar diálogo de detalles si está abierto y recargar
      Navigator.pop(context); // Cerrar diálogo de detalles
      await _loadEquipos();

      if (mounted && _scaffoldMessengerKey.currentState != null) {
        _scaffoldMessengerKey.currentState!.showSnackBar(
          const SnackBar(
            content: Text('Componente eliminado correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted && _scaffoldMessengerKey.currentState != null) {
        _scaffoldMessengerKey.currentState!.showSnackBar(
          SnackBar(
            content: Text('Error al eliminar componente: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}

// Diálogo para editar información del equipo
class _EquipoDialog extends StatefulWidget {
  final Map<String, dynamic> equipo;
  final Function(Map<String, dynamic>) onSave;

  const _EquipoDialog({
    required this.equipo,
    required this.onSave,
  });

  @override
  State<_EquipoDialog> createState() => _EquipoDialogState();
}

class _EquipoDialogState extends State<_EquipoDialog> {
  // Campos de t_computo_detalles_generales
  late TextEditingController _inventarioController;
  late TextEditingController _tipoEquipoController;
  late TextEditingController _marcaController;
  late TextEditingController _modeloController;
  late TextEditingController _procesadorController;
  late TextEditingController _numeroSerieController;
  late TextEditingController _discoDuroController;
  late TextEditingController _memoriaController;
  
  // Campos de t_computo_software
  late TextEditingController _sistemaOperativoController;
  late TextEditingController _etiquetaSoController;
  late TextEditingController _officeInstaladoController;
  
  // Campos de t_computo_identificacion
  late TextEditingController _tipoUsoController;
  late TextEditingController _nombreEquipoDominioController;
  late TextEditingController _statusController;
  late TextEditingController _direccionAdministrativaController;
  late TextEditingController _subdireccionController;
  late TextEditingController _gerenciaController;
  
  // Campos de t_computo_ubicacion
  late TextEditingController _direccionFisicaController;
  late TextEditingController _estadoController;
  late TextEditingController _ciudadController;
  late TextEditingController _tipoEdificioController;
  late TextEditingController _nombreEdificioController;
  
  // Campos de t_computo_usuario_final
  late TextEditingController _nombreFinalController;
  late TextEditingController _apellidoPaternoFinalController;
  late TextEditingController _apellidoMaternoFinalController;
  late TextEditingController _expedienteFinalController;
  late TextEditingController _empresaFinalController;
  late TextEditingController _puestoFinalController;
  
  // Campos de t_computo_usuario_responsable
  late TextEditingController _nombreResponsableController;
  late TextEditingController _apellidoPaternoResponsableController;
  late TextEditingController _apellidoMaternoResponsableController;
  late TextEditingController _expedienteResponsableController;
  late TextEditingController _empresaResponsableController;
  late TextEditingController _puestoResponsableController;
  
  // Campos de t_computo_observaciones
  late TextEditingController _observacionesController;

  @override
  void initState() {
    super.initState();
    // Campos de t_computo_detalles_generales
    _inventarioController = TextEditingController(text: widget.equipo['inventario']?.toString() ?? '');
    _tipoEquipoController = TextEditingController(text: widget.equipo['tipo_equipo']?.toString() ?? '');
    _marcaController = TextEditingController(text: widget.equipo['marca']?.toString() ?? '');
    _modeloController = TextEditingController(text: widget.equipo['modelo']?.toString() ?? '');
    _procesadorController = TextEditingController(text: widget.equipo['procesador']?.toString() ?? '');
    _numeroSerieController = TextEditingController(text: widget.equipo['numero_serie']?.toString() ?? '');
    _discoDuroController = TextEditingController(text: widget.equipo['disco_duro']?.toString() ?? '');
    _memoriaController = TextEditingController(text: widget.equipo['memoria_ram']?.toString() ?? widget.equipo['memoria']?.toString() ?? '');
    
    // Campos de t_computo_software
    _sistemaOperativoController = TextEditingController(
      text: widget.equipo['sistema_operativo_instalado']?.toString() ?? 
            widget.equipo['sistema_operativo']?.toString() ?? ''
    );
    _etiquetaSoController = TextEditingController(text: widget.equipo['etiqueta_sistema_operativo']?.toString() ?? '');
    _officeInstaladoController = TextEditingController(text: widget.equipo['office_instalado']?.toString() ?? '');
    
    // Campos de t_computo_identificacion
    _tipoUsoController = TextEditingController(text: widget.equipo['tipo_uso']?.toString() ?? '');
    _nombreEquipoDominioController = TextEditingController(text: widget.equipo['nombre_equipo_dominio']?.toString() ?? '');
    _statusController = TextEditingController(text: widget.equipo['status']?.toString() ?? 'ASIGNADO');
    _direccionAdministrativaController = TextEditingController(text: widget.equipo['direccion_administrativa']?.toString() ?? '');
    _subdireccionController = TextEditingController(text: widget.equipo['subdireccion']?.toString() ?? '');
    _gerenciaController = TextEditingController(text: widget.equipo['gerencia']?.toString() ?? '');
    
    // Campos de t_computo_ubicacion
    _direccionFisicaController = TextEditingController(
      text: widget.equipo['direccion_fisica']?.toString() ?? 
            widget.equipo['ubicacion_fisica']?.toString() ?? ''
    );
    _estadoController = TextEditingController(text: widget.equipo['estado_ubicacion']?.toString() ?? '');
    _ciudadController = TextEditingController(text: widget.equipo['ciudad']?.toString() ?? '');
    _tipoEdificioController = TextEditingController(text: widget.equipo['tipo_edificio']?.toString() ?? '');
    _nombreEdificioController = TextEditingController(text: widget.equipo['nombre_edificio']?.toString() ?? '');
    
    // Campos de t_computo_usuario_final
    _nombreFinalController = TextEditingController(text: widget.equipo['nombre_final']?.toString() ?? '');
    _apellidoPaternoFinalController = TextEditingController(text: widget.equipo['apellido_paterno_final']?.toString() ?? '');
    _apellidoMaternoFinalController = TextEditingController(text: widget.equipo['apellido_materno_final']?.toString() ?? '');
    _expedienteFinalController = TextEditingController(text: widget.equipo['expediente_final']?.toString() ?? '');
    _empresaFinalController = TextEditingController(text: widget.equipo['empresa_final']?.toString() ?? '');
    _puestoFinalController = TextEditingController(text: widget.equipo['puesto_final']?.toString() ?? '');
    
    // Campos de t_computo_usuario_responsable
    _nombreResponsableController = TextEditingController(text: widget.equipo['nombre_responsable']?.toString() ?? '');
    _apellidoPaternoResponsableController = TextEditingController(text: widget.equipo['apellido_paterno_responsable']?.toString() ?? '');
    _apellidoMaternoResponsableController = TextEditingController(text: widget.equipo['apellido_materno_responsable']?.toString() ?? '');
    _expedienteResponsableController = TextEditingController(text: widget.equipo['expediente_responsable']?.toString() ?? '');
    _empresaResponsableController = TextEditingController(text: widget.equipo['empresa_responsable']?.toString() ?? '');
    _puestoResponsableController = TextEditingController(text: widget.equipo['puesto_responsable']?.toString() ?? '');
    
    // Campos de t_computo_observaciones
    _observacionesController = TextEditingController(text: widget.equipo['observaciones']?.toString() ?? '');
  }

  @override
  void dispose() {
    // Campos de t_computo_detalles_generales
    _inventarioController.dispose();
    _tipoEquipoController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _procesadorController.dispose();
    _numeroSerieController.dispose();
    _discoDuroController.dispose();
    _memoriaController.dispose();
    
    // Campos de t_computo_software
    _sistemaOperativoController.dispose();
    _etiquetaSoController.dispose();
    _officeInstaladoController.dispose();
    
    // Campos de t_computo_identificacion
    _tipoUsoController.dispose();
    _nombreEquipoDominioController.dispose();
    _statusController.dispose();
    _direccionAdministrativaController.dispose();
    _subdireccionController.dispose();
    _gerenciaController.dispose();
    
    // Campos de t_computo_ubicacion
    _direccionFisicaController.dispose();
    _estadoController.dispose();
    _ciudadController.dispose();
    _tipoEdificioController.dispose();
    _nombreEdificioController.dispose();
    
    // Campos de t_computo_usuario_final
    _nombreFinalController.dispose();
    _apellidoPaternoFinalController.dispose();
    _apellidoMaternoFinalController.dispose();
    _expedienteFinalController.dispose();
    _empresaFinalController.dispose();
    _puestoFinalController.dispose();
    
    // Campos de t_computo_usuario_responsable
    _nombreResponsableController.dispose();
    _apellidoPaternoResponsableController.dispose();
    _apellidoMaternoResponsableController.dispose();
    _expedienteResponsableController.dispose();
    _empresaResponsableController.dispose();
    _puestoResponsableController.dispose();
    
    // Campos de t_computo_observaciones
    _observacionesController.dispose();
    super.dispose();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF003366),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003366),
            ),
          ),
        ],
      ),
    );
  }

  void _rellenarDatosFicticios() {
    // Generar datos ficticios realistas para pruebas
    final tiposEquipo = ['Desktop', 'Laptop', 'All-in-One', 'Workstation'];
    final marcas = ['DELL', 'HP', 'Lenovo', 'Acer', 'ASUS'];
    final modelos = [
      'OptiPlex 7090',
      'EliteDesk 800 G8',
      'ThinkCentre M90',
      'Aspire TC-895',
      'VivoMini VC66'
    ];
    final procesadores = [
      'Intel Core i5-11400',
      'Intel Core i7-11700',
      'AMD Ryzen 5 5600G',
      'Intel Core i5-10400',
      'AMD Ryzen 7 5700G'
    ];
    final sistemasOperativos = [
      'Windows 11 Pro',
      'Windows 10 Pro',
      'Windows 11 Home',
      'Windows 10 Enterprise'
    ];
    final offices = [
      'Microsoft Office 2021',
      'Microsoft Office 2019',
      'Microsoft 365',
      'LibreOffice 7.5'
    ];
    final ubicaciones = [
      'Edificio Central - Piso 3',
      'Sucursal Norte - Oficina 205',
      'Centro de Datos - Rack A-12',
      'Oficina Administrativa - Cubículo 15'
    ];
    final nombres = ['Juan', 'María', 'Carlos', 'Ana', 'Pedro'];
    final apellidos = ['García', 'López', 'Martínez', 'Rodríguez', 'González'];
    final empresas = ['TELMEX', 'TELMEX Sucursal', 'TELMEX Central'];
    
    // Seleccionar valores aleatorios
    final random = DateTime.now().millisecondsSinceEpoch;
    final tipoEquipo = tiposEquipo[random % tiposEquipo.length];
    final marca = marcas[random % marcas.length];
    final modelo = modelos[random % modelos.length];
    final procesador = procesadores[random % procesadores.length];
    final sistemaOperativo = sistemasOperativos[random % sistemasOperativos.length];
    final office = offices[random % offices.length];
    final ubicacion = ubicaciones[random % ubicaciones.length];
    final nombre = nombres[random % nombres.length];
    final apellido = apellidos[random % apellidos.length];
    final empresa = empresas[random % empresas.length];
    
    // Generar número de serie ficticio
    final numeroSerie = 'SN${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    
    // Generar disco duro y memoria
    final discosDuros = ['256 GB SSD', '512 GB SSD', '1 TB HDD', '1 TB SSD', '2 TB HDD'];
    final memorias = ['8 GB DDR4', '16 GB DDR4', '32 GB DDR4', '8 GB DDR5', '16 GB DDR5'];
    final discoDuro = discosDuros[random % discosDuros.length];
    final memoria = memorias[random % memorias.length];
    
    // Rellenar los campos
    setState(() {
      _tipoEquipoController.text = tipoEquipo;
      _marcaController.text = marca;
      _modeloController.text = modelo;
      _procesadorController.text = procesador;
      _numeroSerieController.text = numeroSerie;
      _discoDuroController.text = discoDuro;
      _memoriaController.text = memoria;
      _sistemaOperativoController.text = sistemaOperativo;
      _etiquetaSoController.text = 'Windows';
      _officeInstaladoController.text = office;
      _tipoUsoController.text = 'COM';
      _statusController.text = 'ASIGNADO';
      _direccionFisicaController.text = ubicacion;
      _estadoController.text = 'Estado de México';
      _ciudadController.text = 'Ciudad de México';
      _nombreFinalController.text = nombre;
      _apellidoPaternoFinalController.text = apellido;
      _empresaFinalController.text = empresa;
      _observacionesController.text = 'Equipo de prueba - Datos ficticios generados automáticamente';
    });
    
    // Mostrar mensaje de confirmación usando context del diálogo
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Datos ficticios rellenados correctamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _guardar() {
    widget.onSave({
      ...widget.equipo,
      // Campos de t_computo_detalles_generales
      'inventario': _inventarioController.text.trim(),
      'tipo_equipo': _tipoEquipoController.text.trim(),
      'marca': _marcaController.text.trim(),
      'modelo': _modeloController.text.trim(),
      'procesador': _procesadorController.text.trim(),
      'numero_serie': _numeroSerieController.text.trim(),
      'disco_duro': _discoDuroController.text.trim(),
      'memoria_ram': _memoriaController.text.trim(),
      
      // Campos de t_computo_software
      'sistema_operativo_instalado': _sistemaOperativoController.text.trim(),
      'etiqueta_sistema_operativo': _etiquetaSoController.text.trim(),
      'office_instalado': _officeInstaladoController.text.trim(),
      
      // Campos de t_computo_identificacion
      'tipo_uso': _tipoUsoController.text.trim(),
      'nombre_equipo_dominio': _nombreEquipoDominioController.text.trim(),
      'status': _statusController.text.trim(),
      'direccion_administrativa': _direccionAdministrativaController.text.trim(),
      'subdireccion': _subdireccionController.text.trim(),
      'gerencia': _gerenciaController.text.trim(),
      
      // Campos de t_computo_ubicacion
      'direccion_fisica': _direccionFisicaController.text.trim(),
      'estado_ubicacion': _estadoController.text.trim(),
      'ciudad': _ciudadController.text.trim(),
      'tipo_edificio': _tipoEdificioController.text.trim(),
      'nombre_edificio': _nombreEdificioController.text.trim(),
      
      // Campos de t_computo_usuario_final
      'nombre_final': _nombreFinalController.text.trim(),
      'apellido_paterno_final': _apellidoPaternoFinalController.text.trim(),
      'apellido_materno_final': _apellidoMaternoFinalController.text.trim(),
      'expediente_final': _expedienteFinalController.text.trim(),
      'empresa_final': _empresaFinalController.text.trim(),
      'puesto_final': _puestoFinalController.text.trim(),
      
      // Campos de t_computo_usuario_responsable
      'nombre_responsable': _nombreResponsableController.text.trim(),
      'apellido_paterno_responsable': _apellidoPaternoResponsableController.text.trim(),
      'apellido_materno_responsable': _apellidoMaternoResponsableController.text.trim(),
      'expediente_responsable': _expedienteResponsableController.text.trim(),
      'empresa_responsable': _empresaResponsableController.text.trim(),
      'puesto_responsable': _puestoResponsableController.text.trim(),
      
      // Campos de t_computo_observaciones
      'observaciones': _observacionesController.text.trim(),
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isNuevoEquipo = widget.equipo.isEmpty;
    return AlertDialog(
      title: Text(isNuevoEquipo ? 'Agregar Equipo' : 'Editar Equipo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón para rellenar con datos ficticios (solo para equipos nuevos)
            if (isNuevoEquipo)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: OutlinedButton.icon(
                  onPressed: _rellenarDatosFicticios,
                  icon: const Icon(Icons.auto_fix_high, color: Colors.orange),
                  label: const Text(
                    'Rellenar con datos ficticios',
                    style: TextStyle(color: Colors.orange),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            // Sección: Información General del Equipo
            _buildSectionTitle('Información General del Equipo'),
            TextField(
              controller: _inventarioController,
              decoration: InputDecoration(
                labelText: 'Inventario',
                prefixIcon: const Icon(Icons.inventory_2, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              enabled: !isNuevoEquipo, // Solo editable si es edición
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tipoEquipoController,
              decoration: InputDecoration(
                labelText: 'Tipo de Equipo *',
                prefixIcon: const Icon(Icons.category, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _marcaController,
              decoration: InputDecoration(
                labelText: 'Marca',
                prefixIcon: const Icon(Icons.branding_watermark, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _modeloController,
              decoration: InputDecoration(
                labelText: 'Modelo',
                prefixIcon: const Icon(Icons.model_training, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _procesadorController,
              decoration: InputDecoration(
                labelText: 'Procesador',
                prefixIcon: const Icon(Icons.memory, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _numeroSerieController,
              decoration: InputDecoration(
                labelText: 'Número de Serie',
                prefixIcon: const Icon(Icons.qr_code, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _discoDuroController,
              decoration: InputDecoration(
                labelText: 'Disco Duro',
                prefixIcon: const Icon(Icons.storage, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _memoriaController,
              decoration: InputDecoration(
                labelText: 'Memoria RAM',
                prefixIcon: const Icon(Icons.ramp_right, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            
            // Sección: Software
            const SizedBox(height: 24),
            _buildSectionTitle('Software'),
            TextField(
              controller: _sistemaOperativoController,
              decoration: InputDecoration(
                labelText: 'Sistema Operativo Instalado',
                prefixIcon: const Icon(Icons.desktop_windows, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _etiquetaSoController,
              decoration: InputDecoration(
                labelText: 'Etiqueta Sistema Operativo',
                prefixIcon: const Icon(Icons.label, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _officeInstaladoController,
              decoration: InputDecoration(
                labelText: 'Office Instalado',
                prefixIcon: const Icon(Icons.description, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            
            // Sección: Identificación
            const SizedBox(height: 24),
            _buildSectionTitle('Identificación'),
            TextField(
              controller: _tipoUsoController,
              decoration: InputDecoration(
                labelText: 'Tipo de Uso',
                prefixIcon: const Icon(Icons.work, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nombreEquipoDominioController,
              decoration: InputDecoration(
                labelText: 'Nombre Equipo/Dominio',
                prefixIcon: const Icon(Icons.dns, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _statusController,
              decoration: InputDecoration(
                labelText: 'Status',
                prefixIcon: const Icon(Icons.info, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _direccionAdministrativaController,
              decoration: InputDecoration(
                labelText: 'Dirección Administrativa',
                prefixIcon: const Icon(Icons.business, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _subdireccionController,
              decoration: InputDecoration(
                labelText: 'Subdirección',
                prefixIcon: const Icon(Icons.business_center, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _gerenciaController,
              decoration: InputDecoration(
                labelText: 'Gerencia',
                prefixIcon: const Icon(Icons.corporate_fare, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            
            // Sección: Ubicación
            const SizedBox(height: 24),
            _buildSectionTitle('Ubicación'),
            TextField(
              controller: _direccionFisicaController,
              decoration: InputDecoration(
                labelText: 'Dirección Física',
                prefixIcon: const Icon(Icons.location_on, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _estadoController,
              decoration: InputDecoration(
                labelText: 'Estado',
                prefixIcon: const Icon(Icons.map, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ciudadController,
              decoration: InputDecoration(
                labelText: 'Ciudad',
                prefixIcon: const Icon(Icons.location_city, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tipoEdificioController,
              decoration: InputDecoration(
                labelText: 'Tipo de Edificio',
                prefixIcon: const Icon(Icons.apartment, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nombreEdificioController,
              decoration: InputDecoration(
                labelText: 'Nombre del Edificio',
                prefixIcon: const Icon(Icons.apartment, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            
            // Sección: Usuario Final
            const SizedBox(height: 24),
            _buildSectionTitle('Usuario Final'),
            TextField(
              controller: _nombreFinalController,
              decoration: InputDecoration(
                labelText: 'Nombre *',
                prefixIcon: const Icon(Icons.person, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apellidoPaternoFinalController,
              decoration: InputDecoration(
                labelText: 'Apellido Paterno',
                prefixIcon: const Icon(Icons.badge, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apellidoMaternoFinalController,
              decoration: InputDecoration(
                labelText: 'Apellido Materno',
                prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _expedienteFinalController,
              decoration: InputDecoration(
                labelText: 'Expediente',
                prefixIcon: const Icon(Icons.assignment_ind, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _empresaFinalController,
              decoration: InputDecoration(
                labelText: 'Empresa *',
                prefixIcon: const Icon(Icons.business, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _puestoFinalController,
              decoration: InputDecoration(
                labelText: 'Puesto',
                prefixIcon: const Icon(Icons.work_outline, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            
            // Sección: Usuario Responsable
            const SizedBox(height: 24),
            _buildSectionTitle('Usuario Responsable'),
            TextField(
              controller: _nombreResponsableController,
              decoration: InputDecoration(
                labelText: 'Nombre Responsable',
                prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apellidoPaternoResponsableController,
              decoration: InputDecoration(
                labelText: 'Apellido Paterno Responsable',
                prefixIcon: const Icon(Icons.badge, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apellidoMaternoResponsableController,
              decoration: InputDecoration(
                labelText: 'Apellido Materno Responsable',
                prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _expedienteResponsableController,
              decoration: InputDecoration(
                labelText: 'Expediente Responsable',
                prefixIcon: const Icon(Icons.assignment_ind, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _empresaResponsableController,
              decoration: InputDecoration(
                labelText: 'Empresa Responsable',
                prefixIcon: const Icon(Icons.business, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _puestoResponsableController,
              decoration: InputDecoration(
                labelText: 'Puesto Responsable',
                prefixIcon: const Icon(Icons.work_outline, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            
            // Sección: Observaciones
            const SizedBox(height: 24),
            _buildSectionTitle('Observaciones'),
            TextField(
              controller: _observacionesController,
              decoration: InputDecoration(
                labelText: 'Observaciones',
                prefixIcon: const Icon(Icons.note, color: Color(0xFF003366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF003366),
            foregroundColor: Colors.white,
          ),
          child: Text(widget.equipo.isEmpty ? 'Agregar' : 'Guardar'),
        ),
      ],
    );
  }
}
