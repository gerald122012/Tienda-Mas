import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

enum ModoRuta { carro, caminando }

class PasoRuta {
  final String instruccion;
  final double distanciaMetros;

  const PasoRuta({required this.instruccion, required this.distanciaMetros});
}

class ResultadoRuta {
  final double distanciaMetros;
  final double duracionSegundos;
  final List<LatLng> puntos;
  final List<PasoRuta> pasos;
  final bool esEstimacionDirecta;

  const ResultadoRuta({
    required this.distanciaMetros,
    required this.duracionSegundos,
    required this.puntos,
    this.pasos = const [],
    this.esEstimacionDirecta = false,
  });

  double get distanciaKm => distanciaMetros / 1000;
  int get duracionMinutos => (duracionSegundos / 60).ceil().clamp(1, 9999);
}

class RoutingService {
  /// Fórmula histórica. No se aplica al carrito, al pedido ni a la pantalla.
  static double tarifaDelivery(double metros) {
    const base = 3.00;
    const precioKm = 1.50;
    const minima = 3.00;
    final total = base + (metros / 1000 * precioKm);
    return total < minima ? minima : total;
  }

  static Uri urlGoogleMaps({
    required LatLng origen,
    required LatLng destino,
    required ModoRuta modo,
  }) {
    final travelMode = modo == ModoRuta.carro ? 'driving' : 'walking';
    return Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${origen.latitude},${origen.longitude}'
      '&destination=${destino.latitude},${destino.longitude}'
      '&travelmode=$travelMode',
    );
  }

  static String construirMensajeRuta({
    required String nombreDestino,
    required LatLng origen,
    required LatLng destino,
    required ModoRuta modo,
    required ResultadoRuta ruta,
    String? aclaracion,
  }) {
    final link = urlGoogleMaps(origen: origen, destino: destino, modo: modo);
    final modoTexto = modo == ModoRuta.carro ? 'En vehículo' : 'Caminando';
    final nota = (aclaracion == null || aclaracion.trim().isEmpty)
        ? ''
        : '\n${aclaracion.trim()}';
    return 'Ruta Tiendas Mass\n'
        'Destino: $nombreDestino\n'
        'Modo: $modoTexto\n'
        'Distancia de recorrido: ${ruta.distanciaKm.toStringAsFixed(2)} km\n'
        'Tiempo estimado del recorrido: ${ruta.duracionMinutos} min\n'
        'No es un tiempo de entrega garantizado.$nota\n'
        'Abrir en Google Maps: $link';
  }

  Future<ResultadoRuta> obtenerRuta({
    required LatLng origen,
    required LatLng destino,
    required ModoRuta modo,
  }) async {
    final coords =
        '${origen.longitude},${origen.latitude};${destino.longitude},${destino.latitude}';
    final uris = modo == ModoRuta.carro
        ? [
            Uri.parse(
              'https://router.project-osrm.org/route/v1/driving/$coords?overview=full&geometries=geojson&steps=true',
            ),
            Uri.parse(
              'https://routing.openstreetmap.de/routed-car/route/v1/driving/$coords?overview=full&geometries=geojson&steps=true',
            ),
          ]
        : [
            Uri.parse(
              'https://routing.openstreetmap.de/routed-foot/route/v1/foot/$coords?overview=full&geometries=geojson&steps=true',
            ),
          ];

    for (final uri in uris) {
      try {
        final response = await http
            .get(uri, headers: {'User-Agent': 'TiendasMassApp/2.0'})
            .timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) continue;
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['code'] != 'Ok' || (data['routes'] as List).isEmpty) {
          continue;
        }
        final route = (data['routes'] as List).first as Map<String, dynamic>;
        final geometry = route['geometry'] as Map<String, dynamic>;
        final puntos = (geometry['coordinates'] as List).map((item) {
          final par = item as List;
          return LatLng((par[1] as num).toDouble(), (par[0] as num).toDouble());
        }).toList();
        final pasos = _extraerPasos(route);
        return ResultadoRuta(
          distanciaMetros: (route['distance'] as num).toDouble(),
          duracionSegundos: (route['duration'] as num).toDouble(),
          puntos: puntos,
          pasos: pasos,
        );
      } catch (_) {
        continue;
      }
    }

    // Respaldo geodésico si el servidor público no responde.
    return _estimacionRespaldo(origen, destino, modo);
  }

  List<PasoRuta> _extraerPasos(Map<String, dynamic> route) {
    final legs = route['legs'];
    if (legs is! List || legs.isEmpty) return const [];
    final steps = (legs.first as Map)['steps'];
    if (steps is! List) return const [];
    final resultado = <PasoRuta>[];
    for (final raw in steps.whereType<Map>()) {
      final maneuver = raw['maneuver'] as Map?;
      final tipo = (maneuver?['type'] ?? '').toString();
      final mod = (maneuver?['modifier'] ?? '').toString();
      final calle = (raw['name'] ?? '').toString().trim();
      final dist = (raw['distance'] as num?)?.toDouble() ?? 0;
      if (dist < 10 && tipo != 'arrive') continue;
      final instruccion = _traducirPaso(tipo, mod, calle);
      resultado.add(PasoRuta(instruccion: instruccion, distanciaMetros: dist));
    }
    return resultado;
  }

  String _traducirPaso(String tipo, String mod, String calle) {
    final via = calle.isEmpty ? '' : ' por $calle';
    final giro = switch (mod) {
      'left' => 'Gira a la izquierda',
      'right' => 'Gira a la derecha',
      'slight left' => 'Mantente ligeramente a la izquierda',
      'slight right' => 'Mantente ligeramente a la derecha',
      'sharp left' => 'Gira cerrado a la izquierda',
      'sharp right' => 'Gira cerrado a la derecha',
      'uturn' => 'Haz un giro en U',
      _ => 'Continúa recto',
    };
    return switch (tipo) {
      'depart' => 'Inicia el recorrido$via',
      'arrive' => 'Llegaste a tu destino',
      'roundabout' || 'rotary' => 'Toma la rotonda$via',
      _ => '$giro$via',
    };
  }

  ResultadoRuta _estimacionRespaldo(
    LatLng origen,
    LatLng destino,
    ModoRuta modo,
  ) {
    final distRecta = _haversineMetros(origen, destino);
    final distEstimada = distRecta * 1.28;
    final velocidadMps = modo == ModoRuta.carro ? 8.5 : 1.35;
    final duracion = distEstimada / velocidadMps;
    return ResultadoRuta(
      distanciaMetros: distEstimada,
      duracionSegundos: duracion,
      puntos: [origen, destino],
      pasos: [
        PasoRuta(
          instruccion: 'Dirígete hacia el destino seleccionado',
          distanciaMetros: distEstimada,
        ),
        const PasoRuta(instruccion: 'Llegada al destino', distanciaMetros: 0),
      ],
      esEstimacionDirecta: true,
    );
  }

  double _haversineMetros(LatLng a, LatLng b) {
    const r = 6371000.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLon = _rad(b.longitude - a.longitude);
    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(a.latitude)) *
            math.cos(_rad(b.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return 2 * r * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  double _rad(double grados) => grados * math.pi / 180;
}
