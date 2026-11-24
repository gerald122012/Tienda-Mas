import 'package:flutter/material.dart';

import '../../models/cupon.dart';
import '../../services/lectura_escaner.dart';
import '../../tema/tema_mass.dart';

class ResultadoCupon extends StatelessWidget {
  final CuponDescuento? cupon;
  final EstadoCuponVisual estado;
  final String mensaje;
  final VoidCallback alEscanearDeNuevo;
  final VoidCallback? alVolverAlCarrito;

  const ResultadoCupon({
    super.key,
    required this.cupon,
    required this.estado,
    required this.mensaje,
    required this.alEscanearDeNuevo,
    this.alVolverAlCarrito,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final cupon = this.cupon;
    final (etiqueta, color) = switch (estado) {
      EstadoCuponVisual.aplicado => ('Aplicado', tokens.exito),
      EstadoCuponVisual.reconocido => ('Reconocido', tokens.accion),
      EstadoCuponVisual.inactivo => ('Inactivo', tokens.error),
      EstadoCuponVisual.inexistente => ('No encontrado', tokens.error),
      EstadoCuponVisual.condiciones => ('Condiciones', tokens.error),
      EstadoCuponVisual.error => ('Error', tokens.error),
    };
    return _Ficha(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  cupon?.codigo.isNotEmpty == true ? cupon!.codigo : 'Cupón',
                  style: textoMass(
                    tamano: 18,
                    peso: FontWeight.w800,
                    color: tokens.profundo,
                  ),
                ),
              ),
              _Estado(etiqueta: etiqueta, color: color),
            ],
          ),
          if (cupon != null) ...[
            const SizedBox(height: 4),
            Text(cupon.descripcion, style: textoMass(tamano: 13)),
            const SizedBox(height: 4),
            Text(
              '${cupon.etiquetaDescuento} · Mínimo S/ ${cupon.montoMinimo.toStringAsFixed(2)}',
              style: textoMass(
                tamano: 12,
                peso: FontWeight.w700,
                color: tokens.tintaSuave,
                tabular: true,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(mensaje, style: textoMass(tamano: 13, color: tokens.tinta)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                key: const Key('escanear-de-nuevo'),
                onPressed: alEscanearDeNuevo,
                style: OutlinedButton.styleFrom(
                  foregroundColor: tokens.profundo,
                  minimumSize: const Size(48, 48),
                ),
                child: const Text('Escanear de nuevo'),
              ),
              if (alVolverAlCarrito != null)
                FilledButton(
                  key: const Key('volver-carrito'),
                  onPressed: alVolverAlCarrito,
                  style: FilledButton.styleFrom(
                    foregroundColor: Colors.white,
                    minimumSize: const Size(48, 48),
                    textStyle: textoMass(
                      peso: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  child: const Text('Volver al carrito'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Estado extends StatelessWidget {
  final String etiqueta;
  final Color color;

  const _Estado({required this.etiqueta, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        etiqueta,
        style: textoMass(tamano: 11, peso: FontWeight.w800, color: color),
      ),
    );
  }
}

class _Ficha extends StatelessWidget {
  final Widget child;

  const _Ficha({required this.child});

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Material(
      color: tokens.superficie,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: child,
      ),
    );
  }
}
