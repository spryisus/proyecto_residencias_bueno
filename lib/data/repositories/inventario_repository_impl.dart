import '../../domain/entities/producto.dart';
import '../../domain/entities/categoria.dart';
import '../../domain/entities/ubicacion.dart';
import '../../domain/entities/inventario_completo.dart';
import '../../domain/entities/movimiento_inventario.dart';
import '../../domain/repositories/inventario_repository.dart';
import '../datasources/inventario_datasource.dart';
import '../models/producto_model.dart';
import '../models/categoria_model.dart';
import '../models/ubicacion_model.dart';

class InventarioRepositoryImpl implements InventarioRepository {
  final InventarioDataSource dataSource;
  
  InventarioRepositoryImpl(this.dataSource);

  @override
  Future<List<Producto>> getAllProductos() async {
    final models = await dataSource.getAllProductos();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Producto?> getProductoById(int id) async {
    final model = await dataSource.getProductoById(id);
    return model?.toEntity();
  }


  @override
  Future<Producto> createProducto(Producto producto) async {
    final model = ProductoModel.fromEntity(producto);
    final createdModel = await dataSource.createProducto(model);
    return createdModel.toEntity();
  }

  @override
  Future<Producto> updateProducto(Producto producto) async {
    final model = ProductoModel.fromEntity(producto);
    final updatedModel = await dataSource.updateProducto(model);
    return updatedModel.toEntity();
  }

  @override
  Future<void> deleteProducto(int id) async {
    await dataSource.deleteProducto(id);
  }

  @override
  Future<List<Producto>> searchProductos(String query) async {
    final models = await dataSource.searchProductos(query);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<Categoria>> getAllCategorias() async {
    final models = await dataSource.getAllCategorias();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Categoria?> getCategoriaById(int id) async {
    final model = await dataSource.getCategoriaById(id);
    return model?.toEntity();
  }

  @override
  Future<Categoria> createCategoria(Categoria categoria) async {
    final model = CategoriaModel.fromEntity(categoria);
    final createdModel = await dataSource.createCategoria(model);
    return createdModel.toEntity();
  }

  @override
  Future<Categoria> updateCategoria(Categoria categoria) async {
    final model = CategoriaModel.fromEntity(categoria);
    final updatedModel = await dataSource.updateCategoria(model);
    return updatedModel.toEntity();
  }

  @override
  Future<void> deleteCategoria(int id) async {
    await dataSource.deleteCategoria(id);
  }

  @override
  Future<List<Ubicacion>> getAllUbicaciones() async {
    final models = await dataSource.getAllUbicaciones();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Ubicacion?> getUbicacionById(int id) async {
    final model = await dataSource.getUbicacionById(id);
    return model?.toEntity();
  }

  @override
  Future<Ubicacion> createUbicacion(Ubicacion ubicacion) async {
    final model = UbicacionModel.fromEntity(ubicacion);
    final createdModel = await dataSource.createUbicacion(model);
    return createdModel.toEntity();
  }

  @override
  Future<Ubicacion> updateUbicacion(Ubicacion ubicacion) async {
    final model = UbicacionModel.fromEntity(ubicacion);
    final updatedModel = await dataSource.updateUbicacion(model);
    return updatedModel.toEntity();
  }

  @override
  Future<void> deleteUbicacion(int id) async {
    await dataSource.deleteUbicacion(id);
  }

  @override
  Future<List<InventarioCompleto>> getAllInventario() async {
    final data = await dataSource.getAllInventarioCompleto();
    return data.map((json) => _mapToInventarioCompleto(json)).toList();
  }

  @override
  Future<List<InventarioCompleto>> getInventarioByUbicacion(int idUbicacion) async {
    final data = await dataSource.getInventarioByUbicacion(idUbicacion);
    return data.map((json) => _mapToInventarioCompleto(json)).toList();
  }

  @override
  Future<List<InventarioCompleto>> getInventarioByProducto(int idProducto) async {
    final data = await dataSource.getInventarioByProducto(idProducto);
    return data.map((json) => _mapToInventarioCompleto(json)).toList();
  }

  @override
  Future<List<InventarioCompleto>> getInventarioByCategoria(int idCategoria) async {
    final data = await dataSource.getInventarioByCategoria(idCategoria);
    return data.map((json) => _mapToInventarioCompleto(json)).toList();
  }

  @override
  Future<InventarioCompleto?> getInventarioByProductoUbicacion(int idProducto, int idUbicacion) async {
    final data = await dataSource.getInventarioByProductoUbicacion(idProducto, idUbicacion);
    return data != null ? _mapToInventarioCompleto(data) : null;
  }

  @override
  Future<void> ajustarInventario(int idProducto, int idUbicacion, int cantidadDelta, String motivo) async {
    final movimiento = MovimientoInventario(
      idMovimiento: 0, // Se genera automáticamente
      idProducto: idProducto,
      idUbicacion: idUbicacion,
      tipo: MovimientoTipo.ajuste,
      cantidadDelta: cantidadDelta,
      motivo: motivo,
      creadoEn: DateTime.now(),
    );
    
    await dataSource.crearMovimientoInventario(movimiento);
  }

  @override
  Future<void> transferirInventario(int idProducto, int idUbicacionOrigen, int idUbicacionDestino, int cantidad) async {
    // Crear movimiento de salida
    final movimientoSalida = MovimientoInventario(
      idMovimiento: 0,
      idProducto: idProducto,
      idUbicacion: idUbicacionOrigen,
      tipo: MovimientoTipo.salida,
      cantidadDelta: -cantidad,
      motivo: 'Transferencia a ubicación $idUbicacionDestino',
      creadoEn: DateTime.now(),
    );

    // Crear movimiento de entrada
    final movimientoEntrada = MovimientoInventario(
      idMovimiento: 0,
      idProducto: idProducto,
      idUbicacion: idUbicacionDestino,
      tipo: MovimientoTipo.entrada,
      cantidadDelta: cantidad,
      motivo: 'Transferencia desde ubicación $idUbicacionOrigen',
      creadoEn: DateTime.now(),
    );

    await dataSource.crearMovimientoInventario(movimientoSalida);
    await dataSource.crearMovimientoInventario(movimientoEntrada);
  }

  @override
  Future<Map<String, int>> getEstadisticasPorCategoria() async {
    final inventario = await getAllInventario();
    final stats = <String, int>{};
    
    for (final item in inventario) {
      for (final categoria in item.categorias) {
        stats[categoria.nombre] = (stats[categoria.nombre] ?? 0) + item.cantidad;
      }
    }
    
    return stats;
  }

  @override
  Future<Map<String, int>> getEstadisticasPorUbicacion() async {
    final inventario = await getAllInventario();
    final stats = <String, int>{};
    
    for (final item in inventario) {
      stats[item.ubicacion.nombre] = (stats[item.ubicacion.nombre] ?? 0) + item.cantidad;
    }
    
    return stats;
  }

  @override
  Future<int> getTotalProductos() async {
    final productos = await getAllProductos();
    return productos.length;
  }

  @override
  Future<int> getTotalUbicaciones() async {
    final ubicaciones = await getAllUbicaciones();
    return ubicaciones.length;
  }

  @override
  Future<String> exportarInventarioExcel() async {
    // TODO: Implementar exportación a Excel
    throw UnimplementedError('Exportación a Excel no implementada aún');
  }

  @override
  Future<String> exportarInventarioPdf() async {
    // TODO: Implementar exportación a PDF
    throw UnimplementedError('Exportación a PDF no implementada aún');
  }

  @override
  Future<Map<String, dynamic>> exportarInventarioJson() async {
    final inventario = await getAllInventario();
    return {
      'inventario': inventario.map((item) => item.toJson()).toList(),
      'exportado_en': DateTime.now().toIso8601String(),
      'total_items': inventario.length,
    };
  }

  InventarioCompleto _mapToInventarioCompleto(Map<String, dynamic> json) {
    final productoData = json['t_productos'] as Map<String, dynamic>;
    final producto = Producto.fromJson(productoData);
    
    // Manejar ubicación que puede ser null
    final ubicacionData = json['t_ubicaciones'] as Map<String, dynamic>?;
    if (ubicacionData == null) {
      throw Exception('Ubicación es requerida para el inventario');
    }
    final ubicacion = Ubicacion.fromJson(ubicacionData);
    
    // Mapear categorías desde la estructura anidada
    final categoriasData = productoData['t_productos_categorias'] as List?;
    final categorias = categoriasData?.map((cat) => 
      Categoria.fromJson(cat['t_categorias'] as Map<String, dynamic>)
    ).toList() ?? <Categoria>[];

    // Manejar id_inventario que puede ser null cuando no hay registro en t_inventarios
    final idInventario = json['id_inventario'] as int? ?? 0;
    final cantidad = json['cantidad'] as int? ?? 0;

    return InventarioCompleto(
      idInventario: idInventario,
      producto: producto,
      ubicacion: ubicacion,
      categorias: categorias,
      cantidad: cantidad,
    );
  }
}
