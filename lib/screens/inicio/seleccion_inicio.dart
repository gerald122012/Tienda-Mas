import '../../models/producto.dart';

/// Selección visible en Inicio. No es una recomendación personal.
const int limiteProductosInicio = 6;

List<Producto> productosParaInicio(List<Producto> origen) {
  final validos =
      origen
          .where(
            (producto) =>
                producto.disponible &&
                producto.stock > 0 &&
                producto.precio > 0,
          )
          .toList()
        ..sort((a, b) {
          final nombre = a.nombre.toLowerCase().compareTo(
            b.nombre.toLowerCase(),
          );
          if (nombre != 0) return nombre;
          return a.id.compareTo(b.id);
        });

  final elegidos = <Producto>[];
  final ids = <String>{};
  for (final categoria in Producto.categorias) {
    for (final producto in validos) {
      if (producto.categoria == categoria && ids.add(producto.id)) {
        elegidos.add(producto);
        break;
      }
    }
  }
  for (final producto in validos) {
    if (elegidos.length >= limiteProductosInicio) break;
    if (ids.add(producto.id)) elegidos.add(producto);
  }
  if (elegidos.length > limiteProductosInicio) {
    return elegidos.sublist(0, limiteProductosInicio);
  }
  return elegidos;
}

String etiquetaCategoria(String id) => switch (id) {
  'abarrotes' => 'Abarrotes',
  'bebidas' => 'Bebidas',
  'lácteos' => 'Lácteos',
  'limpieza' => 'Limpieza',
  'snacks' => 'Snacks',
  _ => id,
};
