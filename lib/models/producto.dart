import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';

const int kMaxBytesImagenProducto = 150 * 1024;

enum FuenteDeImagen { base64, url, asset, ninguna }

bool esJpeg(Uint8List bytes) {
  return bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF;
}

bool esPng(Uint8List bytes) {
  return bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0D &&
      bytes[5] == 0x0A &&
      bytes[6] == 0x1A &&
      bytes[7] == 0x0A;
}

String textoPesoImagen(int bytes) => '${(bytes / 1024).toStringAsFixed(1)} KB';

String normalizarBase64Imagen(String raw) {
  var texto = raw.trim();
  final coma = texto.indexOf(',');
  if (texto.startsWith('data:image') && coma != -1) {
    texto = texto.substring(coma + 1);
  }
  return texto.replaceAll(RegExp(r'\s+'), '');
}

Uint8List? decodificarImagenProducto(String raw) {
  final texto = normalizarBase64Imagen(raw);
  if (texto.isEmpty) return null;
  try {
    final bytes = base64Decode(texto);
    if (!esJpeg(bytes) && !esPng(bytes)) return null;
    return bytes;
  } catch (_) {
    return null;
  }
}

Future<String?> validarImagenProducto(Uint8List bytes) async {
  if (!esJpeg(bytes) && !esPng(bytes)) {
    return 'Selecciona una imagen JPG o PNG. El archivo no tiene un contenido de imagen válido. Se conservó la imagen anterior.';
  }
  if (bytes.length > kMaxBytesImagenProducto) {
    return 'La imagen procesada pesa ${textoPesoImagen(bytes.length)} y supera el máximo de 150 KB. Se conservó la imagen anterior.';
  }
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final ancho = frame.image.width;
    final alto = frame.image.height;
    frame.image.dispose();
    codec.dispose();
    if (ancho > 600 || alto > 600) {
      return 'La imagen mide $ancho × $alto px y supera el máximo de 600 × 600. Se conservó la imagen anterior.';
    }
  } catch (_) {
    return 'No se pudo leer la imagen. Usa un archivo JPG o PNG en buen estado. Se conservó la imagen anterior.';
  }
  return null;
}

String imagenBase64ParaGuardar({
  required String anterior,
  Uint8List? nueva,
  bool quitar = false,
}) {
  if (nueva != null && nueva.isNotEmpty) return base64Encode(nueva);
  if (quitar) return '';
  return normalizarBase64Imagen(anterior);
}

FuenteDeImagen fuenteDeImagenProducto(Producto producto) {
  if (decodificarImagenProducto(producto.imagenBase64) != null) {
    return FuenteDeImagen.base64;
  }
  if (producto.imagenUrl.trim().isNotEmpty) return FuenteDeImagen.url;
  if (producto.imagenAsset.trim().isNotEmpty) return FuenteDeImagen.asset;
  return FuenteDeImagen.ninguna;
}

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
  String imagenBase64;

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
    this.imagenBase64 = '',
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
      'imagenBase64': normalizarBase64Imagen(imagenBase64),
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
      imagenBase64: normalizarBase64Imagen(
        (datos['imagenBase64'] ?? '').toString(),
      ),
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
