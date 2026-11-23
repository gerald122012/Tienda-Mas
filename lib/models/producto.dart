import 'package:cloud_firestore/cloud_firestore.dart';

class Producto {
  String id;
  String nombre;
  String descripcion;
  String marca;
  double precio;
  int stock;
  String categoria;
  bool disponible;
  DateTime fechaRegistro;
  List<String> presentaciones;
  double valoracion;
  String codigoBarras;
  String imagenUrl;
  String imagenAsset;
  String imagenAutor;
  String imagenLicencia;
  String imagenFuente;

  static const categorias = [
    'abarrotes',
    'bebidas',
    'lácteos',
    'limpieza',
    'snacks',
  ];

  Producto({
    this.id = '',
    this.codigoBarras = '',
    this.imagenUrl = '',
    this.imagenAsset = '',
    this.imagenAutor = '',
    this.imagenLicencia = '',
    this.imagenFuente = '',
    required this.nombre,
    required this.descripcion,
    required this.marca,
    required this.precio,
    required this.stock,
    required this.categoria,
    required this.disponible,
    required this.fechaRegistro,
    required this.presentaciones,
    required this.valoracion,
  });

  String? get precioUnitarioTexto {
    final texto = '${presentaciones.join(' ')} $nombre'.toLowerCase();
    final match = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(kg|g|gr|l|lt|ml|un|und|unid)\b',
    ).firstMatch(texto);
    if (match == null || precio <= 0) return null;
    final cantidad = double.tryParse(match.group(1)!.replaceAll(',', '.'));
    if (cantidad == null || cantidad <= 0) return null;
    final unidad = match.group(2)!;
    switch (unidad) {
      case 'kg':
        return 'S/ ${(precio / cantidad).toStringAsFixed(2)} / kg';
      case 'g':
      case 'gr':
        return 'S/ ${(precio / (cantidad / 1000)).toStringAsFixed(2)} / kg';
      case 'l':
      case 'lt':
        return 'S/ ${(precio / cantidad).toStringAsFixed(2)} / L';
      case 'ml':
        return 'S/ ${(precio / (cantidad / 1000)).toStringAsFixed(2)} / L';
      case 'un':
      case 'und':
      case 'unid':
        if (cantidad <= 1) return null;
        return 'S/ ${(precio / cantidad).toStringAsFixed(2)} / un';
      default:
        return null;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'marca': marca,
      'precio': precio,
      'stock': stock,
      'categoria': categoria,
      'disponible': disponible,
      'fechaRegistro': Timestamp.fromDate(fechaRegistro),
      'presentaciones': presentaciones,
      'valoracion': valoracion,
      'codigoBarras': codigoBarras,
      'imagenUrl': imagenUrl,
      'imagenAsset': imagenAsset,
      'imagenAutor': imagenAutor,
      'imagenLicencia': imagenLicencia,
      'imagenFuente': imagenFuente,
    };
  }

  factory Producto.fromMap(String id, Map datos) {
    final fecha = datos['fechaRegistro'];
    final lista = datos['presentaciones'] ?? datos['tallasDisponibles'] ?? [];
    final cat = (datos['categoria'] ?? '').toString();
    return Producto(
      id: id,
      codigoBarras: (datos['codigoBarras'] ?? '').toString(),
      imagenUrl: (datos['imagenUrl'] ?? '').toString(),
      imagenAsset: (datos['imagenAsset'] ?? '').toString(),
      imagenAutor: (datos['imagenAutor'] ?? '').toString(),
      imagenLicencia: (datos['imagenLicencia'] ?? '').toString(),
      imagenFuente: (datos['imagenFuente'] ?? '').toString(),
      nombre: (datos['nombre'] ?? '').toString(),
      descripcion: (datos['descripcion'] ?? '').toString(),
      marca: (datos['marca'] ?? 'Mass').toString(),
      precio: (datos['precio'] ?? 0).toDouble(),
      stock: (datos['stock'] ?? 0).toInt(),
      categoria: categorias.contains(cat) ? cat : categorias.first,
      disponible: datos['disponible'] ?? true,
      fechaRegistro: fecha is Timestamp ? fecha.toDate() : DateTime.now(),
      presentaciones: List<String>.from(lista),
      valoracion: (datos['valoracion'] ?? 5).toDouble(),
    );
  }
}
