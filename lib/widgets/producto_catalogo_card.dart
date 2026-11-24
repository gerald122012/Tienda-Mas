import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../main.dart';
import '../models/producto.dart';
import '../services/catalogo_visual.dart';
import '../utils/utilidades.dart';
import 'botones_acciones.dart';

class ProductoCatalogoCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback? onEditar;
  final VoidCallback? onDuplicar;
  final VoidCallback? onEliminar;
  final VoidCallback? onAgregar;
  final int enCarrito;

  const ProductoCatalogoCard({
    super.key,
    required this.producto,
    this.onEditar,
    this.onDuplicar,
    this.onEliminar,
    this.onAgregar,
    this.enCarrito = 0,
  });

  IconData get _icono => switch (producto.categoria) {
    'bebidas' => Icons.local_drink_outlined,
    'lácteos' => Icons.breakfast_dining_outlined,
    'limpieza' => Icons.cleaning_services_outlined,
    'snacks' => Icons.cookie_outlined,
    _ => Icons.shopping_bag_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final disponible = producto.disponible && producto.stock > 0;
    final unitario = producto.precioUnitarioTexto;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEditar,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 138,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: _ImagenCatalogo(producto: producto, icono: _icono),
                    ),
                  ),
                  if (unitario != null)
                    Positioned(
                      left: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: kMassMint.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          unitario,
                          maxLines: 1,
                          softWrap: false,
                          style: const TextStyle(
                            color: kMassBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.marca.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: kMassBlue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      producto.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kMassBlue,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      producto.presentaciones.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const Spacer(),
                    precioUnaLinea(
                      formatoPrecio(producto.precio),
                      style: const TextStyle(
                        fontSize: 20,
                        color: kMassBlue,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      disponible
                          ? 'Disponible · ${producto.stock} unid.'
                          : 'Agotado',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: disponible
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
            if (onAgregar != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: FilledButton.icon(
                  onPressed: disponible ? onAgregar : null,
                  icon: const Icon(Icons.add_shopping_cart, size: 17),
                  label: Text(
                    !disponible
                        ? 'AGOTADO'
                        : enCarrito > 0
                        ? 'AGREGAR ($enCarrito)'
                        : 'AGREGAR',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
            else if (onDuplicar != null &&
                onEliminar != null &&
                onEditar != null)
              Align(
                alignment: Alignment.centerRight,
                child: BotonesAcciones(
                  onDuplicar: onDuplicar!,
                  onEditar: onEditar!,
                  onEliminar: onEliminar!,
                ),
              )
            else if (onEditar != null)
              TextButton.icon(
                onPressed: onEditar,
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('Ver producto'),
              )
            else
              const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ImagenCatalogo extends StatefulWidget {
  final Producto producto;
  final IconData icono;

  const _ImagenCatalogo({required this.producto, required this.icono});

  @override
  State<_ImagenCatalogo> createState() => _ImagenCatalogoState();
}

class _ImagenCatalogoState extends State<_ImagenCatalogo> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = bytesImagenProductoEnCache(widget.producto);
  }

  @override
  void didUpdateWidget(covariant _ImagenCatalogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.producto.imagenBase64 != widget.producto.imagenBase64) {
      _bytes = bytesImagenProductoEnCache(widget.producto);
    }
  }

  Widget _sinImagen() => ColoredBox(
    color: kMassMint,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icono, size: 42, color: kMassBlue),
          const SizedBox(height: 4),
          const Text(
            'Sin imagen',
            style: TextStyle(fontSize: 11, color: kMassBlue),
          ),
        ],
      ),
    ),
  );

  Widget _fotoLocal() {
    final asset = widget.producto.imagenAsset.trim();
    if (asset.isEmpty) return _sinImagen();
    return Image.asset(
      asset,
      fit: BoxFit.contain,
      semanticLabel: widget.producto.nombre,
      errorBuilder: (_, _, _) => _sinImagen(),
    );
  }

  Widget _porUrlOAsset() {
    final url = widget.producto.imagenUrl.trim();
    if (url.isEmpty) return _fotoLocal();
    return Image.network(
      url,
      fit: BoxFit.contain,
      semanticLabel: widget.producto.nombre,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _fotoLocal(),
      errorBuilder: (_, _, _) => _fotoLocal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes == null) return _porUrlOAsset();
    return Image.memory(
      bytes,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      semanticLabel: widget.producto.nombre,
      errorBuilder: (_, _, _) => _porUrlOAsset(),
    );
  }
}
