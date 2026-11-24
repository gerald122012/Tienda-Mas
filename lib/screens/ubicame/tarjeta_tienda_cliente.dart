import 'package:flutter/material.dart';

import '../../models/tienda.dart';
import '../../tema/tema_mass.dart';
import '../../widgets/botones_acciones.dart';

class TarjetaTiendaCliente extends StatelessWidget {
  final Tienda tienda;
  final String? lugar;
  final String? horario;
  final String? distanciaAproximada;
  final VoidCallback? alVerRuta;
  final VoidCallback? alSinCoordenadas;
  final bool esAdmin;
  final VoidCallback? alDuplicar;
  final VoidCallback? alEditar;
  final VoidCallback? alEliminar;

  const TarjetaTiendaCliente({
    super.key,
    required this.tienda,
    this.lugar,
    this.horario,
    this.distanciaAproximada,
    this.alVerRuta,
    this.alSinCoordenadas,
    this.esAdmin = false,
    this.alDuplicar,
    this.alEditar,
    this.alEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final direccion = tienda.direccion.trim();
    final servicios = tienda.servicios
        .map((servicio) => servicio.trim())
        .where((servicio) => servicio.isNotEmpty)
        .join(', ');
    return Material(
      color: tokens.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MassRadio.tarjeta),
        side: BorderSide(color: tokens.linea),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _MarcaTienda(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tienda.nombre.trim().isEmpty
                            ? 'Establecimiento'
                            : tienda.nombre.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textoMass(
                          tamano: 16,
                          peso: FontWeight.w800,
                          color: tokens.profundo,
                        ),
                      ),
                      if (lugar != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          lugar!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textoMass(
                            tamano: 13,
                            peso: FontWeight.w700,
                            color: tokens.tinta,
                          ),
                        ),
                      ],
                      if (direccion.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          direccion,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textoMass(
                            tamano: 13,
                            color: tokens.tintaSuave,
                            alto: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (horario != null) ...[
              const SizedBox(height: 10),
              _Dato(
                icono: Icons.schedule_rounded,
                texto: horario!,
              ),
            ],
            if (distanciaAproximada != null) ...[
              const SizedBox(height: 6),
              _Dato(
                icono: Icons.near_me_outlined,
                texto: distanciaAproximada!,
              ),
            ],
            if (servicios.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                servicios,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textoMass(tamano: 12, color: tokens.tintaSuave, alto: 1.35),
              ),
            ],
            const SizedBox(height: 12),
            if (alVerRuta != null)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: Key('ruta-${tienda.id}'),
                  onPressed: alVerRuta,
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.accion,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    textStyle: textoMass(
                      tamano: 14,
                      peso: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  icon: const Icon(Icons.route_rounded, size: 18),
                  label: const Text('Ver ruta GPS'),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: Key('sin-coordenadas-${tienda.id}'),
                  onPressed: alSinCoordenadas,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: tokens.tinta,
                    minimumSize: const Size.fromHeight(48),
                    side: BorderSide(color: tokens.linea),
                  ),
                  icon: Icon(Icons.location_off_outlined, color: tokens.tintaSuave, size: 18),
                  label: const Text('Sin coordenadas para la ruta'),
                ),
              ),
            if (esAdmin && alDuplicar != null && alEditar != null && alEliminar != null)
              Align(
                alignment: Alignment.centerRight,
                child: BotonesAcciones(
                  onDuplicar: alDuplicar!,
                  onEditar: alEditar!,
                  onEliminar: alEliminar!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MarcaTienda extends StatelessWidget {
  const _MarcaTienda();

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Semantics(
      image: true,
      label: 'Ilustración corporativa. No es una fotografía del local.',
      child: SizedBox(
        width: 56,
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.profundo,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.storefront_rounded, color: Colors.white, size: 26),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: tokens.sello,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _Dato({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 16, color: tokens.accion),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textoMass(tamano: 13, peso: FontWeight.w600, color: tokens.tinta),
          ),
        ),
      ],
    );
  }
}
