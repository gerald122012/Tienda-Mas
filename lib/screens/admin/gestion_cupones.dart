import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/cupon.dart';
import '../../services/firebase_service.dart';
import '../../tema/tema_gestion.dart';
import '../../utils/utilidades.dart';
import 'piezas_gestion.dart';

class GestionCupones extends StatefulWidget {
  const GestionCupones({super.key});

  @override
  State<GestionCupones> createState() => _GestionCuponesState();
}

class _GestionCuponesState extends State<GestionCupones> {
  final _servicio = FirebaseService('cupones_mass');

  Future<void> _abrir([CuponDescuento? cupon]) async {
    final codigoCtrl = TextEditingController(text: cupon?.codigo ?? '');
    final descCtrl = TextEditingController(text: cupon?.descripcion ?? '');
    final valorCtrl = TextEditingController(
      text: cupon != null ? cupon.valor.toString() : '10',
    );
    final minCtrl = TextEditingController(
      text: cupon != null ? cupon.montoMinimo.toString() : '15',
    );
    var tipo = cupon?.tipo ?? 'porcentaje';
    var activo = cupon?.activo ?? true;
    final formKey = GlobalKey<FormState>();

    final guardado = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(cupon == null ? 'Nuevo cupón' : 'Editar ${cupon.codigo}'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: codigoCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'Código'),
                    validator: (valor) =>
                        (valor == null || valor.trim().length < 3) ? 'Mínimo 3 caracteres' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                    validator: (valor) =>
                        (valor == null || valor.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: tipo,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: const [
                      DropdownMenuItem(value: 'porcentaje', child: Text('Porcentaje')),
                      DropdownMenuItem(value: 'monto', child: Text('Monto fijo')),
                    ],
                    onChanged: (valor) {
                      if (valor != null) setLocal(() => tipo = valor);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: valorCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: tipo == 'porcentaje' ? 'Porcentaje' : 'Descuento (S/)',
                    ),
                    validator: (valor) {
                      final numero = leerDouble(valor ?? '');
                      if (numero <= 0) return 'Debe ser mayor a 0';
                      if (tipo == 'porcentaje' && numero > 90) return 'Máximo 90%';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: minCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Compra mínima (S/)'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Cupón activo'),
                    value: activo,
                    onChanged: (valor) => setLocal(() => activo = valor),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final nuevo = CuponDescuento(
                  id: cupon?.id ?? '',
                  codigo: codigoCtrl.text.trim().toUpperCase(),
                  descripcion: descCtrl.text.trim(),
                  tipo: tipo,
                  valor: leerDouble(valorCtrl.text),
                  montoMinimo: leerDouble(minCtrl.text),
                  activo: activo,
                );
                try {
                  await _servicio.guardar(nuevo.id, nuevo.toMap());
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (_) {
                  if (ctx.mounted) {
                    mostrarMensaje(ctx, 'No se pudo guardar el cupón. Revisa Firebase.');
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    codigoCtrl.dispose();
    descCtrl.dispose();
    valorCtrl.dispose();
    minCtrl.dispose();
    if (guardado == true && mounted) mostrarMensaje(context, 'Cupón guardado correctamente.');
  }

  Future<void> _eliminar(CuponDescuento cupon) async {
    if (!await confirmarEliminar(context, 'cupón ${cupon.codigo}')) return;
    try {
      await _servicio.eliminar(cupon.id);
      if (!mounted) return;
      mostrarDeshacer(
        context,
        'Cupón ${cupon.codigo} eliminado',
        () => _servicio.restaurar(cupon.id, cupon.toMap()),
      );
    } catch (_) {
      if (mounted) mostrarMensaje(context, 'No se pudo eliminar el cupón.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PaginaGestion(
      titulo: 'Cupones',
      detalle: 'Códigos registrados en la colección. Activar uno aquí no acredita un uso.',
      accion: FilledButton.icon(
        onPressed: () => _abrir(),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Nuevo cupón'),
      ),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _servicio.coleccion.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const EstadoGestion(
              icono: Icons.cloud_off_rounded,
              titulo: 'No pudimos consultar los cupones',
              mensaje: 'Revisa la conexión e inténtalo nuevamente.',
            );
          }
          if (!snapshot.hasData) return const CargandoGestion();
          final cupones = snapshot.data!.docs
              .map((doc) => CuponDescuento.fromMap(doc.id, doc.data()))
              .toList()
            ..sort((a, b) => a.codigo.compareTo(b.codigo));
          if (cupones.isEmpty) {
            return const EstadoGestion(
              icono: Icons.confirmation_number_outlined,
              titulo: 'No hay cupones en Firebase',
              mensaje: 'Los cupones locales de la aplicación no aparecen en esta lista.',
            );
          }
          return ListView.separated(
            itemCount: cupones.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, indice) {
              final cupon = cupones[indice];
              return SuperficieGestion(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    '${cupon.codigo} · ${cupon.etiquetaDescuento}',
                    style: textoGestion(peso: FontWeight.w800, color: GestionColores.profundo),
                  ),
                  subtitle: Text(
                    '${cupon.descripcion}\nMínimo ${formatoPrecio(cupon.montoMinimo)}',
                    style: textoGestion(tamano: 13, color: GestionColores.tintaSuave),
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ChipGestion(
                        texto: cupon.activo ? 'Activo' : 'Inactivo',
                        color: cupon.activo ? GestionColores.exito : GestionColores.tintaSuave,
                        icono: cupon.activo ? Icons.check_rounded : Icons.pause_rounded,
                      ),
                      IconButton(
                        tooltip: 'Editar ${cupon.codigo}',
                        onPressed: () => _abrir(cupon),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Eliminar ${cupon.codigo}',
                        onPressed: () => _eliminar(cupon),
                        icon: const Icon(Icons.delete_outline, color: GestionColores.error),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
