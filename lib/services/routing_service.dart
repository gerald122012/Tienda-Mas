import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

enum ModoRuta { carro, caminando }

class ResultadoRuta {
  final double distanciaMetros;
  final double duracionSegundos;
  final List<LatLng> puntos;

  const ResultadoRuta({
    required this.distanciaMetros,
    required this.duracionSegundos,
    required this.puntos,
  });

  double get distanciaKm => distanciaMetros / 1000;
  int get duracionMinutos => (duracionSegundos / 60).round();
}

// Calcula rutas con el servicio público OSRM (solo soporta conducción).
class RoutingService {
  Future<ResultadoRuta> obtenerRuta({
    required LatLng origen,
    required LatLng destino,
    required ModoRuta modo,
  }) async {
    if (modo == ModoRuta.caminando) {
      throw Exception(
        'OSRM público solo calcula rutas en carro. Para ver la ruta a pie '
        'usa el botón "Cómo llegar caminando", que abre Google Maps.',
      );
    }
    final coords =
        '${origen.longitude},${origen.latitude};${destino.longitude},${destino.latitude}';
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/$coords?overview=full&geometries=geojson',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('Error del servicio de rutas: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['code'] != 'Ok' || (data['routes'] as List).isEmpty) {
      throw Exception('No se encontró una ruta para estas ubicaciones.');
    }
    final route = (data['routes'] as List).first as Map<String, dynamic>;
    final geometry = route['geometry'] as Map<String, dynamic>;
    final puntos = (geometry['coordinates'] as List).map((item) {
      final par = item as List;
      return LatLng((par[1] as num).toDouble(), (par[0] as num).toDouble());
    }).toList();
    return ResultadoRuta(
      distanciaMetros: (route['distance'] as num).toDouble(),
      duracionSegundos: (route['duration'] as num).toDouble(),
      puntos: puntos,
    );
  }
}
