import 'package:flutter/material.dart';

import '../../../main.dart';
import 'tema_acceso.dart';

class NombreConsultado extends StatelessWidget {
  final String nombre;
  final bool simulado;

  const NombreConsultado({
    super.key,
    required this.nombre,
    required this.simulado,
  });

  @override
  Widget build(BuildContext context) {
    final detalle = simulado
        ? 'Dato de prueba. No permite crear una cuenta real.'
        : 'Datos obtenidos mediante consulta de DNI.';
    final color = simulado ? kMassBlue : kExitoAcceso;

    return Semantics(
      container: true,
      label: 'Nombre completo $nombre. $detalle',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9E8),
          borderRadius: BorderRadius.circular(kRadioAcceso),
          border: Border.all(color: const Color(0xFFF0E2A0)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF0E2A0)),
                ),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.person_rounded, color: kMassBlue, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nombre completo',
                      style: textoAcceso(
                        tamano: 12,
                        peso: FontWeight.w700,
                        color: kTintaSuave,
                        alto: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nombre,
                      style: textoAcceso(
                        tamano: 16,
                        peso: FontWeight.w800,
                        alto: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          simulado
                              ? Icons.info_outline
                              : Icons.check_circle_rounded,
                          size: 16,
                          color: color,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            detalle,
                            style: textoAcceso(
                              tamano: 12,
                              peso: FontWeight.w600,
                              color: color,
                              alto: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
