import '../../domain/entities/producto.dart';
import '../../domain/entities/ubicacion.dart';
import '../../domain/entities/categoria.dart';

class InventarioCompleto {
  final int idInventario;
  final Producto producto;
  final Ubicacion ubicacion;
  final List<Categoria> categorias;
  final int cantidad;

  const InventarioCompleto({
    required this.idInventario,
    required this.producto,
    required this.ubicacion,
    required this.categorias,
    required this.cantidad,
  });

  InventarioCompleto copyWith({
    int? idInventario,
    Producto? producto,
    Ubicacion? ubicacion,
    List<Categoria>? categorias,
    int? cantidad,
  }) {
    return InventarioCompleto(
      idInventario: idInventario ?? this.idInventario,
      producto: producto ?? this.producto,
      ubicacion: ubicacion ?? this.ubicacion,
      categorias: categorias ?? this.categorias,
      cantidad: cantidad ?? this.cantidad,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_inventario': idInventario,
      'producto': producto.toJson(),
      'ubicacion': ubicacion.toJson(),
      'categorias': categorias.map((c) => c.toJson()).toList(),
      'cantidad': cantidad,
    };
  }

  factory InventarioCompleto.fromJson(Map<String, dynamic> json) {
    return InventarioCompleto(
      idInventario: json['id_inventario'] as int,
      producto: Producto.fromJson(json['producto'] as Map<String, dynamic>),
      ubicacion: Ubicacion.fromJson(json['ubicacion'] as Map<String, dynamic>),
      categorias: (json['categorias'] as List)
          .map((c) => Categoria.fromJson(c as Map<String, dynamic>))
          .toList(),
      cantidad: json['cantidad'] as int,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventarioCompleto && other.idInventario == idInventario;
  }

  @override
  int get hashCode => idInventario.hashCode;

  @override
  String toString() {
    return 'InventarioCompleto(idInventario: $idInventario, producto: ${producto.nombre}, ubicacion: ${ubicacion.nombre}, cantidad: $cantidad)';
  }
}

