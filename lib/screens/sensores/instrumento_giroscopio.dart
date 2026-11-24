import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/telemetria_sensores.dart';
import '../../tema/tema_mass.dart';
import 'estado_sensor.dart';
import 'grafico_sensor.dart';

class VistaGiroscopio {
  final LecturaEjes? lectura;
  final List<LecturaEjes> serie;
  final SituacionSensor situacion;

  const VistaGiroscopio({
    required this.lectura,
    required this.serie,
    required this.situacion,
  });

  static const vacia = VistaGiroscopio(
    lectura: null,
    serie: [],
    situacion: SituacionSensor.esperando,
  );
}

class InstrumentoGiroscopio extends StatelessWidget {
  final VistaGiroscopio vista;

  const InstrumentoGiroscopio({super.key, required this.vista});

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final lectura = vista.lectura;
    final intensidad = lectura != null && lectura.valida
        ? (lectura.magnitud / 6).clamp(0.0, 1.0)
        : 0.0;
    String texto(double? valor) =>
        lectura == null || !lectura.valida || valor == null
        ? '— rad/s'
        : '${valor.toStringAsFixed(2)} rad/s';
    return TarjetaInstrumento(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EncabezadoInstrumento(
            icono: Icons.rotate_right_rounded,
            titulo: 'Giroscopio',
            detalle: 'Velocidad angular. No es un ángulo de orientación.',
            situacion: vista.situacion,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CustomPaint(
                  painter: _IndicadorGiro(
                    intensidad: intensidad,
                    anillo: tokens.linea,
                    arco: tokens.accion,
                    marca: tokens.sello,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Intensidad de giro',
                      style: textoMass(
                        tamano: 13,
                        peso: FontWeight.w700,
                        color: tokens.tinta,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lectura == null || !lectura.valida
                          ? 'Sin lectura'
                          : '${lectura.magnitud.toStringAsFixed(2)} rad/s',
                      style: textoMass(
                        tamano: 12,
                        color: tokens.tintaSuave,
                        tabular: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Eje('X', texto(lectura?.x), tokens.profundo),
              _Eje('Y', texto(lectura?.y), tokens.accion),
              _Eje('Z', texto(lectura?.z), tokens.exito),
            ],
          ),
          const SizedBox(height: 10),
          GraficoSensor(
            muestras: vista.serie,
            escala: 6,
            etiqueta: 'Gráfico del giroscopio',
          ),
        ],
      ),
    );
  }
}

class _Eje extends StatelessWidget {
  final String eje;
  final String texto;
  final Color color;

  const _Eje(this.eje, this.texto, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eje,
            style: textoMass(tamano: 11, peso: FontWeight.w800, color: color),
          ),
          Text(
            texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textoMass(
              tamano: 12,
              peso: FontWeight.w700,
              tabular: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _IndicadorGiro extends CustomPainter {
  final double intensidad;
  final Color anillo;
  final Color arco;
  final Color marca;

  _IndicadorGiro({
    required this.intensidad,
    required this.anillo,
    required this.arco,
    required this.marca,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final radio = size.width / 2 - 3;
    canvas.drawCircle(
      centro,
      radio,
      Paint()
        ..color = anillo
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    if (intensidad <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: centro, radius: radio),
      -math.pi / 2,
      intensidad * math.pi * 2,
      false,
      Paint()
        ..color = arco
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(centro, 3, Paint()..color = marca);
  }

  @override
  bool shouldRepaint(covariant _IndicadorGiro oldDelegate) =>
      oldDelegate.intensidad != intensidad;
}
