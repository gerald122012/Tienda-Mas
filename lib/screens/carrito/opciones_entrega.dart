import 'dart:convert';

import 'package:flutter/material.dart';

import '../../tema/tema_mass.dart';

class OpcionesEntrega extends StatelessWidget {
  final String tipo;
  final ValueChanged<String> alCambiar;
  final TextEditingController persona;
  final String? fotoBase64;
  final bool capturando;
  final VoidCallback alTomarFoto;
  final VoidCallback alAdjuntarFoto;
  final VoidCallback alQuitarFoto;
  final String? ruta;
  final VoidCallback alAbrirRuta;

  const OpcionesEntrega({
    super.key,
    required this.tipo,
    required this.alCambiar,
    required this.persona,
    required this.fotoBase64,
    required this.capturando,
    required this.alTomarFoto,
    required this.alAdjuntarFoto,
    required this.alQuitarFoto,
    required this.ruta,
    required this.alAbrirRuta,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final reducir = MediaQuery.disableAnimationsOf(context);
    return Material(
      color: tokens.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MassRadio.tarjeta),
        side: BorderSide(color: tokens.linea),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Cómo recibirás tu compra?',
              style: textoMass(
                tamano: 16,
                peso: FontWeight.w800,
                color: tokens.profundo,
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, limites) {
                final apilar = limites.maxWidth < 340;
                final recojo = _Opcion(
                  seleccionada: tipo == 'recojo',
                  icono: Icons.storefront_outlined,
                  titulo: 'Recojo en tienda',
                  detalle: 'Retiro en local',
                  alElegir: () => alCambiar('recojo'),
                  reducir: reducir,
                );
                final delivery = _Opcion(
                  seleccionada: tipo == 'delivery',
                  icono: Icons.local_shipping_outlined,
                  titulo: 'Delivery',
                  detalle: 'Con una ruta',
                  alElegir: () => alCambiar('delivery'),
                  reducir: reducir,
                );
                if (apilar) {
                  return Column(
                    children: [
                      recojo,
                      const SizedBox(height: 8),
                      delivery,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: recojo),
                    const SizedBox(width: 8),
                    Expanded(child: delivery),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: persona,
              textCapitalization: TextCapitalization.words,
              scrollPadding: const EdgeInsets.only(bottom: 160),
              decoration: const InputDecoration(
                labelText: 'Nombre de quien recoge o recibe',
                prefixIcon: Icon(Icons.person_outline),
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Foto de verificación (opcional)',
              style: textoMass(
                tamano: 13,
                peso: FontWeight.w700,
                color: tokens.tinta,
              ),
            ),
            const SizedBox(height: 8),
            if (fotoBase64 != null && fotoBase64!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  base64Decode(fotoBase64!),
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: alQuitarFoto,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Quitar foto'),
                ),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: capturando ? null : alTomarFoto,
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: const Text('Tomar foto'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: capturando ? null : alAdjuntarFoto,
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Adjuntar'),
                  ),
                ),
              ],
            ),
            if (tipo == 'recojo') ...[
              const SizedBox(height: 12),
              Text(
                'Indica quién retirará el pedido. La tienda se elige en Ubícame.',
                style: textoMass(tamano: 12, color: tokens.tintaSuave, alto: 1.4),
              ),
            ],
            if (tipo == 'delivery') ...[
              const SizedBox(height: 12),
              Text(
                ruta ?? 'Aún no hay una ruta adjunta a este pedido.',
                style: textoMass(tamano: 13, color: tokens.tinta, alto: 1.35),
              ),
              const SizedBox(height: 4),
              Text(
                'No hay un costo de entrega calculado. El total corresponde solo a los productos.',
                style: textoMass(tamano: 12, color: tokens.tintaSuave, alto: 1.4),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: alAbrirRuta,
                  icon: const Icon(Icons.route_outlined, size: 18),
                  label: const Text('Ver ruta'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Opcion extends StatelessWidget {
  final bool seleccionada;
  final IconData icono;
  final String titulo;
  final String detalle;
  final VoidCallback alElegir;
  final bool reducir;

  const _Opcion({
    required this.seleccionada,
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.alElegir,
    required this.reducir,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Semantics(
      button: true,
      selected: seleccionada,
      label: titulo,
      child: Material(
        color: seleccionada
            ? tokens.accion.withValues(alpha: 0.08)
            : tokens.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MassRadio.control),
          side: BorderSide(
            color: seleccionada ? tokens.accion : tokens.linea,
            width: seleccionada ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: alElegir,
          borderRadius: BorderRadius.circular(MassRadio.control),
          child: AnimatedContainer(
            duration: Duration(milliseconds: reducir ? 0 : 180),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icono,
                  color: seleccionada ? tokens.accion : tokens.tintaSuave,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textoMass(
                          tamano: 13,
                          peso: FontWeight.w800,
                          color: tokens.tinta,
                        ),
                      ),
                      Text(
                        detalle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textoMass(tamano: 12, color: tokens.tintaSuave),
                      ),
                    ],
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
