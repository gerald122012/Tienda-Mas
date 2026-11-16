import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../main.dart';
import '../../services/routing_service.dart';

// Delivery Mass: ruta desde la ubicación del móvil hasta el destino,
// con distancia, tiempo estimado y tarifa de envío.
class DeliveryMapaScreen extends StatefulWidget {
  const DeliveryMapaScreen({super.key});

  @override
  State<DeliveryMapaScreen> createState() => _DeliveryMapaScreenState();
}

class _DeliveryMapaScreenState extends State<DeliveryMapaScreen> {
  // Coordenadas aproximadas del campus Huancayo; verificar la puerta exacta.
  static const LatLng universidad = LatLng(-12.0432, -75.2017);

  final MapController _mapController = MapController();
  final RoutingService _routingService = RoutingService();
  LatLng? _ubicacionMovil;
  ResultadoRuta? _ruta;
  ModoRuta _modo = ModoRuta.carro;
  bool _obteniendoUbicacion = false;
  bool _calculandoRuta = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _obtenerUbicacion();
  }

  Future<void> _obtenerUbicacion() async {
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
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        throw Exception('No se concedió permiso para obtener la ubicación.');
      }
      // En Android se usa el GPS directo para no depender de la
      // "Precisión de ubicación" de Google Play Services.
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
      setState(() => _ubicacionMovil = LatLng(pos.latitude, pos.longitude));
      _mapController.move(_ubicacionMovil!, 14);
      await _calcularRuta();
    } on TimeoutException {
      if (mounted) {
        setState(
          () => _error =
              'No se pudo obtener tu ubicación a tiempo. Revisa el GPS e '
              'intenta otra vez con "Mi ubicación".',
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
      setState(() => _error = 'Primero obtén la ubicación del móvil.');
      return;
    }
    setState(() {
      _calculandoRuta = true;
      _error = null;
      _ruta = null;
    });
    try {
      final resultado = await _routingService.obtenerRuta(
        origen: _ubicacionMovil!,
        destino: universidad,
        modo: _modo,
      );
      if (!mounted) return;
      setState(() => _ruta = resultado);
      _mapController.move(
        LatLng(
          (_ubicacionMovil!.latitude + universidad.latitude) / 2,
          (_ubicacionMovil!.longitude + universidad.longitude) / 2,
        ),
        12,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _calculandoRuta = false);
    }
  }

  // Tarifa: S/ 3.00 base + S/ 1.50 por km, con mínimo de S/ 3.00.
  double _tarifaDelivery(double metros) {
    const base = 3.00, precioKm = 1.50, minima = 3.00;
    final total = base + (metros / 1000 * precioKm);
    return total < minima ? minima : total;
  }

  Future<void> _abrirNavegacion() async {
    if (_ubicacionMovil == null) {
      setState(() => _error = 'Primero obtén la ubicación del móvil.');
      return;
    }
    final travelMode = _modo == ModoRuta.carro ? 'driving' : 'walking';
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${_ubicacionMovil!.latitude},${_ubicacionMovil!.longitude}'
      '&destination=${universidad.latitude},${universidad.longitude}'
      '&travelmode=$travelMode',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      setState(() => _error = 'No se pudo abrir la aplicación de navegación.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Mass')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.school, color: kMassBlue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Destino: Universidad Continental — Huancayo',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SegmentedButton<ModoRuta>(
                  segments: const [
                    ButtonSegment(
                      value: ModoRuta.carro,
                      icon: Icon(Icons.directions_car),
                      label: Text('Carro'),
                    ),
                    ButtonSegment(
                      value: ModoRuta.caminando,
                      icon: Icon(Icons.directions_walk),
                      label: Text('Caminando'),
                    ),
                  ],
                  selected: {_modo},
                  onSelectionChanged: (value) => setState(() {
                    _modo = value.first;
                    _ruta = null;
                    _error = null;
                  }),
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: universidad,
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.flutter_application_1',
                ),
                if (_ruta != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _ruta!.puntos,
                        strokeWidth: 5,
                        color: kMassBlue,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    const Marker(
                      point: universidad,
                      width: 50,
                      height: 50,
                      child: Icon(Icons.school, color: kMassBlue, size: 40),
                    ),
                    if (_ubicacionMovil != null)
                      Marker(
                        point: _ubicacionMovil!,
                        width: 50,
                        height: 50,
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.red,
                          size: 36,
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
          ),
          if (_error != null)
            Container(
              width: double.infinity,
              color: Colors.orange.shade50,
              padding: const EdgeInsets.all(10),
              child: Text(
                _error!,
                style: TextStyle(color: Colors.orange.shade900),
              ),
            ),
          if (_ruta != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.route, color: kMassBlue),
                          const SizedBox(width: 8),
                          Text(
                            'Distancia: ${_ruta!.distanciaKm.toStringAsFixed(2)} km',
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.schedule, color: kMassBlue),
                          const SizedBox(width: 8),
                          Text('Tiempo estimado: ${_ruta!.duracionMinutos} min'),
                        ],
                      ),
                      if (_modo == ModoRuta.carro)
                        Row(
                          children: [
                            const Icon(Icons.delivery_dining, color: kMassBlue),
                            const SizedBox(width: 8),
                            Text(
                              'Tarifa estimada: S/ ${_tarifaDelivery(_ruta!.distanciaMetros).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: kMassBlue,
                              ),
                            ),
                          ],
                        ),
                      const Text(
                        'Estimación académica; distancia y tiempo pueden variar.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _obteniendoUbicacion ? null : _obtenerUbicacion,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Mi ubicación'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _calculandoRuta ? null : _calcularRuta,
                    icon: const Icon(Icons.route),
                    label: Text(
                      _calculandoRuta ? 'Calculando…' : 'Calcular ruta',
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _abrirNavegacion,
                icon: const Icon(Icons.open_in_new),
                label: Text(
                  _modo == ModoRuta.carro
                      ? 'Cómo llegar en carro'
                      : 'Cómo llegar caminando',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
