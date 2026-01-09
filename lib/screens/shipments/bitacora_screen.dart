import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../app/config/supabase_client.dart' show supabaseClient;
import '../../domain/entities/bitacora_envio.dart';
import '../../domain/entities/estado_envio.dart';
import '../../data/services/bitacora_export_service.dart';
import '../../data/services/storage_service.dart';
import '../../core/utils/file_saver_helper.dart';

// Importación condicional para web
import '../../core/utils/web_file_helper_stub.dart'
    if (dart.library.html) '../../core/utils/web_file_helper.dart' as web_helper;

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
  
  // Nuevos filtros
  String? _selectedTarjeta; // Filtro por tarjeta (RECTIFICADOR, MIS, OAU, etc.)
  final TextEditingController _codigoSearchController = TextEditingController(); // Búsqueda por últimos 4 dígitos
  bool _isSearching = false; // Indica si se está buscando activamente

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
    _codigoSearchController.dispose();
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

    // Filtrar por tarjeta seleccionada
    if (_selectedTarjeta != null && _selectedTarjeta!.isNotEmpty) {
      filtered = filtered.where((bitacora) {
        return bitacora.tarjeta != null && 
               bitacora.tarjeta!.trim().toUpperCase() == _selectedTarjeta!.trim().toUpperCase();
      }).toList();
    }

    // Filtrar por códigos seleccionados (solo si no hay búsqueda activa)
    if (!_isSearching && _selectedCodigos.isNotEmpty) {
      filtered = filtered.where((bitacora) {
        return bitacora.codigo != null && 
               bitacora.codigo!.isNotEmpty &&
               _selectedCodigos.contains(bitacora.codigo);
      }).toList();
    }

    // Búsqueda por últimos 3 o 4 dígitos del código (solo si hay búsqueda activa)
    if (_isSearching) {
      final searchText = _codigoSearchController.text.trim();
      final searchLength = searchText.length;
      if (searchLength >= 3 && searchLength <= 4) {
        final searchDigits = searchText.toUpperCase();
        filtered = filtered.where((bitacora) {
          if (bitacora.codigo == null || bitacora.codigo!.isEmpty) {
            return false;
          }
          final codigo = bitacora.codigo!.toUpperCase();
          // Verificar si los últimos 3 o 4 caracteres coinciden
          if (codigo.length >= searchLength) {
            final ultimosDigitos = codigo.substring(codigo.length - searchLength);
            return ultimosDigitos == searchDigits;
          }
          return false;
        }).toList();
      }
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
    
    // Si hay filtro de tarjeta, aplicar también
    if (_selectedTarjeta != null && _selectedTarjeta!.isNotEmpty) {
      bitacorasFiltradas = bitacorasFiltradas.where((b) {
        return b.tarjeta != null && 
               b.tarjeta!.trim().toUpperCase() == _selectedTarjeta!.trim().toUpperCase();
      }).toList();
    }
    
    // Obtener códigos únicos de las bitácoras filtradas
    final codigos = bitacorasFiltradas
        .where((b) => b.codigo != null && b.codigo!.isNotEmpty)
        .map((b) => b.codigo!)
        .toSet()
        .toList();
    codigos.sort();
    return codigos;
  }

  /// Obtiene las tarjetas únicas disponibles para el filtro
  List<String> _getTarjetasDisponibles() {
    // Filtrar bitácoras por el año seleccionado primero
    List<BitacoraEnvio> bitacorasFiltradas = _bitacoras;
    
    if (_selectedYear != null) {
      bitacorasFiltradas = bitacorasFiltradas.where((b) {
        return b.fecha.year == _selectedYear;
      }).toList();
    }
    
    // Obtener tarjetas únicas (no nulas y no vacías)
    final tarjetas = bitacorasFiltradas
        .where((b) => b.tarjeta != null && b.tarjeta!.trim().isNotEmpty)
        .map((b) => b.tarjeta!.trim().toUpperCase())
        .toSet()
        .toList();
    tarjetas.sort();
    return tarjetas;
  }

  /// Limpia el filtro de tarjeta
  void _clearTarjetaFilter() {
    setState(() {
      _selectedTarjeta = null;
      _applyFilters();
    });
  }

  /// Realiza la búsqueda por últimos 3 o 4 dígitos
  void _performSearch() {
    final searchText = _codigoSearchController.text.trim();
    if (searchText.length >= 3 && searchText.length <= 4) {
      setState(() {
        _isSearching = true;
        _applyFilters();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa 3 o 4 caracteres (números o letras)'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Limpia la búsqueda
  void _clearSearch() {
    setState(() {
      _codigoSearchController.clear();
      _isSearching = false;
      _applyFilters();
    });
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

  /// Muestra diálogo para seleccionar año
  Future<void> _showYearFilterDialog() async {
    final availableYears = _getAvailableYears();
    
    final selectedYear = await showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar por año'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableYears.length + 1, // +1 para "Todos"
            itemBuilder: (context, index) {
              if (index == 0) {
                final isSelected = _selectedYear == null;
                return ListTile(
                  leading: Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? const Color(0xFF003366) : Colors.grey,
                  ),
                  title: const Text('Todos'),
                  selected: isSelected,
                  onTap: () => Navigator.pop(context, null),
                );
              } else {
                final year = availableYears[index - 1];
                final isSelected = _selectedYear == year;
                return ListTile(
                  leading: Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? const Color(0xFF003366) : Colors.grey,
                  ),
                  title: Text(year.toString()),
                  selected: isSelected,
                  onTap: () => Navigator.pop(context, year),
                );
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (selectedYear != null || (_selectedYear != null && selectedYear == null)) {
      _selectYear(selectedYear);
    }
  }

  /// Muestra diálogo para seleccionar tarjeta
  Future<void> _showTarjetaFilterDialog() async {
    final tarjetasDisponibles = _getTarjetasDisponibles();
    
    final selectedTarjeta = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar por tarjeta'),
        content: SizedBox(
          width: double.maxFinite,
          child: tarjetasDisponibles.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No hay tarjetas disponibles'),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: tarjetasDisponibles.length + 1, // +1 para "Todas"
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = _selectedTarjeta == null;
                      return ListTile(
                        leading: Icon(
                          isSelected ? Icons.check_circle : Icons.circle_outlined,
                          color: isSelected ? Colors.orange[400] : Colors.grey,
                        ),
                        title: const Text('Todas'),
                        selected: isSelected,
                        onTap: () => Navigator.pop(context, null),
                      );
                    } else {
                      final tarjeta = tarjetasDisponibles[index - 1];
                      final isSelected = _selectedTarjeta == tarjeta;
                      return ListTile(
                        leading: Icon(
                          isSelected ? Icons.check_circle : Icons.circle_outlined,
                          color: isSelected ? Colors.orange[400] : Colors.grey,
                        ),
                        title: Text(tarjeta),
                        selected: isSelected,
                        onTap: () => Navigator.pop(context, tarjeta),
                      );
                    }
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (selectedTarjeta != null || (_selectedTarjeta != null && selectedTarjeta == null)) {
      setState(() {
        _selectedTarjeta = selectedTarjeta;
        _applyFilters();
      });
    }
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

  // Método helper para obtener años disponibles
  // Incluye años desde 2017 hasta el año actual + 1, y también años que existen en la BD
  List<int> _getAvailableYears() {
    final currentYear = DateTime.now().year;
    final startYear = 2017;
    final endYear = currentYear + 1; // Incluir el año siguiente
    
    // Obtener años que existen en las bitácoras
    final yearsInDb = _bitacoras.map((b) => b.fecha.year).toSet();
    
    // Crear lista con años base (2017 hasta año actual + 1)
    final baseYears = List.generate(endYear - startYear + 1, (index) => startYear + index);
    
    // Agregar años de la BD que no estén en el rango base
    final allYears = <int>{...baseYears, ...yearsInDb};
    
    // Ordenar y retornar
    final sortedYears = allYears.toList()..sort();
    return sortedYears;
  }

  // Obtener años que tienen bitácoras registradas
  List<int> _getYearsWithRecords() {
    final years = _bitacoras.map((b) => b.fecha.year).toSet().toList();
    years.sort();
    return years;
  }

  Future<void> _showAddBitacoraWithYearDialog() async {
    final availableYears = _getAvailableYears();

    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        int? selectedYear;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Nueva Bitácora con Año'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecciona el año para la nueva bitácora:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Año',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  items: availableYears.map((year) {
                    return DropdownMenuItem<int>(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }).toList(),
                  onChanged: (int? year) {
                    setState(() {
                      selectedYear = year;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: selectedYear == null
                    ? null
                    : () => Navigator.pop(context, selectedYear),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003366),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Continuar'),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      // Crear una fecha con el año seleccionado (usar 1 de enero como fecha por defecto)
      final fechaInicial = DateTime(result, 1, 1);
      await _showAddBitacoraDialog(fechaInicial: fechaInicial);
    }
  }

  Future<void> _showDeleteYearDialog() async {
    final yearsWithRecords = _getYearsWithRecords();
    
    if (yearsWithRecords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay bitácoras registradas para eliminar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        int? selectedYear;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Eliminar Bitácoras por Año'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecciona el año cuyas bitácoras deseas eliminar:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Año',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  items: yearsWithRecords.map((year) {
                    final count = _bitacoras.where((b) => b.fecha.year == year).length;
                    return DropdownMenuItem<int>(
                      value: year,
                      child: Text('$year (${count} registro${count != 1 ? 's' : ''})'),
                    );
                  }).toList(),
                  onChanged: (int? year) {
                    setState(() {
                      selectedYear = year;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: selectedYear == null
                    ? null
                    : () => Navigator.pop(context, selectedYear),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Continuar'),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      await _confirmDeleteYear(result);
    }
  }

  Future<void> _confirmDeleteYear(int year) async {
    final count = _bitacoras.where((b) => b.fecha.year == year).length;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirmar Eliminación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás realmente seguro de eliminar la bitácora del año $year?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Se eliminarán $count registro${count != 1 ? 's' : ''} del año $year.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta acción no se puede deshacer.',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

    if (confirm == true) {
      await _deleteBitacorasByYear(year);
    }
  }

  Future<void> _deleteBitacorasByYear(int year) async {
    try {
      // Obtener IDs de las bitácoras del año
      final bitacorasDelAnio = _bitacoras.where((b) => b.fecha.year == year).toList();
      
      if (bitacorasDelAnio.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No hay bitácoras del año $year para eliminar'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

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

      // Eliminar cada bitácora y sus PDFs asociados
      int eliminadas = 0;
      int pdfsEliminados = 0;
      final storageService = StorageService();
      
      for (final bitacora in bitacorasDelAnio) {
        if (bitacora.idBitacora != null) {
          try {
            // Si hay un PDF asociado, eliminarlo del storage primero
            if (bitacora.anexos != null && 
                bitacora.anexos!.isNotEmpty && 
                _isPdfUrl(bitacora.anexos)) {
              try {
                await storageService.deleteFile(bitacora.anexos!);
                pdfsEliminados++;
                debugPrint('✅ PDF eliminado: ${bitacora.anexos}');
              } catch (e) {
                debugPrint('⚠️ Error al eliminar PDF ${bitacora.anexos}: $e');
                // Continuar con la eliminación de la bitácora de todas formas
              }
            }

            // Eliminar la bitácora de la base de datos
            await supabaseClient
                .from('t_bitacora_envios')
                .delete()
                .eq('id_bitacora', bitacora.idBitacora!);
            eliminadas++;
          } catch (e) {
            debugPrint('Error al eliminar bitácora ${bitacora.idBitacora}: $e');
          }
        }
      }

      // Cerrar diálogo de carga
      if (mounted) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Se eliminaron $eliminadas bitácora${eliminadas != 1 ? 's' : ''}${pdfsEliminados > 0 ? ' y $pdfsEliminados PDF${pdfsEliminados != 1 ? 's' : ''}' : ''} del año $year'
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Recargar bitácoras
        await _loadBitacoras();
        
        // Si el año eliminado estaba seleccionado, limpiar la selección
        if (_selectedYear == year) {
          setState(() {
            _selectedYear = null;
          });
          _applyFilters();
        }
      }
    } catch (e) {
      debugPrint('❌ Error al eliminar bitácoras del año $year: $e');
      
      // Cerrar diálogo de carga si está abierto
      if (mounted) {
        Navigator.pop(context);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar bitácoras: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _showExportDialog() async {
    // Obtener años disponibles dinámicamente
    final availableYears = _getAvailableYears();
    
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

  Future<void> _showAddBitacoraDialog({DateTime? fechaInicial}) async {
    await showDialog(
      context: context,
      builder: (context) => _BitacoraFormDialog(
        fechaInicial: fechaInicial,
        onSave: (bitacora, pdfFile, pdfToDelete) async {
          await _saveBitacora(bitacora, pdfFile, pdfToDelete);
        },
      ),
    );
  }

  Future<void> _saveBitacora(BitacoraEnvio bitacora, File? pdfFile, String? pdfToDelete) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nombreUsuario = prefs.getString('nombre_usuario') ?? 'Sistema';

      // Obtener el siguiente consecutivo basado en el año de la fecha
      // Formato: "YY-NN" donde YY es el año (2 dígitos) y NN es el número secuencial
      final anioBitacora = bitacora.fecha.year;
      final anioCorto = anioBitacora % 100; // Obtener últimos 2 dígitos (ej: 2026 -> 26)
      
      String nuevoConsecutivo = '$anioCorto-01'; // Por defecto: primer consecutivo del año
      
      if (_bitacoras.isNotEmpty) {
        // Filtrar bitácoras del mismo año
        final bitacorasDelAnio = _bitacoras
            .where((b) => b.fecha.year == anioBitacora)
            .toList();
        
        if (bitacorasDelAnio.isNotEmpty) {
          // Buscar el máximo número de consecutivo para este año
          int maxNum = 0;
          
          for (final b in bitacorasDelAnio) {
            // Intentar parsear formato "YY-NN"
            if (b.consecutivo.contains('-')) {
              final partes = b.consecutivo.split('-');
              if (partes.length == 2) {
                // Verificar que el año coincida
                final anioConsecutivo = int.tryParse(partes[0]);
                if (anioConsecutivo == anioCorto) {
                  final num = int.tryParse(partes[1]);
                  if (num != null && num > maxNum) {
                    maxNum = num;
                  }
                }
              }
            } else {
              // Si no tiene formato "YY-NN", verificar si es solo un número
              // y si la fecha coincide con el año actual
              final num = int.tryParse(b.consecutivo);
              if (num != null && num > maxNum) {
                // Si es un número simple y la fecha es del mismo año, considerarlo
                maxNum = num;
              }
            }
          }
          
          // Generar nuevo consecutivo: año-número siguiente
          nuevoConsecutivo = '$anioCorto-${(maxNum + 1).toString().padLeft(2, '0')}';
        }
      }

      // Para registros de 2026 en adelante, estado inicial es ENVIADO
      // Para registros anteriores, mantener FINALIZADO (por defecto)
      final estadoInicial = anioBitacora >= 2026 
          ? EstadoEnvio.enviado 
          : EstadoEnvio.recibido;

      final nuevaBitacora = bitacora.copyWith(
        consecutivo: nuevoConsecutivo,
        estado: estadoInicial,
        creadoEn: DateTime.now(),
        actualizadoEn: DateTime.now(),
        creadoPor: nombreUsuario,
        actualizadoPor: nombreUsuario,
      );

      // Usar toJsonForInsert() para excluir id_bitacora (auto-generado)
      final response = await supabaseClient
          .from('t_bitacora_envios')
          .insert(nuevaBitacora.toJsonForInsert())
          .select()
          .single();

      // Obtener el ID de la bitácora recién creada
      final idBitacora = response['id_bitacora'] as int;

      // Si hay un archivo PDF, subirlo ahora que tenemos el ID
      String? pdfUrl;
      if (pdfFile != null) {
        try {
          final storageService = StorageService();
          pdfUrl = await storageService.uploadPdfFile(pdfFile, idBitacora);
          
          // Actualizar la bitácora con la URL del PDF
      await supabaseClient
          .from('t_bitacora_envios')
              .update({'anexos': pdfUrl})
              .eq('id_bitacora', idBitacora);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ Bitácora guardada, pero error al subir PDF: $e'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pdfFile != null && pdfUrl != null
                ? '✅ Bitácora registrada y PDF subido exitosamente'
                : '✅ Bitácora registrada exitosamente'),
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          
          if (isMobile) {
            // INTERFAZ MÓVIL - Diseño completamente vertical
            return _buildMobileLayout();
          } else {
            // INTERFAZ ESCRITORIO - Diseño original
            return _buildDesktopLayout();
          }
        },
      ),
    );
  }

  // Interfaz específica para móvil
  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Header con filtros por año y tarjeta (similar a la imagen de referencia)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF003366),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filtros en fila horizontal - Botones que abren diálogos
              Row(
                children: [
                  // Filtro por año - Botón
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filtrar por año:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[300],
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 36,
                          child: OutlinedButton.icon(
                            onPressed: _showYearFilterDialog,
                            icon: const Icon(Icons.calendar_today, size: 16, color: Colors.white),
                            label: Text(
                              _selectedYear == null ? 'Todos' : _selectedYear.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.15),
                              side: BorderSide(color: Colors.white.withOpacity(0.5)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Filtro por tarjeta - Botón
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filtrar por tarjeta:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[300],
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 36,
                          child: OutlinedButton.icon(
                            onPressed: _showTarjetaFilterDialog,
                            icon: const Icon(Icons.filter_list, size: 16, color: Colors.white),
                            label: Text(
                              _selectedTarjeta == null ? 'Todas' : _selectedTarjeta!,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.15),
                              side: BorderSide(color: Colors.white.withOpacity(0.5)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Filtros y búsqueda - MÓVIL: Todo en columna
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Búsqueda por últimos 3 o 4 dígitos del código
              Text(
                'Buscar por últimos 3 o 4 dígitos del código:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codigoSearchController,
                      maxLength: 4,
                      decoration: InputDecoration(
                        hintText: 'Ej: 8CA9 o CA9',
                        border: const OutlineInputBorder(),
                        counterText: '',
                        suffixIcon: _isSearching
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: _clearSearch,
                                tooltip: 'Limpiar búsqueda',
                              )
                            : null,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      onSubmitted: (_) => _performSearch(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _performSearch,
                    tooltip: 'Buscar',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF003366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Título y botón limpiar en fila (filtros de código - solo si no hay búsqueda activa)
              if (!_isSearching) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filtrar por código:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    if (_selectedCodigos.isNotEmpty)
                      TextButton.icon(
                        onPressed: _clearCodigoFilters,
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Limpiar'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Chips de códigos
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
                const SizedBox(height: 12),
              ],
              // Botones en columna para móvil
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showExportDialog,
                      icon: const Icon(Icons.file_download, size: 18),
                      label: const Text('Exportar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showAddBitacoraDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Nueva'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showAddBitacoraWithYearDialog,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: const Text('Nueva con Año'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showDeleteYearDialog,
                      icon: const Icon(Icons.delete_forever, size: 18),
                      label: const Text('Eliminar Año'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Lista de bitácoras
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
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : _buildCardView(),
        ),
      ],
    );
  }

  // Interfaz específica para escritorio (diseño original)
  Widget _buildDesktopLayout() {
    return Column(
      children: [
        // Header con filtros por año y tarjeta (similar a la imagen de referencia)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF003366),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filtros en fila horizontal - Botones que abren diálogos
              Row(
                children: [
                  // Filtro por año - Botón
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filtrar por año:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[300],
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 36,
                          child: OutlinedButton.icon(
                            onPressed: _showYearFilterDialog,
                            icon: const Icon(Icons.calendar_today, size: 16, color: Colors.white),
                            label: Text(
                              _selectedYear == null ? 'Todos' : _selectedYear.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.15),
                              side: BorderSide(color: Colors.white.withOpacity(0.5)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Filtro por tarjeta - Botón
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filtrar por tarjeta:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[300],
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 36,
                          child: OutlinedButton.icon(
                            onPressed: _showTarjetaFilterDialog,
                            icon: const Icon(Icons.filter_list, size: 16, color: Colors.white),
                            label: Text(
                              _selectedTarjeta == null ? 'Todas' : _selectedTarjeta!,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.15),
                              side: BorderSide(color: Colors.white.withOpacity(0.5)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Filtros y búsqueda - ESCRITORIO
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Búsqueda por últimos 4 dígitos del código
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buscar por últimos 3 o 4 dígitos del código:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _codigoSearchController,
                                maxLength: 4,
                                decoration: InputDecoration(
                                  hintText: 'Ej: 8CA9 o CA9',
                                  border: const OutlineInputBorder(),
                                  counterText: '',
                                  suffixIcon: _isSearching
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: _clearSearch,
                                          tooltip: 'Limpiar búsqueda',
                                        )
                                      : null,
                                ),
                                textCapitalization: TextCapitalization.characters,
                                onSubmitted: (_) => _performSearch(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: _performSearch,
                              tooltip: 'Buscar',
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFF003366),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filtrar por código:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        if (_selectedCodigos.isNotEmpty && !_isSearching) ...[
                          const SizedBox(height: 4),
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
                        if (!_isSearching) ...[
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
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Búsqueda activa. Los filtros de código están deshabilitados.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange[900],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Botones de acción
              Row(
                children: [
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
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showAddBitacoraWithYearDialog,
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Nueva con Año'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showDeleteYearDialog,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Eliminar Año'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
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
          child: ExpansionTile(
            initiallyExpanded: false,
            tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: _buildCardHeader(bitacora),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                _buildEstadoChip(bitacora.estado),
                const SizedBox(height: 4),
                _buildEstadoLeyenda(bitacora.estado),
              ],
            ),
            children: [
              const Divider(height: 1),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Botones de acción
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        color: Colors.blue,
                        onPressed: () => _showEditBitacoraDialog(bitacora),
                        tooltip: 'Editar',
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        color: Colors.red,
                        onPressed: () => _showDeleteConfirmation(bitacora),
                        tooltip: 'Eliminar',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                // Grid de campos principales (siempre usar narrow en móvil)
                _buildNarrowGrid(bitacora),
                // Anexos (si existe)
                if (bitacora.anexos != null && bitacora.anexos!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildAnexosWidget(bitacora.anexos!),
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
            ],
          ),
        );
      },
    );
  }

  /// Construye el encabezado de la tarjeta (consecutivo y fecha)
  Widget _buildCardHeader(BitacoraEnvio bitacora) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
            const SizedBox(width: 12),
            Icon(
              Icons.calendar_today,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _formatDate(bitacora.fecha),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildPreviewData(bitacora),
      ],
    );
  }

  /// Construye la previsualización de datos de la bitácora
  Widget _buildPreviewData(BitacoraEnvio bitacora) {
    final items = <Widget>[];
    
    if (bitacora.cobo != null && bitacora.cobo!.isNotEmpty) {
      items.add(_buildPreviewItem('COBO', bitacora.cobo!, Icons.label));
    }
    if (bitacora.tarjeta != null && bitacora.tarjeta!.isNotEmpty) {
      items.add(_buildPreviewItem('Tarjeta', bitacora.tarjeta!, Icons.credit_card));
    }
    if (bitacora.codigo != null && bitacora.codigo!.isNotEmpty) {
      items.add(_buildPreviewItem('Código', bitacora.codigo!, Icons.qr_code));
    }
    if (bitacora.serie != null && bitacora.serie!.isNotEmpty) {
      items.add(_buildPreviewItem('Serie', bitacora.serie!, Icons.confirmation_number));
    }

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final isLast = index == items.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 4),
            child: entry.value,
          );
        }).toList(),
      ),
    );
  }

  /// Construye un item individual de la previsualización
  Widget _buildPreviewItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[800],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
                  bitacora.anexos != null && bitacora.anexos!.isNotEmpty
                      ? _buildAnexosButton(bitacora.anexos!, compact: true)
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
        onSave: (updatedBitacora, pdfFile, pdfToDelete) async {
          await _updateBitacora(updatedBitacora, pdfFile, pdfToDelete);
        },
      ),
    );
  }

  Future<void> _updateBitacora(BitacoraEnvio bitacora, File? pdfFile, String? pdfToDelete) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nombreUsuario = prefs.getString('nombre_usuario') ?? 'Sistema';

      // Manejar eliminación del PDF si se marcó para eliminar
      String? pdfUrl = bitacora.anexos;
      if (pdfToDelete != null && pdfToDelete.isNotEmpty) {
        try {
          final storageService = StorageService();
          debugPrint('🗑️ Intentando eliminar PDF: $pdfToDelete');
          await storageService.deleteFile(pdfToDelete);
          pdfUrl = null; // Limpiar la URL solo si se eliminó exitosamente
          debugPrint('✅ PDF eliminado del storage exitosamente');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ PDF eliminado del storage'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          debugPrint('❌ Error al eliminar PDF del storage: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ Error al eliminar PDF del storage: $e'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          // Si falla la eliminación, mantener la URL original
          // No limpiar pdfUrl para que el usuario sepa que el archivo sigue ahí
        }
      }

      // Si hay un archivo PDF nuevo, subirlo
      if (pdfFile != null) {
        try {
          final storageService = StorageService();
          pdfUrl = await storageService.uploadPdfFile(pdfFile, bitacora.idBitacora!);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Error al subir PDF: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return; // No actualizar la bitácora si falla la subida del PDF
        }
      }

      final updatedBitacora = bitacora.copyWith(
        anexos: pdfUrl,
        actualizadoEn: DateTime.now(),
        actualizadoPor: nombreUsuario,
      );

      await supabaseClient
          .from('t_bitacora_envios')
          .update(updatedBitacora.toJson())
          .eq('id_bitacora', bitacora.idBitacora!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              pdfFile != null && pdfUrl != null
                  ? '✅ Bitácora actualizada y PDF subido exitosamente'
                  : pdfToDelete != null
                      ? '✅ Bitácora actualizada y PDF eliminado exitosamente'
                      : '✅ Bitácora actualizada exitosamente'
            ),
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
      // Si hay un PDF asociado, eliminarlo del storage primero
      if (bitacora.anexos != null && 
          bitacora.anexos!.isNotEmpty && 
          _isPdfUrl(bitacora.anexos)) {
        try {
          final storageService = StorageService();
          await storageService.deleteFile(bitacora.anexos!);
          debugPrint('✅ PDF eliminado del storage: ${bitacora.anexos}');
        } catch (e) {
          // Si falla la eliminación del PDF, registrar pero continuar
          debugPrint('⚠️ Error al eliminar PDF del storage: $e');
          // Continuar con la eliminación de la bitácora de todas formas
        }
      }

      // Eliminar la bitácora de la base de datos
      await supabaseClient
          .from('t_bitacora_envios')
          .delete()
          .eq('id_bitacora', bitacora.idBitacora!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Bitácora y PDF eliminados exitosamente'),
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
              if (bitacora.anexos != null && bitacora.anexos!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 100,
                      child: Text(
                        'Anexos:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(child: _buildAnexosButton(bitacora.anexos!)),
                  ],
                ),
              ] else
              _buildDetailRow('Anexos', bitacora.anexos),
              _buildDetailRow('Observaciones', bitacora.observaciones),
              _buildDetailRow('COBO', bitacora.cobo),
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(
                    width: 100,
                    child: Text(
                      'Estado:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildEstadoChip(bitacora.estado),
                ],
              ),
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

  Widget _buildEstadoChip(EstadoEnvio estado) {
    Color color;
    IconData icon;

    switch (estado) {
      case EstadoEnvio.enviado:
        color = Colors.blue;
        icon = Icons.send;
        break;
      case EstadoEnvio.enTransito:
        color = Colors.amber; // Amarillo
        icon = Icons.local_shipping;
        break;
      case EstadoEnvio.recibido:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        estado.nombre,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: color.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  /// Widget para mostrar el estado en texto cursiva y gris
  Widget _buildEstadoLeyenda(EstadoEnvio estado) {
    Color color;

    switch (estado) {
      case EstadoEnvio.enviado:
        color = Colors.blue;
        break;
      case EstadoEnvio.enTransito:
        color = Colors.amber; // Amarillo
        break;
      case EstadoEnvio.recibido:
        color = Colors.green;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Estado: ${estado.nombre}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
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

  /// Verifica si el anexo es una URL (especialmente PDF)
  bool _isPdfUrl(String? anexo) {
    if (anexo == null || anexo.isEmpty) return false;
    return anexo.startsWith('http://') || 
           anexo.startsWith('https://') ||
           anexo.toLowerCase().endsWith('.pdf');
  }

  /// Construye el widget para mostrar anexos con botón de PDF
  Widget _buildAnexosWidget(String anexo) {
    if (_isPdfUrl(anexo)) {
      return _buildAnexosButton(anexo);
    }
    
    // Si no es URL, mostrar como texto normal
    return Row(
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
                anexo,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Construye un botón para ver/descargar el PDF
  Widget _buildAnexosButton(String pdfUrl, {bool compact = false}) {
    return InkWell(
      onTap: () => _openPdfUrl(pdfUrl),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: compact 
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.red.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.picture_as_pdf,
              color: Colors.red.shade700,
              size: compact ? 18 : 24,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                compact ? 'Descargar PDF' : 'Descargar PDF',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 12 : 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.download,
              color: Colors.red.shade700,
              size: compact ? 14 : 16,
            ),
          ],
        ),
      ),
    );
  }

  /// Descarga el PDF directamente a la carpeta de Descargas
  Future<void> _openPdfUrl(String url) async {
    try {
      // Mostrar indicador de carga
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Descargando PDF...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Descargar el archivo desde la URL
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode != 200) {
        throw Exception('Error al descargar: ${response.statusCode}');
      }

      // Extraer el nombre del archivo de la URL o generar uno
      String fileName = 'bitacora_evidencia.pdf';
      try {
        final uri = Uri.parse(url);
        final pathSegments = uri.pathSegments;
        if (pathSegments.isNotEmpty) {
          final lastSegment = pathSegments.last;
          if (lastSegment.endsWith('.pdf')) {
            fileName = lastSegment;
          } else {
            // Si no tiene extensión, agregar timestamp
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            fileName = 'bitacora_evidencia_$timestamp.pdf';
          }
        }
      } catch (_) {
        // Si falla, usar nombre por defecto con timestamp
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        fileName = 'bitacora_evidencia_$timestamp.pdf';
      }

      // Guardar el archivo
      String? savedPath;
      
      if (kIsWeb) {
        // Para web, usar el helper de descarga
        savedPath = web_helper.downloadFileWeb(response.bodyBytes, fileName);
      } else {
        // Para móvil/desktop, usar FileSaverHelper
        savedPath = await FileSaverHelper.saveFile(
          fileBytes: response.bodyBytes,
          defaultFileName: fileName,
          dialogTitle: 'Guardar PDF de evidencia',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    savedPath != null
                        ? '✅ PDF descargado: ${savedPath.split('/').last}'
                        : '✅ PDF descargado exitosamente',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error al descargar PDF: $e',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
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
      selectedColor: Colors.white,
      checkmarkColor: const Color(0xFF003366),
      backgroundColor: Colors.white.withOpacity(0.15),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF003366) : Colors.white,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 11,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.4),
          width: isSelected ? 1.5 : 1,
        ),
      ),
    );
  }

  Widget _buildTarjetaChip(String? tarjeta, String label) {
    final isSelected = _selectedTarjeta == tarjeta;
    return FilterChip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 11),
      ),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedTarjeta = isSelected ? null : tarjeta;
          _applyFilters();
        });
      },
      selectedColor: Colors.orange[400],
      checkmarkColor: Colors.white,
      backgroundColor: Colors.white.withOpacity(0.15),
      labelStyle: TextStyle(
        color: Colors.white,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 10,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? Colors.orange[400]! : Colors.white.withOpacity(0.4),
          width: isSelected ? 1.5 : 1,
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
  final DateTime? fechaInicial;
  final Function(BitacoraEnvio, File?, String?) onSave; // File? = nuevo PDF, String? = URL del PDF a eliminar

  const _BitacoraFormDialog({
    this.bitacora,
    this.fechaInicial,
    required this.onSave,
  });

  @override
  State<_BitacoraFormDialog> createState() => _BitacoraFormDialogState();
}

class _BitacoraFormDialogState extends State<_BitacoraFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _fecha;
  EstadoEnvio _estado = EstadoEnvio.recibido;
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
  
  // Estado para el archivo PDF
  File? _selectedPdfFile;
  String? _pdfUrl; // URL del PDF actual (si existe)
  String? _originalPdfUrl; // URL original del PDF antes de eliminarlo (para poder eliminarlo del storage)
  bool _shouldDeletePdf = false; // Indica si el PDF debe eliminarse al guardar
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    if (widget.bitacora != null) {
      final b = widget.bitacora!;
      _fecha = b.fecha;
      _estado = b.estado;
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
      // Si ya hay una URL de PDF guardada, establecerla
      if (b.anexos != null && b.anexos!.isNotEmpty && 
          (b.anexos!.startsWith('http://') || b.anexos!.startsWith('https://'))) {
        _pdfUrl = b.anexos;
        _originalPdfUrl = b.anexos; // Guardar la URL original
      }
      _shouldDeletePdf = false; // Inicializar el flag de eliminación
    } else {
      // Si hay fecha inicial proporcionada, usarla; si no, usar fecha actual
      _fecha = widget.fechaInicial ?? DateTime.now();
      // Para nuevos registros de 2026 en adelante, estado inicial es ENVIADO
      _estado = _fecha.year >= 2026 ? EstadoEnvio.enviado : EstadoEnvio.recibido;
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

  Future<void> _selectPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        
        // Validar tamaño (50 MB máximo)
        final fileSize = await file.length();
        const maxSize = 50 * 1024 * 1024; // 50 MB
        if (fileSize > maxSize) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ El archivo es demasiado grande. Máximo 50 MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedPdfFile = file;
          _pdfUrl = null; // Limpiar URL anterior si hay un nuevo archivo
          _shouldDeletePdf = false; // Si hay un nuevo archivo, no eliminar el anterior
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar archivo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Este método ya no se usa, el PDF se sube solo al guardar

  void _removePdfFile() {
    setState(() {
      _selectedPdfFile = null;
      // Si había un PDF guardado, marcarlo para eliminación
      if (_pdfUrl != null) {
        _shouldDeletePdf = true;
        _originalPdfUrl = _pdfUrl; // Guardar la URL original antes de limpiarla
        _pdfUrl = null; // Limpiar la URL visualmente
      } else {
        _shouldDeletePdf = false;
        _originalPdfUrl = null;
      }
      _anexosController.text = '';
    });
  }

  Future<void> _handleDroppedFile(File file) async {
    // Validar que sea PDF
    final fileName = file.path.split('/').last.toLowerCase();
    if (!fileName.endsWith('.pdf')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Solo se permiten archivos PDF'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Validar tamaño (50 MB máximo)
    try {
      final fileSize = await file.length();
      const maxSize = 50 * 1024 * 1024; // 50 MB
      if (fileSize > maxSize) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ El archivo es demasiado grande. Máximo 50 MB'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        // Si había un PDF guardado anteriormente, guardar su URL antes de limpiarla
        if (_pdfUrl != null && !_shouldDeletePdf) {
          _originalPdfUrl = _pdfUrl;
        }
        _selectedPdfFile = file;
        _pdfUrl = null; // Limpiar URL anterior si hay un nuevo archivo
        _shouldDeletePdf = false; // Si hay un nuevo archivo, no eliminar el anterior
      });

      // El PDF se subirá solo al guardar, no inmediatamente
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar archivo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      // El PDF se subirá/eliminará en el método onSave del padre
      // Aquí solo preparamos los datos
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
        anexos: _pdfUrl ?? (_anexosController.text.trim().isEmpty ? null : _anexosController.text.trim()),
        observaciones: _observacionesController.text.trim().isEmpty ? null : _observacionesController.text.trim(),
        cobo: _coboController.text.trim().isEmpty ? null : _coboController.text.trim(),
        estado: _estado,
        creadoEn: widget.bitacora?.creadoEn ?? DateTime.now(),
        actualizadoEn: DateTime.now(),
        creadoPor: widget.bitacora?.creadoPor,
        actualizadoPor: widget.bitacora?.actualizadoPor,
      );

      // Pasar el archivo PDF y la URL del PDF a eliminar (si se marcó para eliminar)
      widget.onSave(bitacora, _selectedPdfFile, _shouldDeletePdf ? _originalPdfUrl : null);
      
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
              // Anexos - Subida de PDF
              _buildPdfUploadWidget(),
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
              const SizedBox(height: 12),
              // Estado
              DropdownButtonFormField<EstadoEnvio>(
                value: _estado,
                decoration: InputDecoration(
                  labelText: 'Estado',
                  hintText: 'Seleccione el estado del envío',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(
                    _estado == EstadoEnvio.enviado
                        ? Icons.send
                        : _estado == EstadoEnvio.enTransito
                            ? Icons.local_shipping
                            : Icons.check_circle,
                    color: _estado == EstadoEnvio.enviado
                        ? Colors.blue
                        : _estado == EstadoEnvio.enTransito
                            ? Colors.amber
                            : Colors.green,
                  ),
                ),
                items: EstadoEnvio.values.map((estado) {
                  Color color;
                  IconData icon;

                  switch (estado) {
                    case EstadoEnvio.enviado:
                      color = Colors.blue;
                      icon = Icons.send;
                      break;
                    case EstadoEnvio.enTransito:
                      color = Colors.amber;
                      icon = Icons.local_shipping;
                      break;
                    case EstadoEnvio.recibido:
                      color = Colors.green;
                      icon = Icons.check_circle;
                      break;
                  }

                  return DropdownMenuItem<EstadoEnvio>(
                    value: estado,
                    child: Row(
                      children: [
                        Icon(icon, size: 20, color: color),
                        const SizedBox(width: 12),
                        Text(estado.nombre),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (EstadoEnvio? nuevoEstado) {
                  if (nuevoEstado != null) {
                    setState(() {
                      _estado = nuevoEstado;
                    });
                  }
                },
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

  Widget _buildPdfUploadWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Evidencia PDF',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // Widget de seleccionar archivo
        GestureDetector(
          onTap: _selectPdfFile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedPdfFile != null || _pdfUrl != null
                    ? Colors.green
                    : Colors.grey,
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(8),
              color: _selectedPdfFile != null || _pdfUrl != null
                  ? Colors.green.shade50
                  : Colors.grey.shade50,
            ),
            child: _selectedPdfFile != null || _pdfUrl != null
                    ? Column(
                        children: [
                          Icon(
                            Icons.picture_as_pdf,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedPdfFile != null
                                ? _selectedPdfFile!.path.split('/').last
                                : 'PDF cargado',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_shouldDeletePdf && _pdfUrl == null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '🗑️ Se eliminará al guardar',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ] else if (_pdfUrl != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '✅ Archivo guardado',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                              ),
                            ),
                          ] else if (_selectedPdfFile != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '📤 Se subirá al guardar',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: _selectPdfFile,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Cambiar PDF'),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: _removePdfFile,
                                icon: const Icon(Icons.delete, color: Colors.red),
                                label: const Text(
                                  'Eliminar',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 48,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Arrastra un PDF aquí o toca para seleccionar',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Solo archivos PDF (máx. 50 MB)',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
          ),
        ),
        // Campo oculto para guardar la URL
        if (_pdfUrl != null)
          TextFormField(
            controller: _anexosController,
            enabled: false,
            decoration: const InputDecoration(
              labelText: 'URL del archivo (guardada automáticamente)',
              border: InputBorder.none,
            ),
            style: const TextStyle(fontSize: 0), // Ocultar visualmente
        ),
      ],
    );
  }
}
