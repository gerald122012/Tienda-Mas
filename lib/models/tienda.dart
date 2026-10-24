import 'package:cloud_firestore/cloud_firestore.dart';

// Módulo 2 - Ubícame (Tiendas / Bodegas Mass a nivel nacional)
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

  // Ciudades reales donde opera Tiendas Mass según https://www.tiendasmass.com.pe/ubicame/
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
  });

  // Si la tienda tiene 0 productos en inventario se muestra cerrada.
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
    };
  }

  factory Tienda.fromMap(String id, Map datos) {
    final fecha = datos['fechaApertura'];
    final ciudadLeida = (datos['ciudad'] ?? '').toString();
    return Tienda(
      id: id,
      nombre: datos['nombre'] ?? '',
      ciudad: ciudades.contains(ciudadLeida) ? ciudadLeida : ciudades.first,
      distrito: datos['distrito'] ?? '',
      direccion: datos['direccion'] ?? '',
      horario: datos['horario'] ?? '7:00 AM - 10:00 PM',
      cantidadProductos: (datos['cantidadProductos'] ?? 0).toInt(),
      fechaApertura: fecha is Timestamp ? fecha.toDate() : DateTime.now(),
      abierta: datos['abierta'] ?? true,
      servicios: List<String>.from(datos['servicios'] ?? []),
    );
  }

  static List<Tienda> ejemplos() {
    final hoy = DateTime.now();
    return [
      Tienda(
        nombre: 'Mass Los Olivos - Las Palmeras',
        ciudad: 'Lima',
        distrito: 'Los Olivos',
        direccion: 'Av. Las Palmeras 3840',
        horario: '7:00 AM - 10:00 PM',
        cantidadProductos: 850,
        fechaApertura: hoy,
        abierta: true,
        servicios: ['Yape / Plin', 'Tarjetas', 'Bebidas frías'],
      ),
      Tienda(
        nombre: 'Mass Surco - Caminos del Inca',
        ciudad: 'Lima',
        distrito: 'Santiago de Surco',
        direccion: 'Av. Caminos del Inca 1420',
        horario: '7:00 AM - 10:00 PM',
        cantidadProductos: 920,
        fechaApertura: hoy,
        abierta: true,
        servicios: ['Yape / Plin', 'Tarjetas', 'Panadería'],
      ),
      Tienda(
        nombre: 'Mass SJM - San Juan',
        ciudad: 'Lima',
        distrito: 'San Juan de Miraflores',
        direccion: 'Av. San Juan 890',
        horario: '7:00 AM - 10:00 PM',
        cantidadProductos: 780,
        fechaApertura: hoy,
        abierta: true,
        servicios: ['Yape / Plin', 'Ofertas del barrio'],
      ),
      Tienda(
        nombre: 'Mass Arequipa - Cayma',
        ciudad: 'Arequipa',
        distrito: 'Cayma',
        direccion: 'Av. Ejército 640',
        horario: '7:00 AM - 10:00 PM',
        cantidadProductos: 810,
        fechaApertura: hoy,
        abierta: true,
        servicios: ['Yape / Plin', 'Tarjetas', 'Lácteos frescos'],
      ),
    ];
  }
}
