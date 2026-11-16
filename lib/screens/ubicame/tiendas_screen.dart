import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/tienda.dart';
import '../../services/firebase_service.dart';
import '../../utils/utilidades.dart';
import '../../widgets/aparecer.dart';
import '../../widgets/botones_acciones.dart';
import 'tienda_form_screen.dart';

class TiendasScreen extends StatefulWidget {
  // Administrador: gestiona las sedes. Cliente: solo las consulta.
  final bool esAdmin;

  const TiendasScreen({super.key, this.esAdmin = false});

  @override
  State<TiendasScreen> createState() => _TiendasScreenState();
}

class _TiendasScreenState extends State<TiendasScreen> {
  final _servicio = FirebaseService('tiendas_mass');
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _datos = _servicio
      .coleccion
      .snapshots();
  String _ciudadFiltro = 'Todas';

  void _abrirFormulario([Tienda? tienda]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TiendaFormScreen(tienda: tienda)),
    );
  }

  void _duplicar(Tienda tienda) {
    _abrirFormulario(Tienda.fromMap('', tienda.toMap()));
  }

  Future<void> _eliminar(Tienda tienda) async {
    if (!await confirmarEliminar(context, tienda.nombre)) return;
    await _servicio.eliminar(tienda.id);
    if (!mounted) return;
    mostrarDeshacer(
      context,
      'Tienda Mass eliminada',
      () => _servicio.restaurar(tienda.id, tienda.toMap()),
    );
  }

  Future<void> _cargarEjemplos() async {
    for (final t in Tienda.ejemplos()) {
      await _servicio.guardar('', t.toMap());
    }
    if (mounted) {
      mostrarMensaje(context, 'Tiendas Mass de ejemplo cargadas');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMassCream,
      floatingActionButton: widget.esAdmin
          ? FloatingActionButton.extended(
              heroTag: 'tiendas_mass',
              onPressed: () => _abrirFormulario(),
              icon: const Icon(Icons.add_location_alt),
              label: const Text(
                'NUEVA TIENDA',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            )
          : null,
      body: Column(
        children: [
          // Encabezado inspirado en https://www.tiendasmass.com.pe/ubicame/
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: const BoxDecoration(
              color: kMassBlue,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const Text(
                  'BUSCA TU TIENDA MASS CERQUITA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kMassYellow,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                // Selector de ciudad como en la web Ubícame
                DropdownButtonFormField<String>(
                  initialValue: _ciudadFiltro,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por Ciudad',
                    prefixIcon: Icon(Icons.location_city, color: kMassBlue),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'Todas',
                      child: Text('TODAS LAS CIUDADES'),
                    ),
                    ...Tienda.ciudades.map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.toUpperCase()),
                      ),
                    ),
                  ],
                  onChanged: (valor) =>
                      setState(() => _ciudadFiltro = valor ?? 'Todas'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _datos,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar tiendas'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final todas = snapshot.data!.docs
                    .map((doc) => Tienda.fromMap(doc.id, doc.data()))
                    .toList();

                if (todas.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.store_mall_directory_outlined,
                            size: 56,
                            color: kMassBlue,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No hay sedes registradas en Ubícame',
                            style: TextStyle(
                              color: kMassBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (widget.esAdmin)
                            FilledButton.icon(
                              onPressed: _cargarEjemplos,
                              icon: const Icon(Icons.storefront),
                              label: const Text('CARGAR TIENDAS DE EJEMPLO'),
                            ),
                        ],
                      ),
                    ),
                  );
                }

                final tiendas = _ciudadFiltro == 'Todas'
                    ? todas
                    : todas.where((t) => t.ciudad == _ciudadFiltro).toList();

                if (tiendas.isEmpty) {
                  return const Center(
                    child: Text('No hay tiendas registradas en esta ciudad'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 85),
                  itemCount: tiendas.length,
                  itemBuilder: (context, i) =>
                      Aparecer(indice: i, child: _tarjeta(tiendas[i])),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjeta(Tienda t) {
    final abierta = t.estaAbierta;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: abierta ? kMassYellow : Colors.red.shade100,
              foregroundColor: abierta ? kMassBlue : Colors.red,
              child: const Icon(Icons.location_on),
            ),
            title: Text(
              t.nombre.toUpperCase(),
              style: const TextStyle(
                color: kMassBlue,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Text(
              '${t.distrito}, ${t.ciudad} · ${t.direccion}\n'
              'Horario: ${t.horario} · Surtido: ${t.cantidadProductos} prod.\n'
              '${abierta ? 'Abierta ahora' : 'Cerrada'} · ${t.servicios.join(', ')}',
            ),
            isThreeLine: true,
            onTap: widget.esAdmin ? () => _abrirFormulario(t) : null,
          ),
          if (widget.esAdmin)
            Align(
              alignment: Alignment.centerRight,
              child: BotonesAcciones(
                onDuplicar: () => _duplicar(t),
                onEditar: () => _abrirFormulario(t),
                onEliminar: () => _eliminar(t),
              ),
            ),
        ],
      ),
    );
  }
}
