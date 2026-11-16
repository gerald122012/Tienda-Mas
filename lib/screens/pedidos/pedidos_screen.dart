import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/pedido.dart';
import '../../services/firebase_service.dart';
import '../../utils/utilidades.dart';
import '../../widgets/aparecer.dart';

// Solo administrador: revisa las compras de los clientes y cambia su estado.
class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  final _servicio = FirebaseService('pedidos');
  late final _datos = _servicio.coleccion
      .orderBy('fecha', descending: true)
      .snapshots();
  String _filtro = 'todos';

  Color _color(String estado) => switch (estado) {
    'pendiente' => Colors.orange.shade800,
    'preparando' => kMassBlue,
    'entregado' => Colors.green.shade800,
    _ => Colors.red.shade800,
  };

  String _mayus(String t) => t[0].toUpperCase() + t.substring(1);

  Future<void> _cambiarEstado(Pedido p, String estado) async {
    try {
      await _servicio.guardar(p.id, {'estado': estado});
    } catch (_) {
      if (mounted) mostrarMensaje(context, 'No se pudo cambiar el estado.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMassCream,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              color: kMassBlue,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pedidos de clientes',
                  style: TextStyle(
                    color: kMassYellow,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    spacing: 6,
                    children: [
                      for (final e in ['todos', ...Pedido.estados])
                        ChoiceChip(
                          label: Text(
                            _mayus(e),
                            style: TextStyle(
                              color: _filtro == e ? kMassBlue : Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          selected: _filtro == e,
                          selectedColor: kMassYellow,
                          backgroundColor: kMassBlue,
                          side: const BorderSide(color: kMassYellow),
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _filtro = e),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _datos,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar pedidos'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final pedidos = snapshot.data!.docs
                    .map((d) => Pedido.fromMap(d.id, d.data()))
                    .where((p) => _filtro == 'todos' || p.estado == _filtro)
                    .toList();
                if (pedidos.isEmpty) {
                  return const Center(child: Text('No hay pedidos todavía.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: pedidos.length,
                  itemBuilder: (context, i) =>
                      Aparecer(indice: i, child: _tarjeta(pedidos[i])),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjeta(Pedido p) {
    final hora =
        '${p.fecha.hour.toString().padLeft(2, '0')}:${p.fecha.minute.toString().padLeft(2, '0')}';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          '${p.clienteNombre.isEmpty ? p.clienteCorreo : p.clienteNombre} · '
          'S/ ${p.total.toStringAsFixed(2)}',
          style: const TextStyle(color: kMassBlue, fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${formatoFecha(p.fecha)} $hora · ${p.items.length} productos',
        ),
        trailing: Chip(
          label: Text(
            _mayus(p.estado),
            style: TextStyle(
              color: _color(p.estado),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          side: BorderSide(color: _color(p.estado)),
          backgroundColor: Colors.white,
          visualDensity: VisualDensity.compact,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p.clienteCorreo.isNotEmpty) Text('Cliente: ${p.clienteCorreo}'),
          const SizedBox(height: 6),
          for (final i in p.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(child: Text('${i.cantidad} × ${i.nombre}')),
                  Text('S/ ${i.subtotal.toStringAsFixed(2)}'),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final e in Pedido.estados.where((e) => e != p.estado))
                OutlinedButton(
                  onPressed: () => _cambiarEstado(p, e),
                  child: Text('Marcar ${e.toLowerCase()}'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
