import 'package:flutter/material.dart';

import '../../services/telemetria_sensores.dart';
import '../../tema/tema_mass.dart';
import 'estado_sensor.dart';

class VistaNivel {
  final BurbujaNivel? burbuja;
  final LecturaEjes? lectura;
  final SituacionSensor situacion;

  const VistaNivel({
    required this.burbuja,
    required this.lectura,
    required this.situacion,
  });

  static const vacia = VistaNivel(
    burbuja: null,
    lectura: null,
    situacion: SituacionSensor.esperando,
  );
}

class NivelMass extends StatelessWidget {
  final VistaNivel vista;

  const NivelMass({super.key, required this.vista});

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final reducir = MediaQuery.disableAnimationsOf(context);
    final burbuja = vista.burbuja;
    final lectura = vista.lectura;
    final hay = burbuja != null && lectura != null && lectura.valida;
    return TarjetaInstrumento(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EncabezadoInstrumento(
            icono: Icons.straighten_rounded,
            titulo: 'Nivel',
            detalle: 'Referencia visual del acelerómetro.',
            situacion: vista.situacion,
          ),
          const SizedBox(height: 12),
          Center(
            child: Semantics(
              label: !hay
                  ? 'Nivel sin lectura'
                  : burbuja.equilibrio
                  ? 'Nivel en equilibrio'
                  : 'Nivel inclinado',
              child: SizedBox(
                width: 168,
                height: 168,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tokens.fondo,
                    border: Border.all(color: tokens.profundo, width: 2),
                  ),
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: const Size(168, 168),
                        painter: _Cruces(tokens.linea, tokens.profundo),
                      ),
                      if (hay)
                        AnimatedAlign(
                          duration: Duration(milliseconds: reducir ? 0 : 120),
                          curve: Curves.easeOut,
                          alignment: Alignment(
                            -burbuja.x * 0.72,
                            burbuja.y * 0.72,
                          ),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: burbuja.equilibrio
                                  ? tokens.exito
                                  : tokens.accion,
                              border: Border.all(color: tokens.sello, width: 3),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            !hay
                ? 'Sin lectura del acelerómetro'
                : burbuja.equilibrio
                ? 'En equilibrio'
                : 'Inclinado',
            style: textoMass(
              tamano: 16,
              peso: FontWeight.w700,
              color: tokens.profundo,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            !hay
                ? 'La burbuja aparece cuando llega una lectura válida.'
                : 'X ${lectura.x.toStringAsFixed(2)} m/s² · Y ${lectura.y.toStringAsFixed(2)} m/s²',
            style: textoMass(
              tamano: 12,
              color: tokens.tintaSuave,
              tabular: true,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No es un nivel certificado. No se calculan grados de inclinación.',
            style: textoMass(tamano: 12, color: tokens.tintaSuave),
          ),
        ],
      ),
    );
  }
}

class _Cruces extends CustomPainter {
  final Color linea;
  final Color centro;

  _Cruces(this.linea, this.centro);

  @override
  void paint(Canvas canvas, Size size) {
    final medio = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = linea
      ..strokeWidth = 1;
    canvas.drawLine(Offset(18, medio.dy), Offset(size.width - 18, medio.dy), paint);
    canvas.drawLine(Offset(medio.dx, 18), Offset(medio.dx, size.height - 18), paint);
    canvas.drawCircle(
      medio,
      16,
      Paint()
        ..color = centro.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _Cruces oldDelegate) => false;
}
