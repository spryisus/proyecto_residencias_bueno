import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/inventario_completo.dart';
import '../../domain/entities/categoria.dart';
import '../../domain/entities/inventory_session.dart';
import '../../domain/entities/producto.dart';
import '../../domain/repositories/inventario_repository.dart';
import '../../data/local/inventory_session_storage.dart';
import '../../core/di/injection_container.dart';
import '../../app/config/supabase_client.dart' show supabaseClient;
import 'jumper_categories_screen.dart' show JumperCategory;

class CategoryInventoryScreen extends StatefulWidget {
  final Categoria categoria;
  final String categoriaNombre;
  final String? sessionId;
  final String? ownerName;
  final String? ownerId;
  final bool isAdmin;
  final JumperCategory? jumperCategoryFilter;

  const CategoryInventoryScreen({
    super.key,
    required this.categoria,
    required this.categoriaNombre,
    this.sessionId,
    this.ownerName,
    this.ownerId,
    this.isAdmin = false,
    this.jumperCategoryFilter,
  });

  @override
  State<CategoryInventoryScreen> createState() => _CategoryInventoryScreenState();
}

enum SortOrder {
  none,
  ascending, // A-Z
  descending, // Z-A
}

class _CategoryInventoryScreenState extends State<CategoryInventoryScreen> {
  final InventarioRepository _inventarioRepository = serviceLocator.get<InventarioRepository>();
  final InventorySessionStorage _sessionStorage = serviceLocator.get<InventorySessionStorage>();
  List<InventarioCompleto> _items = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  InventorySession? _pendingSession;
  SortOrder _sortOrder = SortOrder.none;

  @override
  void initState() {
    super.initState();
    _loadInventory();
    _loadPendingSession();
  }

  Future<void> _loadInventory() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Obtener inventario por categoría
      final inventario = await _inventarioRepository.getInventarioByCategoria(widget.categoria.idCategoria);
      
