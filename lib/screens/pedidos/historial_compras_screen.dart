import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/pedido.dart';
import '../../models/producto.dart';
import '../../services/auth_service.dart';
import '../../services/carrito_service.dart';
import '../../services/pedidos_local_service.dart';
import '../../utils/utilidades.dart';
import '../../widgets/aparecer.dart';
import '../auth/login_screen.dart';

class HistorialComprasScreen extends StatefulWidget {
  final bool mostrarAppBar;

  const HistorialComprasScreen({super.key, this.mostrarAppBar = false});

  @override
  State<HistorialComprasScreen> createState() => _HistorialComprasScreenState();
}

class _HistorialComprasScreenState extends State<HistorialComprasScreen> {
  String _filtro = 'todos';

  @override
  void initState() {
    super.initState();
    PedidosLocalService.instance.cargar();
  }

  Color _colorEstado(String estado) => switch (estado) {
    'pendiente' => Colors.orange.shade800,
    'preparando' => kMassBlue,
    'entregado' => Colors.green.shade800,
    _ => Colors.red.shade800,
  };

  String _mayus(String t) => t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);

  List<Pedido> _combinarPedidos(
    List<Pedido> remotos,
    List<Pedido> locales,
    String correo,
  ) {
    final c = correo.trim().toLowerCase();
    final mapa = <String, Pedido>{};
    for (final p in locales) {
      if (p.clienteCorreo.trim().toLowerCase() == c) {
        mapa[p.id] = p;
      }
    }
    for (final p in remotos) {
      if (p.clienteCorreo.trim().toLowerCase() == c) {
        mapa[p.id] = p;
      }
    }
    final lista = mapa.values.toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    if (_filtro == 'todos') return lista;
    return lista.where((p) => p.estado == _filtro).toList();
  }

  void _abrirDetalle(Pedido pedido) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetallePedidoScreen(pedido: pedido)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMassCream,
      appBar: widget.mostrarAppBar
          ? AppBar(title: const Text('Historial de compras'))
          : null,
      body: ListenableBuilder(
        listenable: Listenable.merge([
          AuthService.instance,
          PedidosLocalService.instance,
        ]),
        builder: (context, _) {
          final usuario = AuthService.instance.usuario;
          if (usuario == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: kMassBlue,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Inicia sesión para ver tu historial de compras',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kMassBlue,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Aquí podrás consultar todos tus pedidos realizados, el estado actual y los datos de recojo.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      icon: const Icon(Icons.login),
                      label: const Text('INICIAR SESIÓN'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: const BoxDecoration(
                  color: kMassBlue,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mis compras realizadas',
                      style: TextStyle(
                        color: kMassYellow,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Toca cualquier pedido para ver su detalle completo',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        spacing: 6,
                        children: [
                          for (final e in ['todos', ...Pedido.estados])
                            ChoiceChip(
                              label: Text(
                                _mayus(e),
                                style: TextStyle(
                                  color: _filtro == e
                                      ? kMassBlue
                                      : Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              selected: _filtro == e,
                              selectedColor: kMassYellow,
                              backgroundColor: kMassBlue,
                              side: const BorderSide(color: kMassYellow),
                              showCheckmark: false,
                              onSelected: (_) => setState(() => _filtro = e),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  // Las reglas solo permiten al cliente leer sus propios pedidos.
                  stream: FirebaseAuth.instance.currentUser == null
                      ? const Stream.empty()
                      : FirebaseFirestore.instance
                            .collection('pedidos')
                            .where(
                              'clienteUid',
                              isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                            )
                            .snapshots(),
                  builder: (context, snapshot) {
                    final remotos = snapshot.hasData
                        ? snapshot.data!.docs
                              .map((d) => Pedido.fromMap(d.id, d.data()))
                              .toList()
                        : <Pedido>[];
                    final pedidos = _combinarPedidos(
                      remotos,
                      PedidosLocalService.instance.pedidos,
                      usuario.correo,
                    );

                    if (pedidos.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.shopping_bag_outlined,
                                size: 58,
                                color: kMassBlue,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _filtro == 'todos'
                                    ? 'Todavía no realizas compras'
                                    : 'No tienes pedidos con estado "$_filtro"',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: kMassBlue,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: pedidos.length,
                      itemBuilder: (context, i) {
                        final p = pedidos[i];
                        return Aparecer(indice: i, child: _tarjetaPedido(p));
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tarjetaPedido(Pedido p) {
    final color = _colorEstado(p.estado);
    final codigoCorto = p.id.length > 8
        ? p.id.substring(0, 8).toUpperCase()
        : p.id.toUpperCase();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _abrirDetalle(p),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pedido #$codigoCorto',
                      style: const TextStyle(
                        color: kMassBlue,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color),
                    ),
                    child: Text(
                      _mayus(p.estado),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${formatoFechaHora(p.fecha)} · ${p.totalUnidades} unid. · '
                '${p.tipoEntrega == 'delivery' ? 'Delivery' : 'Recojo en tienda'}',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
              ),
              if (p.personaRecojo.isNotEmpty || p.fotoRecojoBase64.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        size: 16,
                        color: kMassBlue,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          p.personaRecojo.isNotEmpty
                              ? 'Recoge: ${p.personaRecojo}'
                              : 'Foto de verificación adjunta',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: kMassBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 16),
              Row(
                children: [
                  Expanded(
                    child: precioUnaLinea(
                      'Total ${formatoPrecio(p.total)}',
                      style: const TextStyle(
                        color: kMassBlue,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _abrirDetalle(p),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('Ver detalle'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DetallePedidoScreen extends StatelessWidget {
  final Pedido pedido;

  const DetallePedidoScreen({super.key, required this.pedido});

  void _volverAPedir(BuildContext context) {
    final carrito = CarritoService.instance;
    for (final item in pedido.items) {
      final prod = Producto(
        id: item.productoId.isEmpty ? item.nombre : item.productoId,
        nombre: item.nombre,
        descripcion: item.nombre,
        marca: item.marca.isEmpty ? 'Mass' : item.marca,
        precio: item.precio,
        stock: item.cantidad + 10,
        categoria: Producto.categorias.first,
        disponible: true,
        fechaRegistro: DateTime.now(),
        presentaciones: const ['Unidad'],
        valoracion: 5,
      );
      for (var i = 0; i < item.cantidad; i++) {
        carrito.agregar(prod);
      }
    }
    mostrarMensaje(context, 'Productos agregados nuevamente a tu carrito.');
  }

  @override
  Widget build(BuildContext context) {
    final codigoCorto = pedido.id.length > 8
        ? pedido.id.substring(0, 8).toUpperCase()
        : pedido.id.toUpperCase();
    final pasosEstado = ['pendiente', 'preparando', 'entregado'];
    final indicePaso = pasosEstado.indexOf(pedido.estado);

    return Scaffold(
      appBar: AppBar(title: Text('Detalle pedido #$codigoCorto')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long, color: kMassBlue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Fecha: ${formatoFechaHora(pedido.fecha)}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Modalidad: ${pedido.tipoEntrega == 'delivery' ? 'Delivery a domicilio' : 'Recojo en tienda'}',
                  ),
                  if (pedido.rutaResumen.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Ruta: ${pedido.rutaResumen}',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (pedido.estado == 'cancelado')
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Pedido cancelado',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red.shade800,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        for (var i = 0; i < pasosEstado.length; i++) ...[
                          Expanded(
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 15,
                                  backgroundColor: i <= indicePaso
                                      ? kMassBlue
                                      : Colors.grey.shade300,
                                  foregroundColor: i <= indicePaso
                                      ? kMassYellow
                                      : Colors.grey.shade600,
                                  child: Icon(
                                    i <= indicePaso
                                        ? Icons.check
                                        : Icons.circle_outlined,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  pasosEstado[i][0].toUpperCase() +
                                      pasosEstado[i].substring(1),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: i <= indicePaso
                                        ? FontWeight.w900
                                        : FontWeight.w500,
                                    color: i <= indicePaso
                                        ? kMassBlue
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (pedido.personaRecojo.isNotEmpty ||
              pedido.fotoRecojoBase64.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.badge_outlined, color: kMassBlue),
                        SizedBox(width: 8),
                        Text(
                          'Verificación de recojo',
                          style: TextStyle(
                            color: kMassBlue,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    if (pedido.personaRecojo.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Persona autorizada: ${pedido.personaRecojo}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                    if (pedido.fotoRecojoBase64.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(
                          base64Decode(pedido.fotoRecojoBase64),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Text(
                            'No se pudo cargar la foto de verificación.',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Productos comprados',
                    style: TextStyle(
                      color: kMassBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final item in pedido.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: kMassMint,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${item.cantidad}x',
                              style: const TextStyle(
                                color: kMassBlue,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${formatoPrecio(item.precio)} c/u',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          precioUnaLinea(
                            formatoPrecio(item.subtotal),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: kMassBlue,
                            ),
                            alignment: Alignment.centerRight,
                          ),
                        ],
                      ),
                    ),
                  const Divider(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal'),
                      precioUnaLinea(
                        formatoPrecio(pedido.subtotalCalculado),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                        alignment: Alignment.centerRight,
                      ),
                    ],
                  ),
                  if (pedido.descuento > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          pedido.cuponCodigo.isNotEmpty
                              ? 'Descuento (${pedido.cuponCodigo})'
                              : 'Descuento aplicado',
                          style: TextStyle(color: Colors.green.shade800),
                        ),
                        precioUnaLinea(
                          '- ${formatoPrecio(pedido.descuento)}',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w800,
                          ),
                          alignment: Alignment.centerRight,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total pagado',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: kMassBlue,
                        ),
                      ),
                      precioUnaLinea(
                        formatoPrecio(pedido.total),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: kMassBlue,
                        ),
                        alignment: Alignment.centerRight,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (AuthService.instance.usuario?.esAdmin != true)
            FilledButton.icon(
              onPressed: () => _volverAPedir(context),
              icon: const Icon(Icons.replay_rounded),
              label: const Text('VOLVER A PEDIR'),
            ),
        ],
      ),
    );
  }
}
