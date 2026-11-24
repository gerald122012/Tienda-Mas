import 'package:flutter/foundation.dart';

/// Búsqueda o categoría enviada desde Inicio hacia la pestaña Productos.
class IntencionCatalogo {
  final int marca;
  final String consulta;
  final String categoria;

  const IntencionCatalogo({
    required this.marca,
    required this.consulta,
    required this.categoria,
  });
}

class FiltroCatalogo extends ChangeNotifier {
  FiltroCatalogo._();

  static final FiltroCatalogo instancia = FiltroCatalogo._();

  IntencionCatalogo? pendiente;

  void buscar(String consulta) => _emitir(consulta.trim(), 'todas');

  void abrirCategoria(String categoria) => _emitir('', categoria);

  void verTodo() => _emitir('', 'todas');

  void reiniciar() {
    pendiente = null;
    notifyListeners();
  }

  void _emitir(String consulta, String categoria) {
    final marca = (pendiente?.marca ?? 0) + 1;
    pendiente = IntencionCatalogo(
      marca: marca,
      consulta: consulta,
      categoria: categoria,
    );
    notifyListeners();
  }
}
