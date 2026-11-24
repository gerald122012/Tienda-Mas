import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

import '../models/cupon.dart';

/// Lecturas locales del dispositivo. No se envían a Firebase ni a Gemini.
class LecturaEjes {
  final double x;
  final double y;
  final double z;

  const LecturaEjes(this.x, this.y, this.z);

  bool get valida => x.isFinite && y.isFinite && z.isFinite;

  double get magnitud =>
      valida ? math.sqrt(x * x + y * y + z * z) : double.nan;
}

enum SituacionSensor { esperando, activo, enPausa, noDisponible, simulado, error }

String textoSituacionSensor(SituacionSensor situacion) => switch (situacion) {
  SituacionSensor.esperando => 'Esperando',
  SituacionSensor.activo => 'Activo',
  SituacionSensor.enPausa => 'En pausa',
  SituacionSensor.noDisponible => 'No disponible',
  SituacionSensor.simulado => 'Simulación',
  SituacionSensor.error => 'Error de lectura',
};

/// Conserva solo las muestras recientes. No hay persistencia.
class SerieLecturas {
  static const limite = 36;
  final List<LecturaEjes> _muestras = [];

  List<LecturaEjes> get muestras => List.unmodifiable(_muestras);
  int get longitud => _muestras.length;

  void agregar(LecturaEjes lectura) {
    if (!lectura.valida) return;
    _muestras.add(lectura);
    if (_muestras.length > limite) {
      _muestras.removeRange(0, _muestras.length - limite);
    }
  }

  void limpiar() => _muestras.clear();
}

/// Rumbo magnético del código anterior: atan2(y, x), sin compensación
/// de inclinación. Null si no hay un vector utilizable.
double? rumboGrados(double mx, double my) {
  if (!mx.isFinite || !my.isFinite) return null;
  if (mx == 0 && my == 0) return null;
  final rad = math.atan2(my, mx);
  return (rad * 180 / math.pi + 360) % 360;
}

String? puntoCardinal(double? grados) {
  if (grados == null || !grados.isFinite) return null;
  const puntos = ['N', 'NE', 'E', 'SE', 'S', 'SO', 'O', 'NO'];
  final idx = ((grados + 22.5) / 45).floor() % 8;
  return puntos[idx];
}

/// Diferencia más corta entre dos rumbos, en el rango −180..180.
double deltaRumboCorto(double desde, double hasta) {
  var delta = (hasta - desde) % 360;
  if (delta < 0) delta += 360;
  if (delta > 180) delta -= 360;
  return delta;
}

double suavizarRumbo(double mostrado, double destino, {required bool saltar}) {
  final delta = deltaRumboCorto(mostrado, destino);
  if (saltar) return mostrado + delta;
  return mostrado + delta * 0.45;
}

/// Misma referencia visual que el nivel anterior: ejes / 9.81, acotados.
/// No convierte esa proporción en grados ni la presenta como medición certificada.
class BurbujaNivel {
  final double x;
  final double y;
  final bool equilibrio;

  const BurbujaNivel(this.x, this.y, this.equilibrio);
}

const double umbralEquilibrioNivel = 0.08;

BurbujaNivel? burbujaDesdeAcelerometro(LecturaEjes lectura) {
  if (!lectura.valida) return null;
  final x = (lectura.x / 9.81).clamp(-1.0, 1.0);
  final y = (lectura.y / 9.81).clamp(-1.0, 1.0);
  return BurbujaNivel(
    x,
    y,
    x.abs() < umbralEquilibrioNivel && y.abs() < umbralEquilibrioNivel,
  );
}

double fuerzaG(LecturaEjes lectura) {
  if (!lectura.valida) return double.nan;
  return lectura.magnitud / 9.80665;
}

class ResultadoSacudida {
  final bool detectada;
  final bool ignoradaPorEspera;
  final CuponDescuento? cupon;
  final int conteo;

  const ResultadoSacudida._({
    required this.detectada,
    required this.ignoradaPorEspera,
    required this.cupon,
    required this.conteo,
  });

  const ResultadoSacudida.ninguna()
    : this._(detectada: false, ignoradaPorEspera: false, cupon: null, conteo: 0);

  const ResultadoSacudida.espera(int conteo)
    : this._(
        detectada: false,
        ignoradaPorEspera: true,
        cupon: null,
        conteo: conteo,
      );

  const ResultadoSacudida.oferta(CuponDescuento cupon, int conteo)
    : this._(
        detectada: true,
        ignoradaPorEspera: false,
        cupon: cupon,
        conteo: conteo,
      );
}

/// Umbrales y cupones del mecanismo anterior. La espera evita repeticiones.
class DetectorSacudida {
  static const espera = Duration(seconds: 2);
  static const umbralLineal = 12.5;
  static const umbralConGravedad = 22.0;

  DateTime? ultima;
  int conteo = 0;

  ResultadoSacudida evaluar({
    required double magnitudLineal,
    required double magnitudConGravedad,
    required DateTime ahora,
  }) {
    final linealValida = magnitudLineal.isFinite && magnitudLineal > umbralLineal;
    final totalValida =
        magnitudConGravedad.isFinite &&
        magnitudConGravedad > umbralConGravedad;
    if (!linealValida && !totalValida) {
      return ResultadoSacudida.ninguna();
    }
    if (ultima != null && ahora.difference(ultima!) < espera) {
      return ResultadoSacudida.espera(conteo);
    }
    ultima = ahora;
    conteo++;
    final cupon = conteo.isOdd
        ? CuponDescuento.predeterminados.first
        : CuponDescuento.predeterminados[2];
    return ResultadoSacudida.oferta(cupon, conteo);
  }
}

class FuenteSensores {
  final Stream<LecturaEjes> Function() acelerometro;
  final Stream<LecturaEjes> Function() lineal;
  final Stream<LecturaEjes> Function() giroscopio;
  final Stream<LecturaEjes> Function() magnetometro;

  const FuenteSensores({
    required this.acelerometro,
    required this.lineal,
    required this.giroscopio,
    required this.magnetometro,
  });

  factory FuenteSensores.dispositivo() {
    return FuenteSensores(
      acelerometro: () => accelerometerEventStream().map(
        (e) => LecturaEjes(e.x, e.y, e.z),
      ),
      lineal: () => userAccelerometerEventStream().map(
        (e) => LecturaEjes(e.x, e.y, e.z),
      ),
      giroscopio: () => gyroscopeEventStream().map(
        (e) => LecturaEjes(e.x, e.y, e.z),
      ),
      magnetometro: () => magnetometerEventStream().map(
        (e) => LecturaEjes(e.x, e.y, e.z),
      ),
    );
  }
}
