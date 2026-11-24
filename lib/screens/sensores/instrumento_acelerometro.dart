import 'package:flutter/material.dart';

import '../../services/telemetria_sensores.dart';
import '../../tema/tema_mass.dart';
import 'estado_sensor.dart';
import 'grafico_sensor.dart';

class VistaAcelerometro {
  final LecturaEjes? gravedad;
  final LecturaEjes? lineal;
  final List<LecturaEjes> serieGravedad;
  final List<LecturaEjes> serieLineal;
  final SituacionSensor situacion;
  final double pico;

  const VistaAcelerometro({
    required this.gravedad,
    required this.lineal,
    required this.serieGravedad,
    required this.serieLineal,
    required this.situacion,
    required this.pico,
  });

  static const vacia = VistaAcelerometro(
    gravedad: null,
    lineal: null,
    serieGravedad: [],
    serieLineal: [],
    situacion: SituacionSensor.esperando,
    pico: 0,
  );
}

class InstrumentoAcelerometro extends StatelessWidget {
  final VistaAcelerometro vista;
  final VoidCallback alReiniciarPico;

  const InstrumentoAcelerometro({
    super.key,
    required this.vista,
    required this.alReiniciarPico,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final g = vista.gravedad == null ? null : fuerzaG(vista.gravedad!);
    final pico = vista.pico.isFinite ? vista.pico : 0.0;
    return TarjetaInstrumento(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EncabezadoInstrumento(
            icono: Icons.speed_rounded,
            titulo: 'Acelerómetro',
            detalle: 'Incluye la gravedad. Unidad m/s².',
            situacion: vista.situacion,
          ),
          const SizedBox(height: 12),
          _Ejes(
            lectura: vista.gravedad,
            unidad: 'm/s²',
          ),
          const SizedBox(height: 8),
          Text(
            g == null || !g.isFinite
                ? 'Fuerza resultante sin lectura'
                : 'Fuerza resultante ${g.toStringAsFixed(2)} g · Pico ${pico.toStringAsFixed(1)} m/s²',
            style: textoMass(
              tamano: 12,
              color: tokens.tintaSuave,
              tabular: true,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: alReiniciarPico,
              style: TextButton.styleFrom(
                foregroundColor: tokens.accion,
                minimumSize: const Size(48, 36),
                padding: EdgeInsets.zero,
              ),
              child: const Text('Reiniciar pico'),
            ),
          ),
          GraficoSensor(
            muestras: vista.serieGravedad,
            escala: 15,
            etiqueta: 'Gráfico del acelerómetro',
          ),
          const SizedBox(height: 14),
          Text(
            'Aceleración lineal',
            style: textoMass(
              tamano: 14,
              peso: FontWeight.w700,
              color: tokens.profundo,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Sin gravedad. Unidad m/s².',
            style: textoMass(tamano: 12, color: tokens.tintaSuave),
          ),
          const SizedBox(height: 8),
          _Ejes(lectura: vista.lineal, unidad: 'm/s²'),
          const SizedBox(height: 8),
          GraficoSensor(
            muestras: vista.serieLineal,
            escala: 10,
            etiqueta: 'Gráfico de aceleración lineal',
          ),
        ],
      ),
    );
  }
}

class _Ejes extends StatelessWidget {
  final LecturaEjes? lectura;
  final String unidad;

  const _Ejes({required this.lectura, required this.unidad});

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final lectura = this.lectura;
    String texto(double? valor) =>
        lectura == null || !lectura.valida || valor == null
        ? '— $unidad'
        : '${valor.toStringAsFixed(2)} $unidad';
    return Row(
      children: [
        _Valor('X', texto(lectura?.x), tokens.profundo),
        _Valor('Y', texto(lectura?.y), tokens.accion),
        _Valor('Z', texto(lectura?.z), tokens.exito),
      ],
    );
  }
}

class _Valor extends StatelessWidget {
  final String eje;
  final String texto;
  final Color color;

  const _Valor(this.eje, this.texto, this.color);

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
              tamano: 13,
              peso: FontWeight.w700,
              color: TokensMass.de(context).tinta,
              tabular: true,
            ),
          ),
        ],
      ),
    );
  }
}
