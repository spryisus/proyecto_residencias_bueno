import 'package:flutter/material.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:excel/excel.dart' as excel_lib show Border, BorderStyle;
import 'dart:io';
import '../../domain/entities/inventory_session.dart';
import '../../domain/entities/categoria.dart';
import '../../domain/entities/inventario_completo.dart';
import '../../domain/repositories/inventario_repository.dart';
import '../../core/di/injection_container.dart';
import '../../app/config/supabase_client.dart' show supabaseClient;
import '../../data/services/computo_export_service.dart';
import '../../data/services/jumpers_export_service.dart';
import '../../core/utils/file_saver_helper.dart';
import 'jumper_categories_screen.dart' show JumperCategory, JumperCategories;

class CompletedInventoryDetailScreen extends StatefulWidget {
  final InventorySession session;
  final Categoria categoria;

  const CompletedInventoryDetailScreen({
    super.key,
    required this.session,
    required this.categoria,
  });

  @override
  State<CompletedInventoryDetailScreen> createState() => _CompletedInventoryDetailScreenState();
}

class _CompletedInventoryDetailScreenState extends State<CompletedInventoryDetailScreen> {
  final InventarioRepository _inventarioRepository = serviceLocator.get<InventarioRepository>();
  List<InventarioCompleto> _inventoryItems = [];
  List<Map<String, dynamic>> _computoEquipos = []; // Para equipos de cómputo
  Map<int, int> _sessionQuantities = {};
  bool _isLoading = true;
  String? _error;
  bool _isComputo = false; // Flag para saber si es inventario de cómputo

  @override
  void initState() {
    super.initState();
    _sessionQuantities = widget.session.quantities;
    _loadInventoryDetails();
  }

  Future<void> _loadInventoryDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Manejo especial para "Equipo de Cómputo" que no tiene categoría en la BD
      if (widget.categoria.idCategoria == -1 || widget.categoria.nombre == 'Equipo de Cómputo') {
        _isComputo = true;
        // Cargar equipos de cómputo desde la base de datos
        try {
          final equiposResponse = await supabaseClient
              .from('v_equipos_computo_completo')
              .select('*');
          
          final equiposList = List<Map<String, dynamic>>.from(equiposResponse);
          
          // Filtrar solo los equipos que están en la sesión (completados = 1)
          final equiposCompletados = equiposList.where((equipo) {
            final inventario = (equipo['inventario']?.toString() ?? '').trim();
            if (inventario.isEmpty) return false;
            final inventarioHash = inventario.hashCode.abs();
            return widget.session.quantities[inventarioHash] == 1;
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
                  // Si falla, intentar con la tabla normal
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
          
          setState(() {
            _computoEquipos = equiposCompletados;
            _isLoading = false;
          });
        } catch (e) {
          setState(() {
            _isLoading = false;
            _error = 'Error al cargar equipos de cómputo: $e';
          });
        }
        return;
      }

      // Obtener TODOS los items de inventario de la categoría
      var allItems = await _inventarioRepository.getInventarioByCategoria(widget.categoria.idCategoria);
      
      // Detectar si hay una subcategoría de jumper en el nombre de la sesión
      // Ej: "Jumpers SC-SC" -> detectar "SC-SC"
      JumperCategory? detectedJumperCategory;
      final categoryNameLower = widget.session.categoryName.toLowerCase();
      if (categoryNameLower.contains('jumper')) {
        for (final jumperCategory in JumperCategories.all) {
          if (widget.session.categoryName.contains(jumperCategory.displayName)) {
            detectedJumperCategory = jumperCategory;
            break;
          }
        }
      }
      
      // Si hay una subcategoría de jumper detectada, filtrar los items
      if (detectedJumperCategory != null) {
        allItems = allItems.where((item) {
          final nombre = item.producto.nombre.toUpperCase();
          final descripcion = (item.producto.descripcion ?? '').toUpperCase();
          final texto = '$nombre $descripcion';
          return _matchesJumperPattern(texto, detectedJumperCategory!.searchPattern);
        }).toList();
      }
      
      // Mostrar TODOS los items de la categoría (filtrados si hay subcategoría)
      // Si un item no está en la sesión, se mostrará con su cantidad original
      setState(() {
        _inventoryItems = allItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error al cargar detalles: $e';
      });
    }
  }

