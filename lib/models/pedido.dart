import 'package:cloud_firestore/cloud_firestore.dart';

class ItemPedido {
  final String productoId;
  final String nombre;
  final String marca;
  final double precio;
  final int cantidad;

  const ItemPedido({
    this.productoId = '',
    required this.nombre,
    required this.marca,
    required this.precio,
    required this.cantidad,
  });

  double get subtotal => precio * cantidad;

  Map<String, dynamic> toMap() => {
    'productoId': productoId,
    'nombre': nombre,
    'marca': marca,
    'precio': precio,
    'cantidad': cantidad,
    'subtotal': subtotal,
  };
}

class Pedido {
  final String id;
  final String clienteUid;
  final String clienteNombre;
  final String clienteCorreo;
  final DateTime fecha;
  final String estado;
  final double subtotal;
  final double descuento;
  final double total;
  final String cuponCodigo;
  final String tipoEntrega;
  final String personaRecojo;
  final String fotoRecojoBase64;
  final String rutaResumen;
  final List<ItemPedido> items;

  const Pedido({
    required this.id,
    this.clienteUid = '',
    required this.clienteNombre,
    required this.clienteCorreo,
    required this.fecha,
    required this.estado,
    this.subtotal = 0,
    this.descuento = 0,
    required this.total,
    this.cuponCodigo = '',
    this.tipoEntrega = 'recojo',
    this.personaRecojo = '',
    this.fotoRecojoBase64 = '',
    this.rutaResumen = '',
    required this.items,
  });

  static const estados = ['pendiente', 'preparando', 'entregado', 'cancelado'];

  int get totalUnidades => items.fold(0, (s, i) => s + i.cantidad);

  double get subtotalCalculado =>
      subtotal > 0 ? subtotal : items.fold(0, (s, i) => s + i.subtotal);

  Map<String, dynamic> toFirestoreMap() => {
    'clienteUid': clienteUid,
    'clienteNombre': clienteNombre,
    'clienteCorreo': clienteCorreo,
    'fecha': Timestamp.fromDate(fecha),
    'estado': estado,
    'subtotal': subtotalCalculado,
    'descuento': descuento,
    'total': total,
    'cuponCodigo': cuponCodigo,
    'tipoEntrega': tipoEntrega,
    'personaRecojo': personaRecojo,
    'fotoRecojoBase64': fotoRecojoBase64,
    'rutaResumen': rutaResumen,
    'items': [for (final i in items) i.toMap()],
  };

  Map<String, dynamic> toLocalJson() => {
    'id': id,
    'clienteUid': clienteUid,
    'clienteNombre': clienteNombre,
    'clienteCorreo': clienteCorreo,
    'fechaIso': fecha.toIso8601String(),
    'estado': estado,
    'subtotal': subtotalCalculado,
    'descuento': descuento,
    'total': total,
    'cuponCodigo': cuponCodigo,
    'tipoEntrega': tipoEntrega,
    'personaRecojo': personaRecojo,
    'fotoRecojoBase64': fotoRecojoBase64,
    'rutaResumen': rutaResumen,
    'items': [for (final i in items) i.toMap()],
  };

  factory Pedido.fromMap(String id, Map<String, dynamic> d) {
    final fechaRaw = d['fecha'];
    DateTime fecha;
    if (fechaRaw is Timestamp) {
      fecha = fechaRaw.toDate();
    } else if (d['fechaIso'] is String) {
      fecha = DateTime.tryParse(d['fechaIso'] as String) ?? DateTime.now();
    } else {
      fecha = DateTime.now();
    }
    final lista = d['items'];
    final items = <ItemPedido>[
      if (lista is List)
        for (final i in lista.whereType<Map>())
          ItemPedido(
            productoId: (i['productoId'] ?? '').toString(),
            nombre: (i['nombre'] ?? '').toString(),
            marca: (i['marca'] ?? '').toString(),
            precio: (i['precio'] as num?)?.toDouble() ?? 0,
            cantidad: (i['cantidad'] as num?)?.toInt() ?? 0,
          ),
    ];
    final total = (d['total'] as num?)?.toDouble() ?? 0;
    final subtotal = (d['subtotal'] as num?)?.toDouble() ?? total;
    return Pedido(
      id: id,
      clienteUid: (d['clienteUid'] ?? '').toString(),
      clienteNombre: (d['clienteNombre'] ?? '').toString(),
      clienteCorreo: (d['clienteCorreo'] ?? '').toString(),
      fecha: fecha,
      estado: estados.contains(d['estado']) ? d['estado'] : 'pendiente',
      subtotal: subtotal,
      descuento: (d['descuento'] as num?)?.toDouble() ?? 0,
      total: total,
      cuponCodigo: (d['cuponCodigo'] ?? '').toString(),
      tipoEntrega: (d['tipoEntrega'] ?? 'recojo').toString(),
      personaRecojo: (d['personaRecojo'] ?? '').toString(),
      fotoRecojoBase64: (d['fotoRecojoBase64'] ?? '').toString(),
      rutaResumen: (d['rutaResumen'] ?? '').toString(),
      items: items,
    );
  }
}
