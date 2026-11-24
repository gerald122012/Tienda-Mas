import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../models/tienda.dart';

String normalizarBusqueda(String valor) {
  const origen = 'áéíóúüñ';
  const destino = 'aeiouun';
  final buffer = StringBuffer();
  for (final rune in valor.toLowerCase().trim().runes) {
    final unidad = String.fromCharCode(rune);
    final indice = origen.indexOf(unidad);
    buffer.write(indice == -1 ? unidad : destino[indice]);
  }
  return buffer.toString();
}

bool coordenadasValidas(double? latitud, double? longitud) {
  if (latitud == null || longitud == null) return false;
  if (!latitud.isFinite || !longitud.isFinite) return false;
  return latitud >= -90 &&
      latitud <= 90 &&
      longitud >= -180 &&
      longitud <= 180;
}

double distanciaLineaRectaMetros(LatLng origen, LatLng destino) {
  const radio = 6371000.0;
  final dLat = _rad(destino.latitude - origen.latitude);
  final dLon = _rad(destino.longitude - origen.longitude);
  final h =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(origen.latitude)) *
          math.cos(_rad(destino.latitude)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return 2 * radio * math.atan2(math.sqrt(h), math.sqrt(1 - h));
}

double _rad(double grados) => grados * math.pi / 180;

List<String> ciudadesDe(Iterable<Tienda> tiendas) {
  final ciudades = <String>{
    for (final tienda in tiendas)
      if (tienda.ciudad.trim().isNotEmpty) tienda.ciudad.trim(),
  };
  final lista = ciudades.toList()..sort();
  return lista;
}

List<Tienda> filtrarTiendas({
  required List<Tienda> tiendas,
  required String consulta,
  required String ciudad,
}) {
  final busqueda = normalizarBusqueda(consulta);
  final ciudadElegida = ciudad.trim();
  return [
    for (final tienda in tiendas)
      if (_coincide(tienda, busqueda, ciudadElegida)) tienda,
  ];
}

bool _coincide(Tienda tienda, String busqueda, String ciudad) {
  if (ciudad.isNotEmpty && ciudad != 'Todas' && tienda.ciudad.trim() != ciudad) {
    return false;
  }
  if (busqueda.isEmpty) return true;
  final texto = normalizarBusqueda(
    '${tienda.nombre} ${tienda.ciudad} ${tienda.distrito} ${tienda.direccion}',
  );
  return texto.contains(busqueda);
}

List<Tienda> ordenarTiendas(List<Tienda> tiendas, LatLng? origen) {
  final copia = [...tiendas];
  copia.sort((a, b) {
    if (origen != null) {
      final distanciaA = _distancia(a, origen);
      final distanciaB = _distancia(b, origen);
      if (distanciaA == null && distanciaB != null) return 1;
      if (distanciaA != null && distanciaB == null) return -1;
      if (distanciaA != null && distanciaB != null) {
        final comparacion = distanciaA.compareTo(distanciaB);
        if (comparacion != 0) return comparacion;
      }
    } else {
      final porCiudad = a.ciudad.compareTo(b.ciudad);
      if (porCiudad != 0) return porCiudad;
    }
    return a.nombre.compareTo(b.nombre);
  });
  return copia;
}

double? _distancia(Tienda tienda, LatLng origen) {
  if (!coordenadasValidas(tienda.latitud, tienda.longitud)) return null;
  return distanciaLineaRectaMetros(
    origen,
    LatLng(tienda.latitud!, tienda.longitud!),
  );
}

String? lugarTienda(Tienda tienda) {
  final partes = [
    tienda.distrito.trim(),
    tienda.ciudad.trim(),
  ].where((parte) => parte.isNotEmpty);
  if (partes.isEmpty) return null;
  return partes.join(' · ');
}
