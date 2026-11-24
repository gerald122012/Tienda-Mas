import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../main.dart';
import '../../models/producto.dart';
import '../../services/firebase_service.dart';
import '../../utils/utilidades.dart';
import '../../utils/validaciones.dart';
import '../../widgets/campo_fecha.dart';
import '../../widgets/campo_lista.dart';

class ProductoFormScreen extends StatefulWidget {
  final Producto? producto;
  final String? codigoBarrasInicial;

  const ProductoFormScreen({
    super.key,
    this.producto,
    this.codigoBarrasInicial,
  });

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scroll = ScrollController();
  final _picker = ImagePicker();
  bool _guardando = false;
  bool _cargandoImagen = false;
  bool _quitarBase64 = false;
  Uint8List? _nuevaImagen;
  Uint8List? _base64Inicial;
  String _nombreArchivo = '';
  final _servicio = FirebaseService('productos_mass');

  bool get _esNuevo => (widget.producto?.id ?? '').isEmpty;

  final _imagenUrl = TextEditingController();
  final _codigoBarras = TextEditingController();
  final _nombre = TextEditingController();
  final _descripcion = TextEditingController();
  final _marca = TextEditingController();
  final _precio = TextEditingController();
  final _stock = TextEditingController();
  final _valoracion = TextEditingController(text: '5');
  String? _categoria;
  bool _disponible = true;
  DateTime _fechaRegistro = DateTime.now();
  List<String> _presentaciones = [];

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    if (p != null) {
      _imagenUrl.text = p.imagenUrl;
      _codigoBarras.text = p.codigoBarras;
      _nombre.text = p.nombre;
      _descripcion.text = p.descripcion;
      _marca.text = p.marca;
      _precio.text = p.precio.toString();
      _stock.text = p.stock.toString();
      _valoracion.text = p.valoracion.toString();
      _categoria = p.categoria;
      _disponible = p.disponible;
      _fechaRegistro = p.fechaRegistro;
      _presentaciones = List.of(p.presentaciones);
      _base64Inicial = decodificarImagenProducto(p.imagenBase64);
      if (_base64Inicial != null) _nombreArchivo = 'Imagen actual';
    } else if (widget.codigoBarrasInicial != null) {
      _codigoBarras.text = widget.codigoBarrasInicial!;
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _imagenUrl.dispose();
    _codigoBarras.dispose();
    _nombre.dispose();
    _descripcion.dispose();
    _marca.dispose();
    _precio.dispose();
    _stock.dispose();
    _valoracion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando || !_formKey.currentState!.validate()) return;

    final errorFecha = fechaNoFutura(_fechaRegistro);
    if (errorFecha != null) {
      mostrarMensaje(context, errorFecha);
      return;
    }
    if (_presentaciones.isEmpty) {
      mostrarMensaje(context, 'Agrega al menos una presentación (ej. 1 kg)');
      return;
    }

    final conservarFoto =
        _imagenUrl.text.trim() == (widget.producto?.imagenUrl ?? '');
    final producto = Producto(
      id: widget.producto?.id ?? '',
      codigoBarras: _codigoBarras.text.trim(),
      imagenUrl: _imagenUrl.text.trim(),
      imagenAsset: conservarFoto ? (widget.producto?.imagenAsset ?? '') : '',
      imagenAutor: conservarFoto ? (widget.producto?.imagenAutor ?? '') : '',
      imagenLicencia: conservarFoto
          ? (widget.producto?.imagenLicencia ?? '')
          : '',
      imagenFuente: conservarFoto ? (widget.producto?.imagenFuente ?? '') : '',
      imagenBase64: imagenBase64ParaGuardar(
        anterior: widget.producto?.imagenBase64 ?? '',
        nueva: _nuevaImagen,
        quitar: _quitarBase64,
      ),
      nombre: _nombre.text.trim(),
      descripcion: _descripcion.text.trim(),
      marca: _marca.text.trim().isEmpty ? 'Mass' : _marca.text.trim(),
      precio: leerDouble(_precio.text),
      stock: leerEntero(_stock.text),
      categoria: _categoria!,
      disponible: _disponible,
      fechaRegistro: _fechaRegistro,
      presentaciones: _presentaciones,
      valoracion: leerDouble(_valoracion.text),
    );

