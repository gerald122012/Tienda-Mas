import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../services/auth_service.dart';
import '../../services/carrito_service.dart';
import '../../utils/utilidades.dart';
import '../../widgets/aparecer.dart';
import '../auth/login_screen.dart';

class CarritoScreen extends StatefulWidget {
  const CarritoScreen({super.key});

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  final _carrito = CarritoService.instance;
  bool _enviando = false;

  Future<void> _finalizar() async {
    if (_enviando || _carrito.vacio) return;
    if (AuthService.instance.usuario == null) {
      // Invitado: debe iniciar sesión para comprar; el carrito se conserva.
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (!mounted) return;
      setState(() {});
      final nuevo = AuthService.instance.usuario;
      if (nuevo == null) return;
      if (nuevo.esAdmin) {
        Navigator.pop(context);
        mostrarMensaje(
          context,
          'Las cuentas de administrador no realizan compras.',
        );
        return;
      }
      mostrarMensaje(
        context,
        'Sesión iniciada. Revisa tu carrito y confirma la compra.',
      );
      return;
    }
    final usuario = AuthService.instance.usuario;
    setState(() => _enviando = true);
    try {
      await FirebaseFirestore.instance.collection('pedidos').add({
        'clienteNombre': usuario?.nombre ?? '',
        'clienteCorreo': usuario?.correo ?? '',
        'fecha': Timestamp.now(),
        'estado': 'pendiente',
        'total': _carrito.total,
        'items': [
          for (final i in _carrito.items)
            {
              'productoId': i.producto.id,
              'nombre': i.producto.nombre,
              'marca': i.producto.marca,
              'precio': i.producto.precio,
              'cantidad': i.cantidad,
              'subtotal': i.subtotal,
            },
        ],
      });
      _carrito.vaciar();
      if (!mounted) return;
      Navigator.pop(context);
      mostrarMensaje(context, '¡Pedido registrado! Gracias por tu compra.');
    } catch (_) {
      if (mounted) {
        mostrarMensaje(
          context,
          'No se pudo registrar el pedido. Revisa la conexión y los permisos.',
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi carrito')),
      body: ListenableBuilder(
        listenable: _carrito,
        builder: (context, _) {
          if (_carrito.vacio) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 56,
                    color: kMassBlue,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Tu carrito está vacío',
                    style: TextStyle(
                      color: kMassBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }
          final items = _carrito.items;
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final p = item.producto;
                    return Aparecer(
                      key: ValueKey(p.id),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.nombre,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: kMassBlue,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'S/ ${p.precio.toStringAsFixed(2)} c/u · '
                                      'Subtotal S/ ${item.subtotal.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Quitar uno',
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => _carrito.quitarUna(p),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, anim) =>
                                    ScaleTransition(scale: anim, child: child),
                                child: Text(
                                  '${item.cantidad}',
                                  key: ValueKey(item.cantidad),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Agregar uno',
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: item.cantidad >= p.stock
                                    ? null
                                    : () => _carrito.agregar(p),
                              ),
                              IconButton(
                                tooltip: 'Eliminar',
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _carrito.eliminar(p),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(blurRadius: 6, color: Colors.black12),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_carrito.unidades} unidades'),
                            TweenAnimationBuilder<double>(
                              tween: Tween(end: _carrito.total),
                              duration: const Duration(milliseconds: 300),
                              builder: (context, v, _) => Text(
                                'Total S/ ${v.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: kMassBlue,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _enviando ? null : _finalizar,
                        icon: _enviando
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: Text(
                          AuthService.instance.usuario == null
                              ? 'INICIAR SESIÓN Y COMPRAR'
                              : 'FINALIZAR COMPRA',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
