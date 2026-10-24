import 'package:flutter/material.dart';

import '../../models/producto.dart';
import '../../services/firebase_service.dart';
import '../../utils/utilidades.dart';
import '../../utils/validaciones.dart';
import '../../widgets/campo_fecha.dart';
import '../../widgets/campo_lista.dart';

class ProductoFormScreen extends StatefulWidget {
  final Producto? producto; // null = nuevo, con datos = editar

  const ProductoFormScreen({super.key, this.producto});

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scroll = ScrollController();
  bool _guardando = false;
  final _servicio = FirebaseService('productos_mass');

  bool get _esNuevo => (widget.producto?.id ?? '').isEmpty;

  final _imagenUrl = TextEditingController();
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
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _imagenUrl.dispose();
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
      imagenUrl: _imagenUrl.text.trim(),
      imagenAsset: conservarFoto ? (widget.producto?.imagenAsset ?? '') : '',
      imagenAutor: conservarFoto ? (widget.producto?.imagenAutor ?? '') : '',
      imagenLicencia: conservarFoto
          ? (widget.producto?.imagenLicencia ?? '')
          : '',
      imagenFuente: conservarFoto ? (widget.producto?.imagenFuente ?? '') : '',
      esEjemplo: widget.producto?.esEjemplo ?? false,
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
                  controller: _imagenUrl,
                  decoration: const InputDecoration(
                    labelText: 'URL de la imagen (opcional)',
                    helperText: 'Puedes agregar la foto más adelante.',
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