    setState(() => _guardando = true);
    try {
      await _servicio.guardar(producto.id, producto.toMap());
      if (!mounted) return;
      mostrarMensaje(context, 'Producto Mass guardado correctamente');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      mostrarMensaje(context, 'Error al guardar: $e');
    }
  }

  Uint8List? get _bytesVistaPrevia {
    if (_nuevaImagen != null) return _nuevaImagen;
    if (_quitarBase64) return null;
    return _base64Inicial;
  }

  bool get _puedeQuitarBase64 =>
      _nuevaImagen != null || (!_quitarBase64 && _base64Inicial != null);

  Future<void> _elegirImagen([ImageSource origen = ImageSource.gallery]) async {
    if (_cargandoImagen || _guardando) return;
    setState(() => _cargandoImagen = true);
    try {
      final archivo = await _picker.pickImage(
        source: origen,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 70,
        requestFullMetadata: false,
      );
      if (!mounted || archivo == null) return;
      final bytes = await archivo.readAsBytes();
      if (!mounted) return;
      final error = await validarImagenProducto(bytes);
      if (!mounted) return;
      if (error != null) {
        mostrarMensaje(context, error);
        return;
      }
      setState(() {
        _nuevaImagen = bytes;
        _nombreArchivo = archivo.name.trim().isEmpty
            ? 'imagen'
            : archivo.name.trim();
        _quitarBase64 = false;
      });
    } catch (_) {
      if (!mounted) return;
      mostrarMensaje(
        context,
        'No se pudo leer la imagen seleccionada. Se conservó la imagen anterior.',
      );
    } finally {
      if (mounted) setState(() => _cargandoImagen = false);
    }
  }

  void _quitarImagen() {
    setState(() {
      _nuevaImagen = null;
      _nombreArchivo = '';
      _quitarBase64 = true;
    });
  }

  Widget _vistaRespaldo() {
    final url = _imagenUrl.text.trim();
    final uri = Uri.tryParse(url);
    if (uri != null && uri.scheme == 'https' && uri.host.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _vistaAssetOVacio(),
      );
    }
    return _vistaAssetOVacio();
  }

  Widget _vistaAssetOVacio() {
    final asset = widget.producto?.imagenAsset.trim() ?? '';
    if (asset.isNotEmpty) {
      return Image.asset(
        asset,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _vistaVacia(),
      );
    }
    return _vistaVacia();
  }

  Widget _vistaVacia() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image_outlined, color: kMassBlue, size: 36),
        SizedBox(height: 6),
        Text(
          'Sin imagen cargada',
          style: TextStyle(color: kMassBlue, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _seccionImagen() {
    final bytes = _bytesVistaPrevia;
    final detalle = bytes != null
        ? '${_nombreArchivo.isEmpty ? 'Imagen actual' : _nombreArchivo} · ${textoPesoImagen(bytes.length)}'
        : _quitarBase64
        ? 'Imagen cargada quitada. Se aplicará al guardar.'
        : 'JPG o PNG · máximo 600 × 600 px y 150 KB';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Imagen del producto',
          style: TextStyle(
            color: kMassBlue,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'La imagen cargada tiene prioridad sobre la URL y se guarda al confirmar el producto.',
          style: TextStyle(fontSize: 12.5),
        ),
        const SizedBox(height: 8),
        Container(
          height: 180,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kMassBlue.withValues(alpha: 0.18)),
          ),
          child: _cargandoImagen
              ? const Center(child: CircularProgressIndicator())
              : bytes != null
              ? Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  semanticLabel: 'Vista previa del producto',
                  errorBuilder: (_, _, _) => _vistaRespaldo(),
                )
              : _vistaRespaldo(),
        ),
        const SizedBox(height: 8),
        Text(
          detalle,
          style: TextStyle(color: Colors.grey.shade800, fontSize: 12.5),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _cargandoImagen || _guardando ? null : _elegirImagen,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(bytes == null ? 'ELEGIR IMAGEN' : 'CAMBIAR IMAGEN'),
            ),
            OutlinedButton.icon(
              onPressed: _cargandoImagen || _guardando
                  ? null
                  : () => _elegirImagen(ImageSource.camera),
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('TOMAR FOTO'),
            ),
            TextButton.icon(
              onPressed: !_puedeQuitarBase64 || _cargandoImagen || _guardando
                  ? null
                  : _quitarImagen,
              icon: const Icon(Icons.hide_image_outlined),
              label: const Text('QUITAR IMAGEN'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esNuevo ? 'Nuevo producto Mass' : 'Editar producto Mass'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _guardando ? null : _guardar,
            icon: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_guardando ? 'Guardando...' : 'GUARDAR PRODUCTO'),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Scrollbar(
          controller: _scroll,
          thumbVisibility: true,
          interactive: true,
          child: SingleChildScrollView(
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            child: Column(
              spacing: 12,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nombre,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del producto *',
                  ),
                  validator: (valor) => minimoCaracteres(valor, 3),
                ),
                TextFormField(
                  controller: _descripcion,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  maxLines: 2,
                ),
                TextFormField(
                  controller: _marca,
                  decoration: const InputDecoration(
                    labelText: 'Marca (ej. Coca-Cola, Field, Gloria)',
                  ),
                ),
                TextFormField(
                  controller: _codigoBarras,
                  decoration: const InputDecoration(
                    labelText: 'Código de barras EAN/UPC (opcional)',
                    prefixIcon: Icon(Icons.barcode_reader),
                  ),
                ),
                _seccionImagen(),
                TextFormField(
                  controller: _imagenUrl,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'URL de la imagen (opcional)',
                    helperText:
                        'Opcional. Se usa cuando no hay una imagen cargada.',
                  ),
                  keyboardType: TextInputType.url,
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) return null;
                    final uri = Uri.tryParse(valor.trim());
                    return uri != null &&
                            uri.scheme == 'https' &&
                            uri.host.isNotEmpty
                        ? null
                        : 'Ingrese una URL HTTPS válida';
                  },
                ),
                TextFormField(
                  controller: _precio,
                  decoration: const InputDecoration(
                    labelText: 'Precio Mass (S/) *',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: mayorACero,
                ),
                TextFormField(
                  controller: _stock,
                  decoration: const InputDecoration(
                    labelText: 'Stock en bodega *',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (valor) => enteroMinimo(valor, 0),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _categoria,
                  decoration: const InputDecoration(
                    labelText: 'Categoría de bodega *',
                  ),
                  items: Producto.categorias
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (valor) => _categoria = valor,
                  validator: (valor) =>
                      valor == null ? 'Seleccione una categoría' : null,
                ),
                TextFormField(
                  controller: _valoracion,
                  decoration: const InputDecoration(
                    labelText: 'Valoración de caser@s (0 a 5)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (valor) => numeroEnRango(valor, 0, 5),
                ),
                CampoFecha(
                  etiqueta: 'Fecha de ingreso',
                  fecha: _fechaRegistro,
                  fechaMaxima: DateTime.now(),
                  onChanged: (fecha) => setState(() => _fechaRegistro = fecha),
                ),
                CampoLista(
                  etiqueta: 'Agregar presentación (ej. 1 kg, 900 ml, Pack)',
                  items: _presentaciones,
                ),
                SwitchListTile(
                  title: const Text('Disponible en tienda'),
                  value: _disponible,
                  onChanged: (valor) => setState(() => _disponible = valor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
