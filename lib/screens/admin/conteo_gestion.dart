import '../../models/cupon.dart';
import '../../models/pedido.dart';
import '../../models/producto.dart';
import '../../models/tienda.dart';
import '../../services/consulta_tiendas.dart';

/// Conteos leídos de los documentos existentes. No calcula ventas ni crecimiento.
class ConteoGestion {
  final int productos;
  final int disponibles;
  final int agotados;
  final int noDisponiblesConStock;
  final int stockUnidades;
  final int pedidos;
  final int pendientes;
  final int preparando;
  final int entregados;
  final int cancelados;
  final int estadosNoReconocidos;
  final int tiendas;
  final int tiendasSinCoordenadas;
  final int cupones;
  final int cuponesActivos;
  final int locales;

  const ConteoGestion({
    required this.productos,
    required this.disponibles,
    required this.agotados,
    required this.noDisponiblesConStock,
    required this.stockUnidades,
    required this.pedidos,
    required this.pendientes,
    required this.preparando,
    required this.entregados,
    required this.cancelados,
    required this.estadosNoReconocidos,
    required this.tiendas,
    required this.tiendasSinCoordenadas,
    required this.cupones,
    required this.cuponesActivos,
    required this.locales,
  });

  factory ConteoGestion.desde({
    required List<Producto> productos,
    required List<Pedido> pedidos,
    required List<Tienda> tiendas,
    required List<CuponDescuento> cupones,
    required int locales,
  }) {
    final disponibles = productos.where((p) => p.disponible && p.stock > 0).length;
    final agotados = productos.where((p) => p.stock <= 0).length;
    final noDisponibles = productos
        .where((p) => !p.disponible && p.stock > 0)
        .length;
    final stock = productos.fold<int>(0, (suma, p) => suma + p.stock);
    int contar(String estado) => pedidos.where((p) => p.estado == estado).length;
    final reconocidos = Pedido.estados.toSet();
    return ConteoGestion(
      productos: productos.length,
      disponibles: disponibles,
      agotados: agotados,
      noDisponiblesConStock: noDisponibles,
      stockUnidades: stock,
      pedidos: pedidos.length,
      pendientes: contar('pendiente'),
      preparando: contar('preparando'),
      entregados: contar('entregado'),
      cancelados: contar('cancelado'),
      estadosNoReconocidos: pedidos.where((p) => !reconocidos.contains(p.estado)).length,
      tiendas: tiendas.length,
      tiendasSinCoordenadas: tiendas
          .where((t) => !coordenadasValidas(t.latitud, t.longitud))
          .length,
      cupones: cupones.length,
      cuponesActivos: cupones.where((c) => c.activo).length,
      locales: locales,
    );
  }

  bool get hayPedidosParaGrafico => pedidos > 0;
}
