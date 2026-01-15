import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/config/supabase_client.dart' show supabaseClient;
import '../../data/services/sicor_export_service.dart';
import '../../domain/entities/inventory_session.dart';
import '../../data/local/inventory_session_storage.dart';
import '../../core/di/injection_container.dart';
import '../inventory/qr_scanner_screen.dart';

class InventarioTarjetasRedScreen extends StatefulWidget {
  final String? sessionId;
  
  const InventarioTarjetasRedScreen({super.key, this.sessionId});

  @override
  State<InventarioTarjetasRedScreen> createState() => _InventarioTarjetasRedScreenState();
}

class _InventarioTarjetasRedScreenState extends State<InventarioTarjetasRedScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final InventorySessionStorage _sessionStorage = serviceLocator.get<InventorySessionStorage>();
  
  List<Map<String, dynamic>> _tarjetas = [];
  List<Map<String, dynamic>> _tarjetasFiltradas = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isAdmin = false;
  bool _modoInventario = false;
  Set<int> _tarjetasCompletadas = {}; // Set de IDs de tarjetas completadas
  String? _pendingSessionId; // ID de la sesión pendiente actual
  InventorySession? _pendingSession; // Sesión pendiente completa
  final ScrollController _scrollController = ScrollController();
  int? _highlightedTarjetaId; // ID de la tarjeta resaltada después de escanear QR
  AnimationController? _blinkAnimationController;
  Animation<double>? _blinkAnimation;
  final Map<int, GlobalKey> _tarjetaKeys = {}; // Map de GlobalKeys para cada tarjeta por su ID

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _loadTarjetas();
    // Si hay un sessionId, cargar el progreso del inventario
    if (widget.sessionId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cargarProgresoInventario();
      });
    }
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
    _scrollController.dispose();
    _blinkAnimationController?.dispose();
    super.dispose();
  }

  Future<void> _loadTarjetas() async {
    if (!mounted) return;
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await supabaseClient
          .from('t_tarjetas_red')
          .select('*')
          .order('numero');

      if (!mounted) return;

      final tarjetasList = List<Map<String, dynamic>>.from(response);
      
      setState(() {
        _tarjetas = tarjetasList;
        _tarjetasFiltradas = tarjetasList;
        _isLoading = false;
      });
      
      // Después de cargar las tarjetas, si hay un sessionId, cargar el progreso pendiente
      if (widget.sessionId != null && mounted) {
        await _cargarProgresoInventario();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar tarjetas de red: $e';
        _isLoading = false;
      });
      debugPrint('Error al cargar tarjetas: $e');
    }
  }

  void _filterTarjetas(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _tarjetasFiltradas = _tarjetas;
      } else {
        _tarjetasFiltradas = _tarjetas.where((tarjeta) {
          final numero = (tarjeta['numero'] ?? '').toString().toLowerCase();
          final codigo = (tarjeta['codigo'] ?? '').toString().toLowerCase();
          final serie = (tarjeta['serie'] ?? '').toString().toLowerCase();
          final marca = (tarjeta['marca'] ?? '').toString().toLowerCase();
          final posicion = (tarjeta['posicion'] ?? '').toString().toLowerCase();
          final comentarios = (tarjeta['comentarios'] ?? '').toString().toLowerCase();
          
          return numero.contains(_searchQuery) ||
                 codigo.contains(_searchQuery) ||
                 serie.contains(_searchQuery) ||
                 marca.contains(_searchQuery) ||
                 posicion.contains(_searchQuery) ||
                 comentarios.contains(_searchQuery);
        }).toList();
      }
    });
  }

  // Abrir escáner QR para buscar tarjeta
  Future<void> _abrirEscannerQR() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(
          onQRScanned: _buscarTarjetaPorQR,
        ),
      ),
    );
    
    // Si se escaneó un código, ya se procesó en _buscarTarjetaPorQR
    if (result != null) {
      debugPrint('QR escaneado: $result');
    }
  }

      // Buscar tarjeta por datos del QR
      Future<void> _buscarTarjetaPorQR(String qrData) async {
        try {
          // Parsear el QR code
          // Formato esperado: líneas separadas con:
          // No. (numero)
          // marca
          // serie
          // codigo
          // no. serie (ignorar, no está en BD)
          // posicion
          
          debugPrint('🔍 QR Data completo: "$qrData"');
          
          final lines = qrData.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
          
          debugPrint('🔍 Líneas parseadas: ${lines.length}');
          for (int i = 0; i < lines.length; i++) {
            debugPrint('🔍 Línea $i: "${lines[i]}"');
          }
          
          if (lines.isEmpty) {
            _mostrarErrorQR('El código QR está vacío o no tiene formato válido');
            return;
          }

      String? codigo;
      String? serie;
      String? posicion;

      // Intentar parsear las líneas
      // Formato esperado del QR:
      // Línea 1: "No. XXXX" o "No.: XXXX" o solo el número (ignorar)
      // Línea 2: "Marca: XXXX" o solo marca (ignorar)
      // Línea 3: "Serie: XXXX" o solo serie
      // Línea 4: "Código: XXXX" o solo codigo
      // Línea 5: "no. serie: XXXX" o similar (ignorar)
      // Línea 6: "Posición: XXXX" o solo posicion

      // Función helper para extraer el valor después de los dos puntos
      String _extraerValor(String line) {
        final trimmed = line.trim();
        // Si contiene ":", tomar solo la parte después de ":"
        if (trimmed.contains(':')) {
          final index = trimmed.indexOf(':');
          if (index >= 0 && index < trimmed.length - 1) {
            final valor = trimmed.substring(index + 1).trim();
            debugPrint('🔧 Extraído de "$trimmed" -> "$valor"');
            return valor;
          }
        }
        return trimmed;
      }

      // Función helper para detectar qué tipo de campo es según su etiqueta
      String? _detectarTipoCampo(String line) {
        final lower = line.toLowerCase().trim();
        // Verificar si la línea comienza con la etiqueta o la contiene
        
        // IMPORTANTE: Verificar "No. Serie:" PRIMERO antes de "no." genérico
        // El formato real del QR tiene "No. Serie:" como la serie
        if (lower.startsWith('no. serie:') || lower.startsWith('numero serie:') ||
            lower.startsWith('no serie:') || lower.startsWith('número serie:') ||
            (lower.contains('no. serie') && lower.contains(':')) ||
            (lower.contains('numero serie') && lower.contains(':'))) {
          return 'serie';
        } else if (lower.startsWith('código:') || lower.startsWith('codigo:') || 
            (lower.contains('código') && lower.contains(':'))) {
          return 'codigo';
        } else if (lower.startsWith('serie:') || 
                   lower.startsWith('serial:') ||
                   (lower.contains('serie') && lower.contains(':')) ||
                   (lower.contains('serial') && lower.contains(':'))) {
          return 'serie';
        } else if (lower.startsWith('posición:') || lower.startsWith('posicion:') ||
                   (lower.contains('posición') && lower.contains(':')) ||
                   (lower.contains('posicion') && lower.contains(':'))) {
          return 'posicion';
        } else if (lower.startsWith('marca:') || (lower.contains('marca') && lower.contains(':'))) {
          return 'marca'; // Para ignorar
        } else if (lower.startsWith('tarjeta:') || (lower.contains('tarjeta') && lower.contains(':'))) {
          return 'tarjeta'; // Para ignorar
        } else if (lower.startsWith('no.') || lower.startsWith('numero') ||
                   (lower.contains('no.') && lower.contains(':')) ||
                   (lower.contains('numero') && lower.contains(':'))) {
          return 'numero'; // Para ignorar
        }
        return null;
      }

      // Detectar si las líneas tienen etiquetas (formato "Etiqueta: Valor")
      bool tieneEtiquetas = false;
      for (var line in lines) {
        if (line.contains(':') && _detectarTipoCampo(line) != null) {
          tieneEtiquetas = true;
          break;
        }
      }

      if (tieneEtiquetas) {
        // Parsear por etiquetas (más robusto)
        debugPrint('📋 Parseando QR con etiquetas. Total líneas: ${lines.length}');
        for (var line in lines) {
          final tipoCampo = _detectarTipoCampo(line);
          debugPrint('📋 Línea: "$line" -> Tipo detectado: $tipoCampo');
          if (tipoCampo == 'codigo') {
            codigo = _extraerValor(line);
            debugPrint('✅ Código extraído: "$codigo"');
          } else if (tipoCampo == 'serie') {
            serie = _extraerValor(line);
            debugPrint('✅ Serie extraída: "$serie"');
          } else if (tipoCampo == 'posicion') {
            posicion = _extraerValor(line);
            debugPrint('✅ Posición extraída: "$posicion"');
          }
          // Ignorar marca, numero, etc.
        }
      } else {
        debugPrint('📋 Parseando QR por posición (sin etiquetas detectadas)');
        // Parsear por posición (formato original sin etiquetas)
        // Intentar detectar por contenido aunque no tenga etiqueta explícita
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          debugPrint('📋 Procesando línea $i: "$line"');
          
          // Intentar detectar el tipo por contenido aunque no tenga etiqueta
          final tipoDetectado = _detectarTipoCampo(line);
          if (tipoDetectado == 'codigo' && codigo == null) {
            codigo = line;
            debugPrint('✅ Código detectado por contenido: "$codigo"');
            continue;
          } else if (tipoDetectado == 'serie' && serie == null) {
            serie = line;
            debugPrint('✅ Serie detectada por contenido: "$serie"');
            continue;
          } else if (tipoDetectado == 'posicion' && posicion == null) {
            posicion = line;
            debugPrint('✅ Posición detectada por contenido: "$posicion"');
            continue;
          }
          
          // Si no se detectó por contenido, usar posición fija
          if (i == 0) {
            // Primera línea: número - ignorar
            continue;
          } else if (i == 1) {
            // marca - ignorar
            continue;
          } else if (i == 2 && serie == null) {
            serie = line;
            debugPrint('✅ Serie asignada por posición: "$serie"');
          } else if (i == 3 && codigo == null) {
            codigo = line;
            debugPrint('✅ Código asignado por posición: "$codigo"');
          } else if (i == 4) {
            // no. serie - ignorar
            continue;
          } else if (i == 5 && posicion == null) {
            posicion = line;
            debugPrint('✅ Posición asignada por posición: "$posicion"');
          }
        }
      }
      
      // Limpiar los valores (eliminar espacios extra y caracteres especiales)
      codigo = codigo?.trim();
      serie = serie?.trim();
      posicion = posicion?.trim();
      
      debugPrint('🔍 QR Parseado FINAL - Código: "$codigo", Serie: "$serie", Posición: "$posicion"');
      debugPrint('🔍 Validación - Código válido: ${codigo != null && codigo.isNotEmpty}');
      debugPrint('🔍 Validación - Serie válida: ${serie != null && serie.isNotEmpty}');

      // Buscar en la base de datos por código Y serie (ambos deben coincidir)
      if (codigo == null || codigo.isEmpty) {
        debugPrint('❌ Error: Código es null o vacío');
        _mostrarErrorQR('El código QR no contiene un código válido. Líneas detectadas: ${lines.length}');
        return;
      }

      if (serie == null || serie.isEmpty) {
        debugPrint('❌ Error: Serie es null o vacía');
        debugPrint('❌ Líneas completas del QR:');
        for (int i = 0; i < lines.length; i++) {
          debugPrint('❌   Línea $i: "${lines[i]}"');
        }
        _mostrarErrorQR('El código QR no contiene una serie válida. Por favor verifica el formato del QR.');
        return;
      }

      debugPrint('🔍 Buscando en BD - Código: "$codigo", Serie: "$serie"');

      // Buscar por código Y serie (ambos deben coincidir exactamente)
      final response = await supabaseClient
          .from('t_tarjetas_red')
          .select('*')
          .eq('codigo', codigo)
          .eq('serie', serie);
      
      debugPrint('🔍 Resultados encontrados: ${response.length}');
      
      final tarjetas = List<Map<String, dynamic>>.from(response);
      
      if (tarjetas.isEmpty) {
        _mostrarErrorQR('No se encontró ninguna tarjeta con el código "$codigo" y serie "$serie" en la base de datos');
        return;
      }

      // Si hay múltiples resultados (poco probable), tomar el primero
      final tarjetaEncontrada = tarjetas.first;
      final idTarjeta = tarjetaEncontrada['id_tarjeta_red'] as int?;

      if (idTarjeta == null) {
        _mostrarErrorQR('La tarjeta encontrada no tiene un ID válido');
        return;
      }

      // Actualizar la posición en la tarjeta encontrada con la del QR si está disponible
      if (posicion != null && posicion.isNotEmpty) {
        tarjetaEncontrada['posicion'] = posicion;
      }

      // Buscar el índice en la lista para hacer scroll
      var index = _tarjetasFiltradas.indexWhere(
        (t) => (t['id_tarjeta_red'] as int?) == idTarjeta,
      );
      var usarListaFiltrada = true;

      if (index == -1) {
        // Si no está en la lista filtrada, limpiar el filtro y buscar de nuevo
        setState(() {
          _searchQuery = '';
          _searchController.clear();
          _tarjetasFiltradas = _tarjetas;
        });
        
        // Buscar de nuevo en la lista completa
        index = _tarjetas.indexWhere(
          (t) => (t['id_tarjeta_red'] as int?) == idTarjeta,
        );
        usarListaFiltrada = false;
        
        if (index == -1) {
          _mostrarErrorQR('La tarjeta no se encuentra en la lista actual');
          return;
        }
      }
      
      // Flujo secuencial:
      // 1. Hacer scroll a la tarjeta encontrada
      await _scrollToTarjeta(index, idTarjeta, usarListaFiltrada);
      
      // 2. Esperar a que el scroll se complete y la tarjeta sea visible
      await Future.delayed(const Duration(milliseconds: 800));
      
      // 3. Iniciar animación de parpadeo
      await _iniciarParpadeo(idTarjeta);
      
      // 4. Esperar a que termine el parpadeo (2 segundos)
      await Future.delayed(const Duration(milliseconds: 2000));
      
      // 5. Detener parpadeo y abrir diálogo según el rol del usuario
      _detenerParpadeo();
      if (mounted) {
        if (_isAdmin) {
          // Si es admin, abrir diálogo de edición
          _mostrarEditarTarjetaDialog(tarjetaEncontrada);
        } else {
          // Si es operador, mostrar solo detalles (solo lectura)
          _mostrarDetallesTarjetaDialog(tarjetaEncontrada);
        }
      }
    } catch (e) {
      debugPrint('Error al buscar tarjeta por QR: $e');
      _mostrarErrorQR('Error al procesar el código QR: $e');
    }
  }

  // Paso 1: Hacer scroll a una tarjeta específica usando GlobalKey (sin parpadeo aún)
  Future<void> _scrollToTarjeta(int index, int idTarjeta, [bool usarListaFiltrada = true]) async {
    setState(() {
      _highlightedTarjetaId = idTarjeta;
    });

    // Asegurarse de que el GlobalKey existe para esta tarjeta
    if (!_tarjetaKeys.containsKey(idTarjeta)) {
      _tarjetaKeys[idTarjeta] = GlobalKey();
      // Necesitamos reconstruir para que el key se asigne al widget
      setState(() {});
    }

    final key = _tarjetaKeys[idTarjeta];
    if (key == null) {
      debugPrint('⚠️ No se pudo obtener el GlobalKey para la tarjeta $idTarjeta');
      return;
    }

    // Esperar a que el widget se construya completamente usando WidgetsBinding
    // Esto asegura que el widget esté en el árbol de widgets antes de intentar acceder al contexto
    await WidgetsBinding.instance.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Intentar múltiples veces hasta que el contexto esté disponible
    BuildContext? finalContext;
    int intentos = 0;
    const maxIntentos = 10;
    
    while (intentos < maxIntentos) {
      finalContext = key.currentContext;
      if (finalContext != null && finalContext.mounted) {
        debugPrint('✅ Contexto disponible después de $intentos intentos');
        break;
      }
      await Future.delayed(const Duration(milliseconds: 100));
      intentos++;
    }

    if (finalContext == null || !finalContext.mounted) {
      debugPrint('⚠️ El contexto no está disponible después de $maxIntentos intentos, usando método fallback');
      // Fallback al método manual si el contexto no está disponible
      if (_scrollController.hasClients) {
        const double alturaTarjeta = 100.0;
        const double margenTarjeta = 16.0;
        final double targetPosition = (index * (alturaTarjeta + margenTarjeta));
        final double maxScroll = _scrollController.position.maxScrollExtent;
        final double finalPosition = targetPosition > maxScroll ? maxScroll : targetPosition;
        await _scrollController.animateTo(
          finalPosition,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
        debugPrint('✅ Scroll completado usando método fallback');
      }
      return;
    }

    // Usar Scrollable.ensureVisible para hacer scroll preciso a la tarjeta
    try {
      await Scrollable.ensureVisible(
        finalContext,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
        alignment: 0.15, // Posicionar la tarjeta en el 15% superior de la pantalla visible
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
      debugPrint('✅ Scroll completado a tarjeta ID: $idTarjeta usando GlobalKey');
    } catch (e) {
      debugPrint('⚠️ Error al hacer scroll con ensureVisible: $e');
      // Fallback al método manual si ensureVisible falla
      if (_scrollController.hasClients) {
        const double alturaTarjeta = 100.0;
        const double margenTarjeta = 16.0;
        final double targetPosition = (index * (alturaTarjeta + margenTarjeta));
        final double maxScroll = _scrollController.position.maxScrollExtent;
        final double finalPosition = targetPosition > maxScroll ? maxScroll : targetPosition;
        await _scrollController.animateTo(
          finalPosition,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
        debugPrint('✅ Scroll completado usando método fallback');
      }
    }

    // Mostrar mensaje de tarjeta encontrada
    final listaUsar = usarListaFiltrada ? _tarjetasFiltradas : _tarjetas;
    final numeroTarjeta = index < listaUsar.length 
        ? (listaUsar[index]['numero'] ?? 'Sin número')
        : 'Sin número';

    if (_scaffoldMessengerKey.currentState != null) {
      _scaffoldMessengerKey.currentState!.showSnackBar(
        SnackBar(
          content: Text('Tarjeta encontrada: $numeroTarjeta'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Paso 3: Iniciar animación de parpadeo
  Future<void> _iniciarParpadeo(int idTarjeta) async {
    // Disposing previous animation controller if exists
    _blinkAnimationController?.dispose();

    // Crear nueva animación de parpadeo
    _blinkAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _blinkAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _blinkAnimationController!,
      curve: Curves.easeInOut,
    ));

    // Iniciar animación de parpadeo repetida
    _blinkAnimationController!.repeat(reverse: true);
    
    // Actualizar el estado para que se muestre el parpadeo
    setState(() {
      _highlightedTarjetaId = idTarjeta;
    });
  }

  // Detener parpadeo y limpiar
  void _detenerParpadeo() {
    _blinkAnimationController?.stop();
    _blinkAnimationController?.dispose();
    _blinkAnimationController = null;
    _blinkAnimation = null;
    setState(() {
      _highlightedTarjetaId = null;
    });
  }

  // Mostrar error al buscar por QR
  void _mostrarErrorQR(String mensaje) {
    if (_scaffoldMessengerKey.currentState != null) {
      _scaffoldMessengerKey.currentState!.showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _exportarInventario() async {
    // Si está en modo inventario, exportar solo las tarjetas marcadas
    List<Map<String, dynamic>> tarjetasAExportar;
    if (_modoInventario) {
      if (_tarjetasCompletadas.isEmpty) {
        if (mounted && _scaffoldMessengerKey.currentState != null) {
          _scaffoldMessengerKey.currentState!.showSnackBar(
            const SnackBar(
              content: Text('Debes marcar al menos una tarjeta para exportar'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      tarjetasAExportar = _tarjetas.where((tarjeta) {
        final idTarjetaRed = tarjeta['id_tarjeta_red'] as int?;
        return idTarjetaRed != null && _tarjetasCompletadas.contains(idTarjetaRed);
      }).toList();
    } else {
      if (_tarjetas.isEmpty) {
        if (mounted && _scaffoldMessengerKey.currentState != null) {
          _scaffoldMessengerKey.currentState!.showSnackBar(
            const SnackBar(
              content: Text('No hay tarjetas para exportar'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      tarjetasAExportar = _tarjetas;
    }

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

      // Preparar datos para exportación según plantilla
      final itemsToExport = tarjetasAExportar.map((tarjeta) => <String, dynamic>{
        'en_stock': tarjeta['en_stock'] ?? 'SI',
        'numero': tarjeta['numero'] ?? '',
        'codigo': tarjeta['codigo'] ?? '',
        'serie': tarjeta['serie'] ?? '',
        'marca': tarjeta['marca'] ?? '',
        'posicion': tarjeta['posicion'] ?? '',
        'comentarios': tarjeta['comentarios'] ?? '',
      }).toList();

      final filePath = await SicorExportService.exportSicorToExcel(itemsToExport);

      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo de carga
        if (filePath != null && _scaffoldMessengerKey.currentState != null) {
          _scaffoldMessengerKey.currentState!.showSnackBar(
            SnackBar(
              content: Text(
                _modoInventario
                    ? 'Inventario exportado: ${tarjetasAExportar.length} tarjetas contadas'
                    : 'Inventario de SICOR exportado: $filePath'
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        if (_scaffoldMessengerKey.currentState != null) {
          _scaffoldMessengerKey.currentState!.showSnackBar(
            SnackBar(
              content: Text('Error al exportar inventario: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Inventario de Tarjetas de Red (SICOR)',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF003366),
          foregroundColor: Colors.white,
          actions: [
            // Botón Agregar (solo para admins)
            if (_isAdmin)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ElevatedButton.icon(
                  onPressed: _mostrarAgregarTarjetaDialog,
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
            if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS))
              IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                tooltip: 'Escanear código QR',
                onPressed: _abrirEscannerQR,
              ),
            if (_tarjetas.isNotEmpty || (_modoInventario && _tarjetasCompletadas.isNotEmpty))
              IconButton(
                icon: const Icon(Icons.file_download),
                tooltip: _modoInventario ? 'Exportar inventario' : 'Exportar a Excel',
                onPressed: _exportarInventario,
              ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualizar',
              onPressed: _loadTarjetas,
            ),
          ],
        ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(color: Colors.red[700]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTarjetas,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
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
                                'Inventario pendiente: ${_tarjetasCompletadas.length} de ${_tarjetas.length} tarjetas contadas',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _tarjetasCompletadas.clear();
                                  _pendingSessionId = null;
                                  _pendingSession = null;
                                });
                              },
                              child: const Text('Reiniciar'),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Barra de búsqueda
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar por número, código, serie, marca, posición...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _filterTarjetas('');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceVariant,
                        ),
                        onChanged: _filterTarjetas,
                      ),
                    ),
                    // Estadísticas
                    if (_tarjetas.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              'Total',
                              '${_tarjetas.length}',
                              Icons.inventory_2,
                              Theme.of(context).colorScheme.primary,
                            ),
                            _buildStatItem(
                              'En Stock',
                              '${_tarjetas.where((t) => (t['en_stock'] ?? '').toString().toUpperCase() == 'SI').length}',
                              Icons.check_circle,
                              Colors.green,
                            ),
                            _buildStatItem(
                              'Sin Stock',
                              '${_tarjetas.where((t) => (t['en_stock'] ?? '').toString().toUpperCase() == 'NO').length}',
                              Icons.cancel,
                              Colors.red,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Lista de tarjetas
                    Expanded(
                      child: _tarjetasFiltradas.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.network_check_outlined,
                                    size: 80,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'No se encontraron tarjetas con ese criterio'
                                        : 'No hay tarjetas de red registradas',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16.0),
                              itemCount: _tarjetasFiltradas.length,
                              itemBuilder: (context, index) {
                                final tarjeta = _tarjetasFiltradas[index];
                                return _buildTarjetaCard(tarjeta, isMobile);
                              },
                            ),
                    ),
                  ],
                ),
        floatingActionButton: !_modoInventario && _tarjetasFiltradas.isNotEmpty && !_isAdmin
            ? FloatingActionButton.extended(
                onPressed: () {
                  setState(() {
                    _modoInventario = true;
                  });
                },
                backgroundColor: const Color(0xFF003366),
                icon: const Icon(Icons.inventory_2, color: Colors.white),
                label: const Text(
                  'Realizar Inventario',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              )
            : _modoInventario
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton(
                        onPressed: _guardarProgresoInventario,
                        backgroundColor: Colors.orange,
                        child: const Icon(Icons.pause_circle, color: Colors.white),
                        tooltip: 'Terminar más tarde',
                      ),
                      const SizedBox(height: 12),
                      FloatingActionButton(
                        onPressed: _finalizarInventario,
                        backgroundColor: Colors.green,
                        child: const Icon(Icons.check_circle, color: Colors.white),
                        tooltip: 'Finalizar inventario',
                      ),
                      const SizedBox(height: 12),
                      FloatingActionButton(
                        onPressed: () {
                          setState(() {
                            _modoInventario = false;
                          });
                        },
                        backgroundColor: Colors.grey,
                        child: const Icon(Icons.close, color: Colors.white),
                        tooltip: 'Cancelar inventario',
                      ),
                    ],
                  )
                : null,
      ),
    );
  }

  // Mostrar diálogo para agregar tarjeta
  void _mostrarAgregarTarjetaDialog() {
    showDialog(
      context: context,
      builder: (context) => _TarjetaDialog(
        tarjeta: {}, // Tarjeta vacía para crear una nueva
        onSave: (nuevaTarjeta) async {
          try {
            final datosInsert = <String, dynamic>{
              'en_stock': (nuevaTarjeta['en_stock'] ?? 'SI').toString().toUpperCase(),
              'numero': nuevaTarjeta['numero']?.toString().trim() ?? '',
            };
            
            // Campos opcionales
            if (nuevaTarjeta['codigo'] != null && nuevaTarjeta['codigo'].toString().trim().isNotEmpty) {
              datosInsert['codigo'] = nuevaTarjeta['codigo'].toString().trim();
            }
            if (nuevaTarjeta['serie'] != null && nuevaTarjeta['serie'].toString().trim().isNotEmpty) {
              datosInsert['serie'] = nuevaTarjeta['serie'].toString().trim();
            }
            if (nuevaTarjeta['marca'] != null && nuevaTarjeta['marca'].toString().trim().isNotEmpty) {
              datosInsert['marca'] = nuevaTarjeta['marca'].toString().trim();
            }
            if (nuevaTarjeta['posicion'] != null && nuevaTarjeta['posicion'].toString().trim().isNotEmpty) {
              datosInsert['posicion'] = nuevaTarjeta['posicion'].toString().trim();
            }
            if (nuevaTarjeta['comentarios'] != null && nuevaTarjeta['comentarios'].toString().trim().isNotEmpty) {
              datosInsert['comentarios'] = nuevaTarjeta['comentarios'].toString().trim();
            }

            // Validar que el número no esté vacío
            if (datosInsert['numero'].toString().trim().isEmpty) {
              throw Exception('El número es requerido');
            }

            // Insertar la nueva tarjeta en la base de datos
            await supabaseClient
                .from('t_tarjetas_red')
                .insert(datosInsert)
                .select();

            if (!mounted) return;

            // Recargar las tarjetas
            await _loadTarjetas();

            if (mounted && _scaffoldMessengerKey.currentState != null) {
              _scaffoldMessengerKey.currentState!.showSnackBar(
                const SnackBar(
                  content: Text('Tarjeta agregada correctamente'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            if (mounted && _scaffoldMessengerKey.currentState != null) {
              _scaffoldMessengerKey.currentState!.showSnackBar(
                SnackBar(
                  content: Text('Error al agregar tarjeta: $e'),
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

  // Eliminar tarjeta
  Future<void> _eliminarTarjeta(Map<String, dynamic> tarjeta) async {
    final numero = tarjeta['numero']?.toString() ?? 'Sin número';
    
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
                child: Text('Eliminar tarjeta de red'),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Estás seguro de que deseas eliminar esta tarjeta?',
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
                          Icons.numbers,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Número: $numero',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (tarjeta['codigo'] != null && tarjeta['codigo'].toString().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.qr_code,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Código: ${tarjeta['codigo']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
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

    // Si el usuario confirmó, eliminar la tarjeta
    if (confirmDelete == true) {
      try {
        final idTarjetaRed = tarjeta['id_tarjeta_red'];
        if (idTarjetaRed == null) {
          throw Exception('ID de la tarjeta no encontrado');
        }

        // Eliminar de la base de datos
        await supabaseClient
            .from('t_tarjetas_red')
            .delete()
            .eq('id_tarjeta_red', idTarjetaRed);

        if (!mounted) return;

        // Recargar las tarjetas
        await _loadTarjetas();

        if (mounted && _scaffoldMessengerKey.currentState != null) {
          _scaffoldMessengerKey.currentState!.showSnackBar(
            const SnackBar(
              content: Text('Tarjeta eliminada correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted && _scaffoldMessengerKey.currentState != null) {
          _scaffoldMessengerKey.currentState!.showSnackBar(
            SnackBar(
              content: Text('Error al eliminar tarjeta: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  // Mostrar diálogo para ver detalles de tarjeta (solo lectura para operadores)
  void _mostrarDetallesTarjetaDialog(Map<String, dynamic> tarjeta) {
    showDialog(
      context: context,
      builder: (context) => _TarjetaDetallesDialog(
        tarjeta: Map<String, dynamic>.from(tarjeta),
      ),
    );
  }

  // Mostrar diálogo para editar tarjeta
  void _mostrarEditarTarjetaDialog(Map<String, dynamic> tarjeta) {
    showDialog(
      context: context,
      builder: (context) => _TarjetaDialog(
        tarjeta: Map<String, dynamic>.from(tarjeta),
        onSave: (tarjetaActualizada) async {
          try {
            final idTarjetaRed = tarjeta['id_tarjeta_red'];
            if (idTarjetaRed == null) {
              throw Exception('ID de la tarjeta no encontrado');
            }

            final datosUpdate = <String, dynamic>{
              'en_stock': (tarjetaActualizada['en_stock'] ?? 'SI').toString().toUpperCase(),
              'numero': tarjetaActualizada['numero']?.toString().trim() ?? '',
            };

            // Campos opcionales
            if (tarjetaActualizada['codigo'] != null) {
              datosUpdate['codigo'] = tarjetaActualizada['codigo'].toString().trim().isEmpty 
                  ? null 
                  : tarjetaActualizada['codigo'].toString().trim();
            }
            if (tarjetaActualizada['serie'] != null) {
              datosUpdate['serie'] = tarjetaActualizada['serie'].toString().trim().isEmpty 
                  ? null 
                  : tarjetaActualizada['serie'].toString().trim();
            }
            if (tarjetaActualizada['marca'] != null) {
              datosUpdate['marca'] = tarjetaActualizada['marca'].toString().trim().isEmpty 
                  ? null 
                  : tarjetaActualizada['marca'].toString().trim();
            }
            if (tarjetaActualizada['posicion'] != null) {
              datosUpdate['posicion'] = tarjetaActualizada['posicion'].toString().trim().isEmpty 
                  ? null 
                  : tarjetaActualizada['posicion'].toString().trim();
            }
            if (tarjetaActualizada['comentarios'] != null) {
              datosUpdate['comentarios'] = tarjetaActualizada['comentarios'].toString().trim().isEmpty 
                  ? null 
                  : tarjetaActualizada['comentarios'].toString().trim();
            }

            // Validar que el número no esté vacío
            if (datosUpdate['numero'].toString().trim().isEmpty) {
              throw Exception('El número es requerido');
            }

            // Actualizar la tarjeta en la base de datos
            await supabaseClient
                .from('t_tarjetas_red')
                .update(datosUpdate)
                .eq('id_tarjeta_red', idTarjetaRed);

            if (!mounted) return;

            // Recargar las tarjetas
            await _loadTarjetas();

            if (mounted && _scaffoldMessengerKey.currentState != null) {
              _scaffoldMessengerKey.currentState!.showSnackBar(
                const SnackBar(
                  content: Text('Tarjeta actualizada correctamente'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            if (mounted && _scaffoldMessengerKey.currentState != null) {
              _scaffoldMessengerKey.currentState!.showSnackBar(
                SnackBar(
                  content: Text('Error al actualizar tarjeta: $e'),
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

  // Guardar progreso del inventario
  Future<void> _guardarProgresoInventario() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ownerId = prefs.getString('id_empleado');
      final ownerName = prefs.getString('nombre_usuario');
      
      // Obtener la categoría SICOR
      final categorias = await supabaseClient
          .from('t_categorias')
          .select('id_categoria, nombre')
          .or('nombre.ilike.sicor,nombre.ilike.%medición%,nombre.ilike.%medicion%')
          .limit(1);
      
      if (categorias.isEmpty) {
        throw Exception('No se encontró la categoría SICOR');
      }
      
      final categoria = categorias.first;
      final categoryName = categoria['nombre'] as String;
      final categoryId = categoria['id_categoria'] as int;
      
      // Crear mapa de quantities usando id_tarjeta_red como clave
      // Valor 1 = completado, 0 = no completado
      final quantities = <int, int>{};
      for (var tarjeta in _tarjetas) {
        final idTarjetaRed = tarjeta['id_tarjeta_red'] as int?;
        if (idTarjetaRed != null) {
          quantities[idTarjetaRed] = _tarjetasCompletadas.contains(idTarjetaRed) ? 1 : 0;
        }
      }
      
      // Determinar el ID de la sesión
      String sessionId;
      if (widget.sessionId != null) {
        // Si se pasó un sessionId desde fuera, usarlo
        sessionId = widget.sessionId!;
      } else if (_pendingSessionId != null) {
        // Verificar que la sesión existente sea pending antes de actualizarla
        final existingSession = await _sessionStorage.getSessionById(_pendingSessionId!);
        if (existingSession != null && existingSession.status == InventorySessionStatus.pending) {
          sessionId = _pendingSessionId!;
        } else {
          // Si la sesión está completada o no existe, crear una nueva
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final categoryNameHash = categoryName.hashCode.abs();
          sessionId = 'sicor_${timestamp}_${categoryNameHash}_${ownerId ?? 'unknown'}';
        }
      } else {
        // Crear un nuevo ID único
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final categoryNameHash = categoryName.hashCode.abs();
        sessionId = 'sicor_${timestamp}_${categoryNameHash}_${ownerId ?? 'unknown'}';
      }
      
      final session = InventorySession(
        id: sessionId,
        categoryId: categoryId,
        categoryName: categoryName,
        quantities: quantities,
        status: InventorySessionStatus.pending,
        updatedAt: DateTime.now(),
        ownerId: ownerId,
        ownerName: ownerName,
        ownerEmail: ownerName,
      );
      
      await _sessionStorage.saveSession(session);
      
      setState(() {
        _pendingSessionId = sessionId;
        _pendingSession = session;
      });
      
      if (mounted && _scaffoldMessengerKey.currentState != null) {
        _scaffoldMessengerKey.currentState!.showSnackBar(
          SnackBar(
            content: Text('Progreso guardado: ${_tarjetasCompletadas.length} de ${_tarjetas.length} tarjetas. Puedes continuar más tarde.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al guardar progreso del inventario: $e');
      if (mounted && _scaffoldMessengerKey.currentState != null) {
        _scaffoldMessengerKey.currentState!.showSnackBar(
          SnackBar(
            content: Text('Error al guardar progreso: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Finalizar inventario
  Future<void> _finalizarInventario() async {
    try {
      if (_tarjetasCompletadas.isEmpty) {
        if (mounted && _scaffoldMessengerKey.currentState != null) {
          _scaffoldMessengerKey.currentState!.showSnackBar(
            const SnackBar(
              content: Text('Debes marcar al menos una tarjeta para finalizar el inventario'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Guardar el progreso primero
      await _guardarProgresoInventario();

      if (_pendingSessionId == null) {
        throw Exception('No se pudo crear la sesión de inventario');
      }

      // Guardar el número de tarjetas completadas antes de limpiar
      final numTarjetasCompletadas = _tarjetasCompletadas.length;

      // Obtener la sesión y marcarla como completada
      final session = await _sessionStorage.getSessionById(_pendingSessionId!);
      if (session != null) {
        final completedSession = InventorySession(
          id: session.id,
          categoryId: session.categoryId,
          categoryName: session.categoryName,
          quantities: session.quantities,
          status: InventorySessionStatus.completed,
          updatedAt: DateTime.now(),
          ownerId: session.ownerId,
          ownerName: session.ownerName,
          ownerEmail: session.ownerEmail,
        );

        await _sessionStorage.saveSession(completedSession);

        setState(() {
          _modoInventario = false;
          _tarjetasCompletadas.clear();
          _pendingSessionId = null;
          _pendingSession = null;
        });

        if (mounted && _scaffoldMessengerKey.currentState != null) {
          _scaffoldMessengerKey.currentState!.showSnackBar(
            SnackBar(
              content: Text('Inventario finalizado: $numTarjetasCompletadas tarjetas contadas'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error al finalizar inventario: $e');
      if (mounted && _scaffoldMessengerKey.currentState != null) {
        _scaffoldMessengerKey.currentState!.showSnackBar(
          SnackBar(
            content: Text('Error al finalizar inventario: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Cargar progreso del inventario pendiente
  Future<void> _cargarProgresoInventario() async {
    if (!mounted) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final ownerId = prefs.getString('id_empleado');
      
      // Obtener la categoría SICOR
      final categorias = await supabaseClient
          .from('t_categorias')
          .select('id_categoria, nombre')
          .or('nombre.ilike.sicor,nombre.ilike.%medición%,nombre.ilike.%medicion%')
          .limit(1);
      
      if (categorias.isEmpty) {
        debugPrint('No se encontró la categoría SICOR');
        return;
      }
      
      final categoria = categorias.first;
      final categoryName = categoria['nombre'] as String;
      
      InventorySession? session;
      
      // Si hay un sessionId pasado como parámetro, cargarlo
      if (widget.sessionId != null) {
        try {
          session = await _sessionStorage.getSessionById(widget.sessionId!);
          // Verificar que la sesión sea pending y pertenezca al usuario
          if (session != null) {
            if (session.status != InventorySessionStatus.pending) {
              session = null; // No cargar si está completada
            } else if (!_isAdmin && session.ownerId != ownerId) {
              session = null; // No cargar si no es del usuario y no es admin
            }
          }
        } catch (e) {
          debugPrint('Error al cargar sesión por ID: $e');
          session = null;
        }
      }
      
      // Si no hay sesión por ID, buscar por nombre de categoría
      if (session == null) {
        try {
          session = await _sessionStorage.getSessionByCategoryName(
            categoryName,
            status: InventorySessionStatus.pending,
          );
          
          // Si no es admin, verificar que la sesión pertenezca al usuario actual
          if (session != null && !_isAdmin && session.ownerId != ownerId) {
            session = null;
          }
        } catch (e) {
          debugPrint('Error al cargar sesión por categoría: $e');
          session = null;
        }
      }
      
      if (!mounted) return;
      
      if (session != null) {
        // Cargar las tarjetas completadas desde la sesión
        final tarjetasCompletadas = <int>{};
        for (var entry in session.quantities.entries) {
          if (entry.value == 1) {
            // El valor 1 significa que está completado
            tarjetasCompletadas.add(entry.key);
          }
        }
        
        setState(() {
          _pendingSessionId = session!.id;
          _pendingSession = session;
          _tarjetasCompletadas = tarjetasCompletadas;
          _modoInventario = true; // Activar modo inventario automáticamente
        });
        
        debugPrint('✅ Progreso cargado: ${tarjetasCompletadas.length} tarjetas completadas');
      } else {
        debugPrint('No se encontró sesión pendiente para SICOR');
      }
    } catch (e) {
      debugPrint('Error al cargar progreso del inventario: $e');
    }
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTarjetaCard(Map<String, dynamic> tarjeta, bool isMobile) {
    final enStock = (tarjeta['en_stock'] ?? '').toString().toUpperCase() == 'SI';
    final numero = tarjeta['numero']?.toString() ?? '';
    final codigo = tarjeta['codigo']?.toString() ?? '';
    final serie = tarjeta['serie']?.toString() ?? '';
    final marca = tarjeta['marca']?.toString() ?? '';
    final posicion = tarjeta['posicion']?.toString() ?? '';
    final comentarios = tarjeta['comentarios']?.toString() ?? '';
    final idTarjetaRed = tarjeta['id_tarjeta_red'] as int?;
    final estaCompletada = idTarjetaRed != null && _tarjetasCompletadas.contains(idTarjetaRed);
    final estaResaltada = idTarjetaRed != null && _highlightedTarjetaId == idTarjetaRed;

    // Color de fondo según el estado de stock y si está resaltada
    final backgroundColor = estaResaltada
        ? Colors.blue[50]?.withOpacity(0.3) ?? Colors.blue[100]!
        : (enStock 
            ? Theme.of(context).colorScheme.surface
            : Colors.red[50]);
    final textColor = enStock 
        ? Theme.of(context).colorScheme.onSurface
        : Colors.red[900]!;

    // Calcular el color del borde base (sin animación)
    Color baseBorderColor;
    if (estaCompletada) {
      baseBorderColor = Colors.green;
    } else if (enStock) {
      baseBorderColor = Colors.grey[300]!;
    } else {
      baseBorderColor = Colors.red[400]!;
    }

    // Obtener o crear el GlobalKey para esta tarjeta
    if (idTarjetaRed != null && !_tarjetaKeys.containsKey(idTarjetaRed)) {
      _tarjetaKeys[idTarjetaRed] = GlobalKey();
    }
    final tarjetaKey = idTarjetaRed != null ? _tarjetaKeys[idTarjetaRed] : null;

    return AnimatedBuilder(
      animation: _blinkAnimation ?? const AlwaysStoppedAnimation(1.0),
      builder: (context, child) {
        // Calcular el color del borde con animación de parpadeo si está resaltada
        Color animatedBorderColor = baseBorderColor;
        if (estaResaltada && _blinkAnimation != null) {
          final opacity = _blinkAnimation!.value;
          animatedBorderColor = Colors.blue.withOpacity(opacity);
        } else if (estaResaltada) {
          animatedBorderColor = Colors.blue;
        }
        
        return Card(
          key: tarjetaKey,
          elevation: estaResaltada ? 8 : (estaCompletada ? 6 : 4),
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: animatedBorderColor,
              width: estaResaltada ? 3 : 2,
            ),
          ),
          child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ExpansionTile(
          leading: SizedBox(
            width: 40,
            child: _modoInventario
                ? Checkbox(
                    value: estaCompletada,
                    onChanged: (value) {
                      setState(() {
                        if (idTarjetaRed != null) {
                          if (value == true) {
                            _tarjetasCompletadas.add(idTarjetaRed);
                          } else {
                            _tarjetasCompletadas.remove(idTarjetaRed);
                          }
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
                      color: enStock 
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      enStock ? Icons.check_circle : Icons.cancel,
                      color: enStock ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
          ),
          title: Text(
            numero.isNotEmpty ? numero : 'Sin número',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 16 : 18,
              color: textColor,
            ),
          ),
          subtitle: Text(
            enStock ? 'En Stock' : 'Sin Stock',
            style: TextStyle(
              color: enStock ? Colors.green[700] : Colors.red[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Código', codigo, textColor),
                  _buildInfoRow('Serie', serie, textColor),
                  _buildInfoRow('Marca', marca, textColor),
                  _buildInfoRow('Posición', posicion, textColor),
                  if (comentarios.isNotEmpty)
                    _buildInfoRow('Comentarios', comentarios, textColor),
                  const SizedBox(height: 8),
                  // Fecha de registro si existe
                  if (tarjeta['fecha_registro'] != null)
                    Text(
                      'Registrado: ${_formatDate(tarjeta['fecha_registro'])}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  // Botones de editar y eliminar (solo para admins)
                  if (_isAdmin) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _mostrarEditarTarjetaDialog(tarjeta);
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Editar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _eliminarTarjeta(tarjeta);
                            },
                            icon: const Icon(Icons.delete),
                            label: const Text('Eliminar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, Color textColor) {
    if (value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: textColor.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final dateTime = date is String ? DateTime.parse(date) : date as DateTime;
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return date.toString();
    }
  }
}

// Diálogo para agregar/editar tarjeta de red
class _TarjetaDialog extends StatefulWidget {
  final Map<String, dynamic> tarjeta;
  final Function(Map<String, dynamic>) onSave;

  const _TarjetaDialog({
    required this.tarjeta,
    required this.onSave,
  });

  @override
  State<_TarjetaDialog> createState() => _TarjetaDialogState();
}

class _TarjetaDialogState extends State<_TarjetaDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _numeroController;
  late TextEditingController _codigoController;
  late TextEditingController _serieController;
  late TextEditingController _marcaController;
  late TextEditingController _posicionController;
  late TextEditingController _comentariosController;
  String _enStock = 'SI';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final enStockValue = (widget.tarjeta['en_stock'] ?? 'SI').toString().toUpperCase();
    _enStock = (enStockValue == 'SI' || enStockValue == 'NO') ? enStockValue : 'SI';
    
    _numeroController = TextEditingController(text: widget.tarjeta['numero']?.toString() ?? '');
    _codigoController = TextEditingController(text: widget.tarjeta['codigo']?.toString() ?? '');
    _serieController = TextEditingController(text: widget.tarjeta['serie']?.toString() ?? '');
    _marcaController = TextEditingController(text: widget.tarjeta['marca']?.toString() ?? '');
    _posicionController = TextEditingController(text: widget.tarjeta['posicion']?.toString() ?? '');
    _comentariosController = TextEditingController(text: widget.tarjeta['comentarios']?.toString() ?? '');
  }

  @override
  void dispose() {
    _numeroController.dispose();
    _codigoController.dispose();
    _serieController.dispose();
    _marcaController.dispose();
    _posicionController.dispose();
    _comentariosController.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    widget.onSave({
      'en_stock': _enStock,
      'numero': _numeroController.text.trim(),
      'codigo': _codigoController.text.trim(),
      'serie': _serieController.text.trim(),
      'marca': _marcaController.text.trim(),
      'posicion': _posicionController.text.trim(),
      'comentarios': _comentariosController.text.trim(),
    });

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNuevo = widget.tarjeta.isEmpty || widget.tarjeta['id_tarjeta_red'] == null;
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isNuevo ? Icons.add_circle : Icons.edit,
            color: const Color(0xFF003366),
          ),
          const SizedBox(width: 8),
          Text(isNuevo ? 'Agregar Tarjeta de Red' : 'Editar Tarjeta de Red'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estado de stock
              DropdownButtonFormField<String>(
                value: _enStock,
                decoration: const InputDecoration(
                  labelText: 'En Stock *',
                  prefixIcon: Icon(Icons.inventory_2, color: Color(0xFF003366)),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'SI', child: Text('SI - En Stock')),
                  DropdownMenuItem(value: 'NO', child: Text('NO - Sin Stock')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _enStock = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecciona el estado de stock';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Número
              TextFormField(
                controller: _numeroController,
                decoration: const InputDecoration(
                  labelText: 'No. *',
                  hintText: 'Ej: SICOR001',
                  prefixIcon: Icon(Icons.numbers, color: Color(0xFF003366)),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El número es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Código
              TextFormField(
                controller: _codigoController,
                decoration: const InputDecoration(
                  labelText: 'Código',
                  hintText: 'Ej: NTFW08CB',
                  prefixIcon: Icon(Icons.qr_code, color: Color(0xFF003366)),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Serie
              TextFormField(
                controller: _serieController,
                decoration: const InputDecoration(
                  labelText: 'Serie',
                  hintText: 'Ej: NNTMA1B1C7FF7',
                  prefixIcon: Icon(Icons.confirmation_number, color: Color(0xFF003366)),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Marca
              TextFormField(
                controller: _marcaController,
                decoration: const InputDecoration(
                  labelText: 'Marca',
                  hintText: 'Ej: NORTEL -TN16X',
                  prefixIcon: Icon(Icons.branding_watermark, color: Color(0xFF003366)),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Posición
              TextFormField(
                controller: _posicionController,
                decoration: const InputDecoration(
                  labelText: 'Posición',
                  hintText: 'Ej: G-1 R-C',
                  prefixIcon: Icon(Icons.location_on, color: Color(0xFF003366)),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Comentarios
              TextFormField(
                controller: _comentariosController,
                decoration: const InputDecoration(
                  labelText: 'Comentarios',
                  hintText: 'Comentarios adicionales...',
                  prefixIcon: Icon(Icons.comment, color: Color(0xFF003366)),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF003366),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(isNuevo ? 'Agregar' : 'Guardar'),
        ),
      ],
    );
  }
}

// Diálogo para ver detalles de tarjeta de red (solo lectura)
class _TarjetaDetallesDialog extends StatelessWidget {
  final Map<String, dynamic> tarjeta;

  const _TarjetaDetallesDialog({
    required this.tarjeta,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(
            Icons.visibility,
            color: Color(0xFF003366),
          ),
          const SizedBox(width: 8),
          const Text('Detalles de Tarjeta de Red'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estado de stock
            _buildDetailRow(
              icon: Icons.inventory_2,
              label: 'En Stock',
              value: (tarjeta['en_stock'] ?? 'SI').toString(),
            ),
            const SizedBox(height: 16),
            // Número
            _buildDetailRow(
              icon: Icons.numbers,
              label: 'No.',
              value: tarjeta['numero']?.toString() ?? 'N/A',
            ),
            const SizedBox(height: 16),
            // Código
            _buildDetailRow(
              icon: Icons.qr_code,
              label: 'Código',
              value: tarjeta['codigo']?.toString() ?? 'N/A',
            ),
            const SizedBox(height: 16),
            // Serie
            _buildDetailRow(
              icon: Icons.confirmation_number,
              label: 'Serie',
              value: tarjeta['serie']?.toString() ?? 'N/A',
            ),
            const SizedBox(height: 16),
            // Marca
            _buildDetailRow(
              icon: Icons.branding_watermark,
              label: 'Marca',
              value: tarjeta['marca']?.toString() ?? 'N/A',
            ),
            const SizedBox(height: 16),
            // Posición
            _buildDetailRow(
              icon: Icons.location_on,
              label: 'Posición',
              value: tarjeta['posicion']?.toString() ?? 'N/A',
            ),
            const SizedBox(height: 16),
            // Comentarios
            if (tarjeta['comentarios'] != null && tarjeta['comentarios'].toString().isNotEmpty) ...[
              _buildDetailRow(
                icon: Icons.comment,
                label: 'Comentarios',
                value: tarjeta['comentarios']?.toString() ?? 'N/A',
                isMultiline: true,
              ),
              const SizedBox(height: 16),
            ],
            // Fecha de registro
            if (tarjeta['fecha_registro'] != null) ...[
              _buildDetailRow(
                icon: Icons.calendar_today,
                label: 'Fecha de Registro',
                value: tarjeta['fecha_registro']?.toString() ?? 'N/A',
              ),
              const SizedBox(height: 16),
            ],
            // Fecha de actualización
            if (tarjeta['fecha_actualizacion'] != null)
              _buildDetailRow(
                icon: Icons.update,
                label: 'Última Actualización',
                value: tarjeta['fecha_actualizacion']?.toString() ?? 'N/A',
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isMultiline = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF003366), size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
            ),
            maxLines: isMultiline ? null : 2,
            overflow: isMultiline ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

