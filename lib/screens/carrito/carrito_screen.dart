import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../main.dart';
import '../../models/pedido.dart';
import '../../services/auth_service.dart';
import '../../services/carrito_service.dart';
import '../../services/pedidos_local_service.dart';
import '../../services/permisos_service.dart';
import '../../utils/utilidades.dart';
import '../../widgets/aparecer.dart';
import '../auth/login_screen.dart';
import '../delivery/delivery_mapa_screen.dart';
import '../escaner/escaner_herramientas_screen.dart';

class CarritoScreen extends StatefulWidget {
  const CarritoScreen({super.key});

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  final _carrito = CarritoService.instance;
  final _picker = ImagePicker();
  final _personaRecojoCtrl = TextEditingController();

  String _tipoEntrega = 'recojo';
  String? _fotoRecojoBase64;
  bool _capturandoFoto = false;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    final usuario = AuthService.instance.usuario;
    if (usuario != null) {
      _personaRecojoCtrl.text = usuario.nombre;
    }
  }

  @override
  void dispose() {
    _personaRecojoCtrl.dispose();
    super.dispose();
  }

  Future<void> _capturarFotoRecojo(ImageSource origen) async {
    if (_capturandoFoto) return;
    if (origen == ImageSource.camera) {
      final permitido = await PermisosService.solicitarPermisoCamara(
        context,
        motivo: 'tomar la foto de la persona autorizada para recoger el pedido',
      );
      if (!permitido || !mounted) return;
    }

    setState(() => _capturandoFoto = true);
    try {
      final img = await _picker.pickImage(
        source: origen,
        maxWidth: 480,
        maxHeight: 480,
        imageQuality: 65,
      );
      if (img == null) return;
      final bytes = await img.readAsBytes();
      if (!mounted) return;
      setState(() => _fotoRecojoBase64 = base64Encode(bytes));
      mostrarMensaje(context, 'Foto de verificación adjuntada al pedido.');
    } catch (_) {
      if (mounted) {
        mostrarMensaje(
          context,
          'No se pudo acceder a la cámara o galería en este dispositivo.',
        );
      }
    } finally {
      if (mounted) setState(() => _capturandoFoto = false);
    }
  }

  Future<void> _finalizar() async {
    if (_enviando || _carrito.vacio) return;
    if (AuthService.instance.usuario == null) {
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (!mounted) return;
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
      if (_personaRecojoCtrl.text.trim().isEmpty) {
        _personaRecojoCtrl.text = nuevo.nombre;
      }
      setState(() {});
      mostrarMensaje(
        context,
        'Sesión iniciada. Revisa tu carrito y confirma la compra.',
      );
      return;
    }

    final usuario = AuthService.instance.usuario!;
    final ahora = DateTime.now();
    final items = [
      for (final i in _carrito.items)
        ItemPedido(
          productoId: i.producto.id,
          nombre: i.producto.nombre,
          marca: i.producto.marca,
          precio: i.producto.precio,
          cantidad: i.cantidad,
        ),
    ];

    final pedidoBorrador = Pedido(
      id: 'local_${ahora.millisecondsSinceEpoch}',
      clienteUid: FirebaseAuth.instance.currentUser?.uid ?? '',
      clienteNombre: usuario.nombre,
      clienteCorreo: usuario.correo,
      fecha: ahora,
      estado: 'pendiente',
      subtotal: _carrito.subtotal,
      descuento: _carrito.descuento,
      total: _carrito.total,
      cuponCodigo: _carrito.cuponAplicado?.codigo ?? '',
      tipoEntrega: _tipoEntrega,
      personaRecojo: _personaRecojoCtrl.text.trim().isEmpty
          ? usuario.nombre
          : _personaRecojoCtrl.text.trim(),
      fotoRecojoBase64: _fotoRecojoBase64 ?? '',
      rutaResumen: _tipoEntrega == 'delivery'
          ? (_carrito.rutaSeleccionada ?? '')
          : '',
      items: items,
    );

    setState(() => _enviando = true);
    try {
      String idFinal = pedidoBorrador.id;
      try {
        final ref = await FirebaseFirestore.instance
            .collection('pedidos')
            .add(pedidoBorrador.toFirestoreMap());
        idFinal = ref.id;
      } catch (_) {}

      final pedidoGuardado = Pedido(
        id: idFinal,
        clienteUid: pedidoBorrador.clienteUid,
        clienteNombre: pedidoBorrador.clienteNombre,
        clienteCorreo: pedidoBorrador.clienteCorreo,
        fecha: pedidoBorrador.fecha,
        estado: pedidoBorrador.estado,
        subtotal: pedidoBorrador.subtotal,
        descuento: pedidoBorrador.descuento,
        total: pedidoBorrador.total,
        cuponCodigo: pedidoBorrador.cuponCodigo,
        tipoEntrega: pedidoBorrador.tipoEntrega,
        personaRecojo: pedidoBorrador.personaRecojo,
        fotoRecojoBase64: pedidoBorrador.fotoRecojoBase64,
        rutaResumen: pedidoBorrador.rutaResumen,
        items: pedidoBorrador.items,
      );
      await PedidosLocalService.instance.guardarPedido(pedidoGuardado);

      _carrito.vaciar();
      if (!mounted) return;
      Navigator.pop(context);
      mostrarMensaje(
        context,
        '¡Pedido registrado! Puedes consultarlo en Mis Compras.',
      );
    } catch (_) {
      if (mounted) {
        mostrarMensaje(
          context,
          'No se pudo registrar el pedido. Inténtalo de nuevo.',
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
                    size: 58,
                    color: kMassBlue,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Tu carrito está vacío',
                    style: TextStyle(
                      color: kMassBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text('Agrega productos del catálogo para empezar.'),
                ],
              ),
            );
          }

          final items = _carrito.items;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (var i = 0; i < items.length; i++)
                      _tarjetaItem(items[i]),
                    const SizedBox(height: 6),
                    _tarjetaCuponQr(),
                    const SizedBox(height: 10),
                    _tarjetaEntregaYVerificacion(),
                  ],
                ),
              ),
              _barraResumenInferior(),
            ],
          );
        },
      ),
    );
  }

  Widget _tarjetaItem(ItemCarrito item) {
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
                    const SizedBox(height: 3),
                    precioUnaLinea(
                      '${formatoPrecio(p.precio)} c/u · Subtotal ${formatoPrecio(item.subtotal)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade800,
                      ),
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
                    fontFeatures: [FontFeature.tabularFigures()],
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
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _carrito.eliminar(p),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tarjetaCuponQr() {
    final cupon = _carrito.cuponAplicado;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: kMassMint,
              foregroundColor: kMassBlue,
              child: const Icon(Icons.qr_code_2),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: cupon == null
                  ? const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¿Tienes un QR de descuento?',
                          style: TextStyle(
                            color: kMassBlue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Escanéalo para ahorrar en esta compra',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cupón ${cupon.codigo} activo',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Ahorras ${formatoPrecio(_carrito.descuento)} (${cupon.etiquetaDescuento})',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
            ),
            if (cupon != null)
              IconButton(
                tooltip: 'Quitar cupón',
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: _carrito.quitarCupon,
              )
            else
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const EscanerHerramientasScreen(tabInicial: 0),
                  ),
                ),
                icon: const Icon(Icons.qr_code_scanner, size: 17),
                label: const Text('Escanear'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaEntregaYVerificacion() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Entrega y verificación de recojo',
              style: TextStyle(
                color: kMassBlue,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'recojo',
                  icon: Icon(Icons.storefront),
                  label: Text('Recojo en tienda'),
                ),
                ButtonSegment(
                  value: 'delivery',
                  icon: Icon(Icons.delivery_dining),
                  label: Text('Delivery'),
                ),
              ],
              selected: {_tipoEntrega},
              onSelectionChanged: (v) => setState(() => _tipoEntrega = v.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _personaRecojoCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre de quien recoge o recibe el pedido',
                prefixIcon: Icon(Icons.person_outline),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Foto de verificación de quien recoge (opcional)',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                color: kMassBlue,
              ),
            ),
            const SizedBox(height: 8),
            if (_fotoRecojoBase64 != null && _fotoRecojoBase64!.isNotEmpty) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      base64Decode(_fotoRecojoBase64!),
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: IconButton.filled(
                      tooltip: 'Quitar foto',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => setState(() => _fotoRecojoBase64 = null),
                      icon: const Icon(Icons.delete_outline, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _capturandoFoto
                        ? null
                        : () => _capturarFotoRecojo(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('Tomar foto'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _capturandoFoto
                        ? null
                        : () => _capturarFotoRecojo(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Adjuntar'),
                  ),
                ),
              ],
            ),
            if (_tipoEntrega == 'delivery') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kMassMint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.route, color: kMassBlue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _carrito.rutaSeleccionada ??
                            'Aún no has calculado una ruta de entrega.',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DeliveryMapaScreen(),
                        ),
                      ),
                      child: const Text('Mapa'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _barraResumenInferior() {
    final usuario = AuthService.instance.usuario;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black12)],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _carrito.descuento > 0
                        ? '${_carrito.unidades} unid. · Ahorro ${formatoPrecio(_carrito.descuento)}'
                        : '${_carrito.unidades} unidades',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: _carrito.descuento > 0
                          ? Colors.green.shade800
                          : Colors.grey.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: _carrito.total),
                    duration: const Duration(milliseconds: 280),
                    builder: (context, v, _) => precioUnaLinea(
                      'Total ${formatoPrecio(v)}',
                      style: const TextStyle(
                        color: kMassBlue,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _enviando ? null : _finalizar,
              icon: _enviando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(
                usuario == null ? 'INGRESAR Y COMPRAR' : 'FINALIZAR COMPRA',
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
