import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'consulta_tiendas.dart';
import 'permisos_service.dart';

enum SituacionUbicacion {
  concedida,
  denegada,
  denegadaPermanentemente,
  gpsDesactivado,
  noDisponible,
}

class LecturaUbicacion {
  final SituacionUbicacion situacion;
  final LatLng? punto;
  final double? precisionMetros;

  const LecturaUbicacion(
    this.situacion, {
    this.punto,
    this.precisionMetros,
  });
}

String? mensajeSituacionUbicacion(
  SituacionUbicacion situacion, {
  required bool enMapa,
}) {
  return switch (situacion) {
    SituacionUbicacion.concedida => null,
    SituacionUbicacion.denegada => enMapa
        ? 'No diste permiso de ubicación. Puedes elegir el destino y continuar sin tu posición.'
        : 'No diste permiso de ubicación. Puedes seguir consultando las tiendas.',
    SituacionUbicacion.denegadaPermanentemente =>
      'El permiso de ubicación está bloqueado. Puedes activarlo en los ajustes del sistema.',
    SituacionUbicacion.gpsDesactivado =>
      'El GPS del dispositivo está desactivado.',
    SituacionUbicacion.noDisponible => 'No se pudo obtener tu ubicación.',
  };
}

Future<void> abrirAjustesUbicacion() {
  return Geolocator.openAppSettings();
}

Future<LecturaUbicacion> leerUbicacionDelDispositivo(BuildContext context) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LecturaUbicacion(SituacionUbicacion.gpsDesactivado);
    }
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.deniedForever) {
      return const LecturaUbicacion(SituacionUbicacion.denegadaPermanentemente);
    }
    if (permiso == LocationPermission.unableToDetermine) {
      return const LecturaUbicacion(SituacionUbicacion.noDisponible);
    }
    if (permiso == LocationPermission.denied) {
      if (!context.mounted) {
        return const LecturaUbicacion(SituacionUbicacion.noDisponible);
      }
      final acepta = await PermisosService.solicitarPermisoUbicacion(context);
      if (!acepta) {
        return const LecturaUbicacion(SituacionUbicacion.denegada);
      }
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied) {
      return const LecturaUbicacion(SituacionUbicacion.denegada);
    }
    if (permiso == LocationPermission.deniedForever) {
      return const LecturaUbicacion(SituacionUbicacion.denegadaPermanentemente);
    }
    if (permiso != LocationPermission.whileInUse &&
        permiso != LocationPermission.always) {
      return const LecturaUbicacion(SituacionUbicacion.noDisponible);
    }
    final posicion = await Geolocator.getCurrentPosition(
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
    if (!coordenadasValidas(posicion.latitude, posicion.longitude)) {
      return const LecturaUbicacion(SituacionUbicacion.noDisponible);
    }
    return LecturaUbicacion(
      SituacionUbicacion.concedida,
      punto: LatLng(posicion.latitude, posicion.longitude),
      precisionMetros: posicion.accuracy,
    );
  } on TimeoutException {
    return const LecturaUbicacion(SituacionUbicacion.noDisponible);
  } on Object {
    return const LecturaUbicacion(SituacionUbicacion.noDisponible);
  }
}
