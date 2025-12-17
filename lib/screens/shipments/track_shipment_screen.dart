import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/services/dhl_tracking_service.dart';
import '../../domain/entities/tracking_event.dart';
import '../../app/theme/app_theme.dart';
import '../../app/config/dhl_proxy_config.dart';
import 'package:intl/intl.dart';

class TrackShipmentScreen extends StatefulWidget {
  const TrackShipmentScreen({super.key});

  @override
  State<TrackShipmentScreen> createState() => _TrackShipmentScreenState();
}

class _TrackShipmentScreenState extends State<TrackShipmentScreen> {
  final TextEditingController _trackingController = TextEditingController();
  late final DHLTrackingService _trackingService;
  
  @override
  void initState() {
    super.initState();
    // Inicializar servicio con la URL correcta según la plataforma y ambiente
    // FastAPI primero (rápido); proxy Puppeteer como respaldo.
    // Para usar producción (cloud) en el proxy, cambiar useProduction: true.
    _trackingService = DHLTrackingService(
      fastApiBaseUrl: DHLProxyConfig.getFastApiBase(),
      proxyUrl: DHLProxyConfig.getProxyUrl(useProduction: false),
    );
  }
  bool _isSearching = false;
  ShipmentTracking? _shipmentData;
  String? _errorMessage;

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  Future<void> _searchShipment() async {
    final trackingNumber = _trackingController.text.trim();
    
    if (trackingNumber.isEmpty) {
      _showError('Por favor ingresa un número de seguimiento');
      return;
    }

    // Validar formato del número de tracking
    if (!_trackingService.isValidTrackingNumber(trackingNumber)) {
      _showError('El número de seguimiento no tiene un formato válido');
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _shipmentData = null;
    });

