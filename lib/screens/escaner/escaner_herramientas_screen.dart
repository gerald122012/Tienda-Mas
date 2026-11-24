import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../models/cupon.dart';
import '../../models/producto.dart';
import '../../services/auth_service.dart';
import '../../services/carrito_service.dart';
import '../../services/catalogo_sesion.dart';
import '../../services/lectura_escaner.dart';
import '../../services/permisos_service.dart';
import '../../tema/tema_mass.dart';
import '../../utils/utilidades.dart';
import '../precios_mass/producto_form_screen.dart';
import 'controles_camara.dart';
import 'estado_permiso_camara.dart';
import 'marco_escaner_mass.dart';
import 'resultado_cupon.dart';
import 'resultado_producto.dart';
import 'selector_archivos_mass.dart';
import 'selector_modo_escaner.dart';

typedef SolicitudCamara =
    Future<SituacionCamara> Function(BuildContext context, String motivo);
typedef BuscarCupon = Future<CuponDescuento?> Function(String codigo);
typedef BuscarProducto =
    Future<Producto?> Function(String codigo, bool manual);
typedef ElegirArchivo = Future<ArchivoElegido?> Function();
typedef RegistrarArchivo =
    Future<ResultadoRegistroArchivo> Function(
      ArchivoElegido archivo,
      String categoria,
    );

class EscanerHerramientasScreen extends StatefulWidget {
  final int tabInicial;
  final bool volverAlCarrito;
  final bool? esAdmin;
  final SolicitudCamara? solicitarCamara;
  final BuscarCupon? buscarCupon;
  final BuscarProducto? buscarProducto;
  final ElegirArchivo? elegirArchivo;
  final RegistrarArchivo? registrarArchivo;
  final Widget Function(ValueChanged<String> alLeer)? vistaCamara;
  final Future<void> Function()? alIniciarCamara;
  final Future<void> Function()? alLiberarCamara;
  final Future<void> Function()? alPausarCamara;
  final Future<bool> Function()? alternarLinterna;
  final Future<bool> Function()? cambiarCamara;

  const EscanerHerramientasScreen({
    super.key,
    this.tabInicial = 0,
    this.volverAlCarrito = false,
    this.esAdmin,
    this.solicitarCamara,
    this.buscarCupon,
    this.buscarProducto,
    this.elegirArchivo,
    this.registrarArchivo,
    this.vistaCamara,
    this.alIniciarCamara,
    this.alLiberarCamara,
    this.alPausarCamara,
    this.alternarLinterna,
    this.cambiarCamara,
  });

  @override
  State<EscanerHerramientasScreen> createState() =>
      _EscanerHerramientasScreenState();
}

