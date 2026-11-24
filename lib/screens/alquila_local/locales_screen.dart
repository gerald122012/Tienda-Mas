import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/local_comercial.dart';
import '../../services/firebase_service.dart';
import '../../tema/tema_gestion.dart';
import '../../utils/utilidades.dart';
import '../../utils/validaciones.dart';
import '../admin/piezas_gestion.dart';
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
  String _filtro = 'todos';

  void _abrir([LocalComercial? local]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LocalFormScreen(local: local)),
    );
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
      mostrarMensaje(context, 'Un local rechazado no puede pasar directamente a aprobado');
      return;
    }
    await _servicio.guardar(local.id, {'estado': nuevo});
    if (mounted) mostrarMensaje(context, 'Estado actualizado a $nuevo');
  }

  @override
  Widget build(BuildContext context) {
    return PaginaGestion(
      titulo: 'Locales comerciales',
      detalle: 'Postulaciones registradas. La renta mostrada es la calculada por la fórmula existente.',
      accion: FilledButton.icon(
        onPressed: () => _abrir(),
        icon: const Icon(Icons.add_business_outlined, size: 18),
        label: const Text('Registrar local'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final estado in ['todos', ...LocalComercial.estados])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(estado == 'todos' ? 'Todos' : estado),
                      selected: _filtro == estado,
                      showCheckmark: false,
                      selectedColor: GestionColores.sello,
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
                    titulo: 'No pudimos consultar los locales',
                    mensaje: 'Revisa la conexión e inténtalo nuevamente.',
                  );
                }
                if (!snapshot.hasData) return const CargandoGestion();
                final locales = snapshot.data!.docs
                    .map((doc) => LocalComercial.fromMap(doc.id, doc.data()))
                    .where((local) => _filtro == 'todos' || local.estado == _filtro)
                    .toList();
                if (snapshot.data!.docs.isEmpty) {
                  return const EstadoGestion(
                    icono: Icons.apartment_outlined,
                    titulo: 'No hay locales postulados',
                    mensaje: 'Registra una propuesta cuando exista un local por evaluar.',
                  );
                }
                if (locales.isEmpty) {
                  return const EstadoGestion(
                    icono: Icons.filter_alt_off_outlined,
                    titulo: 'Ningún local coincide con el filtro',
                    mensaje: 'Elige otro estado para ver el resto de postulaciones.',
                  );
                }
                return ListView.separated(
                  itemCount: locales.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, indice) => _ficha(locales[indice]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _ficha(LocalComercial local) {
    final color = switch (local.estado) {
      'aprobado' => GestionColores.exito,
      'rechazado' => GestionColores.error,
      _ => GestionColores.profundo,
    };
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
                    '${local.propietario} · ${local.distritoCiudad}',
                    style: textoGestion(
                      tamano: 16,
                      peso: FontWeight.w800,
                      color: GestionColores.profundo,
                    ),
                  ),
                ),
                ChipGestion(texto: local.estado, color: color, icono: Icons.circle),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${local.modalidad} · ${local.areaM2} m² · Disponible ${formatoFecha(local.fechaDisponibilidad)}',
              style: textoGestion(color: GestionColores.tintaSuave),
            ),
            Text(
              'Renta calculada ${formatoPrecio(local.rentaFinal)}',
              style: textoGestion(peso: FontWeight.w700),
            ),
            if (local.notas.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(local.notas, style: textoGestion(tamano: 13)),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final estado in LocalComercial.estados.where((e) => e != local.estado))
                  OutlinedButton(
                    onPressed: () => _cambiarEstado(local, estado),
                    child: Text('Marcar $estado'),
                  ),
                IconButton(
                  tooltip: 'Editar',
                  onPressed: () => _abrir(local),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Duplicar',
                  onPressed: () => _abrir(LocalComercial.fromMap('', local.toMap())),
                  icon: const Icon(Icons.copy_outlined),
                ),
                IconButton(
                  tooltip: 'Eliminar',
                  onPressed: () => _eliminar(local),
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
