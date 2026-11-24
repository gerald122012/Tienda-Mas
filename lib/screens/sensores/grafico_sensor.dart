import 'package:flutter/material.dart';

import '../../services/telemetria_sensores.dart';
import '../../tema/tema_mass.dart';

class GraficoSensor extends StatelessWidget {
  final List<LecturaEjes> muestras;
  final double escala;
  final String etiqueta;

  const GraficoSensor({
    super.key,
    required this.muestras,
    required this.escala,
    required this.etiqueta,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Semantics(
      label: '$etiqueta, ${muestras.length} muestras',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RepaintBoundary(
            child: SizedBox(
              height: 72,
              width: double.infinity,
              child: CustomPaint(
                painter: _PintorSerie(
                  muestras: muestras,
                  escala: escala,
                  profundo: tokens.profundo,
                  accion: tokens.accion,
                  exito: tokens.exito,
                  linea: tokens.linea,
                  fondo: tokens.fondo,
                ),
                child: muestras.isEmpty
                    ? Center(
                        child: Text(
                          'Sin lecturas',
                          style: textoMass(tamano: 12, color: tokens.tintaSuave),
                        ),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              _Leyenda(trazo: _Trazo.continuo, texto: 'X', color: tokens.profundo),
              _Leyenda(trazo: _Trazo.punteado, texto: 'Y', color: tokens.accion),
              _Leyenda(trazo: _Trazo.discontinuo, texto: 'Z', color: tokens.exito),
            ],
          ),
        ],
      ),
    );
  }
}

enum _Trazo { continuo, punteado, discontinuo }

class _Leyenda extends StatelessWidget {
  final _Trazo trazo;
  final String texto;
  final Color color;

  const _Leyenda({
    required this.trazo,
    required this.texto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(18, 8),
          painter: _PintorLeyenda(trazo, color),
        ),
        const SizedBox(width: 4),
        Text(
          texto,
          style: textoMass(tamano: 11, peso: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}

class _PintorLeyenda extends CustomPainter {
  final _Trazo trazo;
  final Color color;

  _PintorLeyenda(this.trazo, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (trazo == _Trazo.discontinuo) {
      paint.strokeCap = StrokeCap.butt;
    }
    final y = size.height / 2;
    if (trazo == _Trazo.punteado) {
      canvas.drawCircle(Offset(3, y), 1.4, Paint()..color = color);
      canvas.drawCircle(Offset(9, y), 1.4, Paint()..color = color);
      canvas.drawCircle(Offset(15, y), 1.4, Paint()..color = color);
      return;
    }
    if (trazo == _Trazo.discontinuo) {
      canvas.drawLine(Offset(0, y), Offset(7, y), paint);
      canvas.drawLine(Offset(11, y), Offset(18, y), paint);
      return;
    }
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(covariant _PintorLeyenda oldDelegate) =>
      oldDelegate.trazo != trazo || oldDelegate.color != color;
}

class _PintorSerie extends CustomPainter {
  final List<LecturaEjes> muestras;
  final double escala;
  final Color profundo;
  final Color accion;
  final Color exito;
  final Color linea;
  final Color fondo;

  _PintorSerie({
    required this.muestras,
    required this.escala,
    required this.profundo,
    required this.accion,
    required this.exito,
    required this.linea,
    required this.fondo,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      Paint()..color = fondo,
    );
    final centro = size.height / 2;
    canvas.drawLine(
      Offset(0, centro),
      Offset(size.width, centro),
      Paint()
        ..color = linea
        ..strokeWidth = 1,
    );
    if (muestras.length < 2) {
      if (muestras.length == 1) {
        _marca(canvas, size, muestras.single.x, profundo);
        _marca(canvas, size, muestras.single.y, accion);
        _marca(canvas, size, muestras.single.z, exito);
      }
      return;
    }
    _trazo(canvas, size, (m) => m.x, profundo, _Trazo.continuo);
    _trazo(canvas, size, (m) => m.y, accion, _Trazo.punteado);
    _trazo(canvas, size, (m) => m.z, exito, _Trazo.discontinuo);
  }

  void _marca(Canvas canvas, Size size, double valor, Color color) {
    final normal = (valor / escala).clamp(-1.0, 1.0);
    final y = size.height / 2 - normal * (size.height / 2 - 6);
    canvas.drawCircle(
      Offset(size.width / 2, y),
      3,
      Paint()..color = color,
    );
  }

  void _trazo(
    Canvas canvas,
    Size size,
    double Function(LecturaEjes) eje,
    Color color,
    _Trazo trazo,
  ) {
    final path = Path();
    final n = muestras.length;
    for (var i = 0; i < n; i++) {
      final x = n == 1 ? size.width : size.width * i / (n - 1);
      final valor = (eje(muestras[i]) / escala).clamp(-1.0, 1.0);
      final y = size.height / 2 - valor * (size.height / 2 - 6);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (trazo == _Trazo.discontinuo) {
      paint.strokeCap = StrokeCap.butt;
      _discontinuo(canvas, path, paint);
      return;
    }
    if (trazo == _Trazo.punteado) {
      _punteado(canvas, path, color);
      return;
    }
    canvas.drawPath(path, paint);
  }

  void _discontinuo(Canvas canvas, Path path, Paint paint) {
    for (final metrica in path.computeMetrics()) {
      var distancia = 0.0;
      var pintar = true;
      while (distancia < metrica.length) {
        final fin = (distancia + 5).clamp(0, metrica.length).toDouble();
        if (pintar) {
          canvas.drawPath(metrica.extractPath(distancia, fin), paint);
        }
        distancia = fin + 3;
        pintar = !pintar;
      }
    }
  }

  void _punteado(Canvas canvas, Path path, Color color) {
    final paint = Paint()..color = color;
    for (final metrica in path.computeMetrics()) {
      var distancia = 0.0;
      while (distancia < metrica.length) {
        final punto = metrica.getTangentForOffset(distancia)?.position;
        if (punto != null) canvas.drawCircle(punto, 1.3, paint);
        distancia += 6;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PintorSerie oldDelegate) => true;
}
