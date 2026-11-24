import 'package:flutter/material.dart';

import '../../models/cupon.dart';
import '../../tema/tema_mass.dart';

class TarjetaCuponMovimiento extends StatelessWidget {
  final CuponDescuento? cupon;
  final String mensaje;
  final bool aplicado;
  final VoidCallback? alUsar;

  const TarjetaCuponMovimiento({
    super.key,
    required this.cupon,
    required this.mensaje,
    required this.aplicado,
    required this.alUsar,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final cupon = this.cupon;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.superficie,
        borderRadius: BorderRadius.circular(MassRadio.tarjeta),
        border: Border.all(color: tokens.linea),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tokens.profundo,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.card_giftcard_rounded, color: tokens.sello),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agita y descubre',
                      style: textoMass(
                        tamano: 16,
                        peso: FontWeight.w700,
                        color: tokens.profundo,
                      ),
                    ),
                    Text(
                      'Una sacudida real puede ofrecer un cupón de la aplicación.',
                      style: textoMass(tamano: 12, color: tokens.tintaSuave),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            mensaje,
            style: textoMass(tamano: 13, color: tokens.tinta),
          ),
          if (cupon != null) ...[
            const SizedBox(height: 10),
            Text(
              cupon.codigo,
              style: textoMass(
                tamano: 18,
                peso: FontWeight.w800,
                color: tokens.profundo,
              ),
            ),
            Text(
              cupon.descripcion,
              style: textoMass(tamano: 13, color: tokens.tinta),
            ),
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
            const SizedBox(height: 8),
            if (aplicado)
              Text(
                'Cupón aplicado al carrito.',
                style: textoMass(
                  tamano: 13,
                  peso: FontWeight.w700,
                  color: tokens.exito,
                ),
              )
            else
              FilledButton(
                key: const Key('usar-cupon-movimiento'),
                onPressed: alUsar,
                style: FilledButton.styleFrom(
                  foregroundColor: Colors.white,
                  minimumSize: const Size(48, 48),
                  textStyle: textoMass(
                    peso: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                child: const Text('Usar en el carrito'),
              ),
          ],
        ],
      ),
    );
  }
}

class HerramientasDemostracion extends StatelessWidget {
  final bool simulando;
  final bool pausado;
  final int sacudidasSimuladas;
  final String aviso;
  final ValueChanged<bool> alSimular;
  final VoidCallback alSimularSacudida;
  final VoidCallback alPausar;

  const HerramientasDemostracion({
    super.key,
    required this.simulando,
    required this.pausado,
    required this.sacudidasSimuladas,
    required this.aviso,
    required this.alSimular,
    required this.alSimularSacudida,
    required this.alPausar,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.superficie,
        borderRadius: BorderRadius.circular(MassRadio.tarjeta),
        border: Border.all(color: tokens.sello, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Demostración académica',
            style: textoMass(
              tamano: 16,
              peso: FontWeight.w700,
              color: tokens.profundo,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Simulación. No son lecturas del hardware y no desbloquean un cupón.',
            style: textoMass(tamano: 12, color: tokens.tintaSuave),
          ),
          if (aviso.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              aviso,
              style: textoMass(
                tamano: 13,
                peso: FontWeight.w700,
                color: tokens.profundo,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  simulando ? 'Simulación activa' : 'Simular lecturas',
                  style: textoMass(tamano: 14, peso: FontWeight.w700),
                ),
              ),
              _InterruptorSimulacion(
                activo: simulando,
                tokens: tokens,
                alCambiar: alSimular,
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                key: const Key('simular-sacudida'),
                onPressed: alSimularSacudida,
                style: OutlinedButton.styleFrom(
                  foregroundColor: tokens.profundo,
                  minimumSize: const Size(48, 48),
                  side: BorderSide(color: tokens.linea),
                ),
                child: Text('Simular sacudida ($sacudidasSimuladas)'),
              ),
              OutlinedButton(
                key: const Key('pausar-sensores'),
                onPressed: alPausar,
                style: OutlinedButton.styleFrom(
                  foregroundColor: tokens.profundo,
                  minimumSize: const Size(48, 48),
                  side: BorderSide(color: tokens.linea),
                ),
                child: Text(pausado ? 'Reanudar lectura' : 'Pausar lectura'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InterruptorSimulacion extends StatelessWidget {
  final bool activo;
  final TokensMass tokens;
  final ValueChanged<bool> alCambiar;

  const _InterruptorSimulacion({
    required this.activo,
    required this.tokens,
    required this.alCambiar,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: activo,
      label: activo ? 'Simulación activa' : 'Simular lecturas',
      child: InkWell(
        key: const Key('simular-senal'),
        onTap: () => alCambiar(!activo),
        customBorder: const StadiumBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 46,
              height: 28,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: activo ? tokens.profundo : tokens.linea,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Align(
                alignment:
                    activo ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: activo ? tokens.sello : tokens.superficie,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: activo ? tokens.sello : const Color(0xFFC5CDDC),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