    try {
      final tracking = await _trackingService.trackShipment(trackingNumber);
      
      if (!mounted) return;
      
      setState(() {
        _isSearching = false;
        _shipmentData = tracking;
      });
    } catch (e) {
      if (!mounted) return;

    setState(() {
      _isSearching = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      
      _showError(_errorMessage!);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorRed,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rastrear Envío DHL'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Consulta el Estado de tu Envío',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresa el número de seguimiento DHL para consultar el estado:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),
            // Layout responsive: columna en móvil, fila en desktop
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                
                if (isMobile) {
                  // Layout móvil: columna vertical
                  return Column(
                    children: [
                      TextField(
                        controller: _trackingController,
                        decoration: InputDecoration(
                          labelText: 'Número de Seguimiento DHL',
                          hintText: 'Ej: 1234567890',
                          prefixIcon: const Icon(Icons.local_shipping),
                          border: const OutlineInputBorder(),
                          suffixIcon: _trackingController.text.trim().isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _trackingController.clear();
                                    setState(() {
                                      _shipmentData = null;
                                      _errorMessage = null;
                                    });
                                  },
                                )
                              : null,
                        ),
                        onSubmitted: (_) => _searchShipment(),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isSearching ? null : _searchShipment,
                              icon: _isSearching
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.search),
                              label: Text(_isSearching ? 'Buscando...' : 'Buscar'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          if (_trackingController.text.trim().isNotEmpty) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _openInBrowser(_trackingController.text.trim()),
                              icon: const Icon(Icons.open_in_browser),
                              tooltip: 'Abrir en navegador',
                              style: IconButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  );
                } else {
                  // Layout desktop: fila horizontal
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _trackingController,
                          decoration: InputDecoration(
                            labelText: 'Número de Seguimiento DHL',
                            hintText: 'Ej: 1234567890',
                            prefixIcon: const Icon(Icons.local_shipping),
                            border: const OutlineInputBorder(),
                            suffixIcon: _trackingController.text.trim().isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _trackingController.clear();
                                      setState(() {
                                        _shipmentData = null;
                                        _errorMessage = null;
                                      });
                                    },
                                  )
                                : null,
                          ),
                          onSubmitted: (_) => _searchShipment(),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _isSearching ? null : _searchShipment,
                        icon: _isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.search),
                        label: Text(_isSearching ? 'Buscando...' : 'Buscar'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                      if (_trackingController.text.trim().isNotEmpty) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _openInBrowser(_trackingController.text.trim()),
                          icon: const Icon(Icons.open_in_browser),
                          tooltip: 'Abrir en navegador de DHL',
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isSearching
                  ? _buildLoadingState()
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _shipmentData != null
                  ? _buildShipmentDetails()
                  : _buildEmptyState(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            'Ingresa un número de seguimiento',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'para consultar el estado de tu envío DHL',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text(
            'Consultando información de DHL...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Esto puede tardar hasta 3-4 minutos\ndebido a medidas anti-detección de DHL.\nPor favor, ten paciencia...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final trackingNumber = _trackingController.text.trim();
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: AppTheme.errorRed,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al consultar',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[800],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Ocurrió un error desconocido',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'El proceso puede tardar hasta 3-4 minutos.\nSi el timeout persiste, verifica que el servidor proxy esté corriendo.\nTambién puedes usar "Abrir en navegador" para verificar directamente.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                
                if (isMobile) {
                  // Botones en columna para móvil
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _searchShipment,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Intentar de nuevo'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: trackingNumber.isNotEmpty
                              ? () => _openInBrowser(trackingNumber)
                              : null,
                          icon: const Icon(Icons.open_in_browser),
                          label: const Text('Abrir en navegador'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  // Botones en fila para desktop
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _searchShipment,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Intentar de nuevo'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: trackingNumber.isNotEmpty
                            ? () => _openInBrowser(trackingNumber)
                            : null,
                        icon: const Icon(Icons.open_in_browser),
                        label: const Text('Abrir en navegador'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openInBrowser(String trackingNumber) async {
    final url = Uri.parse(
      'https://www.dhl.com/mx-es/home/tracking/tracking.html?submit=1&tracking-id=$trackingNumber'
    );
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el navegador'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  Widget _buildShipmentDetails() {
    final tracking = _shipmentData!;
    final dateFormat = DateFormat('yyyy-MM-dd');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta de detalles del envío (estilo plantilla)
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título con icono
                Row(
                  children: [
                    Icon(
                      Icons.local_shipping,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Envío #${tracking.trackingNumber}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Información del envío
                _buildInfoRowPlantilla(
                  'Estado:',
                  tracking.status,
                  _getStatusColor(tracking.status),
                ),
                if (tracking.origin != null)
                  _buildInfoRowPlantilla(
                    'Origen:',
                    tracking.origin!,
                    Colors.grey[800]!,
                  ),
                if (tracking.destination != null)
                  _buildInfoRowPlantilla(
                    'Destino:',
                    tracking.destination!,
                    Colors.grey[800]!,
                  ),
                if (tracking.estimatedDelivery != null)
                  _buildInfoRowPlantilla(
                    'Entrega estimada:',
                    dateFormat.format(tracking.estimatedDelivery!),
                    AppTheme.successGreen,
                  ),
                if (tracking.currentLocation != null)
                  _buildInfoRowPlantilla(
                    'Ubicación actual:',
                    tracking.currentLocation!,
                    AppTheme.warningOrange,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Tarjeta de historial (estilo DHL)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título estilo DHL
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Todas las actualizaciones de Envío',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_up,
                      color: Colors.red[700],
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Timeline estilo DHL
                if (tracking.events.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No hay eventos disponibles',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  )
                else
                  _buildDHLTimeline(tracking.events, tracking.trackingNumber),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('entregado') || statusLower.contains('delivered')) {
      return AppTheme.successGreen;
    } else if (statusLower.contains('en tránsito') || statusLower.contains('in transit')) {
      return AppTheme.primaryBlue; // Azul como en la plantilla
    } else if (statusLower.contains('recolectado') || statusLower.contains('picked up')) {
      return AppTheme.infoBlue;
    } else {
      return AppTheme.primaryBlue;
    }
  }

  Widget _buildInfoRowPlantilla(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDHLTimeline(List<TrackingEvent> events, String trackingNumber) {
    // Agrupar eventos por fecha
    final Map<String, List<TrackingEvent>> eventsByDate = {};
    final dateFormat = DateFormat('EEEE d \'de\' MMMM \'de\' yyyy', 'es_ES');
    
    for (final event in events) {
      final dateKey = DateFormat('yyyy-MM-dd').format(event.timestamp);
      eventsByDate.putIfAbsent(dateKey, () => []).add(event);
    }
    
    // Ordenar fechas de más reciente a más antigua
    final sortedDates = eventsByDate.keys.toList()..sort((a, b) => b.compareTo(a));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedDates.map((dateKey) {
        final dateEvents = eventsByDate[dateKey]!;
        final firstEvent = dateEvents.first;
        final displayDate = dateFormat.format(firstEvent.timestamp);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado de fecha
            Padding(
              padding: EdgeInsets.only(
                bottom: 16, 
                top: sortedDates.indexOf(dateKey) > 0 ? 24 : 0,
              ),
              child: Text(
                displayDate,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            // Eventos de esta fecha
            ...dateEvents.asMap().entries.map((entry) {
              final index = entry.key;
              final event = entry.value;
              final isLast = index == dateEvents.length - 1;
              final isFirst = index == 0;
              
              return _buildDHLEventItem(event, trackingNumber, isLast, isFirst);
            }),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDHLEventItem(TrackingEvent event, String trackingNumber, bool isLast, bool isFirst) {
    final timeFormat = DateFormat('h:mm a', 'es_ES');
    final isDelivered = event.description.toLowerCase().contains('entregado') || 
                       event.description.toLowerCase().contains('delivered');
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna de tiempo (izquierda)
          SizedBox(
            width: 120,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${timeFormat.format(event.timestamp)} (UTC-06:00)',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ),
          // Columna del timeline (centro)
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Icono del evento
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isDelivered ? AppTheme.successGreen : Colors.grey[300],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDelivered ? AppTheme.successGreen : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: isDelivered
                      ? const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        )
                      : Icon(
                          Icons.arrow_upward,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                ),
                // Línea vertical
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.grey[300],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Columna de contenido (derecha)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Descripción del evento (en negrita)
                  Text(
                    event.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Ubicación
                  if (event.location != null && event.location!.isNotEmpty)
                    Text(
                      event.location!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                      ),
                    ),
                  if (event.location != null && event.location!.isNotEmpty)
                    const SizedBox(height: 4),
                  // Información de pieza con número de tracking
                  Text(
                    '1 Pieza: $trackingNumber',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
