import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:excel/excel.dart' as excel_lib show Border, BorderStyle;
import 'dart:io';
import '../../domain/entities/inventory_session.dart';
import '../../domain/entities/inventario_completo.dart';
import '../../data/local/inventory_session_storage.dart';
import '../../core/di/injection_container.dart';
import '../../domain/repositories/inventario_repository.dart';
import '../../app/config/supabase_client.dart' show supabaseClient;
import '../../core/utils/file_saver_helper.dart';
import 'completed_inventory_detail_screen.dart';
import 'category_inventory_screen.dart';
import 'jumper_categories_screen.dart' show JumperCategories, JumperCategory, JumperCategoriesScreen;
import '../computo/inventario_computo_screen.dart';
import '../sicor/inventario_tarjetas_red_screen.dart';
import '../../domain/entities/categoria.dart';
import '../../data/services/computo_export_service.dart';
import '../../data/services/jumpers_export_service.dart';

enum SortBy {
  category,
  date,
  items,
  user,
}

enum FilterStatus {
  all,
  pending,
  completed,
}

class CompletedInventoriesScreen extends StatefulWidget {
  const CompletedInventoriesScreen({super.key});

  @override
  State<CompletedInventoriesScreen> createState() => _CompletedInventoriesScreenState();
}

class _CompletedInventoriesScreenState extends State<CompletedInventoriesScreen> {
  final InventorySessionStorage _sessionStorage = serviceLocator.get<InventorySessionStorage>();
  final InventarioRepository _inventarioRepository = serviceLocator.get<InventarioRepository>();
  List<InventorySession> _allSessions = [];
  List<InventorySession> _filteredSessions = [];
  bool _isLoading = true;
  SortBy _sortBy = SortBy.date;
  bool _sortAscending = false;
  FilterStatus _statusFilter = FilterStatus.all;
  String? _categoryFilter;
  String? _jumperCategoryFilter;
  Set<String> _selectedSessionIds = {}; // IDs de sesiones seleccionadas para exportar
  bool _isSelectionMode = false; // Modo de selección múltiple
  bool _filtersExpanded = true; // Estado de expansión de los filtros

  @override
  void initState() {
    super.initState();
    _loadAllSessions();
  }

