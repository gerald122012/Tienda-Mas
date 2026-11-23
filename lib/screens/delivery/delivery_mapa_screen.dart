import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../main.dart';
import '../../services/carrito_service.dart';
import '../../services/permisos_service.dart';
import '../../services/routing_service.dart';
import '../../utils/utilidades.dart';

class _DestinoMapa {
  final String nombre;
  final LatLng coordenada;

  const _DestinoMapa(this.nombre, this.coordenada);
}

class DeliveryMapaScreen extends StatefulWidget {
  final String? nombreDestinoInicial;
  final LatLng? destinoInicial;

  const DeliveryMapaScreen({
    super.key,
    this.nombreDestinoInicial,
    this.destinoInicial,
  });

  @override
  State<DeliveryMapaScreen> createState() => _DeliveryMapaScreenState();
}

class _DeliveryMapaScreenState extends State<DeliveryMapaScreen> {
  static const _destinosBase = [
    _DestinoMapa('Tienda Mass Centro — Huancayo', LatLng(-12.0681, -75.2103)),
    _DestinoMapa('Tienda Mass El Tambo — Huancayo', LatLng(-12.0545, -75.2175)),
    _DestinoMapa('Tienda Mass Miraflores — Lima', LatLng(-12.1211, -77.0297)),
    _DestinoMapa('Tienda Mass Los Olivos — Lima', LatLng(-11.9911, -77.0706)),
  ];

  final MapController _mapController = MapController();
  final RoutingService _routingService = RoutingService();

