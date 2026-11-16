import 'package:flutter/material.dart';

import '../main.dart';
import '../models/producto.dart';
import 'botones_acciones.dart';

class ProductoCatalogoCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback? onEditar;
  final VoidCallback? onDuplicar;
  final VoidCallback? onEliminar;
  // Solo para clientes: reemplaza las acciones de administración.
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

  Widget _sinImagen() => ColoredBox(
    color: kMassMint,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icono, size: 44, color: kMassBlue),
          const SizedBox(height: 4),
          const Text(
            'Imagen pendiente',
            style: TextStyle(fontSize: 11, color: kMassBlue),
          ),
        ],
      ),
    ),
  );

  Widget _fotoLocal() => producto.imagenAsset.isEmpty
      ? _sinImagen()
      : Image.asset(
          producto.imagenAsset,
          fit: BoxFit.contain,
          semanticLabel: producto.nombre,
          errorBuilder: (context, error, stack) => _sinImagen(),
        );

  @override
  Widget build(BuildContext context) {
    final disponible = producto.disponible && producto.stock > 0;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEditar,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 144,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: producto.imagenUrl.isEmpty
                          ? _fotoLocal()
                          : Image.network(
                              producto.imagenUrl,
                              fit: BoxFit.contain,
                              semanticLabel: producto.nombre,
                              loadingBuilder: (context, child, progress) =>
                                  progress == null ? child : _fotoLocal(),
                              errorBuilder: (context, error, stack) =>
                                  _fotoLocal(),
                            ),
                    ),
                  ),
                  if (producto.imagenFuente.isNotEmpty)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: IconButton(
                        tooltip: 'Créditos de la foto',
                        iconSize: 16,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.9),
                        ),
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Foto del producto'),
                            content: SingleChildScrollView(
                              child: SelectableText(
                                '${producto.nombre}\n${producto.presentaciones.join(' · ')}\n\n'
                                'Autor: ${producto.imagenAutor}\nLicencia: ${producto.imagenLicencia}\n\n'
                                'Fuente y condiciones de uso:\n${producto.imagenFuente}',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cerrar'),
                              ),
                            ],
                          ),
                        ),
                        icon: const Icon(Icons.info_outline, color: kMassBlue),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.marca.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: kMassBlue,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      producto.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kMassBlue,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      producto.presentaciones.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      'S/ ${producto.precio.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 21,
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
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: Text(
                    !disponible
                        ? 'AGOTADO'
                        : enCarrito > 0
                        ? 'AGREGAR ($enCarrito)'
                        : 'AGREGAR',
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