  Future<void> _loadAllSessions() async {
    try {
      setState(() {
        _isLoading = true;
      });

      var allSessions = await _sessionStorage.getAllSessions();
      
      // Verificar si el usuario es admin
      final isAdmin = await _checkIsAdmin();
      
      // Si no es admin, filtrar solo los inventarios del usuario actual
      if (!isAdmin) {
        final prefs = await SharedPreferences.getInstance();
        final currentUserId = prefs.getString('id_empleado');
        
        if (currentUserId != null) {
          allSessions = allSessions.where((s) => s.ownerId == currentUserId).toList();
        }
      }

      setState(() {
        _allSessions = allSessions;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar inventarios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    var filtered = List<InventorySession>.from(_allSessions);

    // Filtrar por estado
    if (_statusFilter == FilterStatus.pending) {
      filtered = filtered.where((s) => s.status == InventorySessionStatus.pending).toList();
    } else if (_statusFilter == FilterStatus.completed) {
      filtered = filtered.where((s) => s.status == InventorySessionStatus.completed).toList();
    }

    // Filtrar por categoría principal
    if (_categoryFilter != null) {
      filtered = filtered.where((s) {
        final categoryLower = s.categoryName.toLowerCase();
        if (_categoryFilter == 'Jumpers') {
          return categoryLower.contains('jumper');
        } else if (_categoryFilter == 'Equipo de Cómputo') {
          return categoryLower.contains('comput') || categoryLower.contains('cómputo') || categoryLower.contains('computo');
        } else if (_categoryFilter == 'SICOR') {
          return categoryLower.contains('medición') || categoryLower.contains('medicion') || categoryLower.contains('sicor');
        }
        return true;
      }).toList();
    }

    // Filtrar por subcategoría de jumper
    if (_jumperCategoryFilter != null && _categoryFilter == 'Jumpers') {
      filtered = filtered.where((s) {
        // Aquí podrías agregar lógica adicional si guardas la subcategoría en la sesión
        // Por ahora, solo filtramos si es jumper
        return s.categoryName.toLowerCase().contains('jumper');
      }).toList();
    }

    // Aplicar ordenamiento
    switch (_sortBy) {
      case SortBy.category:
        filtered.sort((a, b) {
          final comparison = a.categoryName.compareTo(b.categoryName);
          return _sortAscending ? comparison : -comparison;
        });
        break;
      case SortBy.date:
        filtered.sort((a, b) {
          final comparison = a.updatedAt.compareTo(b.updatedAt);
          return _sortAscending ? comparison : -comparison;
        });
        break;
      case SortBy.items:
        filtered.sort((a, b) {
          final comparison = a.quantities.length.compareTo(b.quantities.length);
          return _sortAscending ? comparison : -comparison;
        });
        break;
      case SortBy.user:
        filtered.sort((a, b) {
          final nameA = a.ownerName ?? '';
          final nameB = b.ownerName ?? '';
          final comparison = nameA.compareTo(nameB);
          return _sortAscending ? comparison : -comparison;
        });
        break;
    }

    setState(() {
      _filteredSessions = filtered;
    });
  }

  void _onSortChanged(SortBy? newSort) {
    if (newSort == null) return;
    
    if (_sortBy == newSort) {
      setState(() {
        _sortAscending = !_sortAscending;
      });
    } else {
      setState(() {
        _sortBy = newSort;
        _sortAscending = false;
      });
    }
    _applyFilters();
  }

  void _onStatusFilterChanged(FilterStatus? status) {
    if (status == null) return;
    setState(() {
      _statusFilter = status;
      if (status != FilterStatus.all) {
        _jumperCategoryFilter = null; // Reset jumper filter when changing status
      }
    });
    _applyFilters();
  }

  void _onCategoryFilterChanged(String? category) {
    setState(() {
      _categoryFilter = category;
      if (category != 'Jumpers') {
        _jumperCategoryFilter = null; // Reset jumper filter if not jumpers
      }
    });
    _applyFilters();
  }

  void _onJumperCategoryFilterChanged(String? jumperCategory) {
    setState(() {
      _jumperCategoryFilter = jumperCategory;
    });
    _applyFilters();
  }

  Future<void> _viewInventory(InventorySession session) async {
    // Log inmediato al inicio, antes de cualquier cosa
    print('🚨🚨🚨 _viewInventory LLAMADO 🚨🚨🚨');
    print('🚨 session.id: ${session.id}');
    print('🚨 session.categoryName: "${session.categoryName}"');
    print('🚨 session.categoryId: ${session.categoryId}');
    print('🚨 session.status: ${session.status}');
    debugPrint('🔍 _viewInventory llamado:');
    debugPrint('   - session.id: ${session.id}');
    debugPrint('   - session.categoryName: ${session.categoryName}');
    debugPrint('   - session.categoryId: ${session.categoryId}');
    debugPrint('   - session.status: ${session.status}');
    
    // Verificar permisos de admin: solo puede ver detalles de inventarios pendientes de otros usuarios
    final isAdmin = await _checkIsAdmin();
    if (isAdmin) {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('id_empleado');
      
      // Si el inventario está completado, no permitir ver detalles
      if (session.status == InventorySessionStatus.completed) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Como administrador, solo puedes ver detalles de inventarios pendientes de otros usuarios'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      
      // Si el inventario es del mismo admin, no permitir ver detalles
      if (session.ownerId == currentUserId) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Como administrador, solo puedes ver detalles de inventarios pendientes de otros usuarios'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      
      // Si el inventario está pendiente pero no es del admin, permitir verlo
      // (continuar con el flujo normal)
    }
    
    try {
      
      // PRIMERO: Verificar si es SICOR (antes que cómputo)
      final categoryNameLower = session.categoryName.toLowerCase().trim();
      print('🚨 Verificando SICOR:');
      print('   - categoryNameLower: "$categoryNameLower"');
      print('   - contains sicor: ${categoryNameLower.contains('sicor')}');
      print('   - contains medición: ${categoryNameLower.contains('medición')}');
      print('   - contains medicion: ${categoryNameLower.contains('medicion')}');
      
      final isSicor = categoryNameLower.contains('sicor') || 
                     categoryNameLower.contains('medición') || 
                     categoryNameLower.contains('medicion');
      
      print('   - isSicor: $isSicor');
      
      if (isSicor) {
        debugPrint('✅ SICOR detectado en _viewInventory');
        if (session.status == InventorySessionStatus.pending) {
          debugPrint('✅ Redirigiendo a InventarioTarjetasRedScreen (SICOR pendiente)');
          if (!mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InventarioTarjetasRedScreen(
                sessionId: session.id,
              ),
            ),
          );
        } else {
          debugPrint('⚠️ SICOR completado, mostrando detalles');
          // Para SICOR completado, necesitamos obtener la categoría
          if (session.categoryId > 0) {
            final categoria = await _inventarioRepository.getCategoriaById(session.categoryId);
            if (categoria != null && mounted) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CompletedInventoryDetailScreen(
                    session: session,
                    categoria: categoria,
                  ),
                ),
              );
            }
          }
        }
        
        // Recargar sesiones al volver
        if (mounted) {
          _loadAllSessions();
        }
        return;
      }
      
      // Manejo especial para "Equipo de Cómputo" que no tiene categoría en la BD
      // Verificar por categoryId primero (más confiable)
      final isComputo = session.categoryId == -1 || 
                       categoryNameLower.contains('comput') ||
                       categoryNameLower.contains('cómputo');
      
      if (isComputo) {
        if (session.status == InventorySessionStatus.pending) {
          // Si está pendiente, redirigir a la pantalla de inventario de cómputo
          if (!mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const InventarioComputoScreen(),
            ),
          );
        } else {
          // Si está completada, mostrar los detalles usando una categoría dummy
          if (!mounted) return;
          // Crear una categoría dummy para mostrar los detalles
          final categoriaDummy = Categoria(
            idCategoria: -1,
            nombre: 'Equipo de Cómputo',
            descripcion: 'Equipos de cómputo',
          );
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CompletedInventoryDetailScreen(
                session: session,
                categoria: categoriaDummy,
              ),
            ),
          );
        }
        
        // Recargar sesiones al volver
        if (mounted) {
          _loadAllSessions();
        }
        return;
      }
      
      // Para otras categorías, verificar que el categoryId sea válido antes de buscar
      if (session.categoryId <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La categoría asociada no es válida'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Para otras categorías, usar el flujo normal
      final categoria = await _inventarioRepository.getCategoriaById(session.categoryId);
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

      // Verificar si es SICOR antes de continuar (tanto por nombre como por ID de categoría)
      final categoriaNombreLower = categoria.nombre.toLowerCase().trim();
      final isSicorFromCategoria = categoryNameLower.contains('sicor') || 
                                   categoryNameLower.contains('medición') || 
                                   categoryNameLower.contains('medicion') ||
                                   categoriaNombreLower.contains('sicor') ||
                                   categoriaNombreLower.contains('medición') ||
                                   categoriaNombreLower.contains('medicion');

      // Si la sesión está pendiente, redirigir al inventario para continuarlo
      if (session.status == InventorySessionStatus.pending) {
        // Debug: imprimir información de la sesión
        debugPrint('🔍 Sesión pendiente detectada (después de obtener categoría):');
        debugPrint('   - categoryName: ${session.categoryName}');
        debugPrint('   - categoryNameLower: $categoryNameLower');
        debugPrint('   - categoryId: ${session.categoryId}');
        debugPrint('   - categoria.nombre: ${categoria.nombre}');
        debugPrint('   - categoriaNombreLower: $categoriaNombreLower');
        debugPrint('   - isSicorFromCategoria: $isSicorFromCategoria');
        
        // Verificar si es inventario de cómputo
        if (session.categoryId == -1 || categoryNameLower.contains('comput')) {
          debugPrint('✅ Redirigiendo a InventarioComputoScreen');
          // Navegar directamente a la pantalla de inventario de cómputo
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const InventarioComputoScreen(),
            ),
          );
        } 
        // Verificar si es SICOR (tarjetas de red)
        else if (isSicorFromCategoria) {
          debugPrint('✅ Redirigiendo a InventarioTarjetasRedScreen (SICOR)');
          // Navegar directamente a la pantalla de inventario de tarjetas de red (SICOR)
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InventarioTarjetasRedScreen(
                sessionId: session.id,
              ),
            ),
          );
        } 
        else {
          debugPrint('⚠️ No se detectó categoría especial, usando _openPendingSession');
          await _openPendingSession(session, categoria);
        }
      } else {
        // Si está completada, mostrar los detalles
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CompletedInventoryDetailScreen(
              session: session,
              categoria: categoria,
            ),
          ),
        );
      }
      
      // Recargar sesiones al volver
      if (mounted) {
        _loadAllSessions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir inventario: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openPendingSession(InventorySession session, categoria) async {
    try {
      debugPrint('🔍 _openPendingSession llamado:');
      debugPrint('   - session.categoryName: ${session.categoryName}');
      debugPrint('   - categoria.nombre: ${categoria.nombre}');
      
      // Verificar si es Jumpers y si tiene subcategoría en el nombre
      final categoryNameLower = session.categoryName.toLowerCase();
      final categoriaNombreLower = categoria.nombre.toLowerCase();
      
      // Verificar si es SICOR (más robusto)
      final isSicor = categoryNameLower.contains('sicor') || 
                     categoryNameLower.contains('medición') || 
                     categoryNameLower.contains('medicion') ||
                     categoriaNombreLower.contains('sicor') ||
                     categoriaNombreLower.contains('medición') ||
                     categoriaNombreLower.contains('medicion');
      
      debugPrint('   - isSicor: $isSicor');
      
      if (isSicor) {
        debugPrint('✅ SICOR detectado en _openPendingSession, redirigiendo a InventarioTarjetasRedScreen');
        // Navegar a la pantalla de inventario de tarjetas de red (SICOR)
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InventarioTarjetasRedScreen(
              sessionId: session.id,
            ),
          ),
        );
        return;
      }
      
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
                sessionId: session.id,
              ),
            ),
          );
        }
      } else {
        // Para otras categorías, verificar una vez más si es SICOR antes de ir a CategoryInventoryScreen
        final categoriaNombreLower = categoria.nombre.toLowerCase();
        final categoryNameLower = session.categoryName.toLowerCase();
        final isSicorFinal = categoryNameLower.contains('sicor') || 
                            categoryNameLower.contains('medición') || 
                            categoryNameLower.contains('medicion') ||
                            categoriaNombreLower.contains('sicor') ||
                            categoriaNombreLower.contains('medición') ||
                            categoriaNombreLower.contains('medicion');
        
        debugPrint('🔍 Verificación final en else:');
        debugPrint('   - categoryNameLower: $categoryNameLower');
        debugPrint('   - categoriaNombreLower: $categoriaNombreLower');
        debugPrint('   - isSicorFinal: $isSicorFinal');
        
        if (isSicorFinal) {
          debugPrint('✅ SICOR detectado en else final, redirigiendo a InventarioTarjetasRedScreen');
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InventarioTarjetasRedScreen(
                sessionId: session.id,
              ),
            ),
          );
          return;
        }
        
        // Para otras categorías, navegar directamente a la pantalla de inventario
        debugPrint('⚠️ No es SICOR, usando CategoryInventoryScreen');
        final isAdmin = await _checkIsAdmin();
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryInventoryScreen(
              categoria: categoria,
              categoriaNombre: session.categoryName,
              sessionId: session.id,
              isAdmin: isAdmin,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir el inventario guardado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  Future<void> _deleteSession(InventorySession session) async {
    // Mostrar diálogo de confirmación
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Eliminar inventario'),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Estás seguro de que deseas eliminar este inventario?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.label,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            session.categoryName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          session.status == InventorySessionStatus.pending
                              ? Icons.pause_circle
                              : Icons.check_circle,
                          size: 16,
                          color: session.status == InventorySessionStatus.pending
                              ? Colors.orange
                              : Colors.green,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          session.status == InventorySessionStatus.pending
                              ? 'Pendiente'
                              : 'Finalizado',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Esta acción no se puede deshacer.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.red[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    // Si el usuario confirmó, eliminar la sesión
    if (confirmDelete == true) {
      try {
        await _sessionStorage.deleteSession(session.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${session.status == InventorySessionStatus.pending ? "Inventario pendiente" : "Inventario finalizado"} eliminado correctamente',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // Recargar las sesiones
          _loadAllSessions();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar inventario: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSelectionMode 
              ? '${_selectedSessionIds.length} seleccionado${_selectedSessionIds.length != 1 ? 's' : ''}'
              : 'Historial de Inventarios',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedSessionIds.clear();
                  });
                },
              )
            : null,
        actions: [
          if (_isSelectionMode) ...[
            if (_selectedSessionIds.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.select_all),
                tooltip: 'Seleccionar todos',
                onPressed: () {
                  setState(() {
                    _selectedSessionIds = _filteredSessions
                        .where((s) => s.status == InventorySessionStatus.completed)
                        .map((s) => s.id)
                        .toSet();
                  });
                },
              ),
            if (_selectedSessionIds.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.file_download),
                tooltip: 'Exportar seleccionados',
                onPressed: _exportSelectedInventories,
              ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.checklist),
              tooltip: 'Seleccionar para exportar',
              onPressed: () {
                setState(() {
                  _isSelectionMode = true;
                });
              },
            ),
            PopupMenuButton<SortBy>(
            icon: const Icon(Icons.sort),
            tooltip: 'Ordenar',
            onSelected: _onSortChanged,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: SortBy.category,
                child: Row(
                  children: [
                    Icon(
                      Icons.category,
                      size: 20,
                      color: _sortBy == SortBy.category
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Por tipo de inventario'),
                    if (_sortBy == SortBy.category)
                      Icon(
                        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SortBy.date,
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: _sortBy == SortBy.date
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Por fecha'),
                    if (_sortBy == SortBy.date)
                      Icon(
                        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SortBy.items,
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2,
                      size: 20,
                      color: _sortBy == SortBy.items
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Por cantidad de items'),
                    if (_sortBy == SortBy.items)
                      Icon(
                        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SortBy.user,
                child: Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 20,
                      color: _sortBy == SortBy.user
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Por usuario'),
                    if (_sortBy == SortBy.user)
                      Icon(
                        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
              ),
            ],
          ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final padding = isMobile ? 12.0 : 20.0;

                if (_filteredSessions.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 80,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay inventarios',
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 20,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Los inventarios que realices aparecerán aquí',
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadAllSessions,
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Barra de filtros
                        _buildFilterBar(isMobile),
                        const SizedBox(height: 16),
                        // Estadísticas
                        _buildStatsBar(isMobile),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _filteredSessions.length,
                            itemBuilder: (context, index) {
                              final session = _filteredSessions[index];
                              return _buildInventoryCard(session, isMobile);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildFilterBar(bool isMobile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: Icon(
          Icons.filter_list,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          'Filtros',
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        trailing: Icon(
          _filtersExpanded ? Icons.expand_less : Icons.expand_more,
          color: Theme.of(context).colorScheme.primary,
        ),
        initiallyExpanded: _filtersExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _filtersExpanded = expanded;
          });
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filtro por estado
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChip(
                      'Todos',
                      _statusFilter == FilterStatus.all,
                      () => _onStatusFilterChanged(FilterStatus.all),
                      Icons.all_inclusive,
                    ),
                    _buildFilterChip(
                      'Pendientes',
                      _statusFilter == FilterStatus.pending,
                      () => _onStatusFilterChanged(FilterStatus.pending),
                      Icons.pause_circle,
                      Colors.orange,
                    ),
                    _buildFilterChip(
                      'Finalizados',
                      _statusFilter == FilterStatus.completed,
                      () => _onStatusFilterChanged(FilterStatus.completed),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Filtro por categoría
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChip(
                      'Todas las categorías',
                      _categoryFilter == null,
                      () => _onCategoryFilterChanged(null),
                      Icons.category,
                    ),
                    _buildFilterChip(
                      'Jumpers',
                      _categoryFilter == 'Jumpers',
                      () => _onCategoryFilterChanged('Jumpers'),
                      Icons.cable,
                      Colors.blue,
                    ),
                    _buildFilterChip(
                      'Equipo de Cómputo',
                      _categoryFilter == 'Equipo de Cómputo',
                      () => _onCategoryFilterChanged('Equipo de Cómputo'),
                      Icons.computer,
                      Colors.purple,
                    ),
                    _buildFilterChip(
                      'SICOR',
                      _categoryFilter == 'SICOR',
                      () => _onCategoryFilterChanged('SICOR'),
                      Icons.straighten,
                      Colors.green,
                    ),
                  ],
                ),
                // Filtro por subcategoría de jumper (solo si está seleccionado Jumpers)
                if (_categoryFilter == 'Jumpers') ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip(
                        'Todos los jumpers',
                        _jumperCategoryFilter == null,
                        () => _onJumperCategoryFilterChanged(null),
                        Icons.cable,
                      ),
                      ...JumperCategories.all.map((jumperCat) => _buildFilterChip(
                        jumperCat.displayName,
                        _jumperCategoryFilter == jumperCat.name,
                        () => _onJumperCategoryFilterChanged(jumperCat.name),
                        jumperCat.icon,
                        jumperCat.color,
                      )),
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

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    VoidCallback onTap, [
    IconData? icon,
    Color? color,
  ]) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: isSelected ? Colors.white : (color ?? Theme.of(context).colorScheme.primary)),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: color ?? Theme.of(context).colorScheme.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildStatsBar(bool isMobile) {
    final pendingCount = _allSessions.where((s) => s.status == InventorySessionStatus.pending).length;
    final completedCount = _allSessions.where((s) => s.status == InventorySessionStatus.completed).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Total',
              '${_filteredSessions.length}',
              Icons.inventory_2,
              Theme.of(context).colorScheme.primary,
              isMobile,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _buildStatItem(
              'Pendientes',
              '$pendingCount',
              Icons.pause_circle,
              Colors.orange,
              isMobile,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _buildStatItem(
              'Finalizados',
              '$completedCount',
              Icons.check_circle,
              Colors.green,
              isMobile,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color, bool isMobile) {
    return Column(
      children: [
        Icon(icon, color: color, size: isMobile ? 20 : 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 10 : 12,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryCard(InventorySession session, bool isMobile) {
    final itemCount = session.quantities.length;
    final dateStr = _formatDate(session.updatedAt);
    final isPending = session.status == InventorySessionStatus.pending;
    final statusColor = isPending ? Colors.orange : Colors.green;
    final statusIcon = isPending ? Icons.pause_circle : Icons.check_circle;
    final isSelected = _selectedSessionIds.contains(session.id);
    final canSelect = !isPending && _isSelectionMode;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: canSelect
            ? () {
                setState(() {
                  if (isSelected) {
                    _selectedSessionIds.remove(session.id);
                  } else {
                    _selectedSessionIds.add(session.id);
                  }
                });
              }
            : () {
                print('🚨🚨🚨 CARD TAP (onTap) 🚨🚨🚨');
                print('🚨 session.categoryName: "${session.categoryName}"');
                _viewInventory(session);
              },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (canSelect) ...[
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedSessionIds.add(session.id);
                          } else {
                            _selectedSessionIds.remove(session.id);
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      statusIcon,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.categoryName,
                          style: TextStyle(
                            fontSize: isMobile ? 18 : 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isPending ? 'Pendiente' : 'Finalizado',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.inventory_2,
                    '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                    isMobile,
                  ),
                  const SizedBox(width: 8),
                  if (session.ownerName != null)
                    _buildInfoChip(
                      Icons.person,
                      session.ownerName!,
                      isMobile,
                    ),
                ],
              ),
              if (!canSelect) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        print('🚨🚨🚨 BOTÓN CONTINUAR/VER DETALLES PRESIONADO 🚨🚨🚨');
                        print('🚨 session.categoryName: "${session.categoryName}"');
                        print('🚨 session.categoryId: ${session.categoryId}');
                        print('🚨 session.status: ${session.status}');
                        _viewInventory(session);
                      },
                      icon: Icon(
                        isPending ? Icons.play_arrow : Icons.visibility,
                        size: 18,
                      ),
                      label: Text(isPending ? 'Continuar' : 'Ver detalles'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF003366),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _deleteSession(session),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                      ),
                      label: const Text('Eliminar'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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

  String _getMonthYear() {
    final now = DateTime.now();
    final months = [
      'ENERO', 'FEBRERO', 'MARZO', 'ABRIL', 'MAYO', 'JUNIO',
      'JULIO', 'AGOSTO', 'SEPTIEMBRE', 'OCTUBRE', 'NOVIEMBRE', 'DICIEMBRE'
    ];
    return '${months[now.month - 1]} ${now.year}';
  }

  /// Extrae solo el nombre de la subcategoría del nombre de la categoría
  /// Ej: "jumpers SC-SC" -> "SC-SC"
  /// Si no es un jumper, devuelve el nombre completo
  String _getCategoryDisplayName(String categoryName) {
    final categoryNameLower = categoryName.toLowerCase();
    
    // Si es un jumper, extraer solo la subcategoría
    if (categoryNameLower.contains('jumper')) {
      for (final jumperCategory in JumperCategories.all) {
        if (categoryName.contains(jumperCategory.displayName)) {
          return jumperCategory.displayName;
        }
      }
    }
    
    // Si no es jumper o no se encontró subcategoría, devolver el nombre completo
    return categoryName;
  }

  /// Filtra items por subcategoría de jumper si aplica
  List<InventarioCompleto> _filterItemsByJumperCategory(
    List<InventarioCompleto> items,
    String categoryName,
  ) {
    JumperCategory? detectedJumperCategory;
    final categoryNameLower = categoryName.toLowerCase();
    
    if (categoryNameLower.contains('jumper')) {
      for (final jumperCategory in JumperCategories.all) {
        if (categoryName.contains(jumperCategory.displayName)) {
          detectedJumperCategory = jumperCategory;
          break;
        }
      }
    }
    
    if (detectedJumperCategory != null) {
      return items.where((item) {
        final nombre = item.producto.nombre.toUpperCase();
        final descripcion = (item.producto.descripcion ?? '').toUpperCase();
        final texto = '$nombre $descripcion';
        return _matchesJumperPattern(texto, detectedJumperCategory!.searchPattern);
      }).toList();
    }
    
    return items;
  }

  bool _matchesJumperPattern(String text, String pattern) {
    if (pattern.isEmpty) return false;
    final patterns = pattern.split('|');
    return patterns.any((p) => text.contains(p.trim()));
  }

  Future<void> _exportSelectedInventories() async {
    if (_selectedSessionIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un inventario para exportar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Obtener las sesiones seleccionadas para validar
    final selectedSessions = _allSessions
        .where((s) => _selectedSessionIds.contains(s.id))
        .where((s) => s.status == InventorySessionStatus.completed)
        .toList();

    if (selectedSessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo se pueden exportar inventarios finalizados'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Separar sesiones de cómputo, jumpers y otras
    final computoSessions = selectedSessions.where((s) => 
      s.categoryId == -1 || s.categoryName.toLowerCase().contains('comput')
    ).toList();
    
    final jumpersSessions = selectedSessions.where((s) => 
      s.categoryId != -1 && 
      !s.categoryName.toLowerCase().contains('comput') &&
      s.categoryName.toLowerCase().contains('jumper')
    ).toList();
    
    final otrasSessions = selectedSessions.where((s) => 
      s.categoryId != -1 && 
      !s.categoryName.toLowerCase().contains('comput') &&
      !s.categoryName.toLowerCase().contains('jumper')
    ).toList();

    // Si hay sesiones de cómputo, exportarlas usando ComputoExportService
    if (computoSessions.isNotEmpty) {
      try {
        // Mostrar indicador de carga
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Cargar equipos de cómputo desde la base de datos
        final equiposResponse = await supabaseClient
            .from('v_equipos_computo_completo')
            .select('*');
        
        final equiposList = List<Map<String, dynamic>>.from(equiposResponse);
        
        // Filtrar solo los equipos que están en las sesiones seleccionadas (completados = 1)
        final equiposCompletados = equiposList.where((equipo) {
          final inventario = (equipo['inventario']?.toString() ?? '').trim();
          if (inventario.isEmpty) return false;
          final inventarioHash = inventario.hashCode.abs();
          // Verificar si está en alguna de las sesiones de cómputo seleccionadas
          return computoSessions.any((session) => session.quantities[inventarioHash] == 1);
        }).toList();
        
        // Cargar componentes para cada equipo
        for (var equipo in equiposCompletados) {
          try {
            final inventarioEquipo = equipo['inventario']?.toString() ?? '';
            if (inventarioEquipo.isNotEmpty) {
              try {
                final componentesResponse = await supabaseClient
                    .from('v_componentes_computo_completo')
                    .select('*')
                    .eq('inventario_equipo', inventarioEquipo);
                
                equipo['t_componentes_computo'] = List<Map<String, dynamic>>.from(componentesResponse);
              } catch (e) {
                try {
                  final componentesResponseAlt = await supabaseClient
                      .from('t_componentes_computo')
                      .select('tipo_componente, marca, modelo, numero_serie')
                      .eq('inventario_equipo', inventarioEquipo);
                  
                  equipo['t_componentes_computo'] = List<Map<String, dynamic>>.from(componentesResponseAlt);
                } catch (e2) {
                  equipo['t_componentes_computo'] = [];
                }
              }
            } else {
              equipo['t_componentes_computo'] = [];
            }
          } catch (e) {
            equipo['t_componentes_computo'] = [];
          }
        }

        // Preparar datos para exportación según plantilla (14 columnas, incluyendo COMPONENTES)
        final itemsToExport = equiposCompletados.map((equipo) {
          // Formatear componentes: solo el tipo (MONITOR, TECLADO, MOUSE, etc.)
          final componentes = equipo['t_componentes_computo'] as List<dynamic>? ?? [];
          final componentesTexto = componentes
              .map((comp) => (comp['tipo_componente'] ?? '').toString().trim().toUpperCase())
              .where((tipo) => tipo.isNotEmpty)
              .join('; ');
          
          return {
            'inventario': equipo['inventario'] ?? '',
            'tipo_equipo': equipo['tipo_equipo'] ?? '',
            'marca': equipo['marca'] ?? '',
            'modelo': equipo['modelo'] ?? '',
            'procesador': equipo['procesador'] ?? '',
            'numero_serie': equipo['numero_serie'] ?? '',
            'disco_duro': equipo['disco_duro'] ?? '',
            'memoria': equipo['memoria'] ?? '',
            'sistema_operativo_instalado': equipo['sistema_operativo_instalado'] ?? equipo['sistema_operativo'] ?? '',
            'office_instalado': equipo['office_instalado'] ?? '',
            'empleado_asignado': equipo['empleado_asignado_nombre'] ?? equipo['empleado_asignado'] ?? '',
            'direccion_fisica': equipo['direccion_fisica'] ?? equipo['ubicacion_fisica'] ?? '',
            'observaciones': equipo['observaciones'] ?? '',
            'componentes': componentesTexto,
          };
        }).toList();

        final filePath = await ComputoExportService.exportComputoToExcel(itemsToExport);

        if (mounted) {
          Navigator.pop(context); // Cerrar diálogo de carga
          if (filePath != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Inventario de cómputo exportado: $filePath'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
              ),
            );
            
            // Salir del modo de selección
            setState(() {
              _isSelectionMode = false;
              _selectedSessionIds.clear();
            });
          }
        }
        return; // Solo exportar cómputo si hay sesiones de cómputo
      } catch (e) {
        if (mounted) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al exportar inventario de cómputo: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }
    }

    // Si hay sesiones de jumpers, exportarlas usando JumpersExportService
    if (jumpersSessions.isNotEmpty) {
      try {
        // Mostrar indicador de carga
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Preparar datos de todos los jumpers de las sesiones seleccionadas
        final itemsToExport = <Map<String, dynamic>>[];
        
        for (var session in jumpersSessions) {
          try {
            // Obtener la categoría
            final categoria = await _inventarioRepository.getCategoriaById(session.categoryId);
            if (categoria == null) continue;

            // Obtener todos los items de la categoría
            var allItems = await _inventarioRepository.getInventarioByCategoria(categoria.idCategoria);
            
            // Filtrar por subcategoría de jumper si aplica
            allItems = _filterItemsByJumperCategory(allItems, session.categoryName);

            // Obtener contenedores para todos los productos de una vez (optimizado)
            final idProductos = allItems.map((item) => item.producto.idProducto).toList();
            final contenedoresMap = await _inventarioRepository.getContenedoresByProductos(idProductos);

            // Agregar datos de cada producto
            for (var item in allItems) {
              // Si el item está en la sesión, usar esa cantidad, si no, usar la original
              final sessionQuantity = session.quantities.containsKey(item.producto.idProducto)
                  ? session.quantities[item.producto.idProducto]!
                  : item.cantidad;

              // Obtener contenedores de este producto
              final contenedores = contenedoresMap[item.producto.idProducto] ?? [];

              itemsToExport.add({
                'tipo': _getCategoryDisplayName(session.categoryName), // Tipo (solo subcategoría si es jumper)
                'tamano': item.producto.tamano?.toString() ?? '',
                'cantidad': sessionQuantity,
                'rack': item.producto.rack ?? '', // Mantener para compatibilidad
                'contenedor': item.producto.contenedor ?? '', // Mantener para compatibilidad
                'contenedores': contenedores.map((c) => {
                  'rack': c.rack ?? '',
                  'contenedor': c.contenedor,
                }).toList(),
              });
            }
          } catch (e) {
            debugPrint('Error al procesar inventario de jumpers ${session.id}: $e');
            // Continuar con el siguiente inventario
          }
        }

        if (itemsToExport.isEmpty) {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No hay datos de jumpers para exportar'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        final filePath = await JumpersExportService.exportJumpersToExcel(itemsToExport);

        if (mounted) {
          Navigator.pop(context); // Cerrar diálogo de carga
          if (filePath != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Inventario de jumpers exportado: $filePath'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
              ),
            );
            
            // Salir del modo de selección
            setState(() {
              _isSelectionMode = false;
              _selectedSessionIds.clear();
            });
          }
        }
        return; // Solo exportar jumpers si hay sesiones de jumpers
      } catch (e) {
        if (mounted) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al exportar inventario de jumpers: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }
    }

    // Si solo hay otras sesiones (no cómputo ni jumpers), usar el método original
    if (otrasSessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay inventarios seleccionados para exportar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Generar nombre por defecto
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}_${now.month.toString().padLeft(2, '0')}_${now.year}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final defaultFileName = 'Inventarios_Multiples_$dateStr.xlsx';

    try {
      // Mostrar indicador de carga
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );


      // Crear un nuevo archivo Excel
      var excel = Excel.createExcel();
      
      // Crear primero la hoja de inventario
      Sheet sheetObject = excel['Inventario'];
      
      // Eliminar todas las demás hojas (incluyendo Sheet1 si existe)
      final allSheets = excel.tables.keys.toList();
      for (final sheetName in allSheets) {
        if (sheetName != 'Inventario') {
          excel.delete(sheetName);
        }
      }

      // Agregar título (fila 0, columna 2 para centrarlo sobre las columnas)
      final titleCell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0));
      titleCell.value = TextCellValue('INVENTARIO JUMPERS ${_getMonthYear()}');
      titleCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 14,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
      
      // Agregar fila vacía
      sheetObject.appendRow([]);
      
      // Agregar encabezados (fila 2) - empezando desde columna A (índice 0)
      sheetObject.appendRow([
        TextCellValue('TIPO'),
        TextCellValue('TAMAÑO (metros)'),
        TextCellValue('CANTIDAD'),
        TextCellValue('RACK'),
        TextCellValue('CONTENEDOR'),
      ]);

      // Estilo para encabezados con bordes
      final headerStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        leftBorder: excel_lib.Border(borderStyle: excel_lib.BorderStyle.Thin),
        rightBorder: excel_lib.Border(borderStyle: excel_lib.BorderStyle.Thin),
        topBorder: excel_lib.Border(borderStyle: excel_lib.BorderStyle.Thin),
        bottomBorder: excel_lib.Border(borderStyle: excel_lib.BorderStyle.Thin),
      );
      
      // Aplicar estilo a encabezados (fila 2, índice 2)
      for (var col = 0; col < 5; col++) {
        final cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 2));
        cell.cellStyle = headerStyle;
      }

      // Procesar cada inventario seleccionado
      for (var session in otrasSessions) {
        try {
          // Obtener la categoría
          final categoria = await _inventarioRepository.getCategoriaById(session.categoryId);
          if (categoria == null) continue;

          // Obtener todos los items de la categoría
          var allItems = await _inventarioRepository.getInventarioByCategoria(categoria.idCategoria);
          
          // Filtrar por subcategoría de jumper si aplica
          allItems = _filterItemsByJumperCategory(allItems, session.categoryName);

          // Agregar datos de cada producto
          for (var item in allItems) {
            // Si el item está en la sesión, usar esa cantidad, si no, usar la original
            final sessionQuantity = session.quantities.containsKey(item.producto.idProducto)
                ? session.quantities[item.producto.idProducto]!
                : item.cantidad;

            final rowIndex = sheetObject.maxRows;
            sheetObject.appendRow([
              TextCellValue(_getCategoryDisplayName(session.categoryName)), // Tipo (solo subcategoría si es jumper)
              TextCellValue(item.producto.tamano?.toString() ?? ''), // Tamaño
              TextCellValue(sessionQuantity.toString()), // Cantidad
              TextCellValue(item.producto.rack ?? ''), // Rack
              TextCellValue(item.producto.contenedor ?? ''), // Contenedor
            ]);
            
            // Aplicar estilo con bordes y centrado a cada celda de la fila
            final dataStyle = CellStyle(
              horizontalAlign: HorizontalAlign.Center,
              verticalAlign: VerticalAlign.Center,
              leftBorder: excel_lib.Border(borderStyle: excel_lib.BorderStyle.Thin),
              rightBorder: excel_lib.Border(borderStyle: excel_lib.BorderStyle.Thin),
              topBorder: excel_lib.Border(borderStyle: excel_lib.BorderStyle.Thin),
              bottomBorder: excel_lib.Border(borderStyle: excel_lib.BorderStyle.Thin),
            );
            
            for (var col = 0; col < 5; col++) {
              final cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
              cell.cellStyle = dataStyle;
            }
          }
        } catch (e) {
          debugPrint('Error al procesar inventario ${session.id}: $e');
          // Continuar con el siguiente inventario
        }
      }

      // Ajustar ancho de columnas
      sheetObject.setColumnWidth(0, 25.0); // Tipo
      sheetObject.setColumnWidth(1, 12.0); // Tamaño
      sheetObject.setColumnWidth(2, 12.0); // Cantidad
      sheetObject.setColumnWidth(3, 15.0); // Rack
      sheetObject.setColumnWidth(4, 15.0); // Contenedor

      // Eliminar todas las hojas excepto "Inventario" justo antes de guardar
      final allSheetsBeforeSave = excel.tables.keys.toList();
      for (final sheetName in allSheetsBeforeSave) {
        if (sheetName != 'Inventario') {
          excel.delete(sheetName);
        }
      }

      // Guardar archivo en la ubicación seleccionada
      List<int>? fileBytes = excel.save();
      if (fileBytes == null) {
        if (mounted) {
          Navigator.pop(context); // Cerrar diálogo de carga
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al generar archivo Excel'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Usar el helper para guardar el archivo
      String? filePath = await FileSaverHelper.saveFile(
        fileBytes: fileBytes,
        defaultFileName: defaultFileName,
        dialogTitle: 'Guardar inventarios como',
      );
      
      if (filePath == null) {
        if (mounted) {
          Navigator.pop(context); // Cerrar diálogo de carga
        }
        return; // Usuario canceló
      }

      // Cerrar diálogo de carga
      if (mounted) {
        Navigator.pop(context);
      }

      // Mostrar diálogo de éxito
      if (mounted) {
        final fileName = filePath.split('/').last;
        _showExportSuccessDialog(filePath, fileName, otrasSessions.length);
        
        // Salir del modo de selección
        setState(() {
          _isSelectionMode = false;
          _selectedSessionIds.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        // Cerrar diálogo de carga si está abierto
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar inventarios: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showExportSuccessDialog(String filePath, String fileName, int inventoryCount) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Exportación exitosa ($inventoryCount inventario${inventoryCount != 1 ? 's' : ''})'),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Se exportaron $inventoryCount inventario${inventoryCount != 1 ? 's' : ''} correctamente:',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  filePath,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ubicación del archivo guardado',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop(); // Cerrar el diálogo primero
                
                // Intentar abrir la carpeta donde se guardó el archivo
                try {
                  final directory = Directory(filePath).parent;
                  
                  if (Platform.isLinux) {
                    await Process.run('xdg-open', [directory.path]);
                  } else if (Platform.isWindows) {
                    await Process.run('explorer', [directory.path]);
                  } else if (Platform.isMacOS) {
                    await Process.run('open', [directory.path]);
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Archivo guardado en: $filePath'),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ruta del archivo: $filePath'),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.folder_open, size: 18),
              label: const Text('Abrir carpeta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

}

