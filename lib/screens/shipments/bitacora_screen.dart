import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../app/config/supabase_client.dart' show supabaseClient;
import '../../domain/entities/bitacora_envio.dart';
import '../../data/services/bitacora_export_service.dart';

// Clase auxiliar para campos
class _FieldItem {
  final String label;
  final String? value;

  _FieldItem(this.label, this.value);
}

class BitacoraScreen extends StatefulWidget {
  const BitacoraScreen({super.key});

  @override
  State<BitacoraScreen> createState() => _BitacoraScreenState();
}

class _BitacoraScreenState extends State<BitacoraScreen> {
  List<BitacoraEnvio> _bitacoras = [];
  List<BitacoraEnvio> _bitacorasFiltradas = [];
  bool _isLoading = true;
  int? _selectedYear; // null = todos los años
  Set<String> _selectedCodigos = {}; // Códigos seleccionados para filtrar
  final ScrollController _codigosScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Por defecto mostrar el año actual (2025) o el último año con registros
    _selectedYear = DateTime.now().year;
    _loadBitacoras();
  }

  @override
  void dispose() {
    _codigosScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadBitacoras() async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('📥 Cargando bitácoras desde Supabase...');
      
      // Verificar autenticación
      final currentUser = supabaseClient.auth.currentUser;
      final isAuthenticated = currentUser != null;
      debugPrint('🔐 Usuario autenticado: ${isAuthenticated ? currentUser.id : "NO AUTENTICADO"}');
      debugPrint('🔐 Email: ${currentUser?.email ?? "N/A"}');
      
      // Si no está autenticado, intentar autenticar con usuario de servicio
      if (!isAuthenticated) {
        debugPrint('⚠️ Usuario no autenticado en Supabase Auth, intentando autenticación de servicio...');
        try {
          const serviceEmail = 'service@telmex.local';
          const servicePassword = 'ServiceAuth2024!';
          
          await supabaseClient.auth.signInWithPassword(
            email: serviceEmail,
            password: servicePassword,
          );
          debugPrint('✅ Autenticado con usuario de servicio');
        } catch (serviceError) {
          debugPrint('⚠️ No se pudo autenticar con usuario de servicio: $serviceError');
          debugPrint('⚠️ Continuando sin autenticación (las políticas RLS anónimas deberían permitir acceso)');
        }
      }
      
      // Intentar cargar los datos
      List<dynamic> response;
      try {
        response = await supabaseClient
            .from('t_bitacora_envios')
            .select('*')
            .order('consecutivo', ascending: true);
        
        debugPrint('📥 Respuesta recibida: ${response.length} registros');
      } catch (queryError) {
        debugPrint('❌ Error en consulta: $queryError');
        
        // Si el error es de RLS, mostrar mensaje más claro
        final errorString = queryError.toString().toLowerCase();
        if (errorString.contains('row-level security') || 
            errorString.contains('rls') ||
            errorString.contains('policy')) {
          debugPrint('⚠️ Error de RLS detectado. Verifica las políticas en Supabase.');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Error de permisos. Ejecuta el script politica_rls_bitacora_completa.sql en Supabase.',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 8),
                action: SnackBarAction(
                  label: 'Cerrar',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
          }
          return;
        }
        rethrow;
      }
      
      if (response.isEmpty) {
        debugPrint('⚠️ No se encontraron registros en t_bitacora_envios');
        debugPrint('⚠️ Posibles causas:');
        debugPrint('   1. La tabla está vacía');
        debugPrint('   2. Las políticas RLS están bloqueando el acceso');
        debugPrint('   3. El usuario no está autenticado correctamente');
        
        // Intentar una consulta simple para verificar acceso
        try {
          final testResponse = await supabaseClient
              .from('t_bitacora_envios')
              .select('id_bitacora')
              .limit(1);
          debugPrint('🔍 Test de acceso: ${testResponse.length} registros encontrados');
        } catch (testError) {
          debugPrint('❌ Error en test de acceso: $testError');
        }
      }
      
      final bitacoras = response
          .map((json) {
            try {
              return BitacoraEnvio.fromJson(json);
            } catch (e) {
              debugPrint('⚠️ Error al parsear bitácora: $e');
              debugPrint('⚠️ JSON: $json');
              rethrow;
            }
          })
          .toList();

      // Ordenar por consecutivo de forma ascendente
      // Maneja formatos como "17-01", "18-01", "19-01", etc.
      bitacoras.sort((a, b) {
        return _compareConsecutivo(a.consecutivo, b.consecutivo);
      });

      debugPrint('✅ Bitácoras parseadas: ${bitacoras.length}');

      setState(() {
        _bitacoras = bitacoras;
        _isLoading = false;
      });

      // Si no hay año seleccionado o no hay registros del año actual,
      // seleccionar el último año con registros o el año actual
      if (_selectedYear == null || !_hasRecordsForYear(_selectedYear!)) {
        final lastYearWithRecords = _getLastYearWithRecords();
        if (lastYearWithRecords != null) {
          setState(() {
            _selectedYear = lastYearWithRecords;
          });
        } else {
          // Si no hay registros, usar el año actual
          setState(() {
            _selectedYear = DateTime.now().year;
          });
        }
      }

      _applyFilters();
      debugPrint('✅ Filtros aplicados. Bitácoras filtradas: ${_bitacorasFiltradas.length}');
    } catch (e, stackTrace) {
      debugPrint('❌ Error al cargar bitácoras: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _bitacoras = [];
          _bitacorasFiltradas = [];
        });
        
        // Mostrar mensaje de error más amigable
        String errorMessage = 'Error al cargar bitácoras';
        if (e.toString().contains('row-level security') || 
            e.toString().contains('rls') ||
            e.toString().contains('policy')) {
          errorMessage = 'Error de permisos. Verifica las políticas RLS en Supabase.';
        } else if (e.toString().contains('network') || e.toString().contains('connection')) {
          errorMessage = 'Error de conexión. Verifica tu conexión a internet.';
        } else {
          errorMessage = 'Error: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: () {
                _loadBitacoras();
              },
            ),
          ),
        );
      }
    }
  }

  void _applyFilters() {
    List<BitacoraEnvio> filtered = List.from(_bitacoras);

    // Filtrar por año seleccionado
    if (_selectedYear != null) {
      filtered = filtered.where((bitacora) {
        return bitacora.fecha.year == _selectedYear;
      }).toList();
    }

    // Filtrar por códigos seleccionados
    if (_selectedCodigos.isNotEmpty) {
      filtered = filtered.where((bitacora) {
        return bitacora.codigo != null && 
               bitacora.codigo!.isNotEmpty &&
               _selectedCodigos.contains(bitacora.codigo);
      }).toList();
    }

    setState(() {
      _bitacorasFiltradas = filtered;
    });
  }

  List<String> _getCodigosDisponibles() {
    // Filtrar bitácoras por el año seleccionado primero
    List<BitacoraEnvio> bitacorasFiltradas = _bitacoras;
    
    if (_selectedYear != null) {
      bitacorasFiltradas = bitacorasFiltradas.where((b) {
        return b.fecha.year == _selectedYear;
      }).toList();
    }
    
    // Obtener códigos únicos de las bitácoras filtradas por año
    final codigos = bitacorasFiltradas
        .where((b) => b.codigo != null && b.codigo!.isNotEmpty)
        .map((b) => b.codigo!)
        .toSet()
        .toList();
    codigos.sort();
    return codigos;
  }

  void _toggleCodigo(String codigo) {
    setState(() {
      if (_selectedCodigos.contains(codigo)) {
        _selectedCodigos.remove(codigo);
      } else {
        _selectedCodigos.add(codigo);
      }
      _applyFilters();
    });
  }

  void _clearCodigoFilters() {
    setState(() {
      _selectedCodigos.clear();
      _applyFilters();
    });
  }

  void _selectYear(int? year) {
    setState(() {
      _selectedYear = year;
      // Limpiar códigos seleccionados cuando cambia el año
      // para evitar filtros inconsistentes
      _selectedCodigos.clear();
      _applyFilters();
    });
  }

  /// Compara dos consecutivos para ordenamiento ascendente
  /// Maneja formatos como "17-01", "18-01", "19-01", etc.
  /// Retorna: negativo si a < b, cero si a == b, positivo si a > b
  int _compareConsecutivo(String a, String b) {
    try {
      // Intentar parsear formato "YY-NN" (ej: "17-01", "18-01")
      if (a.contains('-') && b.contains('-')) {
        final partsA = a.split('-');
        final partsB = b.split('-');
        
        if (partsA.length == 2 && partsB.length == 2) {
          final yearA = int.tryParse(partsA[0]) ?? 0;
          final numA = int.tryParse(partsA[1]) ?? 0;
          final yearB = int.tryParse(partsB[0]) ?? 0;
          final numB = int.tryParse(partsB[1]) ?? 0;
          
          // Primero comparar por año
          if (yearA != yearB) {
            return yearA.compareTo(yearB);
          }
          // Si el año es igual, comparar por número
          return numA.compareTo(numB);
        }
      }
      
      // Si no tiene el formato esperado, comparar como string
      return a.compareTo(b);
    } catch (e) {
      // En caso de error, comparar como string
      return a.compareTo(b);
    }
  }

  Future<void> _showExportDialog() async {
    // Obtener años disponibles (2017-2025)
    final availableYears = List.generate(2025 - 2017 + 1, (index) => 2017 + index);
    
    // Verificar qué años tienen registros
    final yearsWithRecords = availableYears.where((year) {
      return _bitacoras.any((b) => b.fecha.year == year);
    }).toList();
    
    if (yearsWithRecords.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay registros para exportar'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final selectedYears = await showDialog<List<int>>(
      context: context,
      builder: (context) {
        Set<int> tempSelectedYears = {};
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Exportar Bitácora a Excel'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selecciona uno o más años a exportar:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cada año se exportará en una hoja separada',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: yearsWithRecords.length,
                        itemBuilder: (context, index) {
                          final year = yearsWithRecords[index];
                          final recordCount = _bitacoras.where((b) => b.fecha.year == year).length;
                          final isSelected = tempSelectedYears.contains(year);
                          return CheckboxListTile(
                            title: Text('$year ($recordCount registros)'),
                            value: isSelected,
                            onChanged: (value) {
                              setDialogState(() {
                                if (value == true) {
                                  tempSelectedYears.add(year);
                                } else {
                                  tempSelectedYears.remove(year);
                                }
                              });
                            },
                          );
                        },
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
                  onPressed: tempSelectedYears.isNotEmpty
                      ? () => Navigator.pop(context, tempSelectedYears.toList()..sort())
                      : null,
                  child: const Text('Exportar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedYears != null && selectedYears.isNotEmpty && mounted) {
      _exportToExcel(selectedYears);
    }
  }

  Future<void> _exportToExcel(List<int> years) async {
    try {
      // Ordenar años de forma ascendente
      years.sort();
      
      // Filtrar bitácoras por años seleccionados
      final Map<int, List<BitacoraEnvio>> bitacorasPorAnio = {};
      for (final year in years) {
        final bitacorasDelAnio = _bitacoras.where((b) => b.fecha.year == year).toList();
        if (bitacorasDelAnio.isNotEmpty) {
          bitacorasPorAnio[year] = bitacorasDelAnio;
        }
      }
      
      if (bitacorasPorAnio.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay registros para los años seleccionados'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Mostrar indicador de carga con mensaje más informativo
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Generando Excel con ${years.length} hoja(s)...',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Esto puede tardar unos momentos',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Años: ${years.join(", ")}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      // Exportar
      final result = await BitacoraExportService.exportBitacoraToExcel(
        bitacorasPorAnio,
      );

      // Cerrar indicador de carga
      if (mounted) {
        Navigator.pop(context);
      }

      if (mounted && result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Bitácora exportada exitosamente: $result\n${years.length} hoja(s) creada(s)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Cerrar indicador de carga si hay error
      if (mounted) {
        Navigator.pop(context);
        
        // Extraer mensaje de error más amigable
        String errorMessage = 'Error al exportar';
        final errorStr = e.toString();
        
        if (errorStr.contains('No se pudo conectar') || 
            errorStr.contains('Connection refused') ||
            errorStr.contains('Conexión rehusada') ||
            errorStr.contains('SocketException')) {
          errorMessage = 'El servicio de Excel no está corriendo.\n\n'
              'Ejecuta en otra terminal:\n'
              './iniciar_servicio_excel.sh\n\n'
              'O manualmente:\n'
              'cd excel_generator_service\n'
              'python -m uvicorn main:app --host 0.0.0.0 --port 8001 --reload';
        } else if (errorStr.contains('Tiempo de espera')) {
          errorMessage = 'El servicio no responde. Verifica que esté corriendo.';
        } else if (errorStr.contains('No hay datos')) {
          errorMessage = 'No hay registros para exportar.';
        } else {
          // Mostrar solo la parte útil del error
          final lines = errorStr.split('\n');
          errorMessage = lines.isNotEmpty ? lines[0] : errorStr;
          if (errorMessage.length > 100) {
            errorMessage = '${errorMessage.substring(0, 100)}...';
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Cerrar',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _showAddBitacoraDialog() async {
    await showDialog(
      context: context,
      builder: (context) => _BitacoraFormDialog(
        onSave: (bitacora) async {
          await _saveBitacora(bitacora);
        },
      ),
    );
  }

  Future<void> _saveBitacora(BitacoraEnvio bitacora) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nombreUsuario = prefs.getString('nombre_usuario') ?? 'Sistema';

      // Obtener el siguiente consecutivo
      // Si hay bitácoras existentes, obtener el máximo numérico y sumar 1
      // Si no hay, empezar en 1
      String nuevoConsecutivo = '1';
      if (_bitacoras.isNotEmpty) {
        final numerosConsecutivos = _bitacoras
            .map((b) {
              // Intentar extraer el número del consecutivo (puede ser "17-01" o "1")
              final partes = b.consecutivo.split('-');
              if (partes.isNotEmpty) {
                final num = int.tryParse(partes[0]);
                return num ?? 0;
              }
              final num = int.tryParse(b.consecutivo);
              return num ?? 0;
            })
            .where((n) => n > 0)
            .toList();
        
        if (numerosConsecutivos.isNotEmpty) {
          final maxNum = numerosConsecutivos.reduce((a, b) => a > b ? a : b);
          nuevoConsecutivo = '${maxNum + 1}';
        }
      }

      final nuevaBitacora = bitacora.copyWith(
        consecutivo: nuevoConsecutivo,
        creadoEn: DateTime.now(),
        actualizadoEn: DateTime.now(),
        creadoPor: nombreUsuario,
        actualizadoPor: nombreUsuario,
      );

      await supabaseClient
          .from('t_bitacora_envios')
          .insert(nuevaBitacora.toJson());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Bitácora registrada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadBitacoras();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar bitácora: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bitácora de Envíos',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Selector de años
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtrar por año:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Botón "Todos"
                      _buildYearChip(null, 'Todos'),
                      const SizedBox(width: 8),
                      // Años del 2017 al 2025
                      ...List.generate(2025 - 2017 + 1, (index) {
                        final year = 2017 + index;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildYearChip(year, year.toString()),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Filtros por código y botón agregar
          Padding(
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
                          Row(
                            children: [
                              Text(
                                'Filtrar por código:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              if (_selectedCodigos.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: _clearCodigoFilters,
                                  icon: const Icon(Icons.clear, size: 16),
                                  label: const Text('Limpiar filtros'),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 50,
                            child: Scrollbar(
                              controller: _codigosScrollController,
                              thumbVisibility: true,
                              thickness: 8,
                              radius: const Radius.circular(4),
                              child: SingleChildScrollView(
                                controller: _codigosScrollController,
                                scrollDirection: Axis.horizontal,
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: Row(
                                  children: _getCodigosDisponibles().map((codigo) {
                                    final isSelected = _selectedCodigos.contains(codigo);
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: FilterChip(
                                        label: Text(codigo),
                                        selected: isSelected,
                                        onSelected: (_) => _toggleCodigo(codigo),
                                        selectedColor: Colors.blue[300],
                                        checkmarkColor: Colors.white,
                                        labelStyle: TextStyle(
                                          color: isSelected ? Colors.white : Colors.grey[700],
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 12,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          side: BorderSide(
                                            color: isSelected 
                                                ? Colors.blue[700]! 
                                                : Colors.grey[300]!,
                                            width: isSelected ? 2 : 1,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _showExportDialog,
                      icon: const Icon(Icons.file_download),
                      label: const Text('Exportar a Excel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _showAddBitacoraDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Nueva Bitácora'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Tabla de bitácoras
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _bitacorasFiltradas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.book_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedYear == null && _selectedCodigos.isEmpty
                                  ? 'No hay bitácoras registradas'
                                  : 'No se encontraron resultados con los filtros seleccionados',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildCardView(),
          ),
        ],
      ),
    );
  }

  Widget _buildCardView() {
    if (_bitacorasFiltradas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron resultados con los filtros seleccionados',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _bitacorasFiltradas.length,
      itemBuilder: (context, index) {
        final bitacora = _bitacorasFiltradas[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado con consecutivo y fecha (adaptado para móvil)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF003366),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'CONS. ${bitacora.consecutivo}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: SelectableText(
                                        _formatDate(bitacora.fecha),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              color: Colors.blue,
                              onPressed: () => _showEditBitacoraDialog(bitacora),
                              tooltip: 'Editar',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              color: Colors.red,
                              onPressed: () => _showDeleteConfirmation(bitacora),
                              tooltip: 'Eliminar',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                // Grid de campos principales (siempre usar narrow en móvil)
                _buildNarrowGrid(bitacora),
                // Anexos (si existe)
                if (bitacora.anexos != null && bitacora.anexos!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.attach_file,
                        size: 18,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ANEXOS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              bitacora.anexos!,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                // Observaciones (si existe)
                if (bitacora.observaciones != null &&
                    bitacora.observaciones!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note,
                        size: 18,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'OBSERVACIONES',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              bitacora.observaciones!,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWideGrid(BitacoraEnvio bitacora) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildFieldColumn([
            _FieldItem('Técnico', bitacora.tecnico),
            _FieldItem('Tarjeta', bitacora.tarjeta),
            _FieldItem('Código', bitacora.codigo),
            _FieldItem('Serie', bitacora.serie),
          ]),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildFieldColumn([
            _FieldItem('Folio', bitacora.folio),
            _FieldItem('Envía', bitacora.envia),
            _FieldItem('Recibe', bitacora.recibe),
            _FieldItem('Guía', bitacora.guia),
            _FieldItem('COBO', bitacora.cobo),
          ]),
        ),
      ],
    );
  }

  Widget _buildNarrowGrid(BitacoraEnvio bitacora) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldRow('Técnico', bitacora.tecnico),
        const SizedBox(height: 8),
        _buildFieldRow('Tarjeta', bitacora.tarjeta),
        const SizedBox(height: 8),
        _buildFieldRow('Código', bitacora.codigo),
        const SizedBox(height: 8),
        _buildFieldRow('Serie', bitacora.serie),
        const SizedBox(height: 8),
        _buildFieldRow('Folio', bitacora.folio),
        const SizedBox(height: 8),
        _buildFieldRow('Envía', bitacora.envia),
        const SizedBox(height: 8),
        _buildFieldRow('Recibe', bitacora.recibe),
        const SizedBox(height: 8),
        _buildFieldRow('Guía', bitacora.guia),
        const SizedBox(height: 8),
        _buildFieldRow('COBO', bitacora.cobo),
      ],
    );
  }

  Widget _buildFieldColumn(List<_FieldItem> fields) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fields.map((field) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildFieldRow(field.label, field.value),
        );
      }).toList(),
    );
  }


  Widget _buildFieldRow(String label, String? value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value ?? '-',
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  // Método antiguo de tabla - ya no se usa, pero lo dejamos por si acaso
  Widget _buildDesktopTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(const Color(0xFF003366)),
            headingTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            // Agregar bordes y separadores entre filas más visibles
            dividerThickness: 2.0,
            // Borde horizontal más grueso para mejor separación
            horizontalMargin: 12,
            columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('CONS.')),
            DataColumn(label: Text('FECHA')),
            DataColumn(label: Text('TEC')),
            DataColumn(label: Text('TARJETA')),
            DataColumn(label: Text('CODIGO')),
            DataColumn(label: Text('SERIE')),
            DataColumn(label: Text('FOLIO')),
            DataColumn(label: Text('ENVIA')),
            DataColumn(label: Text('RECIBE')),
            DataColumn(label: Text('GUIA')),
            DataColumn(label: Text('ANEXOS')),
            DataColumn(label: Text('OBSERVACIONES')),
            DataColumn(label: Text('ACCIONES')),
          ],
          rows: _bitacorasFiltradas.asMap().entries.map((entry) {
            final index = entry.key;
            final bitacora = entry.value;
            return DataRow(
              // Alternar colores de fondo para mejor visibilidad
              color: MaterialStateProperty.all(
                index % 2 == 0 ? Colors.grey[50] : Colors.white,
              ),
              cells: [
                DataCell(
                  SelectableText(
                    '${bitacora.consecutivo}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  SelectableText(
                    _formatDate(bitacora.fecha),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  SelectableText(
                    bitacora.tecnico ?? '-',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  SelectableText(
                    bitacora.tarjeta ?? '-',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  SelectableText(
                    bitacora.codigo ?? '-',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  SelectableText(
                    bitacora.serie ?? '-',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  SelectableText(
                    bitacora.folio ?? '-',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  SelectableText(
                    bitacora.envia ?? '-',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  SelectableText(
                    bitacora.recibe ?? '-',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  SelectableText(
                    bitacora.guia ?? '-',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  bitacora.anexos != null
                      ? SelectableText(
                          'ANEXOS',
                          style: const TextStyle(
                            decoration: TextDecoration.underline,
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        )
                      : const SelectableText(
                          '-',
                          style: TextStyle(fontSize: 12),
                        ),
                ),
                DataCell(
                  SizedBox(
                    width: 200,
                    child: SelectableText(
                      bitacora.observaciones ?? '-',
                      style: const TextStyle(fontSize: 12),
                      maxLines: null, // Permitir múltiples líneas al seleccionar
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => _showEditBitacoraDialog(bitacora),
                        tooltip: 'Editar',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                        onPressed: () => _showDeleteConfirmation(bitacora),
                        tooltip: 'Eliminar',
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _showEditBitacoraDialog(BitacoraEnvio bitacora) async {
    await showDialog(
      context: context,
      builder: (context) => _BitacoraFormDialog(
        bitacora: bitacora,
        onSave: (updatedBitacora) async {
          await _updateBitacora(updatedBitacora);
        },
      ),
    );
  }

  Future<void> _updateBitacora(BitacoraEnvio bitacora) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nombreUsuario = prefs.getString('nombre_usuario') ?? 'Sistema';

      final updatedBitacora = bitacora.copyWith(
        actualizadoEn: DateTime.now(),
        actualizadoPor: nombreUsuario,
      );

      await supabaseClient
          .from('t_bitacora_envios')
          .update(updatedBitacora.toJson())
          .eq('id_bitacora', bitacora.idBitacora!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Bitácora actualizada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadBitacoras();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar bitácora: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(BitacoraEnvio bitacora) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar la bitácora #${bitacora.consecutivo}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteBitacora(bitacora);
    }
  }

  Future<void> _deleteBitacora(BitacoraEnvio bitacora) async {
    try {
      await supabaseClient
          .from('t_bitacora_envios')
          .delete()
          .eq('id_bitacora', bitacora.idBitacora!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Bitácora eliminada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadBitacoras();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar bitácora: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBitacoraDetails(BitacoraEnvio bitacora) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bitácora #${bitacora.consecutivo}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Fecha', _formatDate(bitacora.fecha)),
              _buildDetailRow('Técnico', bitacora.tecnico),
              _buildDetailRow('Tarjeta', bitacora.tarjeta),
              _buildDetailRow('Código', bitacora.codigo),
              _buildDetailRow('Serie', bitacora.serie),
              _buildDetailRow('Folio', bitacora.folio),
              _buildDetailRow('Envía', bitacora.envia),
              _buildDetailRow('Recibe', bitacora.recibe),
              _buildDetailRow('Guía', bitacora.guia),
              _buildDetailRow('Anexos', bitacora.anexos),
              _buildDetailRow('Observaciones', bitacora.observaciones),
              _buildDetailRow('COBO', bitacora.cobo),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditBitacoraDialog(bitacora);
            },
            child: const Text('Editar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value ?? '-'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Widget _buildYearChip(int? year, String label) {
    final isSelected = _selectedYear == year;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _selectYear(year),
      selectedColor: const Color(0xFF003366),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF003366) : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
    );
  }

  bool _hasRecordsForYear(int year) {
    return _bitacoras.any((bitacora) => bitacora.fecha.year == year);
  }

  int? _getLastYearWithRecords() {
    if (_bitacoras.isEmpty) return null;
    
    // Obtener todos los años únicos de las bitácoras
    final years = _bitacoras.map((b) => b.fecha.year).toSet().toList();
    years.sort((a, b) => b.compareTo(a)); // Ordenar descendente
    
    // Retornar el año más reciente (primero en la lista ordenada)
    return years.isNotEmpty ? years.first : null;
  }
}

class _BitacoraFormDialog extends StatefulWidget {
  final BitacoraEnvio? bitacora;
  final Function(BitacoraEnvio) onSave;

  const _BitacoraFormDialog({
    this.bitacora,
    required this.onSave,
  });

  @override
  State<_BitacoraFormDialog> createState() => _BitacoraFormDialogState();
}

class _BitacoraFormDialogState extends State<_BitacoraFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _fecha;
  final _tecnicoController = TextEditingController();
  final _tarjetaController = TextEditingController();
  final _codigoController = TextEditingController();
  final _serieController = TextEditingController();
  final _folioController = TextEditingController();
  final _enviaController = TextEditingController();
  final _recibeController = TextEditingController();
  final _guiaController = TextEditingController();
  final _anexosController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _coboController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.bitacora != null) {
      final b = widget.bitacora!;
      _fecha = b.fecha;
      _tecnicoController.text = b.tecnico ?? '';
      _tarjetaController.text = b.tarjeta ?? '';
      _codigoController.text = b.codigo ?? '';
      _serieController.text = b.serie ?? '';
      _folioController.text = b.folio ?? '';
      _enviaController.text = b.envia ?? '';
      _recibeController.text = b.recibe ?? '';
      _guiaController.text = b.guia ?? '';
      _anexosController.text = b.anexos ?? '';
      _observacionesController.text = b.observaciones ?? '';
      _coboController.text = b.cobo ?? '';
    } else {
      _fecha = DateTime.now();
    }
  }

  @override
  void dispose() {
    _tecnicoController.dispose();
    _tarjetaController.dispose();
    _codigoController.dispose();
    _serieController.dispose();
    _folioController.dispose();
    _enviaController.dispose();
    _recibeController.dispose();
    _guiaController.dispose();
    _anexosController.dispose();
    _observacionesController.dispose();
    _coboController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _fecha = picked;
      });
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final bitacora = BitacoraEnvio(
        idBitacora: widget.bitacora?.idBitacora,
        consecutivo: widget.bitacora?.consecutivo ?? '1',
        fecha: _fecha,
        tecnico: _tecnicoController.text.trim().isEmpty ? null : _tecnicoController.text.trim(),
        tarjeta: _tarjetaController.text.trim().isEmpty ? null : _tarjetaController.text.trim(),
        codigo: _codigoController.text.trim().isEmpty ? null : _codigoController.text.trim(),
        serie: _serieController.text.trim().isEmpty ? null : _serieController.text.trim(),
        folio: _folioController.text.trim().isEmpty ? null : _folioController.text.trim(),
        envia: _enviaController.text.trim().isEmpty ? null : _enviaController.text.trim(),
        recibe: _recibeController.text.trim().isEmpty ? null : _recibeController.text.trim(),
        guia: _guiaController.text.trim().isEmpty ? null : _guiaController.text.trim(),
        anexos: _anexosController.text.trim().isEmpty ? null : _anexosController.text.trim(),
        observaciones: _observacionesController.text.trim().isEmpty ? null : _observacionesController.text.trim(),
        cobo: _coboController.text.trim().isEmpty ? null : _coboController.text.trim(),
        creadoEn: widget.bitacora?.creadoEn ?? DateTime.now(),
        actualizadoEn: DateTime.now(),
        creadoPor: widget.bitacora?.creadoPor,
        actualizadoPor: widget.bitacora?.actualizadoPor,
      );

      widget.onSave(bitacora);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.bitacora == null ? 'Nueva Bitácora' : 'Editar Bitácora'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fecha
              ListTile(
                title: const Text('Fecha *'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_fecha)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDate,
              ),
              const Divider(),
              // Técnico
              TextFormField(
                controller: _tecnicoController,
                decoration: InputDecoration(
                  labelText: 'Técnico',
                  hintText: 'Ingrese el nombre del técnico',
                  hintStyle: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[500],
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // Tarjeta
              TextFormField(
                controller: _tarjetaController,
                decoration: InputDecoration(
                  labelText: 'Tarjeta',
                  hintText: 'Ingrese el número o identificación de la tarjeta',
                  hintStyle: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[500],
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // Código
              TextFormField(
                controller: _codigoController,
                decoration: InputDecoration(
                  labelText: 'Código',
                  hintText: 'Ingrese el código del producto/equipo',
                  hintStyle: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[500],
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // Serie
              TextFormField(
                controller: _serieController,
                decoration: InputDecoration(
                  labelText: 'Serie',
                  hintText: 'Ingrese el número de serie',
                  hintStyle: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[500],
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // Folio
              TextFormField(
                controller: _folioController,
                decoration: InputDecoration(
                  labelText: 'Folio',
                  hintText: 'Ingrese el número de folio',
                  hintStyle: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[500],
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // Envía
              TextFormField(
                controller: _enviaController,
                decoration: InputDecoration(
                  labelText: 'Envía',
                  hintText: 'Ingrese quien envía (origen)',
                  hintStyle: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[500],
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // Recibe
              TextFormField(
                controller: _recibeController,
                decoration: InputDecoration(
                  labelText: 'Recibe',
                  hintText: 'Ingrese quien recibe (destino)',
                  hintStyle: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[500],
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // Guía
              TextFormField(
                controller: _guiaController,
                decoration: InputDecoration(
                  labelText: 'Guía',
                  hintText: 'Ingrese el número de guía de envío',
                  hintStyle: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[500],
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // Anexos
              TextFormField(
                controller: _anexosController,
                decoration: InputDecoration(
                  labelText: 'Anexos',
                  hintText: 'Ingrese archivos adjuntos o referencias adicionales',
                  hintStyle: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[500],
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // Observaciones
              TextFormField(
                controller: _observacionesController,
                decoration: InputDecoration(
                  labelText: 'Observaciones',
                  hintText: 'Ingrese notas y observaciones sobre el envío',
                  hintStyle: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[500],
                  ),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              // COBO
              TextFormField(
                controller: _coboController,
                decoration: InputDecoration(
                  labelText: 'COBO',
                  hintText: 'Ingrese el valor de COBO',
                  hintStyle: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[500],
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
