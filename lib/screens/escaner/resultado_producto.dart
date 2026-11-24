import 'package:flutter/material.dart';

import '../../models/producto.dart';
import '../../tema/tema_mass.dart';
import '../../utils/utilidades.dart';
import '../../widgets/foto_producto.dart';

class ResultadoProducto extends StatelessWidget {
  final Producto producto;
  final VoidCallback alAgregar;
  final VoidCallback alEscanearDeNuevo;

  const ResultadoProducto({
    super.key,
    required this.producto,
    required this.alAgregar,
    required this.alEscanearDeNuevo,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final disponible = producto.disponible && producto.stock > 0;
    final presentacion = producto.presentaciones
        .where((item) => item.trim().isNotEmpty)
        .join(' · ');
    return Material(
      color: tokens.superficie,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: ColoredBox(
                      color: tokens.fondo,
                      child: FotoProducto(producto: producto),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textoMass(
                          tamano: 16,
                          peso: FontWeight.w700,
                          color: tokens.profundo,
                        ),
                      ),
                      if (producto.marca.trim().isNotEmpty)
                        Text(
                          producto.marca,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textoMass(tamano: 12, color: tokens.tintaSuave),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (presentacion.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(presentacion, style: textoMass(tamano: 13)),
            ],
            const SizedBox(height: 4),
            Text(
              formatoPrecio(producto.precio),
              style: textoMass(
                tamano: 16,
                peso: FontWeight.w800,
                color: tokens.profundo,
                tabular: true,
              ),
            ),
            Text(
              disponible
                  ? 'Disponible · ${producto.stock} en stock'
                  : 'Sin stock',
              style: textoMass(
                tamano: 12,
                peso: FontWeight.w700,
                color: disponible ? tokens.exito : tokens.error,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  key: const Key('agregar-producto'),
                  onPressed: disponible ? alAgregar : null,
                  style: FilledButton.styleFrom(
                    foregroundColor: Colors.white,
                    disabledForegroundColor: tokens.tintaSuave,
                    minimumSize: const Size(48, 48),
                    textStyle: textoMass(
                      peso: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  child: const Text('Agregar'),
                ),
                OutlinedButton(
                  key: const Key('escanear-de-nuevo'),
                  onPressed: alEscanearDeNuevo,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: tokens.profundo,
                    minimumSize: const Size(48, 48),
                  ),
                  child: const Text('Escanear de nuevo'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProductoNoEncontrado extends StatelessWidget {
  final String codigo;
  final VoidCallback alEscanearDeNuevo;
  final VoidCallback? alRegistrar;

  const ProductoNoEncontrado({
    super.key,
    required this.codigo,
    required this.alEscanearDeNuevo,
    this.alRegistrar,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Material(
      color: tokens.superficie,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No encontramos este producto',
              style: textoMass(
                tamano: 16,
                peso: FontWeight.w700,
                color: tokens.profundo,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'El código $codigo no coincide con los productos disponibles en el catálogo.',
              style: textoMass(tamano: 13, color: tokens.tintaSuave),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  key: const Key('escanear-de-nuevo'),
                  onPressed: alEscanearDeNuevo,
                  style: FilledButton.styleFrom(
                    foregroundColor: Colors.white,
                    minimumSize: const Size(48, 48),
                    textStyle: textoMass(
                      peso: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  child: const Text('Escanear de nuevo'),
                ),
                if (alRegistrar != null)
                  OutlinedButton(
                    key: const Key('registrar-producto'),
                    onPressed: alRegistrar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: tokens.profundo,
                      minimumSize: const Size(48, 48),
                    ),
                    child: const Text('Registrar producto'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
