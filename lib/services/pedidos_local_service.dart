import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pedido.dart';

class PedidosLocalService extends ChangeNotifier {
  PedidosLocalService._();
  static final PedidosLocalService instance = PedidosLocalService._();

  static const _key = 'historial_pedidos_local_v2';
  List<Pedido> _pedidos = [];
  bool _cargado = false;

  List<Pedido> get pedidos => List.unmodifiable(_pedidos);

  Future<void> cargar() async {
    if (_cargado) return;
    _cargado = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null && raw.isNotEmpty) {
        final lista = jsonDecode(raw) as List<dynamic>;
        _pedidos = lista
            .whereType<Map<String, dynamic>>()
            .map((m) => Pedido.fromMap((m['id'] ?? '').toString(), m))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> guardarPedido(Pedido pedido) async {
    await cargar();
    _pedidos.removeWhere((p) => p.id == pedido.id);
    _pedidos.insert(0, pedido);
    notifyListeners();
    final guardado = await _persistir();
    if (!guardado) {
      _pedidos.removeWhere((p) => p.id == pedido.id);
      notifyListeners();
    }
    return guardado;
  }

  Future<void> eliminarPedido(String id) async {
    await cargar();
    _pedidos.removeWhere((p) => p.id == id);
    notifyListeners();
    await _persistir();
  }

  List<Pedido> pedidosDeCorreo(String correo) {
    final c = correo.trim().toLowerCase();
    return _pedidos
        .where((p) => p.clienteCorreo.trim().toLowerCase() == c)
        .toList();
  }

  Future<bool> _persistir() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_pedidos.map((p) => p.toLocalJson()).toList());
      await prefs.setString(_key, encoded);
      return true;
    } catch (_) {
      return false;
    }
  }
}
