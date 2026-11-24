import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/telemetria_sensores.dart';
import '../../tema/tema_mass.dart';
import 'estado_sensor.dart';

class VistaBrujula {
  final double? gradosMostrados;
  final double? gradosLectura;
  final SituacionSensor situacion;

  const VistaBrujula({
    required this.gradosMostrados,
    required this.gradosLectura,
    required this.situacion,
  });

  static const vacia = VistaBrujula(
    gradosMostrados: null,
    gradosLectura: null,
    situacion: SituacionSensor.esperando,
  );
}

class BrujulaMass extends StatelessWidget {
  final VistaBrujula vista;

  const BrujulaMass({super.key, required this.vista});

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final grados = vista.gradosLectura;
    final cardinal = puntoCardinal(grados);
    final hayLectura = grados != null;
    return TarjetaInstrumento(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EncabezadoInstrumento(
            icono: Icons.explore_rounded,
            titulo: 'Brújula',
            detalle: 'Magnetómetro, sin compensación de inclinación.',
            situacion: vista.situacion,
          ),
          const SizedBox(height: 12),
          Center(
            child: Semantics(
              label: hayLectura
                  ? 'Brújula ${grados.toStringAsFixed(0)} grados $cardinal'
                  : 'Brújula sin lectura',
              child: SizedBox(
                width: 188,
                height: 188,
                child: CustomPaint(
                  painter: _PintorBrujula(
                    grados: vista.gradosMostrados,
                    profundo: tokens.profundo,
                    sello: tokens.sello,
                    tinta: tokens.tintaSuave,
                    linea: tokens.linea,
                    superficie: tokens.superficie,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hayLectura
                ? '${grados.toStringAsFixed(0)}°  $cardinal'
                : 'Sin lectura magnética',
            style: textoMass(
              tamano: 18,
              peso: FontWeight.w700,
              color: tokens.profundo,
              tabular: true,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No hay una precisión garantizada. El rumbo usa solo los ejes magnéticos disponibles.',
            style: textoMass(tamano: 12, color: tokens.tintaSuave),
          ),
        ],
      ),
    );
  }
}

class _PintorBrujula extends CustomPainter {
  final double? grados;
  final Color profundo;
  final Color sello;
  final Color tinta;
  final Color linea;
  final Color superficie;

  _PintorBrujula({
    required this.grados,
    required this.profundo,
    required this.sello,
    required this.tinta,
    required this.linea,
    required this.superficie,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final radio = size.width / 2 - 8;
    canvas.drawCircle(centro, radio, Paint()..color = superficie);
    canvas.drawCircle(
      centro,
      radio,
      Paint()
        ..color = profundo
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      centro,
      radio - 10,
      Paint()
        ..color = linea
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    for (var i = 0; i < 12; i++) {
      final angulo = (i * 30 - 90) * math.pi / 180;
      final largo = i % 3 == 0 ? 10.0 : 5.0;
      final interno = radio - 12;
      canvas.drawLine(
        centro + Offset(math.cos(angulo), math.sin(angulo)) * interno,
        centro + Offset(math.cos(angulo), math.sin(angulo)) * (interno - largo),
        Paint()
          ..color = i % 3 == 0 ? profundo : tinta
          ..strokeWidth = i % 3 == 0 ? 2 : 1,
      );
    }
    _letra(canvas, 'N', centro + const Offset(0, -58), profundo, true);
    _letra(canvas, 'E', centro + const Offset(58, 0), tinta, false);
    _letra(canvas, 'S', centro + const Offset(0, 58), tinta, false);
    _letra(canvas, 'O', centro + const Offset(-58, 0), tinta, false);
    final rumbo = grados;
    if (rumbo == null) return;
    canvas.save();
    canvas.translate(centro.dx, centro.dy);
    canvas.rotate(rumbo * math.pi / 180);
    final aguja = Path()
      ..moveTo(0, -radio + 28)
      ..lineTo(7, 8)
      ..lineTo(0, 0)
      ..lineTo(-7, 8)
      ..close();
    canvas.drawPath(aguja, Paint()..color = profundo);
    final punta = Path()
      ..moveTo(0, -radio + 22)
      ..lineTo(5, -radio + 40)
      ..lineTo(-5, -radio + 40)
      ..close();
    canvas.drawPath(punta, Paint()..color = sello);
    canvas.restore();
    canvas.drawCircle(centro, 4, Paint()..color = sello);
    canvas.drawCircle(
      centro,
      4,
      Paint()
        ..color = profundo
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _letra(Canvas canvas, String letra, Offset centro, Color color, bool norte) {
    final painter = TextPainter(
      text: TextSpan(
        text: letra,
        style: TextStyle(
          color: color,
          fontSize: norte ? 16 : 13,
          fontWeight: FontWeight.w800,
          fontFamily: 'Manrope',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, centro - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _PintorBrujula oldDelegate) =>
      oldDelegate.grados != grados;
}