  bool _matchesJumperPattern(String text, String pattern) {
    if (pattern.isEmpty) return false;
    final patterns = pattern.split('|');
    return patterns.any((p) => text.contains(p.trim()));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Inventario'),
        centerTitle: true,
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
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
                          _error!,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadInventoryDetails,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    final padding = isMobile ? 12.0 : 20.0;

                    return Column(
                      children: [
                        // Header con información del inventario
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(padding),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.green.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.session.categoryName,
                                          style: TextStyle(
                                            fontSize: isMobile ? 20 : 24,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Finalizado el ${_formatDate(widget.session.updatedAt)}',
                                          style: TextStyle(
                                            fontSize: isMobile ? 14 : 16,
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: [
                                  _buildStatChip(
                                    Icons.inventory_2,
                                    '${_inventoryItems.length} productos',
                                    isMobile,
                                  ),
                                  if (widget.session.ownerName != null)
                                    _buildStatChip(
                                      Icons.person,
                                      'Realizado por: ${widget.session.ownerName}',
                                      isMobile,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Lista de productos o equipos
                        Expanded(
                          child: _isComputo
                              ? (_computoEquipos.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(padding),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.computer_outlined,
                                              size: 64,
                                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'No se encontraron equipos',
                                              style: TextStyle(
                                                fontSize: isMobile ? 16 : 18,
                                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: EdgeInsets.all(padding),
                                      itemCount: _computoEquipos.length,
                                      itemBuilder: (context, index) {
                                        final equipo = _computoEquipos[index];
                                        return _buildComputoEquipoCard(equipo, isMobile);
                                      },
                                    ))
                              : (_inventoryItems.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(padding),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.inventory_2_outlined,
                                              size: 64,
                                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'No se encontraron productos',
                                              style: TextStyle(
                                                fontSize: isMobile ? 16 : 18,
                                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: EdgeInsets.all(padding),
                                      itemCount: _inventoryItems.length,
                                      itemBuilder: (context, index) {
                                        final item = _inventoryItems[index];
                                        // Si el item está en la sesión, usar esa cantidad, si no, usar la original
                                        final sessionQuantity = _sessionQuantities.containsKey(item.producto.idProducto)
                                            ? _sessionQuantities[item.producto.idProducto]!
                                            : item.cantidad;
                                        return _buildProductCard(item, sessionQuantity, isMobile);
                                      },
                                    )),
                        ),
                      ],
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _exportToExcel,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        tooltip: 'Exportar a Excel',
        child: const Icon(Icons.file_download),
      ),
    );
  }

  Widget _buildComputoEquipoCard(Map<String, dynamic> equipo, bool isMobile) {
    final inventario = (equipo['inventario']?.toString() ?? 'Sin inventario').trim();
    final marca = (equipo['marca']?.toString() ?? '').trim();
    final modelo = (equipo['modelo']?.toString() ?? '').trim();
    final tipoEquipo = (equipo['tipo_equipo']?.toString() ?? '').trim();
    final empleadoAsignado = (equipo['empleado_asignado_nombre']?.toString() ?? 
                              equipo['empleado_asignado']?.toString() ?? '').trim();
    
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 16,
        vertical: 8,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF003366).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.computer,
                    color: Color(0xFF003366),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inventario,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003366),
                        ),
                      ),
                      if (marca.isNotEmpty || modelo.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '$marca $modelo'.trim(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (tipoEquipo.isNotEmpty)
              _buildInfoRow('Tipo Equipo', tipoEquipo),
            if (equipo['procesador'] != null && equipo['procesador'].toString().isNotEmpty)
              _buildInfoRow('Procesador', equipo['procesador']),
            if (equipo['numero_serie'] != null && equipo['numero_serie'].toString().isNotEmpty)
              _buildInfoRow('Número Serie', equipo['numero_serie']),
            if (equipo['memoria'] != null && equipo['memoria'].toString().isNotEmpty)
              _buildInfoRow('Memoria', equipo['memoria']),
            if (equipo['disco_duro'] != null && equipo['disco_duro'].toString().isNotEmpty)
              _buildInfoRow('Disco Duro', equipo['disco_duro']),
            if (equipo['sistema_operativo_instalado'] != null && equipo['sistema_operativo_instalado'].toString().isNotEmpty)
              _buildInfoRow('Sistema Operativo', equipo['sistema_operativo_instalado']),
            if (empleadoAsignado.isNotEmpty)
              _buildInfoRow('Usuario Asignado', empleadoAsignado),
            if (equipo['direccion_fisica'] != null && equipo['direccion_fisica'].toString().isNotEmpty)
              _buildInfoRow('Ubicación', equipo['direccion_fisica']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(InventarioCompleto item, int sessionQuantity, bool isMobile) {
    // Si el item no está en la sesión, usar la cantidad original
    final cantidadFinal = _sessionQuantities.containsKey(item.producto.idProducto) 
        ? sessionQuantity 
        : item.cantidad;
    final diferencia = cantidadFinal - item.cantidad;
    final tieneCambios = diferencia != 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      if (item.producto.descripcion != null && item.producto.descripcion!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.producto.descripcion!,
                          style: TextStyle(
                            fontSize: isMobile ? 13 : 14,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (item.ubicacion.nombre.isNotEmpty)
                  _buildInfoChip(
                    Icons.location_on,
                    item.ubicacion.nombre,
                    isMobile,
                  ),
                if (item.producto.rack != null && item.producto.rack!.isNotEmpty)
                  _buildInfoChip(
                    Icons.grid_view,
                    'Rack: ${item.producto.rack}',
                    isMobile,
                  ),
                if (item.producto.contenedor != null && item.producto.contenedor!.isNotEmpty)
                  _buildInfoChip(
                    Icons.inbox,
                    'Contenedor: ${item.producto.contenedor}',
                    isMobile,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuantityInfo(
                    'Cantidad Original',
                    item.cantidad.toString(),
                    Colors.blue,
                    isMobile,
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                                  _buildQuantityInfo(
                                    'Cantidad Final',
                                    cantidadFinal.toString(),
                                    Colors.green,
                                    isMobile,
                                  ),
                  if (tieneCambios) ...[
                    Container(
                      width: 1,
                      height: 30,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                    _buildQuantityInfo(
                      'Diferencia',
                      diferencia > 0 ? '+$diferencia' : '$diferencia',
                      diferencia > 0 ? Colors.green : Colors.orange,
                      isMobile,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityInfo(String label, String value, Color color, bool isMobile) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 10 : 11,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
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
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isMobile ? 11 : 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text, bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.green[700]),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              color: Colors.green[700],
              fontWeight: FontWeight.w600,
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

  Future<void> _exportToExcel() async {
    try {
      // Verificar si hay datos para exportar (productos normales o equipos de cómputo)
      if (_inventoryItems.isEmpty && _computoEquipos.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay datos para exportar'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Si es inventario de cómputo, usar el servicio de exportación específico
      if (_isComputo && _computoEquipos.isNotEmpty) {
        try {
          // Mostrar indicador de carga
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // Preparar datos para exportación según plantilla (14 columnas, incluyendo COMPONENTES)
          final itemsToExport = _computoEquipos.map((equipo) {
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
                  content: Text('Inventario exportado: $filePath'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context); // Cerrar diálogo de carga
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al exportar: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
        return;
      }

      // Si no hay items de inventario normal, no continuar
      if (_inventoryItems.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay datos para exportar'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Verificar si es inventario de jumpers
      final categoryNameLower = widget.session.categoryName.toLowerCase();
      final isJumpers = categoryNameLower.contains('jumper');

      // Si es jumpers, usar el servicio de exportación específico
      if (isJumpers) {
        try {
          // Mostrar indicador de carga
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // Preparar datos para exportación según plantilla
          final itemsToExport = _inventoryItems.map((item) {
            // Si el item está en la sesión, usar esa cantidad, si no, usar la original
            final sessionQuantity = _sessionQuantities.containsKey(item.producto.idProducto)
                ? _sessionQuantities[item.producto.idProducto]!
                : item.cantidad;

            return {
              'tipo': _getCategoryDisplayName(widget.session.categoryName), // Tipo (solo subcategoría si es jumper)
              'tamano': item.producto.tamano?.toString() ?? '',
              'cantidad': sessionQuantity,
              'rack': item.producto.rack ?? '',
              'contenedor': item.producto.contenedor ?? '',
            };
          }).toList();

          final filePath = await JumpersExportService.exportJumpersToExcel(itemsToExport);

          if (mounted) {
            Navigator.pop(context); // Cerrar diálogo de carga
            if (filePath != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Inventario exportado: $filePath'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context); // Cerrar diálogo de carga
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al exportar: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
        return;
      }

      // Para otros tipos de inventario, usar el método manual (mantener compatibilidad)
      // Mostrar indicador de carga
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

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

      // Agregar título (fila 0, columna 2 para centrarlo)
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
      
      // Agregar encabezados (fila 2)
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

      // Agregar datos de cada producto
      for (var i = 0; i < _inventoryItems.length; i++) {
        final item = _inventoryItems[i];
        // Si el item está en la sesión, usar esa cantidad, si no, usar la original
        final sessionQuantity = _sessionQuantities.containsKey(item.producto.idProducto)
            ? _sessionQuantities[item.producto.idProducto]!
            : item.cantidad;

        final rowIndex = sheetObject.maxRows;
        sheetObject.appendRow([
          TextCellValue(_getCategoryDisplayName(widget.session.categoryName)), // Tipo (solo subcategoría si es jumper)
          TextCellValue(item.producto.tamano?.toString() ?? ''), // Tamaño
          TextCellValue(sessionQuantity.toString()), // Cantidad (del inventario finalizado)
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

      // Generar nombre por defecto con fecha
      final dateStr = _formatDate(widget.session.updatedAt).replaceAll('/', '_').replaceAll(' ', '_').replaceAll(':', '');
      final defaultFileName = 'Inventario_${widget.session.categoryName.replaceAll(' ', '_')}_$dateStr.xlsx';
      
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
        dialogTitle: 'Guardar inventario como',
      );
      
      if (filePath == null) {
        // Usuario canceló
        if (mounted) {
          Navigator.pop(context); // Cerrar diálogo de carga
        }
        return;
      }

      // Cerrar diálogo de carga
      if (mounted) {
        Navigator.pop(context);
      }

      // Mostrar diálogo con la ubicación del archivo
      if (mounted) {
        final fileName = filePath.split('/').last.split('\\').last; // Obtener solo el nombre del archivo
        _showExportSuccessDialog(filePath, fileName);
      }
    } catch (e) {
      if (mounted) {
        // Cerrar diálogo de carga si está abierto
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar a Excel: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showExportSuccessDialog(String filePath, String fileName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Exportación exitosa'),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'El archivo Excel se ha generado correctamente:',
                style: TextStyle(fontSize: 14),
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
                
                // Intentar abrir el archivo o la carpeta
                try {
                  if (Platform.isAndroid || Platform.isIOS) {
                    // En móvil, abrir el archivo directamente
                    await FileSaverHelper.openFile(filePath);
                  } else {
                    // En desktop, abrir la carpeta
                    final directory = Directory(filePath).parent;
                    
                    if (Platform.isLinux) {
                      // En Linux usar xdg-open
                      await Process.run('xdg-open', [directory.path]);
                    } else if (Platform.isWindows) {
                      // En Windows usar explorer
                      await Process.run('explorer', [directory.path]);
                    } else if (Platform.isMacOS) {
                      // En macOS usar open
                      await Process.run('open', [directory.path]);
                    }
                  }
                } catch (e) {
                  // Si falla, mostrar mensaje
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(Platform.isAndroid || Platform.isIOS 
                          ? 'Archivo guardado. Puedes compartirlo desde tu gestor de archivos.'
                          : 'Ruta del archivo: $filePath'),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                }
              },
              icon: Icon(Platform.isAndroid || Platform.isIOS ? Icons.open_in_new : Icons.folder_open, size: 18),
              label: Text(Platform.isAndroid || Platform.isIOS ? 'Abrir archivo' : 'Abrir carpeta'),
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

