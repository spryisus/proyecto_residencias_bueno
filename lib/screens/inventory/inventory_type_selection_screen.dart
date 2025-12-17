import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/inventario_repository.dart';
import '../../domain/entities/categoria.dart';
import '../../data/local/inventory_session_storage.dart';
import '../../core/di/injection_container.dart';
import '../../app/config/supabase_client.dart' show supabaseClient;
import 'category_inventory_screen.dart';
import 'jumper_categories_screen.dart';
import 'qr_scanner_screen.dart';
import 'completed_inventories_screen.dart';
import '../computo/inventario_computo_screen.dart';

class InventoryTypeSelectionScreen extends StatefulWidget {
  const InventoryTypeSelectionScreen({super.key});

  @override
  State<InventoryTypeSelectionScreen> createState() => _InventoryTypeSelectionScreenState();
}

class _InventoryTypeSelectionScreenState extends State<InventoryTypeSelectionScreen> {
  final InventarioRepository _inventarioRepository = serviceLocator.get<InventarioRepository>();
  final InventorySessionStorage _sessionStorage = serviceLocator.get<InventorySessionStorage>();
  Map<String, int> _categoryCounts = {};
  int _totalInventories = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategoryCounts();
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

  Future<void> _loadCategoryCounts() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });

      // Obtener todas las categorías
      final categorias = await _inventarioRepository.getAllCategorias();
      
      // Contar productos por categoría directamente desde t_productos_categorias
      final countMap = <String, int>{};
      
      for (final categoria in categorias) {
        final nombreCategoria = categoria.nombre.toLowerCase();
        
        // Obtener inventario por categoría para contar productos
        try {
          final inventarioCategoria = await _inventarioRepository.getInventarioByCategoria(categoria.idCategoria);
          final cantidad = inventarioCategoria.length;
          
          // Mapear a los nombres de las tarjetas
          if (nombreCategoria.contains('jumper')) {
            countMap['Jumpers'] = cantidad;
          } else if (nombreCategoria.contains('medición') || nombreCategoria.contains('medicion')) {
            countMap['Equipo de Medición'] = cantidad;
          }
        } catch (e) {
          // Si hay error al obtener una categoría, continuar con las demás
          debugPrint('Error al contar productos de categoría ${categoria.nombre}: $e');
        }
      }
      
      // Contar equipos de cómputo directamente desde t_equipos_computo
      try {
        final equiposComputo = await supabaseClient
            .from('t_equipos_computo')
            .select('inventario');
        countMap['Equipo de Cómputo'] = equiposComputo.length;
      } catch (e) {
        debugPrint('Error al contar equipos de cómputo: $e');
        countMap['Equipo de Cómputo'] = 0;
      }

      var sessions = await _sessionStorage.getAllSessions();
      
      // Verificar si el usuario es admin
      final isAdmin = await _checkIsAdmin();
      
      // Si no es admin, filtrar solo los inventarios del usuario actual
      if (!isAdmin) {
        final prefs = await SharedPreferences.getInstance();
        final currentUserId = prefs.getString('id_empleado');
        
        if (currentUserId != null) {
          sessions = sessions.where((s) => s.ownerId == currentUserId).toList();
        }
      }

      if (!mounted) return;
      setState(() {
        _categoryCounts = countMap;
        _totalInventories = sessions.length; // Total de inventarios (filtrados por usuario si no es admin)
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error al cargar conteos de categorías: $e');
    }
  }

  Future<void> _navigateToCategory(String categoryName, String searchTerm) async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });

      // Buscar la categoría en la base de datos
      final categorias = await _inventarioRepository.getAllCategorias();
      
      if (categorias.isEmpty) {
        throw 'No hay categorías disponibles en la base de datos';
      }

      // Buscar la categoría que coincida con el término de búsqueda
      Categoria? categoriaEncontrada;
      
      // Intentar diferentes variaciones del nombre
      final searchVariations = [
        searchTerm.toLowerCase(),
        if (searchTerm.contains('jumper')) 'jumper',
        if (searchTerm.contains('comput')) 'comput',
        if (searchTerm.contains('cómputo')) 'cómputo',
        if (searchTerm.contains('computo')) 'computo',
        if (searchTerm.contains('medición')) 'medición',
        if (searchTerm.contains('medicion')) 'medicion',
        if (searchTerm.contains('medición')) 'equipos de medición',
        if (searchTerm.contains('medicion')) 'equipos de medicion',
      ];

      for (final variation in searchVariations) {
        categoriaEncontrada = categorias.firstWhere(
          (c) => c.nombre.toLowerCase().contains(variation),
          orElse: () => Categoria(idCategoria: 0, nombre: ''),
        );
        
        if (categoriaEncontrada.idCategoria != 0) {
          break;
        }
      }

      // Si no se encontró, intentar buscar por nombre parcial
      if (categoriaEncontrada == null || categoriaEncontrada.idCategoria == 0) {
        for (final cat in categorias) {
          if (cat.nombre.toLowerCase().contains(searchTerm.toLowerCase()) ||
              searchTerm.toLowerCase().contains(cat.nombre.toLowerCase())) {
            categoriaEncontrada = cat;
            break;
          }
        }
      }

      // Si aún no se encontró, mostrar error
      if (categoriaEncontrada == null || categoriaEncontrada.idCategoria == 0) {
        throw 'No se encontró la categoría "$categoryName" en la base de datos. Verifica que exista una categoría con ese nombre.';
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      // Si es Jumpers, navegar a la pantalla de categorías de jumpers
      if (categoryName.toLowerCase().contains('jumper') || 
          searchTerm.toLowerCase().contains('jumper')) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => JumperCategoriesScreen(
              categoria: categoriaEncontrada!,
              categoriaNombre: categoryName,
            ),
          ),
        );
      } else if (categoryName.toLowerCase().contains('cómputo') || 
                 categoryName.toLowerCase().contains('computo') ||
                 searchTerm.toLowerCase().contains('comput')) {
        // Para Equipo de Cómputo, navegar a la pantalla específica de inventario de cómputo
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const InventarioComputoScreen(),
          ),
        );
      } else {
        // Para otras categorías, navegar directamente a la pantalla de inventario
        final isAdmin = await _checkIsAdmin();
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryInventoryScreen(
              categoria: categoriaEncontrada!,
              categoriaNombre: categoryName,
              isAdmin: isAdmin,
            ),
          ),
        );
      }
      if (!mounted) return;
      await _loadCategoryCounts();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar categoría: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tipos de Inventario'),
        centerTitle: true,
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Escanear código QR',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const QRScannerScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final padding = isMobile ? 12.0 : 20.0;
                
                return Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selecciona el tipo de inventario',
                        style: TextStyle(
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Realiza el inventario físico de cada categoría',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Expanded(
                        child: ListView(
                          children: [
                        _buildInventoryTypeCard(
                          title: 'Jumpers',
                          description: 'Cables de conexión y jumpers',
                          icon: Icons.cable,
                          color: Colors.blue,
                          productCount: _categoryCounts['Jumpers'] ?? 0,
                          location: 'Sala de jumpers',
                          onTap: () => _navigateToCategory('Jumpers', 'jumper'),
                        ),
                        const SizedBox(height: 16),
                        _buildInventoryTypeCard(
                          title: 'Equipo de Cómputo',
                          description: 'Computadoras, servidores y equipos de cómputo',
                          icon: Icons.computer,
                          color: Colors.purple,
                          productCount: _categoryCounts['Equipo de Cómputo'] ?? 0,
                          onTap: () => _navigateToCategory('Equipo de Cómputo', 'comput'),
                        ),
                        const SizedBox(height: 16),
                        _buildInventoryTypeCard(
                          title: 'Equipo de Medición',
                          description: 'Equipos de medición y herramientas de diagnóstico',
                          icon: Icons.straighten,
                          color: Colors.green,
                          productCount: _categoryCounts['Equipo de Medición'] ?? 0,
                          onTap: () => _navigateToCategory('Equipo de Medición', 'medición'),
                        ),
                        const SizedBox(height: 32),
                        _buildCompletedInventoriesCard(isMobile),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildInventoryTypeCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required int productCount,
    String? location,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: color,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    if (location != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.room,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            location,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: productCount > 0 
                          ? (Theme.of(context).brightness == Brightness.dark 
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.green[100])
                          : Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$productCount ${productCount == 1 ? 'producto' : 'productos'}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: productCount > 0 
                            ? Colors.green[700]
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedInventoriesCard(bool isMobile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CompletedInventoriesScreen(),
            ),
          ).then((_) => _loadCategoryCounts());
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.history,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historial de Inventarios',
          style: TextStyle(
                        fontSize: isMobile ? 20 : 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
          ),
        ),
                    const SizedBox(height: 4),
                    Text(
                      'Visualiza y consulta todos tus inventarios',
          style: TextStyle(
                        fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                        color: _totalInventories > 0 
                          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5)
                          : Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                        '$_totalInventories ${_totalInventories == 1 ? 'inventario' : 'inventarios'}',
                style: TextStyle(
                  fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _totalInventories > 0 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

}

