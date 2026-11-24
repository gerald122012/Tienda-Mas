import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../services/catalogo_visual.dart';
import '../tema/tema_mass.dart';

/// Foto de un producto real: Base64, URL, asset y, al final, un marcador.
class FotoProducto extends StatelessWidget {
  final Producto producto;

  const FotoProducto({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    final bytes = bytesImagenProductoEnCache(producto);
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _sinBase64(producto),
      );
    }
    return _sinBase64(producto);
  }
}

Widget _sinBase64(Producto producto) {
  final url = producto.imagenUrl.trim();
  if (url.isNotEmpty) {
    return Image.network(
      url,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => _assetOMarcador(producto),
    );
  }
  return _assetOMarcador(producto);
}

Widget _assetOMarcador(Producto producto) {
  final ruta = producto.imagenAsset.trim();
  if (ruta.startsWith('assets/')) {
    return Image.asset(
      ruta,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const _MarcadorProducto(),
    );
  }
  return const _MarcadorProducto();
}

class _MarcadorProducto extends StatelessWidget {
  const _MarcadorProducto();

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return ColoredBox(
      color: tokens.fondo,
      child: Icon(Icons.shopping_bag_outlined, color: tokens.accion, size: 28),
    );
  }
}
