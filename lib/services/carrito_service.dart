import 'package:flutter/foundation.dart';

import '../models/producto.dart';

class ItemCarrito {
  final Producto producto;
  int cantidad;
  ItemCarrito(this.producto, this.cantidad);

  double get subtotal => producto.precio * cantidad;
}

// Carrito en memoria del cliente. La cantidad nunca supera el stock.
class CarritoService extends ChangeNotifier {
  CarritoService._();
  static final CarritoService instance = CarritoService._();

  final Map<String, ItemCarrito> _items = {};

  List<ItemCarrito> get items => _items.values.toList();
  int get unidades => _items.values.fold(0, (s, i) => s + i.cantidad);
  double get total => _items.values.fold(0, (s, i) => s + i.subtotal);
  bool get vacio => _items.isEmpty;

  int cantidadDe(Producto p) => _items[p.id]?.cantidad ?? 0;

  // Devuelve false si el producto no está disponible o ya se alcanzó el stock.
  bool agregar(Producto p) {
    if (!p.disponible || p.stock <= 0) return false;
    final actual = _items[p.id];
    if (actual == null) {
      _items[p.id] = ItemCarrito(p, 1);
    } else if (actual.cantidad < p.stock) {
      actual.cantidad++;
    } else {
      return false;
    }
    notifyListeners();
    return true;
  }

  void quitarUna(Producto p) {
    final actual = _items[p.id];
    if (actual == null) return;
    if (actual.cantidad <= 1) {
      _items.remove(p.id);
    } else {
      actual.cantidad--;
    }
    notifyListeners();
  }

  void eliminar(Producto p) {
    if (_items.remove(p.id) != null) notifyListeners();
  }

  void vaciar() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }
}
