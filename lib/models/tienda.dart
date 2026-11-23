import 'package:cloud_firestore/cloud_firestore.dart';

class Tienda {
  String id;
  String nombre;
  String ciudad;
  String distrito;
  String direccion;
  String horario;
  int cantidadProductos;
  DateTime fechaApertura;
  bool abierta;
  List<String> servicios;
  double? latitud;
  double? longitud;

  static const ciudades = [
    'Lima',
    'Arequipa',
    'Trujillo',
    'Chiclayo',
    'Piura',
    'Ica',
    'Cusco',
    'Huancayo',
  ];

  Tienda({
    this.id = '',
    required this.nombre,
    required this.ciudad,
    required this.distrito,
    required this.direccion,
    required this.horario,
    required this.cantidadProductos,
    required this.fechaApertura,
    required this.abierta,
    required this.servicios,
    this.latitud,
    this.longitud,
  });

  bool get estaAbierta => abierta && cantidadProductos > 0;

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'ciudad': ciudad,
      'distrito': distrito,
      'direccion': direccion,
      'horario': horario,
      'cantidadProductos': cantidadProductos,
      'fechaApertura': Timestamp.fromDate(fechaApertura),
      'abierta': abierta,
      'servicios': servicios,
      if (latitud != null) 'latitud': latitud,
      if (longitud != null) 'longitud': longitud,
    };
  }

  factory Tienda.fromMap(String id, Map datos) {
    final fecha = datos['fechaApertura'];
    final ciudadLeida = (datos['ciudad'] ?? '').toString();
    return Tienda(
      id: id,
      nombre: (datos['nombre'] ?? '').toString(),
      ciudad: ciudades.contains(ciudadLeida) ? ciudadLeida : ciudades.first,
      distrito: (datos['distrito'] ?? '').toString(),
      direccion: (datos['direccion'] ?? '').toString(),
      horario: (datos['horario'] ?? '7:00 AM - 10:00 PM').toString(),
      cantidadProductos: (datos['cantidadProductos'] ?? 0).toInt(),
      fechaApertura: fecha is Timestamp ? fecha.toDate() : DateTime.now(),
      abierta: datos['abierta'] ?? true,
      servicios: List<String>.from(datos['servicios'] ?? []),
      latitud: (datos['latitud'] as num?)?.toDouble(),
      longitud: (datos['longitud'] as num?)?.toDouble(),
    );
  }
}