      setState(() {
        _items = inventario;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<InventarioCompleto> get _filteredItems {
    // Filtrar por categoría de jumper si está especificada
    List<InventarioCompleto> filtered = _items;
    
    if (widget.jumperCategoryFilter != null) {
      final category = widget.jumperCategoryFilter!;
      
      // Filtrar por el patrón de la categoría
      filtered = filtered.where((item) {
        final nombre = item.producto.nombre.toUpperCase();
        final descripcion = (item.producto.descripcion ?? '').toUpperCase();
        final texto = '$nombre $descripcion';
        return _matchesJumperPattern(texto, category.searchPattern);
      }).toList();
    }
    
    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        return item.producto.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               (item.producto.rack?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
               (item.producto.contenedor?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    // Ordenar por contenedor si está seleccionado
    if (_sortOrder != SortOrder.none) {
      filtered = List.from(filtered);
      filtered.sort((a, b) {
        final ubicacionA = _buildRackContenedorText(a.producto.rack, a.producto.contenedor);
        final ubicacionB = _buildRackContenedorText(b.producto.rack, b.producto.contenedor);
        
        final comparison = ubicacionA.compareTo(ubicacionB);
        return _sortOrder == SortOrder.ascending ? comparison : -comparison;
      });
    }

    return filtered;
  }

  bool _matchesJumperPattern(String text, String pattern) {
    if (pattern.isEmpty) return false;
    final patterns = pattern.split('|');
    return patterns.any((p) => text.contains(p.trim()));
  }

  String _buildRackContenedorText(String? rack, String? contenedor) {
    if (rack != null && rack.isNotEmpty && contenedor != null && contenedor.isNotEmpty) {
      return '$rack - $contenedor';
    } else if (rack != null && rack.isNotEmpty) {
      return rack;
    } else if (contenedor != null && contenedor.isNotEmpty) {
      return contenedor;
    }
    return 'Sin ubicación';
  }

  Future<void> _performCompleteInventory(Map<InventarioCompleto, int> inventarioData) async {
    try {
      int itemsActualizados = 0;
      
      for (var entry in inventarioData.entries) {
        final item = entry.key;
        final nuevaCantidad = entry.value;
        final diferencia = nuevaCantidad - item.cantidad;
        
        if (diferencia != 0) {
          await _inventarioRepository.ajustarInventario(
            item.producto.idProducto,
            item.ubicacion.idUbicacion,
            diferencia,
            'Inventario completo de ${widget.categoriaNombre} - Conteo físico',
          );
          itemsActualizados++;
        }
      }
      
      if (mounted) {
        if (itemsActualizados > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Inventario actualizado: $itemsActualizados producto(s) modificado(s)',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ℹ️ No se realizaron cambios en el inventario'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
      
      // Guardar como completado y recargar inventario
      final sessionData = _quantitiesFromData(inventarioData);
      await _saveSessionProgress(sessionData, InventorySessionStatus.completed);
      await _loadInventory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al actualizar inventario: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _loadPendingSession() async {
    InventorySession? session;
    
    // Obtener el usuario actual para verificar permisos
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('id_empleado');
    final isAdmin = widget.isAdmin;
    
    if (widget.sessionId != null) {
      // Si hay sessionId específico, cargar esa sesión
      session = await _sessionStorage.getSessionById(widget.sessionId!);
      
      // IMPORTANTE: Solo cargar como _pendingSession si el estado es pending
      // Si la sesión está completada, no debe mostrarse como pendiente
      if (session != null && session.status != InventorySessionStatus.pending) {
        // La sesión está completada, no la cargamos como pendiente
        session = null;
      } else if (session != null && !isAdmin) {
        // Si no es admin, verificar que la sesión pertenezca al usuario actual
        if (session.ownerId != currentUserId) {
          // El usuario no es dueño de esta sesión y no es admin, no cargar
          session = null;
        }
      }
    } else {
      // Si no hay sessionId, buscar por categoryName completo (incluye subcategoría)
      String categoryName = widget.categoria.nombre;
      if (widget.jumperCategoryFilter != null) {
        categoryName = '${widget.categoria.nombre} ${widget.jumperCategoryFilter!.displayName}';
      }
      session = await _sessionStorage.getSessionByCategoryName(
        categoryName,
        status: InventorySessionStatus.pending,
      );
      
      // Si no es admin, verificar que la sesión pertenezca al usuario actual
      if (session != null && !isAdmin && session.ownerId != currentUserId) {
        session = null;
      }
    }

    if (!mounted) return;
    setState(() {
      _pendingSession = session;
    });
  }

  void _showCompleteInventoryDialog() {
    // Crear controladores para cada item usando el ID del producto como clave
    final Map<int, TextEditingController> controllers = {};
    for (var item in _filteredItems) {
      final productId = item.producto.idProducto;
      final pendingValue = _pendingSession?.quantities[productId];
      controllers[productId] = TextEditingController(
        text: pendingValue?.toString() ?? item.cantidad.toString(),
      );
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.inventory_2, color: Color(0xFF003366), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Realizar Inventario Completo',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003366),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Información
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ingrese las cantidades encontradas para cada producto',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_pendingSession != null) ...[
                      const SizedBox(height: 12),
                      Container(
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
                                await _sessionStorage.deleteSession(_pendingSession!.id);
                                if (!mounted) return;
                                setState(() {
                                  _pendingSession = null;
                                });
                                Navigator.pop(context);
                              },
                              child: const Text('Descartar'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                
                // Lista de productos
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final productId = item.producto.idProducto;
                      final controller = controllers[productId]!;
                      final cantidadActual = item.cantidad;
                      final nuevaCantidad = int.tryParse(controller.text) ?? cantidadActual;
                      final tieneCambios = nuevaCantidad != cantidadActual;

                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return Card(
                        key: ValueKey('inventory_item_${item.producto.idProducto}'),
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: tieneCambios ? 3 : 1,
                        color: tieneCambios 
                          ? (isDark 
                            ? Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.5)
                            : Colors.blue[50])
                          : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: tieneCambios 
                              ? (nuevaCantidad > cantidadActual ? Colors.green[300]! : Colors.orange[300]!)
                              : Theme.of(context).colorScheme.outline,
                            width: tieneCambios ? 2 : 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nombre del producto
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.producto.nombre,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  if (tieneCambios)
                                    Icon(
                                      nuevaCantidad > cantidadActual 
                                        ? Icons.trending_up 
                                        : Icons.trending_down,
                                      color: nuevaCantidad > cantidadActual 
                                        ? Colors.green[700] 
                                        : Colors.orange[700],
                                      size: 20,
                                    ),
                                ],
                              ),
                              
                              // Tamaño y ubicación (rack - contenedor)
                              if (item.producto.tamano != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.straighten, size: 14, color: Theme.of(context).colorScheme.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${item.producto.tamano} m',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    if (item.producto.rack != null || item.producto.contenedor != null) ...[
                                      const SizedBox(width: 12),
                                      Icon(Icons.inventory_2, size: 14, color: Theme.of(context).colorScheme.secondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        _buildRackContenedorText(item.producto.rack, item.producto.contenedor),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.secondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ] else if (item.producto.rack != null || item.producto.contenedor != null) ...[
                                // Si no hay tamaño, mostrar solo rack y contenedor
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.inventory_2, size: 14, color: Theme.of(context).colorScheme.secondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      _buildRackContenedorText(item.producto.rack, item.producto.contenedor),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.secondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              
                              const SizedBox(height: 12),
                              
                              // Cantidad actual y nueva cantidad
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  _buildQuantityChip(
                                    context,
                                    label: 'Actual',
                                    value: '$cantidadActual',
                                    background: Theme.of(context).colorScheme.surfaceVariant,
                                    width: 105,
                                  ),
                                  _buildQuantityInput(
                                    context,
                                    controller: controller,
                                    label: 'Nueva',
                                    width: 105,
                                    productId: item.producto.idProducto,
                                    onChanged: (_) {
                                      // Usar SchedulerBinding para asegurar que el estado se actualice de forma segura
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        if (context.mounted) {
                                          setDialogState(() {});
                                        }
                                      });
                                    },
                                  ),
                                  if (tieneCambios)
                                    _buildQuantityChip(
                                      context,
                                      label: 'Dif.',
                                      value: nuevaCantidad > cantidadActual
                                          ? '+${nuevaCantidad - cantidadActual}'
                                          : '${nuevaCantidad - cantidadActual}',
                                      background: nuevaCantidad > cantidadActual
                                          ? Colors.green.withValues(alpha: 0.15)
                                          : Colors.orange.withValues(alpha: 0.15),
                                      valueColor: nuevaCantidad > cantidadActual
                                          ? Colors.green[700]
                                          : Colors.orange[700],
                                      width: 105,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Botones de acción
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final quantities = _quantitiesFromControllers(controllers);
                        await _saveSessionProgress(
                          quantities,
                          InventorySessionStatus.pending,
                        );
                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Inventario guardado como pendiente'),
                            backgroundColor: Colors.blueGrey,
                          ),
                        );
                      },
                      icon: const Icon(Icons.pause_circle_outline),
                      label: const Text('Terminar más tarde'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Validar que todas las cantidades sean válidas
                        final Map<InventarioCompleto, int> inventarioData = {};
                        bool hayErrores = false;
                        
                        for (var entry in controllers.entries) {
                          final productId = entry.key;
                          final controller = entry.value;
                          final nuevaCantidad = int.tryParse(controller.text);
                          
                          if (nuevaCantidad == null || nuevaCantidad < 0) {
                            hayErrores = true;
                            break;
                          }
                          
                          // Encontrar el item correspondiente al productId
                          final item = _filteredItems.firstWhere(
                            (item) => item.producto.idProducto == productId,
                          );
                          inventarioData[item] = nuevaCantidad;
                        }
                        
                        if (hayErrores) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('❌ Por favor, ingrese cantidades válidas (números enteros >= 0)'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        
                        Navigator.pop(context);
                        await _performCompleteInventory(inventarioData);
                      },
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text(
                        'Guardar Todo',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003366),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
        },
      ),
    ).then((_) {
      // Esperar a que el frame se complete antes de desechar los controladores
      // Esto asegura que el widget esté completamente desmontado
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          for (var controller in controllers.values) {
            try {
              controller.dispose();
            } catch (e) {
              // Si ya fue desechado, ignorar el error
            }
          }
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.jumperCategoryFilter != null
              ? '${widget.categoriaNombre} - ${widget.jumperCategoryFilter!.displayName}'
              : 'Inventario de ${widget.categoriaNombre}',
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        actions: [
          if (widget.isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton.icon(
                onPressed: _showAddProductDialog,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Agregar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInventory,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      floatingActionButton: !widget.isAdmin && _filteredItems.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showCompleteInventoryDialog,
              backgroundColor: const Color(0xFF003366),
              icon: const Icon(Icons.inventory_2, color: Colors.white),
              label: const Text(
                'Realizar Inventario',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final padding = isMobile ? 12.0 : 16.0;
          
          return Column(
            children: [
              // Barra de búsqueda y filtro
              Container(
                padding: EdgeInsets.all(padding),
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  children: [
                    TextField(
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre, rack o contenedor...',
                        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75)),
                        prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75)),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.onSurface),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceVariant,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 16,
                          vertical: isMobile ? 12 : 16,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    // Filtro de ordenamiento
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Icon(Icons.sort, size: 20, color: Theme.of(context).colorScheme.primary),
                        Text(
                          'Ordenar por contenedor:',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Theme.of(context).colorScheme.outline),
                          ),
                          child: DropdownButton<SortOrder>(
                            value: _sortOrder,
                            underline: const SizedBox(),
                            icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurface),
                            dropdownColor: Theme.of(context).colorScheme.surface,
                            items: [
                              DropdownMenuItem(
                                value: SortOrder.none,
                                child: Text('Sin ordenar', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                              ),
                              DropdownMenuItem(
                                value: SortOrder.ascending,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.arrow_upward, size: 16, color: Theme.of(context).colorScheme.onSurface),
                                    const SizedBox(width: 4),
                                    Text('A-Z', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: SortOrder.descending,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.arrow_downward, size: 16, color: Theme.of(context).colorScheme.onSurface),
                                    const SizedBox(width: 4),
                                    Text('Z-A', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _sortOrder = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Estadísticas
              Container(
                padding: EdgeInsets.only(
                  left: isMobile ? 12 : 20,
                  top: 12,
                  bottom: 12,
                  right: isMobile ? 12 : 20,
                ),
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildStatCard(
                    'Total Cables',
                    '${_filteredItems.fold<int>(0, (sum, item) => sum + item.cantidad)}',
                    Icons.inventory_2,
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              
              // Lista de productos
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
                                  size: isMobile ? 48 : 64,
                                  color: Colors.red[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error al cargar inventario',
                                  style: TextStyle(
                                    fontSize: isMobile ? 16 : 18,
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
                                  child: Text(
                                    _error!,
                                    style: TextStyle(color: Colors.red[600], fontSize: isMobile ? 12 : 14),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadInventory,
                                  child: const Text('Reintentar'),
                                ),
                              ],
                            ),
                          )
                        : _filteredItems.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: isMobile ? 48 : 64,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'No hay productos en este inventario'
                                      : 'No se encontraron productos',
                                  style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 12 : 20,
                              vertical: 16,
                            ),
                            itemCount: _filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = _filteredItems[index];
                              return _buildItemCard(item);
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark 
          ? Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.5)
          : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Text(
            '$value ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityChip(
    BuildContext context, {
    required String label,
    required String value,
    required Color background,
    double width = 100,
    Color? valueColor,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String text,
    double? maxWidth,
  }) {
    final chipContent = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return Container(
      constraints: maxWidth != null ? BoxConstraints(maxWidth: maxWidth) : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: chipContent,
    );
  }

  Future<void> _saveSessionProgress(
    Map<int, int> quantities,
    InventorySessionStatus status,
  ) async {
    // Obtener información del usuario actual desde SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final ownerId = prefs.getString('id_empleado');
    final ownerEmail = prefs.getString('nombre_usuario'); // nombre_usuario es el correo

    // Construir el nombre de categoría incluyendo subcategoría de jumper si existe
    String categoryName = widget.categoria.nombre;
    if (widget.jumperCategoryFilter != null) {
      categoryName = '${widget.categoria.nombre} ${widget.jumperCategoryFilter!.displayName}';
    }

    // Si el status es completed, incluir TODOS los items de la categoría
    // Para los items que no están en quantities, usar su cantidad original
    Map<int, int> finalQuantities = quantities;
    if (status == InventorySessionStatus.completed) {
      // Crear un mapa completo con TODOS los items de la categoría
      finalQuantities = <int, int>{};
      
      // Primero agregar todos los items de _filteredItems con su cantidad original
      for (var item in _filteredItems) {
        final productId = item.producto.idProducto;
        // Si el item está en quantities (fue modificado), usar esa cantidad
        // Si no, usar la cantidad original
        finalQuantities[productId] = quantities[productId] ?? item.cantidad;
      }
      
      // Si quantities está vacío, no hacer nada más
      if (finalQuantities.isEmpty) {
        return;
      }
    } else {
      // Para sesiones pendientes, mantener el comportamiento original
      if (quantities.isEmpty) {
        return;
      }
    }

    // Determinar el ID de la sesión:
    // 1. Si hay widget.sessionId, verificar que la sesión sea pending antes de usarla
    // 2. Si no hay widget.sessionId pero hay _pendingSession con el mismo categoryName, usar ese ID
    // 3. Si no, crear un nuevo ID único
    String sessionId;
    if (widget.sessionId != null) {
      // Verificar que la sesión existente sea pending antes de actualizarla
      final existingSession = await _sessionStorage.getSessionById(widget.sessionId!);
      if (existingSession != null && existingSession.status == InventorySessionStatus.pending) {
        // Solo actualizar si la sesión es pending
        sessionId = widget.sessionId!;
      } else {
        // Si la sesión está completada o no existe, crear una nueva
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final categoryNameHash = categoryName.hashCode.abs();
        sessionId = '${timestamp}_${categoryNameHash}_${ownerId ?? 'unknown'}';
      }
    } else if (_pendingSession != null && _pendingSession!.categoryName == categoryName) {
      // Estamos actualizando la misma sesión pendiente que está cargada
      sessionId = _pendingSession!.id;
    } else {
      // Crear un nuevo ID único usando timestamp + hash del categoryName para evitar colisiones
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final categoryNameHash = categoryName.hashCode.abs();
      sessionId = '${timestamp}_${categoryNameHash}_${ownerId ?? 'unknown'}';
    }

    final session = InventorySession(
      id: sessionId,
      categoryId: widget.categoria.idCategoria,
      categoryName: categoryName,
      quantities: finalQuantities,
      status: status,
      updatedAt: DateTime.now(),
      ownerId: ownerId,
      ownerName: ownerEmail, // Usamos el correo como nombre también
      ownerEmail: ownerEmail,
    );

    await _sessionStorage.saveSession(session);

    if (!mounted) return;
    setState(() {
      _pendingSession = status == InventorySessionStatus.pending ? session : null;
    });
  }

  Map<int, int> _quantitiesFromControllers(
    Map<int, TextEditingController> controllers,
  ) {
    final result = <int, int>{};
    controllers.forEach((productId, controller) {
      final value = int.tryParse(controller.text);
      if (value != null && value >= 0) {
        result[productId] = value;
      }
    });
    return result;
  }

  Map<int, int> _quantitiesFromData(Map<InventarioCompleto, int> data) {
    final result = <int, int>{};
    data.forEach((item, value) {
      result[item.producto.idProducto] = value;
    });
    return result;
  }

  String _formatSessionDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  Widget _buildQuantityInput(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required double width,
    required int productId,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            key: ValueKey('quantity_input_$productId'),
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 6),
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(InventarioCompleto item) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final padding = isMobile ? 12.0 : 20.0;
    
    // Obtener cantidad guardada en sesión pendiente si existe
    final productId = item.producto.idProducto;
    final cantidadGuardada = _pendingSession?.quantities[productId];
    final cantidadMostrar = cantidadGuardada ?? item.cantidad;
    final tieneCambiosPendientes = cantidadGuardada != null && cantidadGuardada != item.cantidad;
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.producto.nombre,
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (item.producto.tamano != null)
                            _buildInfoChip(
                              context,
                              icon: Icons.straighten,
                              text: '${item.producto.tamano} m',
                            ),
                          if (item.producto.descripcion != null && item.producto.descripcion!.isNotEmpty)
                            _buildInfoChip(
                              context,
                              icon: Icons.notes,
                              text: item.producto.descripcion!,
                              maxWidth: isMobile ? 150 : 180,
                            ),
                          if (item.producto.rack != null || item.producto.contenedor != null)
                            _buildInfoChip(
                              context,
                              icon: Icons.inventory_2,
                              text: _buildRackContenedorText(item.producto.rack, item.producto.contenedor),
                            ),
                          if (tieneCambiosPendientes)
                            _buildInfoChip(
                              context,
                              icon: Icons.pending_actions,
                              text: 'Cambio pendiente',
                              maxWidth: isMobile ? 130 : 150,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 16,
                        vertical: isMobile ? 8 : 10,
                      ),
                      decoration: BoxDecoration(
                        color: cantidadMostrar > 0 ? Colors.green[100] : Colors.orange[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: tieneCambiosPendientes 
                              ? Colors.blue[400]!
                              : (cantidadMostrar > 0 ? Colors.green[300]! : Colors.orange[300]!),
                          width: tieneCambiosPendientes ? 2.0 : 1.5,
                        ),
                      ),
                      child: Text(
                        '$cantidadMostrar',
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          color: cantidadMostrar > 0 ? Colors.green[700] : Colors.orange[700],
                        ),
                      ),
                    ),
                    if (tieneCambiosPendientes) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Actual: ${item.cantidad}',
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.isAdmin)
              Wrap(
                spacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showEditProductDialog(item),
                    icon: Icon(Icons.edit, size: isMobile ? 16 : 18),
                    label: Text('Editar', style: TextStyle(fontSize: isMobile ? 12 : 14)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 12,
                        vertical: isMobile ? 4 : 8,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showDeleteProductDialog(item),
                    icon: Icon(Icons.delete, size: isMobile ? 16 : 18),
                    label: Text('Eliminar', style: TextStyle(fontSize: isMobile ? 12 : 14)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 12,
                        vertical: isMobile ? 4 : 8,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Métodos CRUD para admin
  Future<void> _showAddProductDialog() async {
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();
    final tamanoController = TextEditingController();
    final cantidadController = TextEditingController();
    final rackController = TextEditingController();
    final contenedorController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Producto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tamanoController,
                decoration: const InputDecoration(
                  labelText: 'Tamaño (metros)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cantidadController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad inicial *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rackController,
                decoration: const InputDecoration(
                  labelText: 'Rack',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contenedorController,
                decoration: const InputDecoration(
                  labelText: 'Contenedor',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nombreController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El nombre es obligatorio')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        // Crear producto
        final producto = Producto(
          idProducto: 0, // Se generará automáticamente
          nombre: nombreController.text.trim(),
          descripcion: descripcionController.text.trim().isEmpty 
              ? null 
              : descripcionController.text.trim(),
          tamano: tamanoController.text.trim().isEmpty 
              ? null 
              : int.tryParse(tamanoController.text.trim()),
          unidad: cantidadController.text.trim().isEmpty 
              ? '0' 
              : cantidadController.text.trim(),
          rack: rackController.text.trim().isEmpty 
              ? null 
              : rackController.text.trim(),
          contenedor: contenedorController.text.trim().isEmpty 
              ? null 
              : contenedorController.text.trim(),
        );

        final productoCreado = await _inventarioRepository.createProducto(producto);

        // Relacionar producto con categoría
        await supabaseClient.from('t_productos_categorias').insert({
          'id_producto': productoCreado.idProducto,
          'id_categoria': widget.categoria.idCategoria,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto agregado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          _loadInventory();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al agregar producto: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showEditProductDialog(InventarioCompleto item) async {
    final nombreController = TextEditingController(text: item.producto.nombre);
    final descripcionController = TextEditingController(text: item.producto.descripcion ?? '');
    final tamanoController = TextEditingController(text: item.producto.tamano?.toString() ?? '');
    final cantidadController = TextEditingController(text: item.cantidad.toString());
    final rackController = TextEditingController(text: item.producto.rack ?? '');
    final contenedorController = TextEditingController(text: item.producto.contenedor ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Producto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tamanoController,
                decoration: const InputDecoration(
                  labelText: 'Tamaño (metros)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cantidadController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rackController,
                decoration: const InputDecoration(
                  labelText: 'Rack',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contenedorController,
                decoration: const InputDecoration(
                  labelText: 'Contenedor',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nombreController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El nombre es obligatorio')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        // Obtener la nueva cantidad
        final nuevaCantidadStr = cantidadController.text.trim();
        final nuevaCantidad = int.tryParse(nuevaCantidadStr);
        
        if (nuevaCantidad == null || nuevaCantidad < 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('La cantidad debe ser un número entero mayor o igual a 0'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Actualizar producto
        final productoActualizado = item.producto.copyWith(
          nombre: nombreController.text.trim(),
          descripcion: descripcionController.text.trim().isEmpty 
              ? null 
              : descripcionController.text.trim(),
          tamano: tamanoController.text.trim().isEmpty 
              ? null 
              : int.tryParse(tamanoController.text.trim()),
          unidad: cantidadController.text.trim(),
          rack: rackController.text.trim().isEmpty 
              ? null 
              : rackController.text.trim(),
          contenedor: contenedorController.text.trim().isEmpty 
              ? null 
              : contenedorController.text.trim(),
        );

        await _inventarioRepository.updateProducto(productoActualizado);

        // Actualizar la cantidad en t_inventarios si cambió
        final cantidadActual = item.cantidad;
        final diferencia = nuevaCantidad - cantidadActual;
        
        if (diferencia != 0) {
          await _inventarioRepository.ajustarInventario(
            item.producto.idProducto,
            item.ubicacion.idUbicacion,
            diferencia,
            'Edición manual de cantidad - ${widget.categoriaNombre}',
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto actualizado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          // Recargar el inventario para reflejar los cambios
          await _loadInventory();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar producto: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showDeleteProductDialog(InventarioCompleto item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${item.producto.nombre}"?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        // Eliminar relación con categoría primero
        await supabaseClient
            .from('t_productos_categorias')
            .delete()
            .eq('id_producto', item.producto.idProducto)
            .eq('id_categoria', widget.categoria.idCategoria);

        // Eliminar producto
        await _inventarioRepository.deleteProducto(item.producto.idProducto);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          _loadInventory();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar producto: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

