import 'package:flutter/material.dart';

import '../../models/producto.dart';
import '../../tema/tema_mass.dart';
import '../../utils/utilidades.dart';
import '../../widgets/foto_producto.dart';
import 'control_cantidad_producto.dart';

class TarjetaProductoCliente extends StatelessWidget {
  final Producto producto;
  final int cantidad;
  final bool horizontal;
  final VoidCallback alAgregar;
  final VoidCallback alQuitar;

  const TarjetaProductoCliente({
    super.key,
    required this.producto,
    required this.cantidad,
    required this.alAgregar,
    required this.alQuitar,
    this.horizontal = false,
  });

  bool get _disponible => producto.disponible && producto.stock > 0;

  bool get _puedeAumentar => _disponible && cantidad < producto.stock;

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final cuerpo = horizontal
        ? _Horizontal(
            producto: producto,
            cantidad: cantidad,
            disponible: _disponible,
            puedeAumentar: _puedeAumentar,
            alAgregar: alAgregar,
            alQuitar: alQuitar,
          )
        : _Vertical(
            producto: producto,
            cantidad: cantidad,
            disponible: _disponible,
            puedeAumentar: _puedeAumentar,
            alAgregar: alAgregar,
            alQuitar: alQuitar,
          );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.superficie,
        borderRadius: BorderRadius.circular(MassRadio.tarjeta),
        border: Border.all(color: tokens.linea),
        boxShadow: sombraMass(),
      ),
      child: cuerpo,
    );
  }
}

class _Vertical extends StatelessWidget {
  final Producto producto;
  final int cantidad;
  final bool disponible;
  final bool puedeAumentar;
  final VoidCallback alAgregar;
  final VoidCallback alQuitar;

  const _Vertical({
    required this.producto,
    required this.cantidad,
    required this.disponible,
    required this.puedeAumentar,
    required this.alAgregar,
    required this.alQuitar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _Foto(producto: producto, disponible: disponible),
          ),
          const SizedBox(height: 8),
          _Ficha(
            producto: producto,
            cantidad: cantidad,
            disponible: disponible,
          ),
          const SizedBox(height: 8),
          ControlCantidadProducto(
            cantidad: cantidad,
            disponible: disponible,
            puedeAumentar: puedeAumentar,
            alAgregar: alAgregar,
            alQuitar: alQuitar,
          ),
        ],
      ),
    );
  }
}

class _Horizontal extends StatelessWidget {
  final Producto producto;
  final int cantidad;
  final bool disponible;
  final bool puedeAumentar;
  final VoidCallback alAgregar;
  final VoidCallback alQuitar;

  const _Horizontal({
    required this.producto,
    required this.cantidad,
    required this.disponible,
    required this.puedeAumentar,
    required this.alAgregar,
    required this.alQuitar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            height: 104,
            child: _Foto(producto: producto, disponible: disponible),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Ficha(
                  producto: producto,
                  cantidad: cantidad,
                  disponible: disponible,
                  compacta: true,
                ),
                const SizedBox(height: 8),
                ControlCantidadProducto(
                  cantidad: cantidad,
                  disponible: disponible,
                  puedeAumentar: puedeAumentar,
                  alAgregar: alAgregar,
                  alQuitar: alQuitar,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Foto extends StatelessWidget {
  final Producto producto;
  final bool disponible;

  const _Foto({required this.producto, required this.disponible});

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(MassRadio.control),
      child: ColoredBox(
        color: tokens.fondo,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.all(6),
              child: Opacity(
                opacity: disponible ? 1 : 0.45,
                child: FotoProducto(producto: producto),
              ),
            ),
            if (!disponible)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  color: tokens.profundo.withValues(alpha: 0.88),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Agotado',
                    textAlign: TextAlign.center,
                    style: textoMass(
                      tamano: 12,
                      peso: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Ficha extends StatelessWidget {
  final Producto producto;
  final int cantidad;
  final bool disponible;
  final bool compacta;

  const _Ficha({
    required this.producto,
    required this.cantidad,
    required this.disponible,
    this.compacta = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final presentacion = producto.presentaciones.join(' · ');
    final unitario = producto.precioUnitarioTexto;
    final superaStock = cantidad > producto.stock;
    final estado = !disponible
        ? 'Agotado'
        : superaStock
        ? 'Supera el stock registrado'
        : 'Disponible · ${producto.stock}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          producto.marca.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textoMass(
            tamano: 11,
            peso: FontWeight.w700,
            color: tokens.accion,
            alto: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          producto.nombre,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textoMass(
            tamano: compacta ? 14 : 13,
            peso: FontWeight.w700,
            color: tokens.profundo,
            alto: 1.15,
          ),
        ),
        if (presentacion.isNotEmpty)
          Text(
            presentacion,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textoMass(tamano: 12, color: tokens.tintaSuave, alto: 1.2),
          ),
        const SizedBox(height: 6),
        precioUnaLinea(
          formatoPrecio(producto.precio),
          style: textoMass(
            tamano: 20,
            peso: FontWeight.w800,
            color: tokens.profundo,
            alto: 1,
            tabular: true,
          ),
        ),
        if (unitario != null)
          Text(
            unitario,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textoMass(tamano: 12, color: tokens.tintaSuave, alto: 1.2),
          ),
        Text(
          estado,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textoMass(
            tamano: 12,
            peso: FontWeight.w700,
            color: !disponible || superaStock ? tokens.error : tokens.exito,
            alto: 1.2,
          ),
        ),
      ],
    );
  }
}
