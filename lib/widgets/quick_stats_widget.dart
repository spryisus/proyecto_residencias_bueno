import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/di/injection_container.dart';
import '../data/local/inventory_session_storage.dart';
import '../domain/entities/inventory_session.dart';
import '../app/config/supabase_client.dart' show supabaseClient;

/// Widget que muestra estadísticas rápidas del usuario actual
class QuickStatsWidget extends StatefulWidget {
  const QuickStatsWidget({super.key});

  @override
  State<QuickStatsWidget> createState() => _QuickStatsWidgetState();
}

class _QuickStatsWidgetState extends State<QuickStatsWidget> {
  final InventorySessionStorage _sessionStorage = serviceLocator.get<InventorySessionStorage>();
  bool _isLoading = true;
  int _pendingInventories = 0;
  int _completedInventories = 0;
  int _totalInventories = 0;
  String? _userName;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener información del usuario actual
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('id_empleado');
      final userName = prefs.getString('nombre_usuario');
      
      // Verificar si es admin
      bool isAdmin = false;
      if (currentUserId != null) {
        try {
          final roles = await supabaseClient
              .from('t_empleado_rol')
              .select('t_roles!inner(nombre)')
              .eq('id_empleado', currentUserId);
          
          isAdmin = roles.any((rol) => 
              rol['t_roles']['nombre']?.toString().toLowerCase() == 'admin');
        } catch (e) {
          debugPrint('Error al verificar rol: $e');
        }
      }

      // Cargar todas las sesiones
      final allSessions = await _sessionStorage.getAllSessions();
      
      // Filtrar por usuario si no es admin
      List<InventorySession> userSessions;
      if (isAdmin) {
        // Admin ve todos los inventarios
        userSessions = allSessions;
      } else if (currentUserId != null) {
        // Usuario normal solo ve sus inventarios
        userSessions = allSessions.where((s) => s.ownerId == currentUserId).toList();
      } else {
        userSessions = [];
      }

      // Calcular estadísticas
      final pending = userSessions.where((s) => s.status == InventorySessionStatus.pending).length;
      final completed = userSessions.where((s) => s.status == InventorySessionStatus.completed).length;
      final total = userSessions.length;

      if (!mounted) return;
      setState(() {
        _pendingInventories = pending;
        _completedInventories = completed;
        _totalInventories = total;
        _userName = userName;
        _isAdmin = isAdmin;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar estadísticas: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estadísticas Rápidas',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (_userName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _isAdmin ? 'Administrador' : _userName!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              _buildStatRow(
                context,
                'Inventarios Pendientes',
                _pendingInventories.toString(),
                Icons.pending_outlined,
                Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildStatRow(
                context,
                'Inventarios Completados',
                _completedInventories.toString(),
                Icons.check_circle_outline,
                Colors.green,
              ),
              const SizedBox(height: 12),
              _buildStatRow(
                context,
                'Total de Inventarios',
                _totalInventories.toString(),
                Icons.inventory_2_outlined,
                Theme.of(context).colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }
}