class _EscanerHerramientasScreenState extends State<EscanerHerramientasScreen>
    with WidgetsBindingObserver {
  final _codigoManual = TextEditingController();
  final _codigoBarras = TextEditingController();
  final _compuerta = CompuertaLectura();

  late int _modo = widget.tabInicial.clamp(0, 2);
  bool _camaraActiva = false;
  bool _abriendo = false;
  bool _procesando = false;
  bool _sesionCamara = false;
  bool _linternaReal = false;
  bool _cambiarReal = false;
  SituacionCamara? _permiso;
  MobileScannerController? _control;

  CuponDescuento? _cupon;
  EstadoCuponVisual? _estadoCupon;
  String _mensajeCupon = '';
  Producto? _producto;
  String? _codigoLeido;
  bool _noEncontrado = false;
  String? _errorProducto;

  String _categoria = SelectorArchivosMass.categorias.first;
  String? _errorArchivo;
  final List<ArchivoSesion> _archivos = [];

  bool get _esAdmin =>
      widget.esAdmin ?? AuthService.instance.usuario?.esAdmin == true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed || !_sesionCamara) return;
    final control = _control;
    if (control != null) unawaited(control.stop());
    final pausar = widget.alPausarCamara;
    if (pausar != null) unawaited(pausar());
  }

  bool get _mostrarLinterna =>
      widget.alternarLinterna != null || _linternaReal;

  bool get _mostrarCambio => widget.cambiarCamara != null || _cambiarReal;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _codigoManual.dispose();
    _codigoBarras.dispose();
    final control = _control;
    _control = null;
    control?.removeListener(_alEstadoCamara);
    control?.dispose();
    if (_sesionCamara) {
      _sesionCamara = false;
      widget.alLiberarCamara?.call();
    }
    super.dispose();
  }

  Future<void> _cambiarModo(int modo) async {
    if (_modo == modo) return;
    await _cerrarCamara();
    if (!mounted) return;
    setState(() {
      _modo = modo;
      _limpiarLectura();
    });
  }

  void _limpiarLectura() {
    _compuerta.reanudar();
    _cupon = null;
    _estadoCupon = null;
    _mensajeCupon = '';
    _producto = null;
    _codigoLeido = null;
    _noEncontrado = false;
    _errorProducto = null;
    _procesando = false;
  }

  Future<void> _activarCamara() async {
    if (_abriendo || _modo == 2) return;
    _abriendo = true;
    final pedir = widget.solicitarCamara ??
        (context, motivo) =>
            PermisosService.situacionCamara(context, motivo: motivo);
    final motivo = _modo == 0
        ? 'leer códigos QR de cupones'
        : 'leer códigos de barras de productos';
    final situacion = await pedir(context, motivo);
    if (!mounted) return;
    if (situacion != SituacionCamara.concedida) {
      setState(() => _permiso = situacion);
      _abriendo = false;
      return;
    }
    await widget.alIniciarCamara?.call();
    if (!mounted) return;
    _sesionCamara = true;
    if (widget.vistaCamara == null) {
      final control = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
      control.addListener(_alEstadoCamara);
      _control = control;
    }
    setState(() {
      _camaraActiva = true;
      _permiso = SituacionCamara.concedida;
    });
    _abriendo = false;
  }

  void _alEstadoCamara() {
    final estado = _control?.value;
    if (estado == null || !mounted) return;
    final linterna = estado.torchState != TorchState.unavailable;
    final camaras = estado.availableCameras;
    final cambiar = camaras == null || camaras >= 2;
    if (linterna == _linternaReal && cambiar == _cambiarReal) return;
    setState(() {
      _linternaReal = linterna;
      _cambiarReal = cambiar;
    });
  }

  Future<void> _cerrarCamara() async {
    final control = _control;
    _control = null;
    control?.removeListener(_alEstadoCamara);
    _linternaReal = false;
    _cambiarReal = false;
    if (_camaraActiva && mounted) {
      setState(() => _camaraActiva = false);
    } else {
      _camaraActiva = false;
    }
    if (_sesionCamara) {
      _sesionCamara = false;
      await widget.alLiberarCamara?.call();
    }
    try {
      await control?.dispose();
    } catch (_) {}
  }

  Future<void> _linterna() async {
    if (widget.alternarLinterna != null) {
      final ok = await widget.alternarLinterna!.call();
      if (!ok && mounted) setState(() {});
      return;
    }
    try {
      await _control?.toggleTorch();
    } catch (_) {
      if (mounted) setState(() => _linternaReal = false);
    }
  }

  Future<void> _cambiarCamara() async {
    if (widget.cambiarCamara != null) {
      await widget.cambiarCamara!.call();
      return;
    }
    try {
      await _control?.switchCamera();
    } catch (_) {
      if (mounted) setState(() => _cambiarReal = false);
    }
  }

  Future<void> _reanudar() async {
    setState(_limpiarLectura);
    try {
      await _control?.start();
    } catch (_) {}
  }

  Future<void> _alLeer(String raw) async {
    if (_compuerta.ocupada || _procesando) return;
    if (_modo == 0) {
      await _procesarQr(raw);
    } else if (_modo == 1) {
      await _procesarBarras(raw, manual: false);
    }
  }

  Future<CuponDescuento?> _resolverCupon(String codigo) {
    if (widget.buscarCupon != null) return widget.buscarCupon!(codigo);
    return _buscarCuponRegistrado(codigo);
  }

  Future<CuponDescuento?> _buscarCuponRegistrado(String codigo) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('cupones_mass')
          .where('codigo', isEqualTo: codigo)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final doc = snap.docs.first;
        return CuponDescuento.fromMap(doc.id, doc.data());
      }
    } catch (_) {}
    return CuponDescuento.predeterminados
        .where((cupon) => cupon.codigo == codigo)
        .firstOrNull;
  }

  Future<void> _procesarQr(String raw) async {
    final previo = CuponDescuento.extraerCodigoDesdeQr(raw);
    if (previo.isEmpty) {
      setState(() {
        _cupon = null;
        _estadoCupon = EstadoCuponVisual.inexistente;
        _mensajeCupon = 'El código no tiene un cupón reconocible.';
      });
      return;
    }
    if (!_compuerta.aceptar(previo)) return;
    setState(() => _procesando = true);
    try {
      final cupon = await _resolverCupon(previo);
      if (!mounted) return;
      final carrito = CarritoService.instance;
      final decision = decidirCupon(
        raw: raw,
        cupon: cupon,
        carritoVacio: carrito.vacio,
        subtotal: carrito.subtotal,
      );
      var estado = decision.estado;
      var mensaje = decision.mensaje;
      if (decision.aplicar && cupon != null) {
        final error = carrito.aplicarCupon(cupon);
        if (error == null) {
          estado = EstadoCuponVisual.aplicado;
          mensaje = 'Cupón ${cupon.codigo} aplicado al carrito.';
        } else {
          estado = error.contains('activo')
              ? EstadoCuponVisual.inactivo
              : EstadoCuponVisual.condiciones;
          mensaje = error;
        }
      }
      setState(() {
        _cupon = cupon;
        _estadoCupon = estado;
        _mensajeCupon = mensaje;
      });
      await _control?.pause();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cupon = null;
        _estadoCupon = EstadoCuponVisual.error;
        _mensajeCupon = 'No se pudo validar el cupón.';
      });
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<Producto?> _resolverProducto(String codigo, bool manual) {
    if (widget.buscarProducto != null) {
      return widget.buscarProducto!(codigo, manual);
    }
    return _buscarProductoRegistrado(codigo, manual);
  }

  Future<Producto?> _buscarProductoRegistrado(String codigo, bool manual) async {
    final sesion = CatalogoSesion.instancia;
    if (sesion.productos.isNotEmpty) {
      return productoPorCodigo(
        sesion.productos,
        codigo,
        permitirNombre: manual,
      );
    }
    final snap = await FirebaseFirestore.instance
        .collection('productos_mass')
        .get();
    final productos = [
      for (final doc in snap.docs) Producto.fromMap(doc.id, doc.data()),
    ];
    return productoPorCodigo(productos, codigo, permitirNombre: manual);
  }

  Future<void> _procesarBarras(String raw, {required bool manual}) async {
    final limpio = raw.trim();
    if (limpio.isEmpty || !_compuerta.aceptar(limpio)) return;
    setState(() {
      _procesando = true;
      _producto = null;
      _noEncontrado = false;
      _errorProducto = null;
      _codigoLeido = limpio;
    });
    try {
      final producto = await _resolverProducto(limpio, manual);
      if (!mounted) return;
      setState(() {
        _producto = producto;
        _noEncontrado = producto == null;
      });
      await _control?.pause();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorProducto = 'No se pudo consultar el catálogo en este momento.';
      });
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  void _agregarProducto() {
    final producto = _producto;
    if (producto == null || !mounted) return;
    final ok = CarritoService.instance.agregar(producto);
    mostrarMensaje(
      context,
      ok
          ? '${producto.nombre} agregado al carrito.'
          : 'Producto sin stock disponible.',
    );
  }

  Future<void> _seleccionarArchivo() async {
    if (_procesando) return;
    setState(() {
      _procesando = true;
      _errorArchivo = null;
    });
    try {
      final archivo = await (widget.elegirArchivo ?? _elegirArchivo)();
      if (archivo == null || !mounted) return;
      final validez = validarArchivoElegido(archivo);
      if (validez != EstadoArchivoLectura.valido) {
        setState(() => _errorArchivo = mensajeArchivoInvalido(validez));
        return;
      }
      final registro = await (widget.registrarArchivo ?? _registrarArchivo)(
        archivo,
        _categoria,
      );
      if (!mounted) return;
      if (registro.error != null) {
        setState(() => _errorArchivo = registro.error);
        return;
      }
      setState(() {
        _archivos.insert(
          0,
          ArchivoSesion(
            nombre: archivo.nombre,
            extension: archivo.extension,
            tamanoBytes: archivo.tamanoBytes,
            categoria: _categoria,
            resultado: registro.enNube
                ? 'Metadatos registrados. El archivo no se almacenó.'
                : 'Solo en esta sesión. No se registró en la nube.',
          ),
        );
      });
    } catch (_) {
      if (mounted) {
        setState(() => _errorArchivo = 'No se pudo procesar el archivo.');
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<ArchivoElegido?> _elegirArchivo() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensionesArchivoPermitidas.toList(),
      withData: false,
    );
    if (resultado == null || resultado.files.isEmpty) return null;
    final archivo = resultado.files.first;
    return ArchivoElegido(
      nombre: archivo.name,
      extension: (archivo.extension ?? '').toLowerCase(),
      tamanoBytes: archivo.size,
    );
  }

  Future<ResultadoRegistroArchivo> _registrarArchivo(
    ArchivoElegido archivo,
    String categoria,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('archivos_subidos').add({
        'nombre': archivo.nombre,
        'extension': archivo.extension.toLowerCase(),
        'tamanoBytes': archivo.tamanoBytes,
        'categoria': categoria,
        'usuarioCorreo': AuthService.instance.usuario?.correo ?? 'invitado',
        'fecha': Timestamp.fromDate(DateTime.now()),
      });
      return const ResultadoRegistroArchivo(enNube: true);
    } catch (_) {
      return const ResultadoRegistroArchivo(enNube: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Scaffold(
      backgroundColor: tokens.fondo,
      appBar: AppBar(title: const Text('Escáner Mass')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              'QR, códigos de barras y archivos',
              style: textoMass(tamano: 13, color: tokens.tintaSuave),
            ),
          ),
          SelectorModoEscaner(indice: _modo, alElegir: _cambiarModo),
          Expanded(child: _cuerpo()),
        ],
      ),
    );
  }

  Widget _cuerpo() {
    if (_modo == 2) return _archivosVista();
    if (_camaraActiva) return _visor();
    return _preparacion();
  }

  Widget _visor() {
    final tokens = TokensMass.de(context);
    final instrucciones = _modo == 0
        ? 'Apunta el código QR. La guía es solo visual.'
        : 'Alinea el código de barras. La guía es solo visual.';
    return Stack(
      children: [
        Positioned.fill(child: _superficieCamara()),
        Positioned.fill(child: MarcoEscanerMass(barras: _modo == 1)),
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.superficie.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                instrucciones,
                textAlign: TextAlign.center,
                style: textoMass(tamano: 12, color: tokens.profundo),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ControlesCamara(
                linterna: _mostrarLinterna,
                cambiarCamara: _mostrarCambio,
                alLinterna: _linterna,
                alCambiarCamara: _cambiarCamara,
                alReiniciar: _reanudar,
                alCerrar: _cerrarCamara,
              ),
              if (_resultado != null)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.46,
                  ),
                  child: SingleChildScrollView(child: _resultado),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _superficieCamara() {
    final vista = widget.vistaCamara;
    if (vista != null) {
      return ColoredBox(
        color: TokensMass.de(context).profundo,
        child: vista(_alLeer),
      );
    }
    final control = _control;
    if (control == null) return const SizedBox.shrink();
    return MobileScanner(
      controller: control,
      onDetect: (capture) {
        final raw = capture.barcodes.firstOrNull?.rawValue;
        if (raw != null && raw.isNotEmpty) _alLeer(raw);
      },
      placeholderBuilder: (context) => ColoredBox(
        color: TokensMass.de(context).profundo,
        child: Center(
          child: Text(
            'Preparando cámara',
            style: textoMass(color: Colors.white),
          ),
        ),
      ),
      errorBuilder: (context, error) => const ColoredBox(
        color: Color(0xFF06206A),
        child: Center(
          child: EstadoPermisoCamara(
            situacion: SituacionCamara.noDisponible,
            alReintentar: null,
          ),
        ),
      ),
    );
  }

  Widget _preparacion() {
    final tokens = TokensMass.de(context);
    final qr = _modo == 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.profundo,
            borderRadius: BorderRadius.circular(18),
          ),
          child: SizedBox(
            height: 168,
            child: Stack(
              children: [
                Positioned.fill(child: MarcoEscanerMass(barras: !qr)),
                Center(
                  child: Icon(
                    qr ? Icons.qr_code_2_rounded : Icons.barcode_reader,
                    color: tokens.sello,
                    size: qr ? 36 : 28,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          qr ? 'Cupón por código QR' : 'Producto por código de barras',
          style: textoMass(
            tamano: 16,
            peso: FontWeight.w700,
            color: tokens.profundo,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          qr
              ? 'La cámara lee el código y valida el cupón. No abre enlaces.'
              : 'Si el código existe en el catálogo, verás el producto antes de agregarlo.',
          style: textoMass(tamano: 13, color: tokens.tintaSuave),
        ),
        if (_permiso != null && _permiso != SituacionCamara.concedida) ...[
          const SizedBox(height: 8),
          EstadoPermisoCamara(
            situacion: _permiso!,
            alReintentar: _activarCamara,
          ),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const Key('activar-camara'),
          onPressed: _activarCamara,
          style: FilledButton.styleFrom(
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            textStyle: textoMass(peso: FontWeight.w700, color: Colors.white),
          ),
          icon: const Icon(Icons.photo_camera_rounded, color: Colors.white),
          label: const Text('Activar cámara'),
        ),
        const SizedBox(height: 16),
        Text(
          qr ? 'Escribir el código' : 'Escribir el código o el nombre exacto',
          style: textoMass(tamano: 14, peso: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: Key(qr ? 'codigo-manual' : 'codigo-barras'),
                controller: qr ? _codigoManual : _codigoBarras,
                textCapitalization: qr
                    ? TextCapitalization.characters
                    : TextCapitalization.none,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: qr ? 'MASS10' : 'Código de barras',
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              key: Key(qr ? 'aplicar-codigo' : 'buscar-barras'),
              onPressed: _procesando
                  ? null
                  : () => qr
                        ? _procesarQr(_codigoManual.text)
                        : _procesarBarras(_codigoBarras.text, manual: true),
              style: FilledButton.styleFrom(
                foregroundColor: Colors.white,
                minimumSize: const Size(48, 48),
                textStyle: textoMass(peso: FontWeight.w700, color: Colors.white),
              ),
              child: Text(qr ? 'Validar' : 'Buscar'),
            ),
          ],
        ),
        if (_resultado != null) ...[
          const SizedBox(height: 12),
          _resultado!,
        ],
        if (qr) ...[
          const SizedBox(height: 16),
          Text(
            'Cupones de la aplicación',
            style: textoMass(
              tamano: 14,
              peso: FontWeight.w700,
              color: tokens.profundo,
            ),
          ),
          const SizedBox(height: 8),
          for (final cupon in CuponDescuento.predeterminados)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tokens.superficie,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tokens.linea),
                ),
                child: ListTile(
                  title: Text(
                    '${cupon.codigo} · ${cupon.etiquetaDescuento}',
                    style: textoMass(tamano: 14, peso: FontWeight.w700),
                  ),
                  subtitle: Text(
                    cupon.descripcion,
                    style: textoMass(tamano: 12, color: tokens.tintaSuave),
                  ),
                  trailing: TextButton(
                    key: Key('usar-${cupon.codigo}'),
                    onPressed: _procesando ? null : () => _procesarQr(cupon.codigo),
                    child: const Text('Usar'),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget? get _resultado {
    if (_errorProducto != null) {
      return _aviso(_errorProducto!);
    }
    if (_estadoCupon != null) {
      return ResultadoCupon(
        cupon: _cupon,
        estado: _estadoCupon!,
        mensaje: _mensajeCupon,
        alEscanearDeNuevo: _reanudar,
        alVolverAlCarrito: widget.volverAlCarrito
            ? () => Navigator.maybePop(context)
            : null,
      );
    }
    if (_producto != null) {
      return ResultadoProducto(
        producto: _producto!,
        alAgregar: _agregarProducto,
        alEscanearDeNuevo: _reanudar,
      );
    }
    if (_noEncontrado && _codigoLeido != null) {
      return ProductoNoEncontrado(
        codigo: _codigoLeido!,
        alEscanearDeNuevo: _reanudar,
        alRegistrar: _esAdmin
            ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductoFormScreen(
                    codigoBarrasInicial: _codigoLeido,
                  ),
                ),
              )
            : null,
      );
    }
    return null;
  }

  Widget _aviso(String texto) {
    final tokens = TokensMass.de(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.linea),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              texto,
              style: textoMass(tamano: 13, color: tokens.error),
            ),
            TextButton(
              key: const Key('escanear-de-nuevo'),
              onPressed: _reanudar,
              child: const Text('Escanear de nuevo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _archivosVista() {
    return SelectorArchivosMass(
      categoria: _categoria,
      alElegirCategoria: (valor) => setState(() => _categoria = valor),
      alSeleccionar: _seleccionarArchivo,
      procesando: _procesando,
      error: _errorArchivo,
      archivos: _archivos,
      alQuitar: (archivo) => setState(() => _archivos.remove(archivo)),
    );
  }
}
