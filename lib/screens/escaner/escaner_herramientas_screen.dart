import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../main.dart';
import '../../models/cupon.dart';
import '../../models/producto.dart';
import '../../services/auth_service.dart';
import '../../services/carrito_service.dart';
import '../../services/permisos_service.dart';
import '../../utils/utilidades.dart';
import '../precios_mass/producto_form_screen.dart';

class _ArchivoSubido {
  final String id;
  final String nombre;
  final String extension;
  final int tamanoBytes;
  final DateTime fecha;
  final String categoria;

  const _ArchivoSubido({
    required this.id,
    required this.nombre,
    required this.extension,
    required this.tamanoBytes,
    required this.fecha,
    required this.categoria,
  });

  String get tamanoTexto {
    if (tamanoBytes < 1024) return '$tamanoBytes B';
    if (tamanoBytes < 1024 * 1024) {
      return '${(tamanoBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(tamanoBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class EscanerHerramientasScreen extends StatefulWidget {
  final int tabInicial;

  const EscanerHerramientasScreen({super.key, this.tabInicial = 0});

  @override
  State<EscanerHerramientasScreen> createState() =>
      _EscanerHerramientasScreenState();
}

class _EscanerHerramientasScreenState extends State<EscanerHerramientasScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _codigoManualCtrl = TextEditingController();
  final _barcodeManualCtrl = TextEditingController();

  bool _camaraActivaQr = false;
  bool _camaraActivaBarras = false;
  bool _procesandoCodigo = false;
  String? _ultimoQrLeido;
  String? _ultimoBarcodeLeido;
  Producto? _productoEncontrado;
  bool _buscandoProducto = false;

  String _categoriaArchivo = 'Comprobante de pago';
  bool _subiendoArchivo = false;
  final List<_ArchivoSubido> _archivosLocales = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.tabInicial.clamp(0, 2),
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _camaraActivaQr = false;
          _camaraActivaBarras = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codigoManualCtrl.dispose();
    _barcodeManualCtrl.dispose();
    super.dispose();
  }

  Future<void> _activarCamaraQr() async {
    final ok = await PermisosService.solicitarPermisoCamara(
      context,
      motivo: 'escanear códigos QR de descuento Tiendas Mass',
    );
    if (!ok || !mounted) return;
    setState(() {
      _camaraActivaQr = true;
      _camaraActivaBarras = false;
    });
  }

  Future<void> _activarCamaraBarras() async {
    final ok = await PermisosService.solicitarPermisoCamara(
      context,
      motivo: 'escanear códigos de barras de productos',
    );
    if (!ok || !mounted) return;
    setState(() {
      _camaraActivaBarras = true;
      _camaraActivaQr = false;
    });
  }

