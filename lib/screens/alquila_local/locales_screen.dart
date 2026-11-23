import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/local_comercial.dart';
import '../../services/firebase_service.dart';
import '../../utils/utilidades.dart';
import '../../utils/validaciones.dart';
import '../../widgets/botones_acciones.dart';
import 'local_form_screen.dart';

class LocalesScreen extends StatefulWidget {
  const LocalesScreen({super.key});

  @override
  State<LocalesScreen> createState() => _LocalesScreenState();
}

class _LocalesScreenState extends State<LocalesScreen> {
  final _servicio = FirebaseService('locales_mass');
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _datos = _servicio
      .coleccion
      .orderBy('fechaDisponibilidad')
      .snapshots();

  void _abrirFormulario([LocalComercial? local]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LocalFormScreen(local: local)),
    );
  }

  void _duplicar(LocalComercial local) {
    _abrirFormulario(LocalComercial.fromMap('', local.toMap()));
  }

  Future<void> _eliminar(LocalComercial local) async {
    if (!await confirmarEliminar(
      context,
      'local de ${local.propietario} (${local.distritoCiudad})',
    )) {
      return;
    }
    await _servicio.eliminar(local.id);
    if (!mounted) return;
    mostrarDeshacer(
      context,
      'Postulación de local eliminada',
      () => _servicio.restaurar(local.id, local.toMap()),
    );
  }

  Future<void> _cambiarEstado(LocalComercial local, String nuevo) async {
    if (!puedeCambiarEstado(local.estado, nuevo)) {
      mostrarMensaje(
        context,
        'Un local rechazado no puede pasar directamente a aprobado',
      );
      return;
    }
    await _servicio.guardar(local.id, {'estado': nuevo});
    if (mounted) mostrarMensaje(context, 'Estado actualizado a $nuevo');
  }

  Color _colorEstado(String estado) {
    if (estado == 'aprobado') return Colors.green;
    if (estado == 'rechazado') return Colors.red;
    return Colors.orange; // evaluando
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMassMint,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'locales_mass',
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add_business),
        label: const Text(
          'OFRECE TU LOCAL',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
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
                  'ALQUILA TU LOCAL A TIENDAS MASS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kMassYellow,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '¿Tienes un local comercial de 200 m² o más? ¡Regístralo aquí!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _paso('1', 'Registra tu local'),
                    const SizedBox(width: 6),
                    _paso('2', 'Evaluamos la zona'),
                    const SizedBox(width: 6),
                    _paso('3', 'Firmamos contrato'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _datos,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar locales'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final locales = snapshot.data!.docs
                    .map((doc) => LocalComercial.fromMap(doc.id, doc.data()))
                    .toList();

                if (locales.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.real_estate_agent_outlined,
                            size: 56,
                            color: kMassBlue,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No hay locales postulados todavía',
                            style: TextStyle(
                              color: kMassBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Toca "OFRECE TU LOCAL" para registrar una propuesta de local para una nueva tienda Mass.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 85),
                  itemCount: locales.length,
                  itemBuilder: (context, i) => _tarjeta(locales[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _paso(String numero, String texto) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        decoration: BoxDecoration(
          color: kMassYellow,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          '$numero. $texto',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: kMassBlue,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _tarjeta(LocalComercial l) {
    final color = _colorEstado(l.estado);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: kMassYellow,
              foregroundColor: kMassBlue,
              child: const Icon(Icons.store),
            ),
            title: Text(
              '${l.propietario} → ${l.distritoCiudad}',
              style: const TextStyle(
                color: kMassBlue,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Text(
              'Modalidad: ${l.modalidad} · Área: ${l.areaM2} m²\n'
              'Disponible: ${formatoFecha(l.fechaDisponibilidad)} · '
              'Renta est.: S/ ${l.rentaFinal.toStringAsFixed(2)}',
            ),
            isThreeLine: true,
            onTap: () => _abrirFormulario(l),
          ),
          Row(
            children: [
              const SizedBox(width: 16),
              PopupMenuButton<String>(
                tooltip: 'Cambiar estado',
                onSelected: (nuevo) => _cambiarEstado(l, nuevo),
                itemBuilder: (_) => LocalComercial.estados
                    .map((e) => PopupMenuItem(value: e, child: Text(e)))
                    .toList(),
                child: Chip(
                  avatar: Icon(Icons.circle, color: color, size: 14),
                  label: Text(l.estado.toUpperCase()),
                ),
              ),
              const Spacer(),
              BotonesAcciones(
                onDuplicar: () => _duplicar(l),
                onEditar: () => _abrirFormulario(l),
                onEliminar: () => _eliminar(l),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
