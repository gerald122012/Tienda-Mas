import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/producto.dart';

/// Imágenes del catálogo ya cargadas en la app, reutilizadas por MassBot.
///
/// Una tarjeta no descarga la colección. Si el producto todavía no está en
/// memoria, se lee solo ese documento y se conserva aquí.
class CatalogoVisual extends ChangeNotifier {
  CatalogoVisual._();

  static final CatalogoVisual instancia = CatalogoVisual._();

  final Map<String, Producto> _porId = {};
  final Set<String> _enCurso = {};

  /// Las pruebas la dejan en falso para no tocar Firebase.
  static bool lecturaRemota = true;

  Producto? buscar(String id) => _porId[id];

  void recordar(Iterable<Producto> productos) {
    var cambio = false;
    for (final producto in productos) {
      if (producto.id.isEmpty) continue;
      final previo = _porId[producto.id];
      if (previo != null &&
          previo.imagenBase64 == producto.imagenBase64 &&
          previo.imagenUrl == producto.imagenUrl &&
          previo.imagenAsset == producto.imagenAsset) {
        continue;
      }
      _porId[producto.id] = producto;
      cambio = true;
    }
    if (cambio) notifyListeners();
  }

  void limpiar() {
    _porId.clear();
    _enCurso.clear();
    notifyListeners();
  }

  Future<void> asegurar(String id) async {
    if (id.isEmpty || _porId.containsKey(id) || _enCurso.contains(id)) return;
    if (!lecturaRemota) return;
    _enCurso.add(id);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('productos_mass')
          .doc(id)
          .get();
      final datos = doc.data();
      if (doc.exists && datos != null) {
        recordar([Producto.fromMap(doc.id, datos)]);
      }
    } catch (_) {
      // Sin conexión o sin permiso: la tarjeta usa el recurso que ya trae.
    } finally {
      _enCurso.remove(id);
    }
  }
}

const int _maxImagenesEnCache = 24;
final List<String> _ordenImagenes = [];
final Map<String, Uint8List> _imagenesDecodificadas = {};

/// Decodifica cada foto una sola vez y olvida las más antiguas al pasar de 24.
Uint8List? bytesImagenProductoEnCache(Producto producto) {
  final crudo = producto.imagenBase64;
  if (crudo.isEmpty) return null;
  final clave = '${producto.id}|${crudo.length}|${crudo.hashCode}';
  final previa = _imagenesDecodificadas[clave];
  if (previa != null) {
    _ordenImagenes.remove(clave);
    _ordenImagenes.add(clave);
    return previa;
  }
  final bytes = decodificarImagenProducto(crudo);
  if (bytes == null) return null;
  _imagenesDecodificadas[clave] = bytes;
  _ordenImagenes.add(clave);
  while (_ordenImagenes.length > _maxImagenesEnCache) {
    _imagenesDecodificadas.remove(_ordenImagenes.removeAt(0));
  }
  return bytes;
}
