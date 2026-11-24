import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/carrito_service.dart';
import '../../services/consulta_tiendas.dart';
import '../../services/control_solicitudes_ruta.dart';
import '../../services/formato_recorrido.dart';
import '../../services/lectura_ubicacion.dart';
import '../../services/routing_service.dart';
import '../../tema/tema_mass.dart';
import '../../utils/utilidades.dart';
import '../ubicame/estado_ubicacion.dart';
import 'controles_mapa.dart';
import 'marcador_mass.dart';
import 'panel_ruta.dart';

const ejemplosRecorrido = <DestinoReferencia>[
  DestinoReferencia(
    nombre: 'Tienda Mass Centro — Huancayo',
    coordenada: LatLng(-12.0681, -75.2103),
  ),
  DestinoReferencia(
    nombre: 'Tienda Mass El Tambo — Huancayo',
    coordenada: LatLng(-12.0545, -75.2175),
  ),
  DestinoReferencia(
    nombre: 'Tienda Mass Miraflores — Lima',
    coordenada: LatLng(-12.1211, -77.0297),
  ),
  DestinoReferencia(
    nombre: 'Tienda Mass Los Olivos — Lima',
    coordenada: LatLng(-11.9911, -77.0706),
  ),
];

class DeliveryMapaScreen extends StatefulWidget {
  final String? nombreDestinoInicial;
  final String? detalleDestinoInicial;
  final LatLng? destinoInicial;
  final bool destinoDeTienda;
  final bool destinoEsEjemplo;
  final bool volverAlCarrito;
  final bool mostrarMapa;
  final Future<ResultadoRuta> Function(LatLng origen, LatLng destino, ModoRuta modo)? calcular;
  final Future<LecturaUbicacion> Function()? leerUbicacion;
  final Future<bool> Function(Uri uri)? abrirEnlace;
  final TileProvider? proveedorTeselas;

  const DeliveryMapaScreen({
    super.key,
    this.nombreDestinoInicial,
    this.detalleDestinoInicial,
    this.destinoInicial,
    this.destinoDeTienda = false,
    this.destinoEsEjemplo = false,
    this.volverAlCarrito = false,
    this.mostrarMapa = true,
    this.calcular,
    this.leerUbicacion,
    this.abrirEnlace,
    this.proveedorTeselas,
  });

  @override
  State<DeliveryMapaScreen> createState() => _DeliveryMapaScreenState();
}

class _DeliveryMapaScreenState extends State<DeliveryMapaScreen> {
  static const _vistaPais = LatLng(-9.19, -75.02);

  final MapController _mapController = MapController();
  final DraggableScrollableController _panel = DraggableScrollableController();
  final RoutingService _routing = RoutingService();
  final ControlSolicitudesRuta _solicitudes = ControlSolicitudesRuta();

  late String _nombreDestino;
  late String _detalleDestino;
  LatLng? _destino;
  ClaseDestino _clase = ClaseDestino.ninguno;
  bool _destinoInvalido = false;
  LatLng? _origen;
  double? _precision;
  ResultadoRuta? _ruta;
  String? _mensajeRuta;
  SituacionUbicacion? _situacion;
  ModoRuta _modo = ModoRuta.carro;
  bool _obteniendo = false;
  bool _calculando = false;
  bool _mapaListo = false;
  bool _expandido = false;

  @override
  void initState() {
    super.initState();
    _aplicarDestinoInicial();
    _panel.addListener(_alMoverPanel);
  }

