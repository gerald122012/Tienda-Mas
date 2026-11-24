import 'package:flutter/material.dart';

import 'tema_massbot.dart';

/// Asistente de compras: visor azul, mirada calma y una chispa.
///
/// Se descartó una bolsa con cara porque, en 60 puntos, se leía como un
/// icono genérico de tienda. Esta silueta se reconoce como guía.
class AvatarMassBot extends StatelessWidget {
  final double tamano;

  const AvatarMassBot({super.key, this.tamano = 60});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: tamano,
      child: CustomPaint(
        painter: const PintorAvatarMassBot(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class PintorAvatarMassBot extends CustomPainter {
  const PintorAvatarMassBot();

  @override
  void paint(Canvas canvas, Size size) {
    final lado = size.width;
    final centro = Offset(lado / 2, lado / 2);
    final anillo = Paint()..color = kAmarilloBot;
    final cuerpo = Paint()..color = kAzulProfundoBot;
    canvas.drawCircle(centro, lado / 2, anillo);
    canvas.drawCircle(centro, lado / 2 - lado * 0.055, cuerpo);

    final brillo = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = lado * 0.035;
    canvas.drawArc(
      Rect.fromCircle(center: centro, radius: lado * 0.34),
      -2.5,
      1.5,
      false,
      brillo,
    );

    final visor = RRect.fromRectAndRadius(
      Rect.fromLTWH(lado * 0.16, lado * 0.24, lado * 0.68, lado * 0.36),
      Radius.circular(lado * 0.12),
    );
    canvas.drawRRect(visor, Paint()..color = kAzulBot);

    _ojo(canvas, Offset(lado * 0.38, lado * 0.42), lado);
    _ojo(canvas, Offset(lado * 0.62, lado * 0.42), lado);

    canvas.drawCircle(
      Offset(lado / 2, lado * 0.76),
      lado * 0.035,
      Paint()..color = kAmarilloBot,
    );

    _chispa(canvas, Offset(lado * 0.78, lado * 0.18), lado * 0.11);
  }

  void _ojo(Canvas canvas, Offset centro, double lado) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: centro,
          width: lado * 0.15,
          height: lado * 0.072,
        ),
        Radius.circular(lado),
      ),
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      centro.translate(-lado * 0.028, 0),
      lado * 0.016,
      Paint()..color = kAzulProfundoBot,
    );
  }

  void _chispa(Canvas canvas, Offset centro, double radio) {
    final camino = Path()
      ..moveTo(centro.dx, centro.dy - radio)
      ..quadraticBezierTo(
        centro.dx,
        centro.dy,
        centro.dx + radio,
        centro.dy,
      )
      ..quadraticBezierTo(
        centro.dx,
        centro.dy,
        centro.dx,
        centro.dy + radio,
      )
      ..quadraticBezierTo(
        centro.dx,
        centro.dy,
        centro.dx - radio,
        centro.dy,
      )
      ..quadraticBezierTo(
        centro.dx,
        centro.dy,
        centro.dx,
        centro.dy - radio,
      );
    canvas.drawPath(camino, Paint()..color = kAmarilloBot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
