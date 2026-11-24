import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/tienda.dart';
import '../../services/consulta_tiendas.dart';
import '../../services/firebase_service.dart';
import '../../tema/tema_gestion.dart';
import '../../utils/utilidades.dart';
import '../ubicame/tienda_form_screen.dart';
import 'piezas_gestion.dart';

class GestionTiendas extends StatefulWidget {
  const GestionTiendas({super.key});

  @override
  State<GestionTiendas> createState() => _GestionTiendasState();
}

class _GestionTiendasState extends State<GestionTiendas> {
  final _servicio = FirebaseService('tiendas_mass');
  final _busqueda = TextEditingController();
  bool _soloSinCoordenadas = false;

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  void _abrir([Tienda? tienda]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TiendaFormScreen(tienda: tienda)),
    );
  }

  Future<void> _eliminar(Tienda tienda) async {
    if (!await confirmarEliminar(context, tienda.nombre)) return;
    try {
      await _servicio.eliminar(tienda.id);
      if (!mounted) return;
      mostrarDeshacer(
        context,
        'Tienda Mass eliminada',
        () => _servicio.restaurar(tienda.id, tienda.toMap()),
      );
    } catch (_) {
      if (mounted) mostrarMensaje(context, 'No se pudo eliminar la tienda.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PaginaGestion(
      titulo: 'Establecimientos',
      detalle: 'Sedes registradas. Una ficha sin coordenadas no recibe una ubicación automática.',
      accion: FilledButton.icon(
        onPressed: () => _abrir(),
        icon: const Icon(Icons.add_location_alt_outlined, size: 18),
        label: const Text('Nueva tienda'),
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _busqueda,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre, ciudad o dirección',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              FilterChip(
                label: const Text('Sin coordenadas válidas'),
                selected: _soloSinCoordenadas,
                showCheckmark: false,
                selectedColor: GestionColores.sello,
                onSelected: (valor) => setState(() => _soloSinCoordenadas = valor),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _servicio.coleccion.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const EstadoGestion(
                    icono: Icons.cloud_off_rounded,
                    titulo: 'No pudimos consultar las tiendas',
                    mensaje: 'Revisa la conexión e inténtalo nuevamente.',
                  );
                }
                if (!snapshot.hasData) return const CargandoGestion();
                final consulta = _busqueda.text.trim().toLowerCase();
                final tiendas = snapshot.data!.docs
                    .map((doc) => Tienda.fromMap(doc.id, doc.data()))
                    .where((tienda) {
                      final texto =
                          '${tienda.nombre} ${tienda.ciudad} ${tienda.distrito} ${tienda.direccion}'
                              .toLowerCase();
                      final coincide = consulta.isEmpty || texto.contains(consulta);
                      final coordenadas = coordenadasValidas(tienda.latitud, tienda.longitud);
                      return coincide && (!_soloSinCoordenadas || !coordenadas);
                    })
                    .toList()
                  ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
                if (snapshot.data!.docs.isEmpty) {
                  return const EstadoGestion(
                    icono: Icons.storefront_outlined,
                    titulo: 'No hay establecimientos registrados',
                    mensaje: 'Registra una sede con su dirección y, si las conoces, sus coordenadas.',
                  );
                }
                if (tiendas.isEmpty) {
                  return const EstadoGestion(
                    icono: Icons.search_off_rounded,
                    titulo: 'Ningún establecimiento coincide',
                    mensaje: 'Ajusta la búsqueda o el filtro de coordenadas.',
                  );
                }
                return ListView.separated(
                  itemCount: tiendas.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, indice) => _ficha(tiendas[indice]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _ficha(Tienda tienda) {
    final coordenadas = coordenadasValidas(tienda.latitud, tienda.longitud);
    return SuperficieGestion(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tienda.nombre,
                    style: textoGestion(
                      tamano: 16,
                      peso: FontWeight.w800,
                      color: GestionColores.profundo,
                    ),
                  ),
                ),
                ChipGestion(
                  texto: coordenadas ? 'Coordenadas registradas' : 'Sin coordenadas válidas',
                  color: coordenadas ? GestionColores.exito : GestionColores.error,
                  icono: coordenadas ? Icons.place_outlined : Icons.wrong_location_outlined,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${tienda.distrito} · ${tienda.ciudad}',
              style: textoGestion(peso: FontWeight.w700),
            ),
            Text(tienda.direccion, style: textoGestion(color: GestionColores.tintaSuave)),
            const SizedBox(height: 6),
            Text(
              tienda.horario.trim().isEmpty ? 'Horario no registrado' : tienda.horario,
              style: textoGestion(color: GestionColores.tintaSuave),
            ),
            if (tienda.servicios.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  tienda.servicios.join(' · '),
                  style: textoGestion(tamano: 13, color: GestionColores.tintaSuave),
                ),
              ),
            if (coordenadas)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${tienda.latitud}, ${tienda.longitud}',
                  style: textoGestion(tamano: 13, color: GestionColores.tintaSuave),
                ),
              ),
            Row(
              children: [
                const Spacer(),
                IconButton(
                  tooltip: 'Editar ${tienda.nombre}',
                  onPressed: () => _abrir(tienda),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Duplicar ${tienda.nombre}',
                  onPressed: () => _abrir(Tienda.fromMap('', tienda.toMap())),
                  icon: const Icon(Icons.copy_outlined),
                ),
                IconButton(
                  tooltip: 'Eliminar ${tienda.nombre}',
                  onPressed: () => _eliminar(tienda),
                  icon: const Icon(Icons.delete_outline, color: GestionColores.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
