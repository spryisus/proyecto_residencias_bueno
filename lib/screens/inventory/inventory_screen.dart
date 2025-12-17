import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/inventario_completo.dart';
import '../../domain/repositories/inventario_repository.dart';
import '../../core/di/injection_container.dart';
import '../../app/config/supabase_client.dart' show supabaseClient;
import 'qr_scanner_screen.dart';
import 'inventory_report_screen.dart';
import 'inventory_type_selection_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final InventarioRepository _inventarioRepository = serviceLocator.get<InventarioRepository>();
  List<InventarioCompleto> _inventario = [];
  bool _isLoading = true;
  String? _error;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
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
        
        setState(() {
          _isAdmin = isAdmin;
        });
        
        // Si no es admin, cargar inventario normal
        if (!isAdmin) {
          _loadInventario();
        }
      } else {
        _loadInventario();
      }
    } catch (e) {
      // Si hay error, cargar inventario normal
      _loadInventario();
    }
  }

  Future<void> _loadInventario() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final inventario = await _inventarioRepository.getAllInventario();
      
      setState(() {
        _inventario = inventario;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si es admin, mostrar la pantalla de selección de categorías
    if (_isAdmin) {
      return const InventoryTypeSelectionScreen();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventarios'),
        centerTitle: true,
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInventario,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inventario General',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total de productos: ${_inventario.length}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            
            // Botón de escaneo QR solo en dispositivos móviles
            if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS))
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const QRScannerScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner, size: 24),
                  label: const Text(
                    'Escanear Código QR',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar inventario',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(color: Colors.red[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadInventario,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: _inventario.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay productos en el inventario',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _inventario.length,
                        itemBuilder: (context, index) {
                          final item = _inventario[index];
                          return _buildInventoryItemCard(context, item);
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryItemCard(BuildContext context, InventarioCompleto item) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003366),
                        ),
                      ),
                      if (item.producto.descripcion != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.producto.descripcion!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: item.cantidad > 0 ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${item.cantidad}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: item.cantidad > 0 ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.room,
                  size: 16,
                  color: Colors.blue[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Sala: ${item.ubicacion.nombre}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (item.ubicacion.posicion != null && item.ubicacion.posicion!.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Pos: ${item.ubicacion.posicion}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                const Spacer(),
                if (item.categorias.isNotEmpty) ...[
                  Icon(
                    Icons.category,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.categorias.map((c) => c.nombre).join(', '),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InventoryReportScreen(
                            category: item.categorias.isNotEmpty 
                                ? item.categorias.first.nombre 
                                : 'General',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.assessment, size: 16),
                    label: const Text('Ver Reporte'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF003366),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showAdjustmentDialog(context, item);
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Ajustar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003366),
                      foregroundColor: Colors.white,
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

  void _showAdjustmentDialog(BuildContext context, InventarioCompleto item) {
    final cantidadController = TextEditingController(text: item.cantidad.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajustar Inventario - ${item.producto.nombre}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.room, size: 16, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text('Sala: ${item.ubicacion.nombre}'),
              ],
            ),
            if (item.ubicacion.posicion != null && item.ubicacion.posicion!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text('Posición: ${item.ubicacion.posicion}'),
                ],
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: cantidadController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nueva Cantidad',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nuevaCantidad = int.tryParse(cantidadController.text);
              if (nuevaCantidad != null && nuevaCantidad >= 0) {
                final diferencia = nuevaCantidad - item.cantidad;
                if (diferencia != 0) {
                  try {
                    await _inventarioRepository.ajustarInventario(
                      item.producto.idProducto,
                      item.ubicacion.idUbicacion,
                      diferencia,
                      'Ajuste manual desde app',
                    );
                    Navigator.pop(context);
                    _loadInventario();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Inventario ajustado correctamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al ajustar inventario: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Ajustar'),
          ),
        ],
      ),
    );
  }
}