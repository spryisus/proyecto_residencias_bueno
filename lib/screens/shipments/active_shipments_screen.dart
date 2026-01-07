import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../app/config/supabase_client.dart' show supabaseClient;
import '../../domain/entities/bitacora_envio.dart';
import '../../domain/entities/estado_envio.dart';

class ActiveShipmentsScreen extends StatefulWidget {
  const ActiveShipmentsScreen({super.key});

  @override
  State<ActiveShipmentsScreen> createState() => _ActiveShipmentsScreenState();
}

class _ActiveShipmentsScreenState extends State<ActiveShipmentsScreen> {
  List<BitacoraEnvio> _enviosActivos = [];
  bool _isLoading = true;
  EstadoEnvio? _filtroEstado; // null = todos los activos

  @override
  void initState() {
    super.initState();
    _loadEnviosActivos();
  }

  Future<void> _loadEnviosActivos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Usar la vista v_envios_activos que agrupa por código
      // O consultar directamente con filtro de estado
      final query = supabaseClient
          .from('t_bitacora_envios')
          .select()
          .inFilter('estado', ['ENVIADO', 'EN_TRANSITO']);

      // Si hay filtro específico, aplicarlo
      if (_filtroEstado != null) {
        query.eq('estado', _filtroEstado!.toDbString());
      }

      // Ordenar por fecha descendente (más recientes primero)
      final response = await query.order('fecha', ascending: false).order('creado_en', ascending: false);

      // Agrupar por código para mostrar solo el más reciente de cada código
      final Map<String, BitacoraEnvio> enviosPorCodigo = {};
      
      for (final json in response) {
        try {
          final bitacora = BitacoraEnvio.fromJson(json);
          if (bitacora.codigo != null && bitacora.codigo!.isNotEmpty) {
            // Si no existe o si este registro es más reciente, actualizar
            if (!enviosPorCodigo.containsKey(bitacora.codigo) ||
                bitacora.fecha.isAfter(enviosPorCodigo[bitacora.codigo]!.fecha)) {
              enviosPorCodigo[bitacora.codigo!] = bitacora;
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error al parsear envío activo: $e');
        }
      }

      if (mounted) {
        setState(() {
          _enviosActivos = enviosPorCodigo.values.toList();
          // Ordenar por fecha descendente
          _enviosActivos.sort((a, b) => b.fecha.compareTo(a.fecha));
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error al cargar envíos activos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar envíos activos: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cambiarEstado(BitacoraEnvio bitacora, EstadoEnvio nuevoEstado) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nombreUsuario = prefs.getString('nombre_usuario') ?? 'Sistema';

      // Actualizar el estado en la base de datos
      await supabaseClient
          .from('t_bitacora_envios')
          .update({
            'estado': nuevoEstado.toDbString(),
            'actualizado_en': DateTime.now().toIso8601String(),
            'actualizado_por': nombreUsuario,
          })
          .eq('id_bitacora', bitacora.idBitacora!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Estado actualizado a: ${nuevoEstado.nombre}'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadEnviosActivos();
      }
    } catch (e) {
      debugPrint('❌ Error al cambiar estado: $e');
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

  void _mostrarDialogoCambiarEstado(BitacoraEnvio bitacora) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cambiar Estado - ${bitacora.codigo ?? "Sin código"}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Estado actual: ${bitacora.estado.nombre}'),
            const SizedBox(height: 20),
            const Text('Selecciona el nuevo estado:'),
            const SizedBox(height: 16),
            // Botón ENVIADO
            if (bitacora.estado != EstadoEnvio.enviado)
              ListTile(
                leading: const Icon(Icons.send, color: Colors.blue),
                title: const Text('Enviado'),
                subtitle: const Text('La pieza fue enviada'),
                onTap: () {
                  Navigator.pop(context);
                  _cambiarEstado(bitacora, EstadoEnvio.enviado);
                },
              ),
            // Botón EN TRANSITO
            if (bitacora.estado != EstadoEnvio.enTransito)
              ListTile(
                leading: const Icon(Icons.local_shipping, color: Colors.orange),
                title: const Text('En Tránsito'),
                subtitle: const Text('La pieza está en camino'),
                onTap: () {
                  Navigator.pop(context);
                  _cambiarEstado(bitacora, EstadoEnvio.enTransito);
                },
              ),
            // Botón RECIBIDO
            if (bitacora.estado != EstadoEnvio.recibido)
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Recibido'),
                subtitle: const Text('La pieza llegó a su destino'),
                onTap: () {
                  Navigator.pop(context);
                  _cambiarEstado(bitacora, EstadoEnvio.recibido);
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoChip(EstadoEnvio estado) {
    Color color;
    IconData icon;

    switch (estado) {
      case EstadoEnvio.enviado:
        color = Colors.blue;
        icon = Icons.send;
        break;
      case EstadoEnvio.enTransito:
        color = Colors.orange;
        icon = Icons.local_shipping;
        break;
      case EstadoEnvio.recibido:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
    }

    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(estado.nombre),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Envíos Activos'),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        actions: [
          // Filtro de estado
          PopupMenuButton<EstadoEnvio?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (EstadoEnvio? estado) {
              setState(() {
                _filtroEstado = estado;
              });
              _loadEnviosActivos();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('Todos los activos'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: EstadoEnvio.enviado,
                child: Text('Enviado'),
              ),
              const PopupMenuItem(
                value: EstadoEnvio.enTransito,
                child: Text('En Tránsito'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEnviosActivos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _enviosActivos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _filtroEstado == null
                            ? 'No hay envíos activos'
                            : 'No hay envíos con estado: ${_filtroEstado!.nombre}',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Los envíos recibidos no se muestran aquí',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _enviosActivos.length,
                  itemBuilder: (context, index) {
                    final bitacora = _enviosActivos[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: InkWell(
                        onTap: () => _mostrarDialogoCambiarEstado(bitacora),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header con código y estado
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Código: ${bitacora.codigo ?? "Sin código"}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Consecutivo: ${bitacora.consecutivo}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _buildEstadoChip(bitacora.estado),
                                ],
                              ),
                              const Divider(height: 24),
                              // Información del envío
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoItem(
                                      Icons.calendar_today,
                                      'Fecha',
                                      _formatDate(bitacora.fecha),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildInfoItem(
                                      Icons.person,
                                      'Técnico',
                                      bitacora.tecnico ?? '-',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoItem(
                                      Icons.send,
                                      'Envía',
                                      bitacora.envia ?? '-',
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildInfoItem(
                                      Icons.call_received,
                                      'Recibe',
                                      bitacora.recibe ?? '-',
                                    ),
                                  ),
                                ],
                              ),
                              if (bitacora.guia != null && bitacora.guia!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _buildInfoItem(
                                  Icons.qr_code,
                                  'Guía',
                                  bitacora.guia!,
                                ),
                              ],
                              if (bitacora.observaciones != null &&
                                  bitacora.observaciones!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.note,
                                        size: 20,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          bitacora.observaciones!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              // Botón para cambiar estado
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _mostrarDialogoCambiarEstado(bitacora),
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Cambiar Estado'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

