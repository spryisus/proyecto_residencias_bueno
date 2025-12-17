import '../../domain/entities/movimiento_inventario.dart';
import '../models/producto_model.dart';
import '../models/categoria_model.dart';
import '../models/ubicacion_model.dart';
import '../../app/config/supabase_client.dart';

abstract class InventarioDataSource {
  // Productos
  Future<List<ProductoModel>> getAllProductos();
  Future<ProductoModel?> getProductoById(int id);
  Future<ProductoModel> createProducto(ProductoModel producto);
  Future<ProductoModel> updateProducto(ProductoModel producto);
  Future<void> deleteProducto(int id);
  Future<List<ProductoModel>> searchProductos(String query);

  // Categorías
  Future<List<CategoriaModel>> getAllCategorias();
  Future<CategoriaModel?> getCategoriaById(int id);
  Future<CategoriaModel> createCategoria(CategoriaModel categoria);
  Future<CategoriaModel> updateCategoria(CategoriaModel categoria);
  Future<void> deleteCategoria(int id);

  // Ubicaciones
  Future<List<UbicacionModel>> getAllUbicaciones();
  Future<UbicacionModel?> getUbicacionById(int id);
  Future<UbicacionModel> createUbicacion(UbicacionModel ubicacion);
  Future<UbicacionModel> updateUbicacion(UbicacionModel ubicacion);
  Future<void> deleteUbicacion(int id);

  // Inventario completo con joins
  Future<List<Map<String, dynamic>>> getAllInventarioCompleto();
  Future<List<Map<String, dynamic>>> getInventarioByUbicacion(int idUbicacion);
  Future<List<Map<String, dynamic>>> getInventarioByProducto(int idProducto);
  Future<List<Map<String, dynamic>>> getInventarioByCategoria(int idCategoria);
  Future<Map<String, dynamic>?> getInventarioByProductoUbicacion(int idProducto, int idUbicacion);

  // Movimientos
  Future<void> crearMovimientoInventario(MovimientoInventario movimiento);
}

