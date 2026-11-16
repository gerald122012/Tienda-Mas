import 'package:cloud_firestore/cloud_firestore.dart';

class ItemPedido {
  final String nombre;
  final String marca;
  final double precio;
  final int cantidad;

  const ItemPedido({
    required this.nombre,
    required this.marca,
    required this.precio,
    required this.cantidad,
  });

  double get subtotal => precio * cantidad;
}

// Compra registrada por un cliente desde el carrito (colección "pedidos").
class Pedido {
  final String id;
  final String clienteNombre;
  final String clienteCorreo;
  final DateTime fecha;
  final String estado;
  final double total;
  final List<ItemPedido> items;

  const Pedido({
    required this.id,
    required this.clienteNombre,
    required this.clienteCorreo,
    required this.fecha,
    required this.estado,
    required this.total,
    required this.items,
  });

  static const estados = ['pendiente', 'preparando', 'entregado', 'cancelado'];

  factory Pedido.fromMap(String id, Map<String, dynamic> d) {
    final fecha = d['fecha'];
    final lista = d['items'];
    return Pedido(
      id: id,
      clienteNombre: (d['clienteNombre'] ?? '').toString(),
      clienteCorreo: (d['clienteCorreo'] ?? '').toString(),
      fecha: fecha is Timestamp ? fecha.toDate() : DateTime.now(),
      estado: estados.contains(d['estado']) ? d['estado'] : 'pendiente',
      total: (d['total'] as num?)?.toDouble() ?? 0,
      items: [
        if (lista is List)
          for (final i in lista.whereType<Map>())
            ItemPedido(
              nombre: (i['nombre'] ?? '').toString(),
              marca: (i['marca'] ?? '').toString(),
              precio: (i['precio'] as num?)?.toDouble() ?? 0,
              cantidad: (i['cantidad'] as num?)?.toInt() ?? 0,
            ),
      ],
    );
  }
}
