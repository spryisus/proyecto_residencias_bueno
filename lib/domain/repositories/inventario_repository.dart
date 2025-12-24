import '../entities/producto.dart';
import '../entities/categoria.dart';
import '../entities/ubicacion.dart';
import '../entities/inventario_completo.dart';
import '../entities/contenedor.dart';

abstract class InventarioRepository {
  // Productos
  Future<List<Producto>> getAllProductos();
  Future<Producto?> getProductoById(int id);
  Future<Producto> createProducto(Producto producto);
  Future<Producto> updateProducto(Producto producto);
  Future<void> deleteProducto(int id);
  Future<List<Producto>> searchProductos(String query);

  // Categorías
  Future<List<Categoria>> getAllCategorias();
  Future<Categoria?> getCategoriaById(int id);
  Future<Categoria> createCategoria(Categoria categoria);
  Future<Categoria> updateCategoria(Categoria categoria);
  Future<void> deleteCategoria(int id);

  // Ubicaciones
  Future<List<Ubicacion>> getAllUbicaciones();
  Future<Ubicacion?> getUbicacionById(int id);
  Future<Ubicacion> createUbicacion(Ubicacion ubicacion);
  Future<Ubicacion> updateUbicacion(Ubicacion ubicacion);
  Future<void> deleteUbicacion(int id);

  // Inventario
  Future<List<InventarioCompleto>> getAllInventario();
  Future<List<InventarioCompleto>> getInventarioByUbicacion(int idUbicacion);
  Future<List<InventarioCompleto>> getInventarioByProducto(int idProducto);
  Future<List<InventarioCompleto>> getInventarioByCategoria(int idCategoria);
  Future<InventarioCompleto?> getInventarioByProductoUbicacion(int idProducto, int idUbicacion);
  
  // Movimientos de inventario
  Future<void> ajustarInventario(int idProducto, int idUbicacion, int cantidadDelta, String motivo);
  Future<void> transferirInventario(int idProducto, int idUbicacionOrigen, int idUbicacionDestino, int cantidad);
  
  // Actualización directa de cantidad para jumpers (actualiza t_productos.unidad)
  Future<void> actualizarCantidadJumper(int idProducto, int nuevaCantidad);

  // Contenedores de jumpers
  Future<List<Contenedor>> getContenedoresByProducto(int idProducto);
  Future<Map<int, List<Contenedor>>> getContenedoresByProductos(List<int> idProductos);
  Future<Contenedor> createContenedor(Contenedor contenedor);
  Future<Contenedor> updateContenedor(Contenedor contenedor);
  Future<void> deleteContenedor(int idContenedor);
  Future<void> deleteContenedoresByProducto(int idProducto);

  // Estadísticas
  Future<Map<String, int>> getEstadisticasPorCategoria();
  Future<Map<String, int>> getEstadisticasPorUbicacion();
  Future<int> getTotalProductos();
  Future<int> getTotalUbicaciones();

  // Exportación
  Future<String> exportarInventarioExcel();
  Future<String> exportarInventarioPdf();
  Future<Map<String, dynamic>> exportarInventarioJson();
}
