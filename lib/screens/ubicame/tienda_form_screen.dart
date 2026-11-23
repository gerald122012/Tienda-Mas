import 'package:flutter/material.dart';

import '../../models/tienda.dart';
import '../../services/firebase_service.dart';
import '../../utils/utilidades.dart';
import '../../utils/validaciones.dart';
import '../../widgets/campo_fecha.dart';
import '../../widgets/campo_lista.dart';

class TiendaFormScreen extends StatefulWidget {
  final Tienda? tienda;

  const TiendaFormScreen({super.key, this.tienda});

  @override
  State<TiendaFormScreen> createState() => _TiendaFormScreenState();
}

class _TiendaFormScreenState extends State<TiendaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scroll = ScrollController();
  bool _guardando = false;
  final _servicio = FirebaseService('tiendas_mass');

  bool get _esNuevo => (widget.tienda?.id ?? '').isEmpty;

  final _nombre = TextEditingController();
  final _distrito = TextEditingController();
  final _direccion = TextEditingController();
  final _horario = TextEditingController(text: '7:00 AM - 10:00 PM');
  final _cantidadProductos = TextEditingController(text: '800');
  final _latitud = TextEditingController();
  final _longitud = TextEditingController();
  String? _ciudad;
  bool _abierta = true;
  DateTime _fechaApertura = DateTime.now();
  List<String> _servicios = [];

  @override
  void initState() {
    super.initState();
    final t = widget.tienda;
    if (t != null) {
      _nombre.text = t.nombre;
      _ciudad = t.ciudad;
      _distrito.text = t.distrito;
      _direccion.text = t.direccion;
      _horario.text = t.horario;
      _cantidadProductos.text = t.cantidadProductos.toString();
      if (t.latitud != null) _latitud.text = t.latitud.toString();
      if (t.longitud != null) _longitud.text = t.longitud.toString();
      _abierta = t.abierta;
      _fechaApertura = t.fechaApertura;
      _servicios = List.of(t.servicios);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _nombre.dispose();
    _distrito.dispose();
    _direccion.dispose();
    _horario.dispose();
    _cantidadProductos.dispose();
    _latitud.dispose();
    _longitud.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando || !_formKey.currentState!.validate()) return;

    final errorFecha = fechaNoFutura(_fechaApertura);
    if (errorFecha != null) {
      mostrarMensaje(context, errorFecha);
      return;
    }
    if (_servicios.isEmpty) {
      mostrarMensaje(
        context,
        'Agrega al menos un servicio (ej. Yape / Plin, Tarjetas)',
      );
      return;
    }

    final cantidad = leerEntero(_cantidadProductos.text);
    final lat = _latitud.text.trim().isEmpty
        ? null
        : double.tryParse(_latitud.text.trim().replaceAll(',', '.'));
    final lng = _longitud.text.trim().isEmpty
        ? null
        : double.tryParse(_longitud.text.trim().replaceAll(',', '.'));

    final tienda = Tienda(
      id: widget.tienda?.id ?? '',
      nombre: _nombre.text.trim(),
      ciudad: _ciudad!,
      distrito: _distrito.text.trim(),
      direccion: _direccion.text.trim(),
      horario: _horario.text.trim(),
      cantidadProductos: cantidad,
      fechaApertura: _fechaApertura,
      abierta: _abierta && cantidad > 0,
      servicios: _servicios,
      latitud: lat,
      longitud: lng,
    );

    setState(() => _guardando = true);
    try {
      await _servicio.guardar(tienda.id, tienda.toMap());
      if (!mounted) return;
      mostrarMensaje(context, 'Tienda Mass guardada correctamente');
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
        title: Text(_esNuevo ? 'Nueva Tienda Mass' : 'Editar Tienda Mass'),
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
            label: Text(_guardando ? 'Guardando...' : 'GUARDAR TIENDA'),
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
                    labelText: 'Nombre de la tienda (ej. Mass Los Olivos) *',
                  ),
                  validator: (valor) => minimoCaracteres(valor, 3),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _ciudad,
                  decoration: const InputDecoration(labelText: 'Ciudad *'),
                  items: Tienda.ciudades
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (valor) => _ciudad = valor,
                  validator: (valor) =>
                      valor == null ? 'Seleccione una ciudad' : null,
                ),
                TextFormField(
                  controller: _distrito,
                  decoration: const InputDecoration(labelText: 'Distrito *'),
                  validator: (valor) => minimoCaracteres(valor, 3),
                ),
                TextFormField(
                  controller: _direccion,
                  decoration: const InputDecoration(labelText: 'Dirección *'),
                  validator: obligatorio,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latitud,
                        decoration: const InputDecoration(
                          labelText: 'Latitud GPS (opcional)',
                          hintText: '-12.0681',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _longitud,
                        decoration: const InputDecoration(
                          labelText: 'Longitud GPS (opcional)',
                          hintText: '-75.2103',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: _horario,
                  decoration: const InputDecoration(
                    labelText: 'Horario de atención *',
                  ),
                  validator: obligatorio,
                ),
                TextFormField(
                  controller: _cantidadProductos,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad de productos en tienda *',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (valor) => enteroMinimo(valor, 0),
                ),
                CampoFecha(
                  etiqueta: 'Fecha de inauguración',
                  fecha: _fechaApertura,
                  fechaMaxima: DateTime.now(),
                  onChanged: (fecha) => setState(() => _fechaApertura = fecha),
                ),
                CampoLista(
                  etiqueta: 'Agregar servicio (ej. Yape / Plin, Tarjetas)',
                  items: _servicios,
                ),
                SwitchListTile(
                  title: const Text('Tienda abierta al público'),
                  subtitle: const Text(
                    'Si tiene 0 productos se mostrará como cerrada',
                  ),
                  value: _abierta,
                  onChanged: (valor) => setState(() => _abierta = valor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