  @override
  void dispose() {
    _panel.removeListener(_alMoverPanel);
    _panel.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _aplicarDestinoInicial() {
    final punto = widget.destinoInicial;
    final nombre = widget.nombreDestinoInicial?.trim() ?? '';
    final detalle = widget.detalleDestinoInicial?.trim() ?? '';
    if (punto != null && coordenadasValidas(punto.latitude, punto.longitude)) {
      _destino = punto;
      _nombreDestino = nombre.isEmpty ? 'Destino seleccionado' : nombre;
      _detalleDestino = detalle;
      if (widget.destinoDeTienda) {
        _clase = ClaseDestino.tienda;
      } else if (widget.destinoEsEjemplo) {
        _clase = ClaseDestino.ejemplo;
      } else {
        _clase = ClaseDestino.mapa;
      }
      return;
    }
    _nombreDestino = '';
    _detalleDestino = '';
    _destino = null;
    _clase = ClaseDestino.ninguno;
    _destinoInvalido = nombre.isNotEmpty || punto != null;
    if (_destinoInvalido && nombre.isNotEmpty) _nombreDestino = nombre;
  }

  void _alMoverPanel() {
    if (!_panel.isAttached || !mounted) return;
    final ahora = _panel.size >= 0.6;
    if (ahora == _expandido) return;
    setState(() => _expandido = ahora);
  }

  Future<void> _alternarPanel() async {
    if (!_panel.isAttached) return;
    final destino = _expandido ? 0.34 : 0.86;
    if (MediaQuery.disableAnimationsOf(context)) {
      _panel.jumpTo(destino);
      return;
    }
    await _panel.animateTo(
      destino,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _usarUbicacion() async {
    if (_obteniendo) return;
    setState(() {
      _obteniendo = true;
      _situacion = null;
    });
    final lectura = widget.leerUbicacion != null
        ? await widget.leerUbicacion!()
        : await leerUbicacionDelDispositivo(context);
    if (!mounted) return;
    setState(() {
      _obteniendo = false;
      _situacion = lectura.situacion;
      if (lectura.situacion == SituacionUbicacion.concedida && lectura.punto != null) {
        _origen = lectura.punto;
        _precision = lectura.precisionMetros;
      }
    });
    final origen = _origen;
    if (lectura.situacion == SituacionUbicacion.concedida && origen != null) {
      final destino = _destino;
      if (destino != null && !_destinoInvalido) {
        _encuadrar([origen, destino]);
        await _calcular();
      } else {
        _mover(origen, 15);
      }
    }
  }

  Future<void> _calcular({bool reemplazar = false}) async {
    final origen = _origen;
    final destino = _destino;
    if (origen == null || destino == null || _destinoInvalido) {
      setState(() {
        _mensajeRuta = origen == null
            ? 'Primero usa tu ubicación.'
            : 'Elige un destino para calcular la ruta.';
      });
      return;
    }
    if (_solicitudes.ocupada && !reemplazar) return;
    setState(() {
      _calculando = true;
      _mensajeRuta = null;
      _ruta = null;
    });
    final modo = _modo;
    final respuesta = await _solicitudes.ejecutar(() {
      final calcular = widget.calcular;
      if (calcular != null) return calcular(origen, destino, modo);
      return _routing.obtenerRuta(origen: origen, destino: destino, modo: modo);
    }, reemplazar: reemplazar);
    if (!mounted || respuesta.ignorada) {
      if (mounted && !_solicitudes.ocupada) {
        setState(() => _calculando = false);
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _calculando = false;
      if (respuesta.error != null) {
        _ruta = null;
        _mensajeRuta = 'No se pudo calcular la ruta. Inténtalo nuevamente.';
      } else {
        final ruta = respuesta.valor!;
        if (ruta.esEstimacionDirecta || ruta.puntos.length < 2) {
          _ruta = null;
          _mensajeRuta = 'La ruta por carretera no está disponible.';
        } else {
          _ruta = ruta;
          _mensajeRuta = null;
          _encuadrar(ruta.puntos);
        }
      }
    });
  }

  void _fijarDestino({
    required LatLng punto,
    required String nombre,
    required ClaseDestino clase,
    String detalle = '',
  }) {
    _solicitudes.invalidar();
    setState(() {
      _destino = punto;
      _nombreDestino = nombre;
      _detalleDestino = detalle;
      _clase = clase;
      _destinoInvalido = false;
      _ruta = null;
      _mensajeRuta = null;
      _calculando = false;
    });
    _mover(punto, 14);
    if (_origen != null) _calcular(reemplazar: true);
  }

  void _cambiarModo(ModoRuta modo) {
    if (modo == _modo) return;
    _solicitudes.invalidar();
    setState(() {
      _modo = modo;
      _ruta = null;
      _mensajeRuta = null;
    });
    if (_origen != null && _destino != null && !_destinoInvalido) {
      _calcular(reemplazar: true);
    }
  }

  void _mover(LatLng punto, double zoom) {
    if (!widget.mostrarMapa || !_mapaListo) return;
    try {
      _mapController.move(punto, zoom);
    } on Object {
      return;
    }
  }

  void _encuadrar(List<LatLng> puntos) {
    if (!widget.mostrarMapa || !_mapaListo || puntos.length < 2 || !mounted) return;
    final alto = MediaQuery.sizeOf(context).height;
    final reserva = alto * 0.38 + 28;
    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(puntos),
          padding: EdgeInsets.fromLTRB(72, 128, 72, reserva),
        ),
      );
    } on Object {
      return;
    }
  }

