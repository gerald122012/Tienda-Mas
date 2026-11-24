import 'package:flutter/material.dart';

import '../../tema/tema_mass.dart';

/// Marco visual. No recorta la zona real de detección de la cámara.
class MarcoEscanerMass extends StatelessWidget {
  final bool barras;

  const MarcoEscanerMass({super.key, required this.barras});

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return IgnorePointer(
      child: CustomPaint(
        painter: _PintorMarco(
          barras: barras,
          velo: tokens.profundo.withValues(alpha: 0.46),
          esquina: tokens.sello,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _PintorMarco extends CustomPainter {
  final bool barras;
  final Color velo;
  final Color esquina;

  _PintorMarco({
    required this.barras,
    required this.velo,
    required this.esquina,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final ancho = size.width * (barras ? 0.86 : 0.68);
    final alto = barras ? size.height * 0.24 : ancho;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: ancho.clamp(120, size.width - 24),
      height: alto.clamp(72, size.height * 0.7),
    );
    final marco = RRect.fromRectAndRadius(rect, const Radius.circular(16));
    final veloPath = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(marco)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(veloPath, Paint()..color = velo);
    final paint = Paint()
      ..color = esquina
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const largo = 22.0;
    for (final esquinaRect in [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ]) {
      final derecha = esquinaRect.dx > rect.center.dx;
      final abajo = esquinaRect.dy > rect.center.dy;
      final dx = derecha ? -1.0 : 1.0;
      final dy = abajo ? -1.0 : 1.0;
      canvas.drawLine(esquinaRect, esquinaRect + Offset(largo * dx, 0), paint);
      canvas.drawLine(esquinaRect, esquinaRect + Offset(0, largo * dy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PintorMarco oldDelegate) =>
      oldDelegate.barras != barras;
}
