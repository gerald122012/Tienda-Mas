import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/local_comercial.dart';
import '../../services/firebase_service.dart';
import '../../utils/utilidades.dart';
import '../../utils/validaciones.dart';
import '../../widgets/campo_fecha.dart';

class LocalFormScreen extends StatefulWidget {
  final LocalComercial? local;

  const LocalFormScreen({super.key, this.local});

  @override
  State<LocalFormScreen> createState() => _LocalFormScreenState();
}

class _LocalFormScreenState extends State<LocalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scroll = ScrollController();
  bool _guardando = false;
  final _servicio = FirebaseService('locales_mass');

  bool get _esNuevo => (widget.local?.id ?? '').isEmpty;

  final _propietario = TextEditingController();
  final _documento = TextEditingController();
  final _distritoCiudad = TextEditingController();
  final _precioPorM2 = TextEditingController(text: '25');
  final _areaM2 = TextEditingController(text: '200');
  final _descuento = TextEditingController(text: '0');
  final _notas = TextEditingController();
  String? _modalidad;
  String _estado = 'evaluando';
  bool _enEsquina = false;
  DateTime _fechaRegistro = DateTime.now();
  DateTime _fechaDisponibilidad = DateTime.now().add(const Duration(days: 15));
  List<String> _caracteristicas = [];

  @override
  void initState() {
    super.initState();
    final l = widget.local;
    if (l != null) {
      _propietario.text = l.propietario;
      _documento.text = l.documento;
      _distritoCiudad.text = l.distritoCiudad;
      _precioPorM2.text = l.precioPorM2.toString();
      _areaM2.text = l.areaM2.toString();
      _descuento.text = l.bonificacionPorcentaje.toString();
      _notas.text = l.notas;
      _modalidad = l.modalidad;
      _estado = l.estado;
      _enEsquina = l.enEsquina;
      _fechaRegistro = l.fechaRegistro;
      _fechaDisponibilidad = l.fechaDisponibilidad;
      _caracteristicas = List.of(l.caracteristicas);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _propietario.dispose();
    _documento.dispose();
    _distritoCiudad.dispose();
    _precioPorM2.dispose();
    _areaM2.dispose();
    _descuento.dispose();
    _notas.dispose();
    super.dispose();
  }

  double get _rentaFinal => LocalComercial.calcularRentaFinal(
    leerDouble(_precioPorM2.text),
    leerEntero(_areaM2.text),
    leerDouble(_descuento.text),
    _enEsquina,
  );

  Future<void> _guardar() async {
    if (_guardando || !_formKey.currentState!.validate()) return;

    if (!_fechaDisponibilidad.isAfter(_fechaRegistro)) {
      mostrarMensaje(
        context,
        'La fecha de disponibilidad debe ser posterior al registro',
      );
      return;
    }
    if (_rentaFinal <= 0) {
      mostrarMensaje(context, 'La renta estimada debe ser mayor a 0');
      return;
    }
    if (_caracteristicas.isEmpty) {
      mostrarMensaje(
        context,
        'Selecciona al menos una característica del local',
      );
      return;
    }

    final local = LocalComercial(
      id: widget.local?.id ?? '',
      propietario: _propietario.text.trim(),
      documento: _documento.text.trim(),
      distritoCiudad: _distritoCiudad.text.trim(),
      modalidad: _modalidad!,
      precioPorM2: leerDouble(_precioPorM2.text),
      areaM2: leerEntero(_areaM2.text),
      bonificacionPorcentaje: leerDouble(_descuento.text),
      rentaFinal: _rentaFinal,
      fechaRegistro: _fechaRegistro,
      fechaDisponibilidad: _fechaDisponibilidad,
      estado: _estado,
      enEsquina: _enEsquina,
      caracteristicas: _caracteristicas,
      notas: _notas.text.trim(),
    );

    setState(() => _guardando = true);
    try {
      await _servicio.guardar(local.id, local.toMap());
      if (!mounted) return;
      mostrarMensaje(context, 'Local comercial registrado correctamente');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      mostrarMensaje(context, 'Error al guardar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoOriginal = _esNuevo ? 'evaluando' : widget.local!.estado;

    return Scaffold(
      appBar: AppBar(
        title: Text(_esNuevo ? 'Ofrece tu Local a Mass' : 'Editar Local Mass'),
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
            label: Text(_guardando ? 'Guardando...' : 'REGISTRAR LOCAL'),
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
                  controller: _propietario,
                  decoration: const InputDecoration(
                    labelText: 'Propietario / Contacto *',
                  ),
                  validator: obligatorio,
                ),
                TextFormField(
                  controller: _documento,
                  decoration: const InputDecoration(
                    labelText: 'Documento (DNI 8 dígitos) *',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  validator: documentoValido,
                ),
                TextFormField(
                  controller: _distritoCiudad,
                  decoration: const InputDecoration(
                    labelText: 'Distrito y Dirección del local *',
                  ),
                  validator: obligatorio,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _modalidad,
                  decoration: const InputDecoration(
                    labelText: 'Modalidad de oferta *',
                  ),
                  items: LocalComercial.modalidades
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (valor) => _modalidad = valor,
                  validator: (valor) =>
                      valor == null ? 'Seleccione una modalidad' : null,
                ),
                TextFormField(
                  controller: _precioPorM2,
                  decoration: const InputDecoration(
                    labelText: 'Precio solicitado por m² (S/) *',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: mayorACero,
                  onChanged: (_) => setState(() {}),
                ),
                TextFormField(
                  controller: _areaM2,
                  decoration: const InputDecoration(
                    labelText:
                        'Área del local en m² (mínimo 200 m² sugerido) *',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (valor) => enteroMinimo(valor, 50),
                  onChanged: (_) => setState(() {}),
                ),
                TextFormField(
                  controller: _descuento,
                  decoration: const InputDecoration(
                    labelText: 'Descuento por contrato largo (%) *',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (valor) => numeroEnRango(valor, 0, 100),
                  onChanged: (_) => setState(() {}),
                ),
                SwitchListTile(
                  title: const Text('Local ubicado en esquina comercial'),
                  subtitle: Text(
                    '+ S/ ${LocalComercial.bonoEsquinaPorM2.toStringAsFixed(0)} adicional por m²',
                  ),
                  value: _enEsquina,
                  onChanged: (valor) => setState(() => _enEsquina = valor),
                ),
                CampoFecha(
                  etiqueta: 'Fecha de registro',
                  fecha: _fechaRegistro,
                  onChanged: (fecha) => setState(() => _fechaRegistro = fecha),
                ),
                CampoFecha(
                  etiqueta: 'Fecha de disponibilidad del local',
                  fecha: _fechaDisponibilidad,
                  onChanged: (fecha) =>
                      setState(() => _fechaDisponibilidad = fecha),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _estado,
                  decoration: const InputDecoration(
                    labelText: 'Estado de evaluación *',
                  ),
                  items: LocalComercial.estados
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (valor) => _estado = valor!,
                  validator: (valor) =>
                      puedeCambiarEstado(estadoOriginal, valor!)
                      ? null
                      : 'Un local rechazado no puede pasar a aprobado',
                ),
                const Text(
                  'Características del local (Requisitos Tiendas Mass) *',
                  style: TextStyle(
                    color: kMassBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Wrap(
                  spacing: 6,
                  children: LocalComercial.caracteristicasDisponibles
                      .map(
                        (c) => FilterChip(
                          label: Text(c),
                          selected: _caracteristicas.contains(c),
                          selectedColor: kMassYellow,
                          onSelected: (marcado) => setState(() {
                            marcado
                                ? _caracteristicas.add(c)
                                : _caracteristicas.remove(c);
                          }),
                        ),
                      )
                      .toList(),
                ),
                TextFormField(
                  controller: _notas,
                  decoration: const InputDecoration(
                    labelText: 'Referencias o notas adicionales',
                  ),
                  maxLines: 2,
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kMassBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Renta mensual estimada: S/ ${_rentaFinal.toStringAsFixed(2)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: kMassYellow,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
