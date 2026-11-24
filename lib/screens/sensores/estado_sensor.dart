import 'package:flutter/material.dart';

import '../../services/telemetria_sensores.dart';
import '../../tema/tema_mass.dart';

class EtiquetaSensor extends StatelessWidget {
  final SituacionSensor situacion;

  const EtiquetaSensor({super.key, required this.situacion});

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final (fondo, tinta, icono) = switch (situacion) {
      SituacionSensor.activo => (
        tokens.exito.withValues(alpha: 0.12),
        tokens.exito,
        Icons.check_rounded,
      ),
      SituacionSensor.simulado => (
        tokens.sello.withValues(alpha: 0.45),
        tokens.profundo,
        Icons.science_outlined,
      ),
      SituacionSensor.enPausa => (
        tokens.fondo,
        tokens.tintaSuave,
        Icons.pause_rounded,
      ),
      SituacionSensor.noDisponible => (
        tokens.error.withValues(alpha: 0.10),
        tokens.error,
        Icons.sensors_off_rounded,
      ),
      SituacionSensor.error => (
        tokens.error.withValues(alpha: 0.10),
        tokens.error,
        Icons.error_outline_rounded,
      ),
      SituacionSensor.esperando => (
        tokens.fondo,
        tokens.tintaSuave,
        Icons.hourglass_empty_rounded,
      ),
    };
    return Semantics(
      label: 'Estado ${textoSituacionSensor(situacion)}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 14, color: tinta),
            const SizedBox(width: 4),
            Text(
              textoSituacionSensor(situacion),
              style: textoMass(tamano: 11, peso: FontWeight.w700, color: tinta),
            ),
          ],
        ),
      ),
    );
  }
}

class TarjetaInstrumento extends StatelessWidget {
  final Widget child;

  const TarjetaInstrumento({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.superficie,
        borderRadius: BorderRadius.circular(MassRadio.tarjeta),
        border: Border.all(color: tokens.linea),
      ),
      child: child,
    );
  }
}

class EncabezadoInstrumento extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String detalle;
  final SituacionSensor situacion;

  const EncabezadoInstrumento({
    super.key,
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.situacion,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tokens.profundo,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icono, size: 18, color: tokens.sello),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    titulo,
                    style: textoMass(
                      tamano: 16,
                      peso: FontWeight.w700,
                      color: tokens.profundo,
                    ),
                  ),
                  EtiquetaSensor(situacion: situacion),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                detalle,
                style: textoMass(tamano: 12, color: tokens.tintaSuave),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
