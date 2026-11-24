import 'package:flutter/foundation.dart';

import '../models/producto.dart';

/// Lista que Productos ya recibió. Inicio la reutiliza sin otro listener.
class CatalogoSesion extends ChangeNotifier {
  CatalogoSesion._();

  static final CatalogoSesion instancia = CatalogoSesion._();

  List<Producto> productos = const [];
  bool cargando = true;
  bool fallo = false;
  String _firma = '';

  void publicar(List<Producto> lista) {
    final firma = [
      for (final producto in lista)
        '${producto.id}:${producto.precio}:${producto.stock}:${producto.disponible}:${producto.imagenBase64.hashCode}:${producto.imagenUrl}:${producto.imagenAsset}',
    ].join('|');
    if (_firma == firma && !cargando && !fallo) return;
    _firma = firma;
    productos = List<Producto>.unmodifiable(lista);
    cargando = false;
    fallo = false;
    notifyListeners();
  }

  void publicarFallo() {
    if (fallo && !cargando) return;
    fallo = true;
    cargando = false;
    notifyListeners();
  }

  void reiniciar() {
    productos = const [];
    cargando = true;
    fallo = false;
    _firma = '';
    notifyListeners();
  }
}