  Future<void> _procesarQrDescuento(String raw) async {
    if (_procesandoCodigo) return;
    final codigo = CuponDescuento.extraerCodigoDesdeQr(raw);
    if (codigo.isEmpty) return;

    setState(() {
      _procesandoCodigo = true;
      _ultimoQrLeido = codigo;
      _camaraActivaQr = false;
    });

    try {
      CuponDescuento? cupon;
      try {
        final snap = await FirebaseFirestore.instance
            .collection('cupones_mass')
            .where('codigo', isEqualTo: codigo)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          cupon = CuponDescuento.fromMap(
            snap.docs.first.id,
            snap.docs.first.data(),
          );
        }
      } catch (_) {}

      cupon ??= CuponDescuento.predeterminados
          .where((c) => c.codigo == codigo)
          .firstOrNull;

      if (!mounted) return;
      if (cupon == null) {
        mostrarMensaje(
          context,
          'El código "$codigo" no corresponde a un cupón válido.',
        );
        return;
      }

      final carrito = CarritoService.instance;
      if (carrito.vacio) {
        mostrarMensaje(
          context,
          'Cupón ${cupon.codigo} (${cupon.etiquetaDescuento}) válido. Agrega productos al carrito para aplicarlo.',
        );
        return;
      }
      final err = carrito.aplicarCupon(cupon);
      mostrarMensaje(
        context,
        err ??
            '¡Cupón ${cupon.codigo} aplicado! (${cupon.etiquetaDescuento})',
      );
    } finally {
      if (mounted) setState(() => _procesandoCodigo = false);
    }
  }

  Future<void> _buscarPorCodigoBarras(String codigo) async {
    final limpio = codigo.trim();
    if (limpio.isEmpty || _buscandoProducto) return;

    setState(() {
      _buscandoProducto = true;
      _ultimoBarcodeLeido = limpio;
      _productoEncontrado = null;
      _camaraActivaBarras = false;
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection('productos_mass')
          .get();
      final productos = snap.docs
          .map((d) => Producto.fromMap(d.id, d.data()))
          .toList();
      final match = productos.where((p) {
        return p.codigoBarras.trim() == limpio ||
            p.id == limpio ||
            p.nombre.toLowerCase().contains(limpio.toLowerCase());
      }).firstOrNull;

      if (!mounted) return;
      setState(() => _productoEncontrado = match);
      if (match == null) {
        mostrarMensaje(
          context,
          'No se encontró ningún producto con el código "$limpio".',
        );
      }
    } catch (_) {
      if (mounted) {
        mostrarMensaje(
          context,
          'No se pudo consultar el catálogo en este momento.',
        );
      }
    } finally {
      if (mounted) setState(() => _buscandoProducto = false);
    }
  }

  Future<void> _seleccionarYSubirArchivo() async {
    if (_subiendoArchivo) return;
    setState(() => _subiendoArchivo = true);
    try {
      final resultado = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx', 'txt'],
        withData: false,
      );
      if (resultado == null || resultado.files.isEmpty) return;
      final f = resultado.files.first;
      final ahora = DateTime.now();
      final idLocal = 'file_${ahora.millisecondsSinceEpoch}';
      final usuario = AuthService.instance.usuario;

      String idGuardado = idLocal;
      try {
        final docRef = await FirebaseFirestore.instance
            .collection('archivos_subidos')
            .add({
              'nombre': f.name,
              'extension': (f.extension ?? '').toLowerCase(),
              'tamanoBytes': f.size,
              'categoria': _categoriaArchivo,
              'usuarioCorreo': usuario?.correo ?? 'invitado',
              'fecha': Timestamp.fromDate(ahora),
            });
        idGuardado = docRef.id;
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _archivosLocales.insert(
          0,
          _ArchivoSubido(
            id: idGuardado,
            nombre: f.name,
            extension: (f.extension ?? 'archivo').toUpperCase(),
            tamanoBytes: f.size,
            fecha: ahora,
            categoria: _categoriaArchivo,
          ),
        );
      });
      mostrarMensaje(context, 'Archivo "${f.name}" adjuntado correctamente.');
    } catch (_) {
      if (mounted) {
        mostrarMensaje(context, 'No se pudo seleccionar el archivo.');
      }
    } finally {
      if (mounted) setState(() => _subiendoArchivo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esAdmin = AuthService.instance.usuario?.esAdmin == true;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escáner y Archivos'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: kMassBlue,
          unselectedLabelColor: kMassBlue.withValues(alpha: 0.65),
          indicatorColor: kMassBlue,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_2), text: 'QR Descuento'),
            Tab(icon: Icon(Icons.barcode_reader), text: 'Cód. Barras'),
            Tab(icon: Icon(Icons.upload_file), text: 'Archivos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _tabQrDescuento(),
          _tabCodigoBarras(esAdmin),
          _tabSubidaArchivos(),
        ],
      ),
    );
  }

  Widget _tabQrDescuento() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: _camaraActivaQr
              ? SizedBox(
                  height: 260,
                  child: Stack(
                    children: [
                      MobileScanner(
                        onDetect: (capture) {
                          final raw = capture.barcodes.firstOrNull?.rawValue;
                          if (raw != null && raw.isNotEmpty) {
                            _procesarQrDescuento(raw);
                          }
                        },
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton.filled(
                          onPressed: () =>
                              setState(() => _camaraActivaQr = false),
                          icon: const Icon(Icons.close),
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 56,
                        color: kMassBlue,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Escanea un QR de descuento Mass',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: kMassBlue,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Apunta a un código QR promocional para aplicar el descuento directo en tu carrito.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: _activarCamaraQr,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('ACTIVAR CÁMARA QR'),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Ingresar código manualmente',
                  style: TextStyle(
                    color: kMassBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codigoManualCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          hintText: 'Ej. MASS10',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () =>
                          _procesarQrDescuento(_codigoManualCtrl.text),
                      child: const Text('APLICAR'),
                    ),
                  ],
                ),
                if (_ultimoQrLeido != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Último código leído: $_ultimoQrLeido',
                    style: const TextStyle(fontSize: 12, color: kMassBlue),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Cupones vigentes disponibles',
          style: TextStyle(
            color: kMassBlue,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        for (final c in CuponDescuento.predeterminados)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: kMassYellow,
                foregroundColor: kMassBlue,
                child: const Icon(Icons.local_offer),
              ),
              title: Text(
                '${c.codigo} · ${c.etiquetaDescuento}',
                style: const TextStyle(
                  color: kMassBlue,
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: Text(c.descripcion),
              trailing: TextButton(
                onPressed: () => _procesarQrDescuento(c.codigo),
                child: const Text('USAR'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _tabCodigoBarras(bool esAdmin) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: _camaraActivaBarras
              ? SizedBox(
                  height: 260,
                  child: Stack(
                    children: [
                      MobileScanner(
                        onDetect: (capture) {
                          final raw = capture.barcodes.firstOrNull?.rawValue;
                          if (raw != null && raw.isNotEmpty) {
                            _buscarPorCodigoBarras(raw);
                          }
                        },
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton.filled(
                          onPressed: () =>
                              setState(() => _camaraActivaBarras = false),
                          icon: const Icon(Icons.close),
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.barcode_reader,
                        size: 56,
                        color: kMassBlue,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Escáner de códigos de barras',
                        style: TextStyle(
                          color: kMassBlue,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Escanea el código de barras EAN/UPC de un producto para consultar su precio o agregarlo al carrito.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: _activarCamaraBarras,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('ESCANEAR CÓDIGO DE BARRAS'),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _barcodeManualCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ingresar código de barras o nombre',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _buscandoProducto
                      ? null
                      : () => _buscarPorCodigoBarras(_barcodeManualCtrl.text),
                  child: const Text('BUSCAR'),
                ),
              ],
            ),
          ),
        ),
        if (_buscandoProducto)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_productoEncontrado != null) ...[
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: kMassMint,
                foregroundColor: kMassBlue,
                child: Icon(Icons.inventory_2_outlined),
              ),
              title: Text(
                _productoEncontrado!.nombre,
                style: const TextStyle(
                  color: kMassBlue,
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: Text(
                '${_productoEncontrado!.marca} · ${formatoPrecio(_productoEncontrado!.precio)} · Stock: ${_productoEncontrado!.stock}',
              ),
              trailing: esAdmin
                  ? IconButton(
                      icon: const Icon(Icons.edit, color: kMassBlue),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductoFormScreen(
                            producto: _productoEncontrado,
                          ),
                        ),
                      ),
                    )
                  : FilledButton(
                      onPressed: () {
                        final ok = CarritoService.instance.agregar(
                          _productoEncontrado!,
                        );
                        mostrarMensaje(
                          context,
                          ok
                              ? '${_productoEncontrado!.nombre} agregado al carrito.'
                              : 'Producto sin stock disponible.',
                        );
                      },
                      child: const Text('AGREGAR'),
                    ),
            ),
          ),
        ] else if (_ultimoBarcodeLeido != null && !_buscandoProducto && esAdmin) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Código $_ultimoBarcodeLeido no registrado',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductoFormScreen(
                          codigoBarrasInicial: _ultimoBarcodeLeido,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('REGISTRAR PRODUCTO CON ESTE CÓDIGO'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _tabSubidaArchivos() {
    const categorias = [
      'Comprobante de pago',
      'Boleta / Factura',
      'Documento de local',
      'Otro documento',
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.cloud_upload_outlined,
                  size: 48,
                  color: kMassBlue,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Subir comprobantes o archivos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kMassBlue,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Adjunta vouchers de Yape/Plin, PDFs o documentos de soporte (JPG, PNG, PDF, DOC).',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _categoriaArchivo,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de documento',
                    isDense: true,
                  ),
                  items: categorias
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _categoriaArchivo = v);
                  },
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _subiendoArchivo ? null : _seleccionarYSubirArchivo,
                  icon: _subiendoArchivo
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.attach_file),
                  label: Text(
                    _subiendoArchivo ? 'ADJUNTANDO…' : 'SELECCIONAR ARCHIVO',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Archivos adjuntados en esta sesión',
          style: TextStyle(
            color: kMassBlue,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        if (_archivosLocales.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Aún no has subido archivos.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          for (final a in _archivosLocales)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: kMassMint,
                  foregroundColor: kMassBlue,
                  child: Icon(
                    a.extension == 'PDF'
                        ? Icons.picture_as_pdf
                        : Icons.insert_drive_file_outlined,
                  ),
                ),
                title: Text(
                  a.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${a.categoria} · ${a.extension} · ${a.tamanoTexto} · ${formatoFechaHora(a.fecha)}',
                ),
                trailing: IconButton(
                  tooltip: 'Quitar',
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    setState(() => _archivosLocales.remove(a));
                  },
                ),
              ),
            ),
      ],
    );
  }
}
