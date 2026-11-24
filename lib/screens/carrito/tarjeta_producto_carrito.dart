import 'package:flutter/material.dart';

import '../../services/carrito_service.dart';
import '../../tema/tema_mass.dart';
import '../../utils/utilidades.dart';
import '../../widgets/foto_producto.dart';
import '../precios_mass/control_cantidad_producto.dart';

class TarjetaProductoCarrito extends StatelessWidget {
  final ItemCarrito item;
  final VoidCallback alAgregar;
  final VoidCallback alQuitar;
  final VoidCallback alEliminar;

  const TarjetaProductoCarrito({
    super.key,
    required this.item,
    required this.alAgregar,
    required this.alQuitar,
    required this.alEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final producto = item.producto;
    final presentacion = producto.presentaciones
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .join(' · ');
    final marca = producto.marca.trim();
    final puedeAumentar =
        producto.disponible && item.cantidad < producto.stock;
    final supera = item.cantidad > producto.stock || !producto.disponible;
    final aviso = supera
        ? 'Supera el stock registrado'
        : !puedeAumentar
        ? 'No hay más unidades registradas'
        : null;

    return Material(
      color: tokens.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MassRadio.tarjeta),
        side: BorderSide(color: tokens.linea),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 84,
                height: 84,
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (marca.isNotEmpty)
                              Text(
                                marca,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textoMass(
                                  tamano: 11,
                                  peso: FontWeight.w700,
                                  color: tokens.accion,
                                ),
                              ),
                            Text(
                              producto.nombre,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textoMass(
                                tamano: 15,
                                peso: FontWeight.w700,
                                color: tokens.tinta,
                                alto: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Quitar ${producto.nombre}',
                        onPressed: alEliminar,
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: tokens.error,
                        ),
                      ),
                    ],
                  ),
                  if (presentacion.isNotEmpty)
                    Text(
                      presentacion,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textoMass(tamano: 12, color: tokens.tintaSuave),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${formatoPrecio(producto.precio)} c/u',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textoMass(
                            tamano: 13,
                            color: tokens.tintaSuave,
                            tabular: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          formatoPrecio(item.subtotal),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: textoMass(
                            tamano: 16,
                            peso: FontWeight.w800,
                            color: tokens.profundo,
                            tabular: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (aviso != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      aviso,
                      style: textoMass(
                        tamano: 12,
                        peso: FontWeight.w700,
                        color: supera ? tokens.error : tokens.tintaSuave,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 176),
                      child: ControlCantidadProducto(
                        cantidad: item.cantidad,
                        disponible: producto.disponible && producto.stock > 0,
                        puedeAumentar: puedeAumentar,
                        alAgregar: alAgregar,
                        alQuitar: alQuitar,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
