import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/cupon.dart';
import '../../services/carrito_service.dart';
import '../../services/telemetria_sensores.dart';
import '../../tema/tema_mass.dart';
import '../../utils/utilidades.dart';
import 'brujula_mass.dart';
import 'instrumento_acelerometro.dart';
import 'instrumento_giroscopio.dart';
import 'nivel_mass.dart';
import 'tarjeta_cupon_movimiento.dart';

class SensoresScreen extends StatefulWidget {
  final bool visible;
  final FuenteSensores? fuente;
  final DateTime Function()? ahora;

  const SensoresScreen({
    super.key,
    this.visible = true,
    this.fuente,
    this.ahora,
  });

  @override
  State<SensoresScreen> createState() => _SensoresScreenState();
}

class _SensoresScreenState extends State<SensoresScreen>
    with WidgetsBindingObserver {
  final _acc = ValueNotifier<VistaAcelerometro>(VistaAcelerometro.vacia);
  final _gyro = ValueNotifier<VistaGiroscopio>(VistaGiroscopio.vacia);
  final _brujula = ValueNotifier<VistaBrujula>(VistaBrujula.vacia);
  final _nivel = ValueNotifier<VistaNivel>(VistaNivel.vacia);

  final _serieAcc = SerieLecturas();
  final _serieLineal = SerieLecturas();
  final _serieGyro = SerieLecturas();
  final _detector = DetectorSacudida();

  StreamSubscription<LecturaEjes>? _subAcc;
  StreamSubscription<LecturaEjes>? _subLineal;
  StreamSubscription<LecturaEjes>? _subGyro;
  StreamSubscription<LecturaEjes>? _subMag;

  SituacionSensor _sitAcc = SituacionSensor.esperando;
  SituacionSensor _sitLineal = SituacionSensor.esperando;
  SituacionSensor _sitGyro = SituacionSensor.esperando;
  SituacionSensor _sitMag = SituacionSensor.esperando;

  LecturaEjes? _gravedad;
  LecturaEjes? _lineal;
  LecturaEjes? _giro;
  double _pico = 0;
  double? _rumboMostrado;
  double? _rumboLectura;

  bool _escuchando = false;
  bool _primerPlano = true;
  bool _pausaManual = false;
  bool _simulacion = false;
  Timer? _simulador;
  Timer? _pintura;
  bool _pinturaPendiente = false;
  double _fase = 0;
  int _sacudidasSimuladas = 0;
  String _avisoSimulacion = '';

  CuponDescuento? _cuponOfrecido;
  String _mensajeCupon =
      'Esperando un movimiento real del dispositivo.';
  bool _cuponAplicado = false;

  DateTime get _ahora => widget.ahora?.call() ?? DateTime.now();

  bool get _puedeLeer =>
      widget.visible && _primerPlano && !_pausaManual && !_simulacion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sincronizar();
  }

  @override
  void didUpdateWidget(covariant SensoresScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fuente != widget.fuente) _cancelar();
    if (oldWidget.visible != widget.visible ||
        oldWidget.fuente != widget.fuente) {
      _sincronizar();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final activo = state == AppLifecycleState.resumed;
    if (activo == _primerPlano) return;
    _primerPlano = activo;
    _sincronizar();
  }

  void _sincronizar() {
    if (_puedeLeer) {
      _suscribir();
    } else {
      _cancelar();
    }
    final simular =
        widget.visible && _primerPlano && !_pausaManual && _simulacion;
    if (simular) {
      _iniciarSimulacion();
    } else {
      _simulador?.cancel();
      _simulador = null;
    }
    _publicar(forzar: true);
  }

  void _suscribir() {
    if (_escuchando) return;
    final fuente = widget.fuente ?? FuenteSensores.dispositivo();
    _escuchando = true;
    _subAcc = _escuchar(fuente.acelerometro, _onGravedad, _falloAcc);
    _subLineal = _escuchar(fuente.lineal, _onLineal, _falloLineal);
    _subGyro = _escuchar(fuente.giroscopio, _onGiro, _falloGiro);
    _subMag = _escuchar(fuente.magnetometro, _onMag, _falloMag);
  }

  StreamSubscription<LecturaEjes>? _escuchar(
    Stream<LecturaEjes> Function() abrir,
    void Function(LecturaEjes) onData,
    void Function() onError,
  ) {
    try {
      return abrir().listen(onData, onError: (_) => onError());
    } catch (_) {
      onError();
      return null;
    }
  }

  void _cancelar() {
    _subAcc?.cancel();
    _subLineal?.cancel();
    _subGyro?.cancel();
    _subMag?.cancel();
    _subAcc = null;
    _subLineal = null;
    _subGyro = null;
    _subMag = null;
    _escuchando = false;
    _pintura?.cancel();
    _pinturaPendiente = false;
  }

  SituacionSensor _estado(SituacionSensor actual) {
    if (_simulacion && widget.visible && _primerPlano && !_pausaManual) {
      return SituacionSensor.simulado;
    }
    if (!widget.visible || !_primerPlano || _pausaManual) {
      if (actual == SituacionSensor.noDisponible ||
          actual == SituacionSensor.error) {
        return actual;
      }
      if (actual == SituacionSensor.esperando) return actual;
      return SituacionSensor.enPausa;
    }
    return actual == SituacionSensor.simulado ? SituacionSensor.esperando : actual;
  }

  void _onGravedad(LecturaEjes lectura) => _recibirGravedad(lectura, real: true);

  void _recibirGravedad(LecturaEjes lectura, {required bool real}) {
    if (!mounted || (_simulacion && real) || _pausaManual) return;
    if (!widget.visible || !_primerPlano) return;
    if (!lectura.valida) {
      _sitAcc = SituacionSensor.error;
      _programarPintura();
      return;
    }
    _gravedad = lectura;
    _sitAcc = real ? SituacionSensor.activo : SituacionSensor.simulado;
    _serieAcc.agregar(lectura);
    if (lectura.magnitud > _pico) _pico = lectura.magnitud;
    if (real) _ofrecerSiSacude(lineal: 0, total: lectura.magnitud);
    _programarPintura();
  }

  void _onLineal(LecturaEjes lectura) {
    if (!mounted || _simulacion || _pausaManual) return;
    if (!widget.visible || !_primerPlano) return;
    if (!lectura.valida) {
      _sitLineal = SituacionSensor.error;
      _programarPintura();
      return;
    }
    _lineal = lectura;
    _sitLineal = SituacionSensor.activo;
    _serieLineal.agregar(lectura);
    _ofrecerSiSacude(lineal: lectura.magnitud, total: 0);
    _programarPintura();
  }

  void _onGiro(LecturaEjes lectura) => _recibirGiro(lectura, real: true);

  void _recibirGiro(LecturaEjes lectura, {required bool real}) {
    if (!mounted || (_simulacion && real) || _pausaManual) return;
    if (!widget.visible || !_primerPlano) return;
    if (!lectura.valida) {
      _sitGyro = SituacionSensor.error;
      _programarPintura();
      return;
    }
    _giro = lectura;
    _sitGyro = real ? SituacionSensor.activo : SituacionSensor.simulado;
    _serieGyro.agregar(lectura);
    _programarPintura();
  }

  void _onMag(LecturaEjes lectura) => _recibirMag(lectura, real: true);

  void _recibirMag(LecturaEjes lectura, {required bool real}) {
    if (!mounted || (_simulacion && real) || _pausaManual) return;
    if (!widget.visible || !_primerPlano) return;
    final rumbo = rumboGrados(lectura.x, lectura.y);
    if (!lectura.valida || rumbo == null) {
      _sitMag = SituacionSensor.error;
      _programarPintura();
      return;
    }
    final saltar = MediaQuery.disableAnimationsOf(context);
    _rumboMostrado = _rumboMostrado == null
        ? rumbo
        : suavizarRumbo(_rumboMostrado!, rumbo, saltar: saltar);
    _rumboLectura = rumbo;
    _sitMag = real ? SituacionSensor.activo : SituacionSensor.simulado;
    _programarPintura();
  }

  void _falloAcc() {
    _sitAcc = SituacionSensor.noDisponible;
    _programarPintura();
  }

  void _falloLineal() {
    _sitLineal = SituacionSensor.noDisponible;
    _programarPintura();
  }

  void _falloGiro() {
    _sitGyro = SituacionSensor.noDisponible;
    _programarPintura();
  }

  void _falloMag() {
    _sitMag = SituacionSensor.noDisponible;
    _programarPintura();
  }

  void _ofrecerSiSacude({required double lineal, required double total}) {
    final resultado = _detector.evaluar(
      magnitudLineal: lineal,
      magnitudConGravedad: total,
      ahora: _ahora,
    );
    if (!resultado.detectada || resultado.cupon == null) return;
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
    final cupon = resultado.cupon!;
    setState(() {
      _cuponOfrecido = cupon;
      _cuponAplicado = false;
      _mensajeCupon = 'Sacudida detectada. Puedes usar ${cupon.codigo}.';
    });
    mostrarMensaje(context, _mensajeCupon);
  }

  void _usarCupon() {
    final cupon = _cuponOfrecido;
    if (cupon == null || !mounted) return;
    final error = CarritoService.instance.aplicarCupon(cupon);
    setState(() {
      _cuponAplicado = error == null;
      _mensajeCupon = error ?? 'Cupón ${cupon.codigo} aplicado al carrito.';
    });
    mostrarMensaje(context, _mensajeCupon);
  }

  void _programarPintura() {
    if (_pinturaPendiente) return;
    _pinturaPendiente = true;
    _pintura = Timer(const Duration(milliseconds: 100), () {
      _pinturaPendiente = false;
      _publicar();
    });
  }

  void _publicar({bool forzar = false}) {
    if (!mounted) return;
    if (!forzar && _pinturaPendiente) return;
    final sitAcc = _estado(
      _sitAcc == SituacionSensor.esperando &&
              _sitLineal != SituacionSensor.esperando
          ? _sitLineal
          : _sitAcc,
    );
    _acc.value = VistaAcelerometro(
      gravedad: _gravedad,
      lineal: _lineal,
      serieGravedad: _serieAcc.muestras,
      serieLineal: _serieLineal.muestras,
      situacion: sitAcc,
      pico: _pico,
    );
    _gyro.value = VistaGiroscopio(
      lectura: _giro,
      serie: _serieGyro.muestras,
      situacion: _estado(_sitGyro),
    );
    _brujula.value = VistaBrujula(
      gradosMostrados: _rumboMostrado,
      gradosLectura: _rumboLectura,
      situacion: _estado(_sitMag),
    );
    _nivel.value = VistaNivel(
      burbuja: _gravedad == null ? null : burbujaDesdeAcelerometro(_gravedad!),
      lectura: _gravedad,
      situacion: _estado(_sitAcc),
    );
  }

  void _iniciarSimulacion() {
    _simulador ??= Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!mounted) return;
      _fase += 0.16;
      _recibirGravedad(
        LecturaEjes(
          math.sin(_fase) * 3.8,
          math.cos(_fase * 0.7) * 2.9,
          9.81 + math.sin(_fase * 1.4) * 0.4,
        ),
        real: false,
      );
      _lineal = LecturaEjes(
        math.cos(_fase * 1.3) * 1.2,
        math.sin(_fase * 1.1) * 0.9,
        math.sin(_fase * 0.6) * 0.5,
      );
      _sitLineal = SituacionSensor.simulado;
      _serieLineal.agregar(_lineal!);
      _recibirGiro(
        LecturaEjes(
          math.sin(_fase * 0.9) * 0.8,
          math.cos(_fase * 1.2) * 0.7,
          math.sin(_fase * 0.5) * 0.4,
        ),
        real: false,
      );
      _recibirMag(
        LecturaEjes(
          math.cos(_fase * 0.25) * 42,
          math.sin(_fase * 0.25) * 42,
          -18.5,
        ),
        real: false,
      );
    });
  }

  void _alternarSimulacion(bool activa) {
    _serieAcc.limpiar();
    _serieLineal.limpiar();
    _serieGyro.limpiar();
    _gravedad = null;
    _lineal = null;
    _giro = null;
    _rumboMostrado = null;
    _rumboLectura = null;
    _pico = 0;
    _sitAcc = SituacionSensor.esperando;
    _sitLineal = SituacionSensor.esperando;
    _sitGyro = SituacionSensor.esperando;
    _sitMag = SituacionSensor.esperando;
    setState(() => _simulacion = activa);
    _sincronizar();
  }

  void _simularSacudida() {
    setState(() {
      _sacudidasSimuladas++;
      _avisoSimulacion = 'Sacudida simulada. No se desbloqueó un cupón.';
    });
  }

  void _alternarPausa() {
    setState(() => _pausaManual = !_pausaManual);
    _sincronizar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelar();
    _simulador?.cancel();
    _acc.dispose();
    _gyro.dispose();
    _brujula.dispose();
    _nivel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Scaffold(
      backgroundColor: tokens.fondo,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Text(
            'Sensores inteligentes',
            style: textoMass(
              tamano: 22,
              peso: FontWeight.w700,
              color: tokens.profundo,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Explora las capacidades de tu dispositivo',
            style: textoMass(tamano: 13, color: tokens.tintaSuave),
          ),
          const SizedBox(height: 6),
          Text(
            'Las lecturas se pausan al salir de esta pestaña. No se envían a la nube.',
            style: textoMass(tamano: 12, color: tokens.tintaSuave),
          ),
          const SizedBox(height: 14),
          ValueListenableBuilder<VistaAcelerometro>(
            valueListenable: _acc,
            builder: (_, vista, _) => InstrumentoAcelerometro(
              vista: vista,
              alReiniciarPico: () {
                _pico = 0;
                _publicar(forzar: true);
              },
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<VistaGiroscopio>(
            valueListenable: _gyro,
            builder: (_, vista, _) => InstrumentoGiroscopio(vista: vista),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<VistaBrujula>(
            valueListenable: _brujula,
            builder: (_, vista, _) => BrujulaMass(vista: vista),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<VistaNivel>(
            valueListenable: _nivel,
            builder: (_, vista, _) => NivelMass(vista: vista),
          ),
          const SizedBox(height: 12),
          TarjetaCuponMovimiento(
            cupon: _cuponOfrecido,
            mensaje: _mensajeCupon,
            aplicado: _cuponAplicado,
            alUsar: _cuponOfrecido == null ? null : _usarCupon,
          ),
          const SizedBox(height: 12),
          HerramientasDemostracion(
            simulando: _simulacion,
            pausado: _pausaManual,
            sacudidasSimuladas: _sacudidasSimuladas,
            aviso: _avisoSimulacion,
            alSimular: _alternarSimulacion,
            alSimularSacudida: _simularSacudida,
            alPausar: _alternarPausa,
          ),
        ],
      ),
    );
  }
}
