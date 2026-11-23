import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/cupon.dart';
import '../models/producto.dart';

class ItemCarrito {
  final Producto producto;
  int cantidad;
  ItemCarrito(this.producto, this.cantidad);

  double get subtotal => producto.precio * cantidad;
}

class CarritoService extends ChangeNotifier {
  CarritoService._();
  static final CarritoService instance = CarritoService._();

  final Map<String, ItemCarrito> _items = {};
  CuponDescuento? _cuponAplicado;
  double? _presupuesto;
  String? _rutaSeleccionada;

  List<ItemCarrito> get items => _items.values.toList();
  int get unidades => _items.values.fold(0, (s, i) => s + i.cantidad);
  double get subtotal => _items.values.fold(0, (s, i) => s + i.subtotal);
  CuponDescuento? get cuponAplicado => _cuponAplicado;
  double get descuento => _cuponAplicado?.calcularDescuento(subtotal) ?? 0;
  double get total => (subtotal - descuento).clamp(0, double.infinity);
  bool get vacio => _items.isEmpty;

  double? get presupuesto => _presupuesto;
  String? get rutaSeleccionada => _rutaSeleccionada;

  double? get restantePresupuesto =>
      _presupuesto == null ? null : _presupuesto! - total;

  bool get excedePresupuesto => _presupuesto != null && total > _presupuesto!;

  int cantidadDe(Producto p) => _items[p.id]?.cantidad ?? 0;

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
    HapticFeedback.lightImpact();
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
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  void eliminar(Producto p) {
    if (_items.remove(p.id) != null) {
      HapticFeedback.selectionClick();
      notifyListeners();
    }
  }

  String? aplicarCupon(CuponDescuento cupon) {
    if (!cupon.activo) return 'Este cupón ya no está activo.';
    if (subtotal < cupon.montoMinimo) {
      return 'Compra mínima de S/ ${cupon.montoMinimo.toStringAsFixed(2)} para usar ${cupon.codigo}.';
    }
    _cuponAplicado = cupon;
    HapticFeedback.mediumImpact();
    notifyListeners();
    return null;
  }

  void quitarCupon() {
    if (_cuponAplicado == null) return;
    _cuponAplicado = null;
    notifyListeners();
  }

  void setPresupuesto(double? monto) {
    _presupuesto = (monto != null && monto > 0) ? monto : null;
    notifyListeners();
  }

  void setRutaSeleccionada(String? resumen) {
    _rutaSeleccionada = resumen?.trim().isEmpty == true ? null : resumen;
    notifyListeners();
  }

  void vaciar() {
    if (_items.isEmpty && _cuponAplicado == null && _rutaSeleccionada == null) {
      return;
    }
    _items.clear();
    _cuponAplicado = null;
    _rutaSeleccionada = null;
    notifyListeners();
  }
}