  late String _nombreDestino;
  late LatLng _destino;
  LatLng? _ubicacionMovil;
  double? _precisionMetros;
  ResultadoRuta? _ruta;
  ModoRuta _modo = ModoRuta.carro;
  bool _obteniendoUbicacion = false;
  bool _calculandoRuta = false;
  bool _mostrarPasos = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nombreDestino =
        widget.nombreDestinoInicial ?? _destinosBase.first.nombre;
    _destino = widget.destinoInicial ?? _destinosBase.first.coordenada;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _obtenerUbicacion(mostrarDialogoPrevio: false);
    });
  }

  Future<void> _obtenerUbicacion({bool mostrarDialogoPrevio = true}) async {
    setState(() {
      _obteniendoUbicacion = true;
      _error = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Activa el GPS o servicio de ubicación del móvil.');
      }
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        if (mostrarDialogoPrevio && mounted) {
          final continuar =
              await PermisosService.solicitarPermisoUbicacion(context);
          if (!continuar) {
            setState(() => _obteniendoUbicacion = false);
            return;
          }
        }
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        throw Exception('No se concedió permiso para obtener la ubicación.');
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: defaultTargetPlatform == TargetPlatform.android
            ? AndroidSettings(
                accuracy: LocationAccuracy.high,
                forceLocationManager: true,
                timeLimit: const Duration(seconds: 20),
              )
            : const LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 20),
              ),
      );
      if (!mounted) return;
      setState(() {
        _ubicacionMovil = LatLng(pos.latitude, pos.longitude);
        _precisionMetros = pos.accuracy;
      });
      _mapController.move(_ubicacionMovil!, 14.5);
      await _calcularRuta();
    } on TimeoutException {
      if (mounted) {
        setState(
          () => _error =
              'No se pudo obtener tu ubicación a tiempo. Revisa la señal GPS e intenta nuevamente con "Mi ubicación".',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _obteniendoUbicacion = false);
    }
  }

  Future<void> _calcularRuta() async {
    if (_ubicacionMovil == null) {
      setState(() => _error = 'Primero obtén tu ubicación actual.');
      return;
    }
    setState(() {
      _calculandoRuta = true;
      _error = null;
    });
    try {
      final resultado = await _routingService.obtenerRuta(
        origen: _ubicacionMovil!,
        destino: _destino,
        modo: _modo,
      );
      if (!mounted) return;
      setState(() => _ruta = resultado);
      _encuadrarRuta(resultado.puntos);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _calculandoRuta = false);
    }
  }

  void _encuadrarRuta(List<LatLng> puntos) {
    if (puntos.length < 2) return;
    try {
      final bounds = LatLngBounds.fromPoints(puntos);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
      );
    } catch (_) {}
  }

  void _seleccionarDestinoManual(LatLng punto) {
    setState(() {
      _destino = punto;
      _nombreDestino =
          'Punto seleccionado (${punto.latitude.toStringAsFixed(4)}, ${punto.longitude.toStringAsFixed(4)})';
      _ruta = null;
    });
    if (_ubicacionMovil != null) {
      _calcularRuta();
    }
  }

  Future<void> _abrirNavegacion() async {
    if (_ubicacionMovil == null) {
      setState(() => _error = 'Primero obtén tu ubicación actual.');
      return;
    }
    final uri = RoutingService.urlGoogleMaps(
      origen: _ubicacionMovil!,
      destino: _destino,
      modo: _modo,
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      setState(() => _error = 'No se pudo abrir la aplicación de navegación.');
    }
  }

  Future<void> _compartirYEnviarRuta() async {
    if (_ubicacionMovil == null || _ruta == null) {
      mostrarMensaje(context, 'Calcula primero una ruta para poder enviarla.');
      return;
    }
    final mensaje = RoutingService.construirMensajeRuta(
      nombreDestino: _nombreDestino,
      origen: _ubicacionMovil!,
      destino: _destino,
      modo: _modo,
      ruta: _ruta!,
    );

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: kMassCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enviar o guardar ruta generada',
                style: TextStyle(
                  color: kMassBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SelectableText(
                  mensaje,
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () async {
                  final waUri = Uri.parse(
                    'https://wa.me/?text=${Uri.encodeComponent(mensaje)}',
                  );
                  Navigator.pop(ctx);
                  final ok = await launchUrl(
                    waUri,
                    mode: LaunchMode.externalApplication,
                  );
                  if (!ok && mounted) {
                    await Clipboard.setData(ClipboardData(text: mensaje));
                    if (mounted) {
                      mostrarMensaje(
                        context,
                        'Ruta copiada al portapapeles para compartir.',
                      );
                    }
                  }
                },
                icon: const Icon(Icons.send_rounded),
                label: const Text('ENVIAR POR WHATSAPP'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: mensaje));
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    mostrarMensaje(
                      context,
                      'Resumen y enlace de ruta copiados al portapapeles.',
                    );
                  }
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('COPIAR RUTA Y ENLACE'),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  final resumenCorto =
                      '$_nombreDestino · ${_ruta!.distanciaKm.toStringAsFixed(2)} km · ${_ruta!.duracionMinutos} min';
                  CarritoService.instance.setRutaSeleccionada(resumenCorto);
                  Navigator.pop(ctx);
                  mostrarMensaje(
                    context,
                    'Ruta adjuntada a tu carrito para el pedido.',
                  );
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('ADJUNTAR RUTA A MI PEDIDO'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geolocalización y Rutas'),
        actions: [
          if (_ruta != null)
            IconButton(
              tooltip: 'Enviar ruta',
              icon: const Icon(Icons.share_rounded),
              onPressed: _compartirYEnviarRuta,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _destinosBase.any((d) => d.nombre == _nombreDestino)
                      ? _nombreDestino
                      : null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Destino (o toca el mapa para elegir)',
                    hintText: _nombreDestino,
                    prefixIcon: const Icon(Icons.storefront, color: kMassBlue),
                    isDense: true,
                  ),
                  items: _destinosBase
                      .map(
                        (d) => DropdownMenuItem(
                          value: d.nombre,
                          child: Text(
                            d.nombre,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (valor) {
                    if (valor == null) return;
                    final encontrado = _destinosBase.firstWhere(
                      (d) => d.nombre == valor,
                    );
                    setState(() {
                      _nombreDestino = encontrado.nombre;
                      _destino = encontrado.coordenada;
                      _ruta = null;
                    });
                    _mapController.move(_destino, 14);
                    if (_ubicacionMovil != null) _calcularRuta();
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<ModoRuta>(
                        segments: const [
                          ButtonSegment(
                            value: ModoRuta.carro,
                            icon: Icon(Icons.directions_car),
                            label: Text('Vehículo'),
                          ),
                          ButtonSegment(
                            value: ModoRuta.caminando,
                            icon: Icon(Icons.directions_walk),
                            label: Text('Caminando'),
                          ),
                        ],
                        selected: {_modo},
                        onSelectionChanged: (value) {
                          setState(() {
                            _modo = value.first;
                            _ruta = null;
                            _error = null;
                          });
                          if (_ubicacionMovil != null) _calcularRuta();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _destino,
                    initialZoom: 13.5,
                    onTap: (_, punto) => _seleccionarDestinoManual(punto),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.tiendasmass.app',
                    ),
                    if (_ruta != null)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _ruta!.puntos,
                            strokeWidth: 5,
                            color: _modo == ModoRuta.carro
                                ? kMassBlue
                                : Colors.teal.shade700,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _destino,
                          width: 48,
                          height: 48,
                          child: const Icon(
                            Icons.location_on,
                            color: kMassBlue,
                            size: 42,
                          ),
                        ),
                        if (_ubicacionMovil != null)
                          Marker(
                            point: _ubicacionMovil!,
                            width: 46,
                            height: 46,
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.red,
                              size: 34,
                            ),
                          ),
                      ],
                    ),
                    const RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution('© OpenStreetMap contributors'),
                      ],
                    ),
                  ],
                ),
                if (_precisionMetros != null)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'GPS activo (±${_precisionMetros!.round()} m)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: kMassBlue,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_error != null)
            Container(
              width: double.infinity,
              color: Colors.orange.shade50,
              padding: const EdgeInsets.all(10),
              child: Text(
                _error!,
                style: TextStyle(color: Colors.orange.shade900, fontSize: 12.5),
              ),
            ),
          if (_ruta != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.route, color: kMassBlue, size: 20),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${_ruta!.distanciaKm.toStringAsFixed(2)} km · ${_ruta!.duracionMinutos} min',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: kMassBlue,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (_modo == ModoRuta.carro)
                            precioUnaLinea(
                              'Envío ${formatoPrecio(RoutingService.tarifaDelivery(_ruta!.distanciaMetros))}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: kMassBlue,
                                fontSize: 15,
                              ),
                              alignment: Alignment.centerRight,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _ruta!.esEstimacionDirecta
                                  ? 'Ruta estimada según coordenadas GPS actuales.'
                                  : 'Distancia y tiempo estimados según ruta y tránsito actual.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          if (_ruta!.pasos.isNotEmpty)
                            TextButton(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              onPressed: () => setState(
                                () => _mostrarPasos = !_mostrarPasos,
                              ),
                              child: Text(
                                _mostrarPasos
                                    ? 'Ocultar pasos'
                                    : 'Ver pasos (${_ruta!.pasos.length})',
                              ),
                            ),
                        ],
                      ),
                      if (_mostrarPasos && _ruta!.pasos.isNotEmpty)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 110),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _ruta!.pasos.length,
                            itemBuilder: (_, i) {
                              final paso = _ruta!.pasos[i];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: Text(
                                  '${i + 1}. ${paso.instruccion}'
                                  '${paso.distanciaMetros > 0 ? ' (${paso.distanciaMetros.round()} m)' : ''}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _obteniendoUbicacion
                              ? null
                              : () => _obtenerUbicacion(),
                          icon: const Icon(Icons.my_location, size: 18),
                          label: const Text('Mi ubicación'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _calculandoRuta ? null : _calcularRuta,
                          icon: const Icon(Icons.route, size: 18),
                          label: Text(
                            _calculandoRuta ? 'Calculando…' : 'Generar ruta',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: _ruta == null
                              ? null
                              : _compartirYEnviarRuta,
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: const Text('Enviar ruta'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _abrirNavegacion,
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: const Text('Google Maps'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
