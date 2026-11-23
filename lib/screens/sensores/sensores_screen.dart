import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../main.dart';
import '../../models/cupon.dart';
import '../../services/carrito_service.dart';
import '../../utils/utilidades.dart';

class SensoresScreen extends StatefulWidget {
  const SensoresScreen({super.key});

  @override
  State<SensoresScreen> createState() => _SensoresScreenState();
}

class _SensoresScreenState extends State<SensoresScreen> {
  StreamSubscription<AccelerometerEvent>? _accSub;
  StreamSubscription<UserAccelerometerEvent>? _userAccSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<MagnetometerEvent>? _magSub;

  double _ax = 0, _ay = 0, _az = 9.81;
  double _uax = 0, _uay = 0, _uaz = 0;
  double _gx = 0, _gy = 0, _gz = 0;
  double _mx = 0, _my = 0, _mz = 0;

  double _picoAceleracion = 0;
  int _sacudidas = 0;
  DateTime? _ultimaSacudida;
  bool _pausado = false;
  bool _sensorRealDetectado = false;
  bool _modoSimulacion = false;
  Timer? _simTimer;
  double _faseSim = 0;

  @override
  void initState() {
    super.initState();
    _iniciarSensores();
  }

  void _iniciarSensores() {
    try {
      _accSub = accelerometerEventStream().listen(
        (e) {
          if (_pausado || _modoSimulacion || !mounted) return;
          _procesarAcelerometro(e.x, e.y, e.z, real: true);
        },
        onError: (_) {},
      );
      _userAccSub = userAccelerometerEventStream().listen(
        (e) {
          if (_pausado || _modoSimulacion || !mounted) return;
          final mag = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
          if (mag > 12.5) _registrarSacudida();
          setState(() {
            _sensorRealDetectado = true;
            _uax = e.x;
            _uay = e.y;
            _uaz = e.z;
          });
        },
        onError: (_) {},
      );
      _gyroSub = gyroscopeEventStream().listen(
        (e) {
          if (_pausado || _modoSimulacion || !mounted) return;
          setState(() {
            _sensorRealDetectado = true;
            _gx = e.x;
            _gy = e.y;
            _gz = e.z;
          });
        },
        onError: (_) {},
      );
      _magSub = magnetometerEventStream().listen(
        (e) {
          if (_pausado || _modoSimulacion || !mounted) return;
          setState(() {
            _sensorRealDetectado = true;
            _mx = e.x;
            _my = e.y;
            _mz = e.z;
          });
        },
        onError: (_) {},
      );
    } catch (_) {}
  }

  void _procesarAcelerometro(
    double x,
    double y,
    double z, {
    required bool real,
  }) {
    final mag = math.sqrt(x * x + y * y + z * z);
    final pico = mag > _picoAceleracion ? mag : _picoAceleracion;
    if (mag > 22.0) _registrarSacudida();
    setState(() {
      if (real) _sensorRealDetectado = true;
      _ax = x;
      _ay = y;
      _az = z;
      _picoAceleracion = pico;
    });
  }

  void _registrarSacudida() {
    final ahora = DateTime.now();
    if (_ultimaSacudida != null &&
        ahora.difference(_ultimaSacudida!) < const Duration(seconds: 2)) {
      return;
    }
    _ultimaSacudida = ahora;
    HapticFeedback.heavyImpact();
    setState(() => _sacudidas++);
    if (!mounted) return;
    _mostrarRecompensaSacudida();
  }