class SupabaseInventarioDataSource implements InventarioDataSource {
  @override
  Future<List<ProductoModel>> getAllProductos() async {
    try {
      final response = await supabaseClient
          .from('t_productos')
          .select('*')
          .order('nombre');
      
      return response.map((json) => ProductoModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener productos: $e');
    }
  }

  @override
  Future<ProductoModel?> getProductoById(int id) async {
    try {
      final response = await supabaseClient
          .from('t_productos')
          .select('*')
          .eq('id_producto', id)
          .single();
      
      return ProductoModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }


  @override
  Future<ProductoModel> createProducto(ProductoModel producto) async {
    try {
      final json = producto.toJson();
      // Remover id_producto al crear (se genera automáticamente)
      json.remove('id_producto');
      
      final response = await supabaseClient
          .from('t_productos')
          .insert(json)
          .select()
          .single();
      
      return ProductoModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear producto: $e');
    }
  }

  @override
  Future<ProductoModel> updateProducto(ProductoModel producto) async {
    try {
      // Remover id_producto del JSON ya que es una columna IDENTITY GENERATED ALWAYS
      // y no puede ser actualizada
      final json = producto.toJson();
      json.remove('id_producto');
      
      final response = await supabaseClient
          .from('t_productos')
          .update(json)
          .eq('id_producto', producto.idProducto)
          .select()
          .single();
      
      return ProductoModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar producto: $e');
    }
  }

  @override
  Future<void> deleteProducto(int id) async {
    try {
      await supabaseClient
          .from('t_productos')
          .delete()
          .eq('id_producto', id);
    } catch (e) {
      throw Exception('Error al eliminar producto: $e');
    }
  }

  @override
  Future<List<ProductoModel>> searchProductos(String query) async {
    try {
      final response = await supabaseClient
          .from('t_productos')
          .select('*')
          .or('nombre.ilike.%$query%,descripcion.ilike.%$query%')
          .order('nombre');
      
      return response.map((json) => ProductoModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al buscar productos: $e');
    }
  }

  @override
  Future<List<CategoriaModel>> getAllCategorias() async {
    try {
      final response = await supabaseClient
          .from('t_categorias')
          .select('*')
          .order('nombre');
      
      return response.map((json) => CategoriaModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener categorías: $e');
    }
  }

  @override
  Future<CategoriaModel?> getCategoriaById(int id) async {
    try {
      final response = await supabaseClient
          .from('t_categorias')
          .select('*')
          .eq('id_categoria', id)
          .single();
      
      return CategoriaModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<CategoriaModel> createCategoria(CategoriaModel categoria) async {
    try {
      final response = await supabaseClient
          .from('t_categorias')
          .insert(categoria.toJson())
          .select()
          .single();
      
      return CategoriaModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear categoría: $e');
    }
  }

  @override
  Future<CategoriaModel> updateCategoria(CategoriaModel categoria) async {
    try {
      final response = await supabaseClient
          .from('t_categorias')
          .update(categoria.toJson())
          .eq('id_categoria', categoria.idCategoria)
          .select()
          .single();
      
      return CategoriaModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar categoría: $e');
    }
  }

  @override
  Future<void> deleteCategoria(int id) async {
    try {
      await supabaseClient
          .from('t_categorias')
          .delete()
          .eq('id_categoria', id);
    } catch (e) {
      throw Exception('Error al eliminar categoría: $e');
    }
  }

  @override
  Future<List<UbicacionModel>> getAllUbicaciones() async {
    try {
      final response = await supabaseClient
          .from('t_ubicaciones')
          .select('*')
          .order('nombre');
      
      return response.map((json) => UbicacionModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener ubicaciones: $e');
    }
  }

  @override
  Future<UbicacionModel?> getUbicacionById(int id) async {
    try {
      final response = await supabaseClient
          .from('t_ubicaciones')
          .select('*')
          .eq('id_ubicacion', id)
          .single();
      
      return UbicacionModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<UbicacionModel> createUbicacion(UbicacionModel ubicacion) async {
    try {
      final response = await supabaseClient
          .from('t_ubicaciones')
          .insert(ubicacion.toJson())
          .select()
          .single();
      
      return UbicacionModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear ubicación: $e');
    }
  }

  @override
  Future<UbicacionModel> updateUbicacion(UbicacionModel ubicacion) async {
    try {
      final response = await supabaseClient
          .from('t_ubicaciones')
          .update(ubicacion.toJson())
          .eq('id_ubicacion', ubicacion.idUbicacion)
          .select()
          .single();
      
      return UbicacionModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar ubicación: $e');
    }
  }

  @override
  Future<void> deleteUbicacion(int id) async {
    try {
      await supabaseClient
          .from('t_ubicaciones')
          .delete()
          .eq('id_ubicacion', id);
    } catch (e) {
      throw Exception('Error al eliminar ubicación: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllInventarioCompleto() async {
    try {
      // Intentar con posicion primero
      try {
        final response = await supabaseClient
            .from('t_inventarios')
            .select('''
              id_inventario,
              cantidad,
              t_productos!inner(
                id_producto, 
                nombre, 
                descripcion, 
                unidad,
                tamano,
                rack,
                contenedor,
                t_productos_categorias!inner(
                  t_categorias!inner(id_categoria, nombre, descripcion)
                )
              ),
              t_ubicaciones!inner(id_ubicacion, nombre, descripcion, posicion)
            ''')
            .order('t_productos(nombre)');
        return response;
      } catch (e) {
        // Si falla, intentar sin posicion (columna no existe aún)
        final response = await supabaseClient
            .from('t_inventarios')
            .select('''
              id_inventario,
              cantidad,
              t_productos!inner(
                id_producto, 
                nombre, 
                descripcion, 
                unidad,
                tamano,
                rack,
                contenedor,
                t_productos_categorias!inner(
                  t_categorias!inner(id_categoria, nombre, descripcion)
                )
              ),
              t_ubicaciones!inner(id_ubicacion, nombre, descripcion)
            ''')
            .order('t_productos(nombre)');
        // Agregar posicion null a cada resultado
        return response.map((item) {
          if (item['t_ubicaciones'] != null) {
            (item['t_ubicaciones'] as Map<String, dynamic>)['posicion'] = null;
          }
          return item;
        }).toList();
      }
    } catch (e) {
      throw Exception('Error al obtener inventario completo: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getInventarioByUbicacion(int idUbicacion) async {
    try {
      // Intentar con posicion primero
      try {
        final response = await supabaseClient
            .from('t_inventarios')
            .select('''
              id_inventario,
              cantidad,
              t_productos!inner(
                id_producto, 
                nombre, 
                descripcion, 
                unidad,
                tamano,
                rack,
                contenedor,
                t_productos_categorias!inner(
                  t_categorias!inner(id_categoria, nombre, descripcion)
                )
              ),
              t_ubicaciones!inner(id_ubicacion, nombre, descripcion, posicion)
            ''')
            .eq('id_ubicacion', idUbicacion)
            .order('t_productos(nombre)');
        return response;
      } catch (e) {
        // Si falla, intentar sin posicion
        final response = await supabaseClient
            .from('t_inventarios')
            .select('''
              id_inventario,
              cantidad,
              t_productos!inner(
                id_producto, 
                nombre, 
                descripcion, 
                unidad,
                tamano,
                rack,
                contenedor,
                t_productos_categorias!inner(
                  t_categorias!inner(id_categoria, nombre, descripcion)
                )
              ),
              t_ubicaciones!inner(id_ubicacion, nombre, descripcion)
            ''')
            .eq('id_ubicacion', idUbicacion)
            .order('t_productos(nombre)');
        return response.map((item) {
          if (item['t_ubicaciones'] != null) {
            (item['t_ubicaciones'] as Map<String, dynamic>)['posicion'] = null;
          }
          return item;
        }).toList();
      }
    } catch (e) {
      throw Exception('Error al obtener inventario por ubicación: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getInventarioByProducto(int idProducto) async {
    try {
      // Intentar con posicion primero
      try {
        final response = await supabaseClient
            .from('t_inventarios')
            .select('''
              id_inventario,
              cantidad,
              t_productos!inner(
                id_producto, 
                nombre, 
                descripcion, 
                unidad,
                tamano,
                rack,
                contenedor,
                t_productos_categorias!inner(
                  t_categorias!inner(id_categoria, nombre, descripcion)
                )
              ),
              t_ubicaciones!inner(id_ubicacion, nombre, descripcion, posicion)
            ''')
            .eq('id_producto', idProducto)
            .order('t_ubicaciones(nombre)');
        return response;
      } catch (e) {
        // Si falla, intentar sin posicion
        final response = await supabaseClient
            .from('t_inventarios')
            .select('''
              id_inventario,
              cantidad,
              t_productos!inner(
                id_producto, 
                nombre, 
                descripcion, 
                unidad,
                tamano,
                rack,
                contenedor,
                t_productos_categorias!inner(
                  t_categorias!inner(id_categoria, nombre, descripcion)
                )
              ),
              t_ubicaciones!inner(id_ubicacion, nombre, descripcion)
            ''')
            .eq('id_producto', idProducto)
            .order('t_ubicaciones(nombre)');
        return response.map((item) {
          if (item['t_ubicaciones'] != null) {
            (item['t_ubicaciones'] as Map<String, dynamic>)['posicion'] = null;
          }
          return item;
        }).toList();
      }
    } catch (e) {
      throw Exception('Error al obtener inventario por producto: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getInventarioByCategoria(int idCategoria) async {
    try {
      // Obtener todos los productos con esta categoría, incluyendo sus datos completos
      final productosResponse = await supabaseClient
          .from('t_productos_categorias')
          .select('''
            id_producto,
            t_productos!inner(
              id_producto,
              nombre,
              descripcion,
              unidad,
              tamano,
              rack,
              contenedor,
              t_productos_categorias!inner(
                t_categorias!inner(id_categoria, nombre, descripcion)
              )
            )
          ''')
          .eq('id_categoria', idCategoria);
      
      if (productosResponse.isEmpty) {
        return [];
      }
      
      // Obtener todas las ubicaciones (necesitamos al menos una)
      final ubicaciones = await supabaseClient
          .from('t_ubicaciones')
          .select('*')
          .limit(1);
      
      // Obtener los IDs de productos
      final idsProductos = productosResponse
          .map((pc) => pc['id_producto'] as int)
          .toList();
      
      // Obtener los inventarios existentes de esos productos
      // Intentar obtener con posicion, si falla, obtener sin posicion
      List<Map<String, dynamic>> inventariosResponse;
      try {
        inventariosResponse = await supabaseClient
            .from('t_inventarios')
            .select('''
              id_inventario,
              id_producto,
              id_ubicacion,
              cantidad,
              t_ubicaciones!inner(id_ubicacion, nombre, descripcion, posicion)
            ''')
            .inFilter('id_producto', idsProductos);
      } catch (e) {
        // Si falla porque posicion no existe, intentar sin posicion
        inventariosResponse = await supabaseClient
            .from('t_inventarios')
            .select('''
              id_inventario,
              id_producto,
              id_ubicacion,
              cantidad,
              t_ubicaciones!inner(id_ubicacion, nombre, descripcion)
            ''')
            .inFilter('id_producto', idsProductos);
      }
      
      // Crear un mapa de inventarios por producto (solo el primero de cada producto)
      final inventariosPorProducto = <int, Map<String, dynamic>>{};
      for (final inv in inventariosResponse) {
        final idProducto = inv['id_producto'] as int;
        // Solo guardar el primer inventario de cada producto para evitar duplicados
        if (!inventariosPorProducto.containsKey(idProducto)) {
          inventariosPorProducto[idProducto] = inv;
        }
      }
      
      // Construir el resultado: un registro por producto
      // Usar el campo 'unidad' como cantidad desde t_productos
      final resultado = <Map<String, dynamic>>[];
      
      for (final pc in productosResponse) {
        final producto = pc['t_productos'] as Map<String, dynamic>;
        
        // Obtener la cantidad desde el campo 'unidad' del producto
        // Convertir unidad (que es String) a int
        final unidadStr = producto['unidad'] as String? ?? '0';
        final cantidad = int.tryParse(unidadStr) ?? 0;
        
        // Usar la primera ubicación disponible o crear una estructura básica
        if (ubicaciones.isNotEmpty) {
          final primeraUbicacion = ubicaciones.first;
          resultado.add({
            'id_inventario': null,
            'cantidad': cantidad,
            't_productos': producto,
            't_ubicaciones': {
              'id_ubicacion': primeraUbicacion['id_ubicacion'],
              'nombre': primeraUbicacion['nombre'],
              'descripcion': primeraUbicacion['descripcion'],
              'posicion': primeraUbicacion['posicion'] ?? null, // Manejar si no existe
            },
          });
        } else {
          // Si no hay ubicaciones, crear una estructura mínima
          resultado.add({
            'id_inventario': null,
            'cantidad': cantidad,
            't_productos': producto,
            't_ubicaciones': {
              'id_ubicacion': 0,
              'nombre': 'Sin ubicación',
              'descripcion': null,
              'posicion': null,
            },
          });
        }
      }
      
      // Ordenar por nombre de producto
      resultado.sort((a, b) {
        final nombreA = (a['t_productos'] as Map)['nombre'] as String;
        final nombreB = (b['t_productos'] as Map)['nombre'] as String;
        return nombreA.compareTo(nombreB);
      });
      
      return resultado;
    } catch (e) {
      throw Exception('Error al obtener inventario por categoría: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> getInventarioByProductoUbicacion(int idProducto, int idUbicacion) async {
    try {
      // Intentar con posicion primero
      try {
        final response = await supabaseClient
            .from('t_inventarios')
            .select('''
              id_inventario,
              cantidad,
              t_productos!inner(
                id_producto, 
                nombre, 
                descripcion, 
                unidad,
                tamano,
                rack,
                contenedor,
                t_productos_categorias!inner(
                  t_categorias!inner(id_categoria, nombre, descripcion)
                )
              ),
              t_ubicaciones!inner(id_ubicacion, nombre, descripcion, posicion)
            ''')
            .eq('id_producto', idProducto)
            .eq('id_ubicacion', idUbicacion)
            .single();
        return response;
      } catch (e) {
        // Si falla, intentar sin posicion
        final response = await supabaseClient
            .from('t_inventarios')
            .select('''
              id_inventario,
              cantidad,
              t_productos!inner(
                id_producto, 
                nombre, 
                descripcion, 
                unidad,
                tamano,
                rack,
                contenedor,
                t_productos_categorias!inner(
                  t_categorias!inner(id_categoria, nombre, descripcion)
                )
              ),
              t_ubicaciones!inner(id_ubicacion, nombre, descripcion)
            ''')
            .eq('id_producto', idProducto)
            .eq('id_ubicacion', idUbicacion)
            .single();
        // Agregar posicion null
        if (response['t_ubicaciones'] != null) {
          (response['t_ubicaciones'] as Map<String, dynamic>)['posicion'] = null;
        }
        return response;
      }
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> crearMovimientoInventario(MovimientoInventario movimiento) async {
    try {
      // Usar toJsonForInsert() para excluir id_movimiento ya que es una columna de identidad GENERATED ALWAYS
      await supabaseClient
          .from('t_movimientos_inventario')
          .insert(movimiento.toJsonForInsert());
    } catch (e) {
      throw Exception('Error al crear movimiento de inventario: $e');
    }
  }
}
