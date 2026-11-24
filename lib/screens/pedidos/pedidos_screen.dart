import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/pedido.dart';
import '../../services/firebase_service.dart';
import '../../services/pedidos_local_service.dart';
import '../../tema/tema_gestion.dart';
import '../../utils/utilidades.dart';
import '../admin/piezas_gestion.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  final _servicio = FirebaseService('pedidos');
  final _busqueda = TextEditingController();
  late final _datos = _servicio.coleccion.orderBy('fecha', descending: true).snapshots();
  String _filtro = 'todos';

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  String _etiqueta(String estado) => switch (estado) {
    'todos' => 'Todos',
    'pendiente' => 'Pendiente',
    'preparando' => 'En preparación',
    'entregado' => 'Entregado',
    'cancelado' => 'Cancelado',
    _ => 'Estado no reconocido',
  };

  Color _color(String estado) => switch (estado) {
    'pendiente' => GestionColores.profundo,
    'preparando' => GestionColores.accion,
    'entregado' => GestionColores.exito,
    'cancelado' => GestionColores.error,
    _ => GestionColores.tintaSuave,
  };

  Future<void> _cambiarEstado(Pedido pedido, String estado) async {
    try {
      await _servicio.guardar(pedido.id, {'estado': estado});
      if (mounted) mostrarMensaje(context, 'Estado actualizado a ${_etiqueta(estado).toLowerCase()}.');
    } catch (_) {
      if (mounted) mostrarMensaje(context, 'No se pudo cambiar el estado.');
    }
  }

  Future<void> _eliminar(Pedido pedido) async {
    final nombre = pedido.clienteNombre.isEmpty ? pedido.clienteCorreo : pedido.clienteNombre;
    if (!await confirmarEliminar(context, 'pedido de $nombre')) return;
    try {
      await _servicio.eliminar(pedido.id);
      await PedidosLocalService.instance.eliminarPedido(pedido.id);
      if (!mounted) return;
      mostrarDeshacer(
        context,
        'Pedido eliminado',
        () => _servicio.restaurar(pedido.id, pedido.toFirestoreMap()),
      );
    } catch (_) {
      if (mounted) mostrarMensaje(context, 'No se pudo eliminar el pedido.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PaginaGestion(
      titulo: 'Pedidos',
      detalle: 'Registros de compra. El importe es el guardado en el pedido, no un cobro confirmado.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _busqueda,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Buscar por cliente, correo o cupón',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final estado in ['todos', ...Pedido.estados])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_etiqueta(estado)),
                      selected: _filtro == estado,
                      showCheckmark: false,
                      selectedColor: GestionColores.sello,
                      labelStyle: textoGestion(
                        peso: FontWeight.w700,
                        color: _filtro == estado
                            ? GestionColores.profundo
                            : GestionColores.tinta,
                      ),
                      onSelected: (_) => setState(() => _filtro = estado),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _datos,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const EstadoGestion(
                    icono: Icons.cloud_off_rounded,
                    titulo: 'No pudimos consultar los pedidos',
                    mensaje: 'Revisa la conexión e inténtalo nuevamente.',
                  );
                }
                if (!snapshot.hasData) return const CargandoGestion();
                final consulta = _busqueda.text.trim().toLowerCase();
                final pedidos = snapshot.data!.docs
                    .map((doc) => Pedido.fromMap(doc.id, doc.data()))
                    .where((pedido) => _filtro == 'todos' || pedido.estado == _filtro)
                    .where((pedido) {
                      final texto =
                          '${pedido.clienteNombre} ${pedido.clienteCorreo} ${pedido.cuponCodigo}'
                              .toLowerCase();
                      return consulta.isEmpty || texto.contains(consulta);
                    })
                    .toList();
                if (snapshot.data!.docs.isEmpty) {
                  return const EstadoGestion(
                    icono: Icons.receipt_long_outlined,
                    titulo: 'No hay pedidos registrados',
                    mensaje: 'Cuando un cliente confirme una compra, aparecerá en esta lista.',
                  );
                }
                if (pedidos.isEmpty) {
                  return const EstadoGestion(
                    icono: Icons.filter_alt_off_outlined,
                    titulo: 'Ningún pedido coincide',
                    mensaje: 'Prueba con otro estado o con otro cliente.',
                  );
                }
                return ListView.separated(
                  itemCount: pedidos.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, indice) => _pedido(pedidos[indice]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _pedido(Pedido pedido) {
    final cliente = pedido.clienteNombre.isEmpty ? pedido.clienteCorreo : pedido.clienteNombre;
    final entrega = pedido.tipoEntrega == 'delivery' ? 'Delivery' : 'Recojo en tienda';
    return SuperficieGestion(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  cliente,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textoGestion(peso: FontWeight.w800, color: GestionColores.profundo),
                ),
              ),
              const SizedBox(width: 8),
              ChipGestion(
                texto: _etiqueta(pedido.estado),
                color: _color(pedido.estado),
                icono: Icons.circle,
              ),
            ],
          ),
          subtitle: Text(
            '${formatoFechaHora(pedido.fecha)} · ${pedido.totalUnidades} unidades · $entrega',
            style: textoGestion(tamano: 12, color: GestionColores.tintaSuave),
          ),
          trailing: Text(
            formatoPrecio(pedido.total),
            style: textoGestion(peso: FontWeight.w800, color: GestionColores.profundo),
          ),
          children: [
            _linea('Cliente', cliente),
            if (pedido.clienteCorreo.isNotEmpty) _linea('Correo', pedido.clienteCorreo),
            _linea('Modalidad', entrega),
            if (pedido.personaRecojo.isNotEmpty) _linea('Persona de recojo', pedido.personaRecojo),
            if (pedido.cuponCodigo.isNotEmpty)
              _linea('Cupón', '${pedido.cuponCodigo} · - ${formatoPrecio(pedido.descuento)}'),
            if (pedido.rutaResumen.isNotEmpty) _linea('Recorrido', pedido.rutaResumen),
            const SizedBox(height: 8),
            Text('Productos', style: textoGestion(peso: FontWeight.w800)),
            const SizedBox(height: 6),
            for (final item in pedido.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.cantidad} × ${item.nombre}',
                        style: textoGestion(),
                      ),
                    ),
                    Text(
                      '${formatoPrecio(item.precio)} c/u',
                      style: textoGestion(tamano: 12, color: GestionColores.tintaSuave),
                    ),
                    const SizedBox(width: 12),
                    Text(formatoPrecio(item.subtotal), style: textoGestion(peso: FontWeight.w700)),
                  ],
                ),
              ),
            const Divider(height: 22),
            _linea('Subtotal registrado', formatoPrecio(pedido.subtotalCalculado)),
            if (pedido.descuento > 0) _linea('Descuento', '- ${formatoPrecio(pedido.descuento)}'),
            _linea('Importe registrado', formatoPrecio(pedido.total)),
            if (pedido.fotoRecojoBase64.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Foto de verificación', style: textoGestion(peso: FontWeight.w800)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  base64Decode(pedido.fotoRecojoBase64),
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Text(
                    'No se pudo mostrar la fotografía.',
                    style: textoGestion(color: GestionColores.error),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final estado in Pedido.estados.where((estado) => estado != pedido.estado))
                  OutlinedButton(
                    onPressed: () => _cambiarEstado(pedido, estado),
                    child: Text('Marcar ${_etiqueta(estado).toLowerCase()}'),
                  ),
                TextButton.icon(
                  onPressed: () => _eliminar(pedido),
                  icon: const Icon(Icons.delete_outline, color: GestionColores.error, size: 18),
                  label: Text(
                    'Eliminar',
                    style: textoGestion(peso: FontWeight.w700, color: GestionColores.error),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _linea(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(etiqueta, style: textoGestion(color: GestionColores.tintaSuave)),
          ),
          Expanded(child: Text(valor, style: textoGestion(peso: FontWeight.w700))),
        ],
      ),
    );
  }
}