  Future<bool> _abrir(Uri uri) {
    final abrir = widget.abrirEnlace;
    if (abrir != null) return abrir(uri);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String? get _aclaracion {
    return switch (_clase) {
      ClaseDestino.ejemplo => 'Destino de ejemplo. No es un establecimiento registrado.',
      ClaseDestino.mapa => 'Punto elegido en el mapa. No es un establecimiento registrado.',
      _ => null,
    };
  }

  String? get _distanciaRecta {
    final origen = _origen;
    final destino = _destino;
    if (origen == null || destino == null || _ruta != null) return null;
    return textoDistanciaRecorrido(distanciaLineaRectaMetros(origen, destino));
  }

  Future<void> _verEjemplos() async {
    final tokens = TokensMass.de(context);
    final elegido = await showModalBottomSheet<DestinoReferencia>(
      context: context,
      backgroundColor: tokens.superficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: [
              Text(
                'Recorridos de ejemplo',
                style: textoMass(tamano: 18, peso: FontWeight.w800, color: tokens.profundo),
              ),
              const SizedBox(height: 6),
              Text(
                'Estos puntos no son establecimientos registrados.',
                style: textoMass(tamano: 13, color: tokens.tintaSuave, alto: 1.35),
              ),
              const SizedBox(height: 12),
              for (final ejemplo in ejemplosRecorrido)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, ejemplo),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: tokens.tinta,
                      minimumSize: const Size.fromHeight(48),
                      alignment: Alignment.centerLeft,
                      side: BorderSide(color: tokens.linea),
                    ),
                    child: Text(ejemplo.nombre, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                ),
            ],
          ),
        );
      },
    );
    if (elegido == null || !mounted) return;
    _fijarDestino(
      punto: elegido.coordenada,
      nombre: elegido.nombre,
      clase: ClaseDestino.ejemplo,
    );
  }

  Future<void> _abrirNavegacion() async {
    final origen = _origen;
    final destino = _destino;
    if (origen == null || destino == null) {
      setState(() => _mensajeRuta = 'Primero usa tu ubicación.');
      return;
    }
    final uri = RoutingService.urlGoogleMaps(origen: origen, destino: destino, modo: _modo);
    if (!await _abrir(uri) && mounted) {
      setState(() => _mensajeRuta = 'No se pudo abrir la aplicación de mapas.');
    }
  }

  Future<void> _adjuntar() async {
    final ruta = _ruta;
    final origen = _origen;
    if (ruta == null || origen == null) return;
    CarritoService.instance.setRutaSeleccionada(
      resumenRutaParaCarrito(nombreDestino: _nombreDestino, modo: _modo, ruta: ruta),
    );
    if (!mounted) return;
    if (widget.volverAlCarrito && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
      return;
    }
    mostrarMensaje(context, 'Ruta adjunta a tu carrito. No incluye un costo de entrega.');
  }

  Future<void> _compartir() async {
    final ruta = _ruta;
    final origen = _origen;
    final destino = _destino;
    if (ruta == null || origen == null || destino == null) return;
    final mensaje = RoutingService.construirMensajeRuta(
      nombreDestino: _nombreDestino,
      origen: origen,
      destino: destino,
      modo: _modo,
      ruta: ruta,
      aclaracion: _aclaracion,
    );
    final tokens = TokensMass.de(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: tokens.superficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Revisar antes de compartir',
                  style: textoMass(tamano: 18, peso: FontWeight.w800, color: tokens.profundo),
                ),
                const SizedBox(height: 6),
                Text(
                  'El mensaje incluye el destino y el enlace del recorrido. Revísalo antes de enviarlo.',
                  style: textoMass(tamano: 13, color: tokens.tintaSuave, alto: 1.35),
                ),
                const SizedBox(height: 12),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: tokens.fondo,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(
                      mensaje,
                      style: textoMass(tamano: 13, color: tokens.tinta, alto: 1.4),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(mensaje)}');
                    Navigator.pop(ctx);
                    final ok = await _abrir(uri);
                    if (!ok && mounted) {
                      await Clipboard.setData(ClipboardData(text: mensaje));
                      if (mounted) {
                        mostrarMensaje(context, 'No se pudo abrir WhatsApp. La ruta se copió.');
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.accion,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    textStyle: textoMass(tamano: 14, peso: FontWeight.w800, color: Colors.white),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Enviar por WhatsApp'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: mensaje));
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) mostrarMensaje(context, 'Ruta copiada.');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: tokens.accion,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copiar ruta'),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _adjuntar();
                  },
                  style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                  label: Text(
                    widget.volverAlCarrito
                        ? 'Adjuntar y volver al carrito'
                        : 'Adjuntar al carrito',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final aviso = _situacion == null
        ? null
        : mensajeSituacionUbicacion(_situacion!, enMapa: true);
    return Scaffold(
      backgroundColor: tokens.profundo,
      appBar: AppBar(
        title: const Text('Delivery y rutas'),
        actions: [
          if (_ruta != null)
            IconButton(
              key: const Key('compartir-appbar'),
              tooltip: 'Compartir ruta',
              onPressed: _compartir,
              icon: const Icon(Icons.ios_share_rounded),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, limites) {
          final controlesBottom = limites.maxHeight * 0.34 + 12;
          return Stack(
            children: [
              Positioned.fill(child: _mapa(tokens)),
              if (widget.mostrarMapa && !_mapaListo)
                const Positioned(
                  top: 12,
                  left: 16,
                  child: Text('Cargando mapa'),
                ),
              if (aviso != null)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 44,
                  child: AvisoContextual(icono: Icons.my_location_outlined, mensaje: aviso),
                ),
              Positioned(
                right: 12,
                bottom: controlesBottom,
                child: ControlesMapa(
                  puedeCentrar: !_obteniendo,
                  puedeVerRuta: _ruta != null,
                  alCentrar: () {
                    final origen = _origen;
                    if (origen == null) {
                      _usarUbicacion();
                    } else {
                      _mover(origen, 15);
                    }
                  },
                  alVerRuta: () {
                    final ruta = _ruta;
                    if (ruta != null) _encuadrar(ruta.puntos);
                  },
                ),
              ),
              DraggableScrollableSheet(
                controller: _panel,
                minChildSize: 0.30,
                initialChildSize: 0.34,
                maxChildSize: 0.86,
                snap: true,
                snapSizes: const [0.34, 0.86],
                builder: (context, scroll) {
                  return PanelRutaMass(
                    scroll: scroll,
                    expandido: _expandido,
                    clase: _clase,
                    nombreDestino: _nombreDestino,
                    detalleDestino: _detalleDestino,
                    destinoInvalido: _destinoInvalido,
                    tieneOrigen: _origen != null,
                    precisionMetros: _precision,
                    obteniendo: _obteniendo,
                    calculando: _calculando,
                    ruta: _ruta,
                    mensaje: _mensajeRuta,
                    distanciaRecta: _distanciaRecta,
                    modo: _modo,
                    volverAlCarrito: widget.volverAlCarrito,
                    alVerEjemplos: _verEjemplos,
                    alAmpliar: _alternarPanel,
                    alUsarUbicacion: _usarUbicacion,
                    alCalcular: _calcular,
                    alCambiarModo: _cambiarModo,
                    alCompartir: _compartir,
                    alAdjuntar: _adjuntar,
                    alAbrirMapas: _abrirNavegacion,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _mapa(TokensMass tokens) {
    if (!widget.mostrarMapa) {
      return ColoredBox(
        color: tokens.fondo,
        child: const SizedBox.expand(),
      );
    }
    final destino = _destino;
    final origen = _origen;
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: destino ?? _vistaPais,
        initialZoom: destino == null ? 5.2 : 14,
        onMapReady: () {
          if (mounted) setState(() => _mapaListo = true);
        },
        onTap: (_, punto) {
          if (!coordenadasValidas(punto.latitude, punto.longitude)) return;
          _fijarDestino(
            punto: punto,
            nombre:
                'Punto ${punto.latitude.toStringAsFixed(4)}, ${punto.longitude.toStringAsFixed(4)}',
            clase: ClaseDestino.mapa,
          );
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.tiendasmass.app',
          // La caché integrada falla al pedir el directorio en este
          // dispositivo y deja el mapa en blanco. Las teselas siguen
          // siendo las de OpenStreetMap, sin caché local.
          tileProvider: widget.proveedorTeselas ??
              NetworkTileProvider(
                cachingProvider: const DisabledMapCachingProvider(),
              ),
        ),
        if (_ruta != null && !_ruta!.esEstimacionDirecta && _ruta!.puntos.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _ruta!.puntos,
                strokeWidth: 5,
                color: _modo == ModoRuta.carro ? tokens.accion : tokens.profundo,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (destino != null)
              Marker(
                point: destino,
                width: 88,
                height: 78,
                alignment: Alignment.topCenter,
                child: MarcadorMass(
                  destino: true,
                  etiqueta: switch (_clase) {
                    ClaseDestino.tienda => 'Tienda',
                    ClaseDestino.ejemplo => 'Ejemplo',
                    _ => 'Punto',
                  },
                  descripcion: 'Marcador de destino, $_nombreDestino',
                ),
              ),
            if (origen != null)
              Marker(
                point: origen,
                width: 72,
                height: 64,
                alignment: Alignment.topCenter,
                child: const MarcadorMass(
                  destino: false,
                  etiqueta: 'Tú',
                  descripcion: 'Marcador de origen. Tu ubicación.',
                ),
              ),
          ],
        ),
        Align(
          alignment: Alignment.topLeft,
          child: SafeArea(
            minimum: const EdgeInsets.all(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 210),
              child: Material(
                color: const Color(0xF2FFFFFF),
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  onTap: () => _abrir(
                    Uri.parse('https://www.openstreetmap.org/copyright'),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text(
                      '© OpenStreetMap contributors',
                      style: textoMass(
                        tamano: 11,
                        peso: FontWeight.w700,
                        color: tokens.tinta,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
