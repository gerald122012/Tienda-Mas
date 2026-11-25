import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/cupon.dart';
import '../../models/pedido.dart';
import '../../services/auth_service.dart';
import '../../services/carrito_service.dart';
import '../../services/permisos_service.dart';
import '../../services/registro_pedidos.dart';
import '../../tema/tema_mass.dart';
import '../../utils/utilidades.dart';
import '../auth/login_screen.dart';
import '../delivery/delivery_mapa_screen.dart';
import '../escaner/escaner_herramientas_screen.dart';
import 'carrito_vacio.dart';
import 'opciones_entrega.dart';
import 'resumen_compra.dart';
import 'seccion_ahorro.dart';
import 'tarjeta_producto_carrito.dart';

class CarritoScreen extends StatefulWidget {
  final VoidCallback? alVerProductos;
  final RegistroPedidos? registro;
  final String uidCliente;
  final Future<CuponDescuento?> Function(String codigo)? buscarCupon;
  final WidgetBuilder? pantallaRuta;

  const CarritoScreen({
    super.key,
    this.alVerProductos,
    this.registro,
    this.uidCliente = '',
    this.buscarCupon,
    this.pantallaRuta,
  });

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  final _carrito = CarritoService.instance;
  final _picker = ImagePicker();
  final _personaRecojoCtrl = TextEditingController();
  final _codigoCuponCtrl = TextEditingController();

  String _tipoEntrega = 'recojo';
  String? _fotoRecojoBase64;
  bool _capturandoFoto = false;
  bool _enviando = false;
  bool _aplicandoCupon = false;
  bool _confirmacionPendiente = false;
  String? _avisoCupon;
  String? _avisoPedido;
  IntentoRegistro? _intento;

  @override
  void initState() {
    super.initState();
    final usuario = AuthService.instance.usuario;
    if (usuario != null) {
      _personaRecojoCtrl.text = usuario.nombre;
    }
    _restaurarIntento();
  }