  void _mostrarRecompensaSacudida() {
    final cupon = _sacudidas.isOdd
        ? CuponDescuento.predeterminados.first
        : CuponDescuento.predeterminados[2];
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: kMassBlue,
          content: Text(
            '¡Sacudida detectada! Desbloqueaste ${cupon.codigo} (${cupon.etiquetaDescuento})',
            style: const TextStyle(
              color: kMassYellow,
              fontWeight: FontWeight.w800,
            ),
          ),
          action: SnackBarAction(
            label: 'APLICAR',
            textColor: Colors.white,
            onPressed: () {
              final err = CarritoService.instance.aplicarCupon(cupon);
              if (mounted) {
                mostrarMensaje(
                  context,
                  err ?? 'Cupón ${cupon.codigo} aplicado a tu carrito.',
                );
              }
            },
          ),
        ),
      );
  }

  void _alternarSimulacion(bool activo) {
    _simTimer?.cancel();
    setState(() => _modoSimulacion = activo);
    if (!activo) return;
    _simTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (_pausado || !mounted) return;
      _faseSim += 0.16;
      setState(() {
        _ax = math.sin(_faseSim) * 3.8;
        _ay = math.cos(_faseSim * 0.7) * 2.9;
        _az = 9.81 + math.sin(_faseSim * 1.4) * 0.4;
        _uax = math.cos(_faseSim * 1.3) * 1.2;
        _uay = math.sin(_faseSim * 1.1) * 0.9;
        _uaz = math.sin(_faseSim * 0.6) * 0.5;
        _gx = math.sin(_faseSim * 0.9) * 0.8;
        _gy = math.cos(_faseSim * 1.2) * 0.7;
        _gz = math.sin(_faseSim * 0.5) * 0.4;
        _mx = math.cos(_faseSim * 0.25) * 42.0;
        _my = math.sin(_faseSim * 0.25) * 42.0;
        _mz = -18.5;
        final mag = math.sqrt(_ax * _ax + _ay * _ay + _az * _az);
        if (mag > _picoAceleracion) _picoAceleracion = mag;
      });
    });
  }

  @override
  void dispose() {
    _accSub?.cancel();
    _userAccSub?.cancel();
    _gyroSub?.cancel();
    _magSub?.cancel();
    _simTimer?.cancel();
    super.dispose();
  }

  double get _fuerzaG => math.sqrt(_ax * _ax + _ay * _ay + _az * _az) / 9.80665;

  double get _rumboGrados {
    if (_mx == 0 && _my == 0) return 0;
    final rad = math.atan2(_my, _mx);
    return (rad * 180 / math.pi + 360) % 360;
  }

  String get _puntoCardinal {
    const puntos = ['N', 'NE', 'E', 'SE', 'S', 'SO', 'O', 'NO'];
    final idx = ((_rumboGrados + 22.5) / 45).floor() % 8;
    return puntos[idx];
  }

  @override
  Widget build(BuildContext context) {
    final tabNum = const [FontFeature.tabularFigures()];
    return Scaffold(
      backgroundColor: kMassCream,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: const BoxDecoration(
              color: kMassBlue,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sensores en Tiempo Real',
                            style: TextStyle(
                              color: kMassYellow,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Telemetría activa · Agita el equipo para desbloquear un cupón',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filled(
                      tooltip: _pausado ? 'Reanudar lectura' : 'Pausar lectura',
                      style: IconButton.styleFrom(
                        backgroundColor: kMassYellow,
                        foregroundColor: kMassBlue,
                      ),
                      onPressed: () => setState(() => _pausado = !_pausado),
                      icon: Icon(_pausado ? Icons.play_arrow : Icons.pause),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _etiquetaEstado(
                      icono: _pausado
                          ? Icons.pause_circle
                          : Icons.sensors_rounded,
                      texto: _pausado
                          ? 'Lectura pausada'
                          : _modoSimulacion
                          ? 'Simulación activa'
                          : _sensorRealDetectado
                          ? 'Hardware conectado'
                          : 'Esperando señal física',
                      colorFondo: _pausado
                          ? Colors.orange.shade100
                          : kMassYellow,
                    ),
                    ActionChip(
                      avatar: Icon(
                        _modoSimulacion
                            ? Icons.stop_circle_outlined
                            : Icons.science_outlined,
                        size: 16,
                        color: kMassBlue,
                      ),
                      label: Text(
                        _modoSimulacion ? 'Usar sensor físico' : 'Simular señal',
                        style: const TextStyle(
                          color: kMassBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: Colors.white,
                      onPressed: () => _alternarSimulacion(!_modoSimulacion),
                    ),
                    ActionChip(
                      avatar: const Icon(
                        Icons.vibration,
                        size: 16,
                        color: kMassBlue,
                      ),
                      label: Text(
                        'Probar agitar ($_sacudidas)',
                        style: const TextStyle(
                          color: kMassBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: kMassMint,
                      onPressed: _registrarSacudida,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                _tarjetaNivelYBrujula(tabNum),
                const SizedBox(height: 12),
                _tarjetaSensor(
                  titulo: 'Acelerómetro (con gravedad)',
                  subtitulo:
                      'Fuerza G: ${_fuerzaG.toStringAsFixed(2)} g · Pico: ${_picoAceleracion.toStringAsFixed(1)} m/s²',
                  icono: Icons.speed_rounded,
                  unidad: 'm/s²',
                  x: _ax,
                  y: _ay,
                  z: _az,
                  escalaMax: 15,
                  tabNum: tabNum,
                ),
                const SizedBox(height: 10),
                _tarjetaSensor(
                  titulo: 'Aceleración Lineal (sin gravedad)',
                  subtitulo: 'Movimiento neto del dispositivo en el espacio',
                  icono: Icons.trending_up_rounded,
                  unidad: 'm/s²',
                  x: _uax,
                  y: _uay,
                  z: _uaz,
                  escalaMax: 10,
                  tabNum: tabNum,
                ),
                const SizedBox(height: 10),
                _tarjetaSensor(
                  titulo: 'Giroscopio',
                  subtitulo: 'Velocidad angular de rotación en 3 ejes',
                  icono: Icons.threesixty_rounded,
                  unidad: 'rad/s',
                  x: _gx,
                  y: _gy,
                  z: _gz,
                  escalaMax: 6,
                  tabNum: tabNum,
                ),
                const SizedBox(height: 10),
                _tarjetaSensor(
                  titulo: 'Magnetómetro (Brújula)',
                  subtitulo:
                      'Orientación: ${_rumboGrados.toStringAsFixed(0)}° ($_puntoCardinal)',
                  icono: Icons.explore_rounded,
                  unidad: 'µT',
                  x: _mx,
                  y: _my,
                  z: _mz,
                  escalaMax: 80,
                  tabNum: tabNum,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _etiquetaEstado({
    required IconData icono,
    required String texto,
    required Color colorFondo,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 16, color: kMassBlue),
          const SizedBox(width: 6),
          Text(
            texto,
            style: const TextStyle(
              color: kMassBlue,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaNivelYBrujula(List<FontFeature> tabNum) {
    final normX = (_ax / 9.81).clamp(-1.0, 1.0);
    final normY = (_ay / 9.81).clamp(-1.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: Container(
                decoration: BoxDecoration(
                  color: kMassMint,
                  shape: BoxShape.circle,
                  border: Border.all(color: kMassBlue, width: 2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: kMassBlue.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 110),
                      alignment: Alignment(-normX * 0.85, normY * 0.85),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: kMassBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 8,
                            height: 8,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: kMassYellow,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nivel e Inclinación',
                    style: TextStyle(
                      color: kMassBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rumbo magnético: ${_rumboGrados.toStringAsFixed(1)}° $_puntoCardinal',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontFeatures: tabNum,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fuerza G total: ${_fuerzaG.toStringAsFixed(2)} g',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontFeatures: tabNum,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () => setState(() => _picoAceleracion = 0),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Reiniciar pico'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaSensor({
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required String unidad,
    required double x,
    required double y,
    required double z,
    required double escalaMax,
    required List<FontFeature> tabNum,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: kMassYellow,
                  foregroundColor: kMassBlue,
                  child: Icon(icono),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          color: kMassBlue,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        subtitulo,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontFeatures: tabNum,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _barraEje('X', x, escalaMax, unidad, Colors.red.shade600, tabNum),
            const SizedBox(height: 6),
            _barraEje('Y', y, escalaMax, unidad, Colors.green.shade700, tabNum),
            const SizedBox(height: 6),
            _barraEje('Z', z, escalaMax, unidad, kMassBlue, tabNum),
          ],
        ),
      ),
    );
  }

  Widget _barraEje(
    String eje,
    double valor,
    double escalaMax,
    String unidad,
    Color color,
    List<FontFeature> tabNum,
  ) {
    final fraccion = (valor.abs() / escalaMax).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 22,
          child: Text(
            eje,
            style: TextStyle(fontWeight: FontWeight.w900, color: color),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fraccion,
              minHeight: 10,
              backgroundColor: color.withValues(alpha: 0.14),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 84,
          child: Text(
            '${valor.toStringAsFixed(2)} $unidad',
            textAlign: TextAlign.right,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              fontFeatures: tabNum,
            ),
          ),
        ),
      ],
    );
  }
}