  String _uidActual() {
    if (widget.registro != null) return widget.uidCliente;
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  String get _correoActual => AuthService.instance.usuario?.correo ?? '';

  Future<void> _restaurarIntento() async {
    final intento = await IntentoRegistroPedido.leer(
      uid: _uidActual(),
      correo: _correoActual,
    );
    if (!mounted || intento == null) return;
    setState(() {
      _intento = intento;
      if (intento.escrituraEnviada) {
        _confirmacionPendiente = true;
        _avisoPedido = _mensajeSinConfirmar;
      }
    });
  }

  @override
  void dispose() {
    _personaRecojoCtrl.dispose();
    _codigoCuponCtrl.dispose();
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

  Future<CuponDescuento?> _buscarCupon(String codigo) async {
    if (widget.buscarCupon != null) return widget.buscarCupon!(codigo);
    final local = CuponDescuento.predeterminados
        .where((c) => c.codigo == codigo)
        .firstOrNull;
    if (local != null) return local;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('cupones_mass')
          .where('codigo', isEqualTo: codigo)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        return CuponDescuento.fromMap(
          snap.docs.first.id,
          snap.docs.first.data(),
        );
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<void> _aplicarCodigo() async {
    if (_aplicandoCupon) return;
    final codigo = CuponDescuento.extraerCodigoDesdeQr(_codigoCuponCtrl.text);
    if (codigo.isEmpty) {
      setState(() => _avisoCupon = 'Escribe el código del cupón.');
      return;
    }
    setState(() {
      _aplicandoCupon = true;
      _avisoCupon = null;
    });
    try {
      final cupon = await _buscarCupon(codigo);
      if (!mounted) return;
      if (cupon == null) {
        setState(
          () => _avisoCupon = 'El código "$codigo" no corresponde a un cupón válido.',
        );
        return;
      }
      if (!cupon.activo) {
        setState(() => _avisoCupon = 'Este cupón ya no está activo.');
        return;
      }
      final error = _carrito.aplicarCupon(cupon);
      setState(() {
        _avisoCupon = error;
        if (error == null) _codigoCuponCtrl.clear();
      });
    } finally {
      if (mounted) setState(() => _aplicandoCupon = false);
    }
  }

  Future<void> _eliminarProducto(ItemCarrito item) async {
    final confirmar = await confirmarEliminar(context, item.producto.nombre);
    if (!confirmar || !mounted) return;
    _carrito.eliminar(item.producto);
  }

  Future<void> _vaciar() async {
    final respuesta = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vaciar carrito'),
        content: const Text(
          'Se quitarán los productos y el cupón aplicado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: TokensMass.de(context).error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );
    if (respuesta == true) _carrito.vaciar();
  }

  void _verProductos() {
    final accion = widget.alVerProductos;
    if (accion != null) {
      accion();
      return;
    }
    Navigator.maybePop(context);
  }

  static const _mensajeRechazo =
      'No se pudo registrar tu pedido. Tus productos siguen en el carrito. Inténtalo nuevamente.';
  static const _mensajeSinConfirmar =
      'Todavía no pudimos confirmar el registro de tu pedido.';
  static const _mensajeConfirmado =
      '¡Pedido registrado! Puedes consultarlo en Mis Compras.';
  static const _mensajeCopiaLocal =
      'Tu pedido quedó registrado. No pudimos guardar la copia en este dispositivo; consúltalo en Mis compras.';

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
    final registro = widget.registro ?? RegistroPedidos.firestore();
    final uid = _uidActual();
    final intento = _intento ??
        IntentoRegistro(id: crearIdIntento(uid), escrituraEnviada: false);
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
      id: intento.id,
      clienteUid: uid,
      clienteNombre: usuario.nombre,
      clienteCorreo: usuario.correo,
      fecha: DateTime.now(),
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

    setState(() {
      _enviando = true;
      _avisoPedido = null;
    });
    final resultado = await registro.registrar(
      pedidoBorrador,
      escrituraEnviada: intento.escrituraEnviada,
    );
    if (!mounted) return;

    if (resultado.confirmado) {
      try {
        await IntentoRegistroPedido.limpiar(uid: uid, correo: usuario.correo);
      } catch (_) {
        // El pedido ya fue confirmado. Perder la marca local no lo deshace.
      }
      _carrito.vaciar();
      if (!mounted) return;
      Navigator.pop(context);
      mostrarMensaje(
        context,
        resultado.copiaLocalGuardada ? _mensajeConfirmado : _mensajeCopiaLocal,
      );
      return;
    }

    final pendiente = resultado.tipo == TipoResultadoRegistro.sinConfirmar;
    final conservado = IntentoRegistro(
      id: resultado.id,
      escrituraEnviada: resultado.escrituraEnviada,
    );
    try {
      await IntentoRegistroPedido.guardar(
        conservado,
        uid: uid,
        correo: usuario.correo,
      );
    } catch (_) {
      // La marca del intento no cambia el resultado del servidor.
    }
    if (!mounted) return;
    setState(() {
      _enviando = false;
      _intento = conservado;
      _confirmacionPendiente = pendiente;
      _avisoPedido = pendiente ? _mensajeSinConfirmar : _mensajeRechazo;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Scaffold(
      backgroundColor: tokens.fondo,
      appBar: AppBar(
        backgroundColor: tokens.sello,
        foregroundColor: tokens.profundo,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: ListenableBuilder(
          listenable: _carrito,
          builder: (context, _) {
            final n = _carrito.unidades;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mi carrito',
                  style: textoMass(
                    tamano: 18,
                    peso: FontWeight.w800,
                    color: tokens.profundo,
                  ),
                ),
                Text(
                  n == 0
                      ? 'Sin productos'
                      : '$n ${n == 1 ? 'unidad' : 'unidades'}',
                  style: textoMass(tamano: 12, color: tokens.tintaSuave),
                ),
              ],
            );
          },
        ),
        actions: [
          ListenableBuilder(
            listenable: _carrito,
            builder: (context, _) {
              if (_carrito.vacio) return const SizedBox(width: 8);
              return TextButton(
                onPressed: _vaciar,
                child: const Text('Vaciar'),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _carrito,
        builder: (context, _) {
          if (_carrito.vacio) {
            return CarritoVacio(alVerProductos: _verProductos);
          }
          final items = _carrito.items;
          final cupon = _carrito.cuponAplicado;
          final avisoCondicion = cupon != null ? null : _avisoCupon;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    for (final item in items) ...[
                      TarjetaProductoCarrito(
                        key: ValueKey(item.producto.id),
                        item: item,
                        alAgregar: () => _carrito.agregar(item.producto),
                        alQuitar: () => _carrito.quitarUna(item.producto),
                        alEliminar: () => _eliminarProducto(item),
                      ),
                      const SizedBox(height: 10),
                    ],
                    SeccionAhorro(
                      cupon: cupon,
                      descuento: _carrito.descuento,
                      aviso: avisoCondicion,
                      aplicando: _aplicandoCupon,
                      codigo: _codigoCuponCtrl,
                      alAplicar: _aplicarCodigo,
                      alQuitar: () {
                        _carrito.quitarCupon();
                        setState(() => _avisoCupon = null);
                      },
                      alEscanear: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const EscanerHerramientasScreen(
                                tabInicial: 0,
                                volverAlCarrito: true,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OpcionesEntrega(
                      tipo: _tipoEntrega,
                      alCambiar: (valor) => setState(() => _tipoEntrega = valor),
                      persona: _personaRecojoCtrl,
                      fotoBase64: _fotoRecojoBase64,
                      capturando: _capturandoFoto,
                      alTomarFoto: () =>
                          _capturarFotoRecojo(ImageSource.camera),
                      alAdjuntarFoto: () =>
                          _capturarFotoRecojo(ImageSource.gallery),
                      alQuitarFoto: () =>
                          setState(() => _fotoRecojoBase64 = null),
                      ruta: _carrito.rutaSeleccionada,
                      alAbrirRuta: () async {
                        final adjunto = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: widget.pantallaRuta ??
                                (_) => const DeliveryMapaScreen(
                                  volverAlCarrito: true,
                                ),
                          ),
                        );
                        if (!context.mounted || adjunto != true) return;
                        mostrarMensaje(
                          context,
                          'Ruta adjunta a tu carrito. No incluye un costo de entrega.',
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    ResumenCompra(
                      subtotal: _carrito.subtotal,
                      descuento: _carrito.descuento,
                      codigoCupon: cupon?.codigo,
                      total: _carrito.total,
                      delivery: _tipoEntrega == 'delivery',
                    ),
                  ],
                ),
              ),
              if (_avisoPedido != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    _avisoPedido!,
                    style: textoMass(
                      tamano: 13,
                      peso: FontWeight.w700,
                      color: _confirmacionPendiente
                          ? tokens.profundo
                          : tokens.error,
                      alto: 1.35,
                    ),
                  ),
                ),
              BarraConfirmacionCarrito(
                unidades: _carrito.unidades,
                total: _carrito.total,
                descuento: _carrito.descuento,
                enviando: _enviando,
                invitado: AuthService.instance.usuario == null,
                alConfirmar: _finalizar,
              ),
            ],
          );
        },
      ),
    );
  }
}
