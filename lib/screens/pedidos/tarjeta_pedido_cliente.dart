import 'package:flutter/material.dart';

import '../../models/pedido.dart';
import '../../services/catalogo_sesion.dart';
import '../../services/historial_pedidos.dart';
import '../../tema/tema_mass.dart';
import '../../utils/utilidades.dart';
import '../../widgets/foto_producto.dart';
import 'estado_pedido.dart';

class TarjetaPedidoCliente extends StatelessWidget {
  final Pedido pedido;
  final bool sinConfirmar;
  final VoidCallback alVerDetalle;

  const TarjetaPedidoCliente({
    super.key,
    required this.pedido,
    required this.alVerDetalle,
    this.sinConfirmar = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final modalidad = pedido.tipoEntrega == 'delivery'
        ? 'Delivery'
        : 'Recojo en tienda';
    final unidades = pedido.totalUnidades;
    final textoUnidades = '$unidades ${unidades == 1 ? 'unidad' : 'unidades'}';
    return Semantics(
      button: true,
      label:
          'Pedido ${pedido.id}, ${sinConfirmar ? 'sin confirmación del servidor' : etiquetaEstadoPedido(pedido.estado)}, $textoUnidades, $modalidad, total de productos ${formatoPrecio(pedido.total)}',
      child: Material(
        color: tokens.superficie,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MassRadio.tarjeta),
          side: BorderSide(color: tokens.linea),
        ),
        child: InkWell(
          onTap: alVerDetalle,
          borderRadius: BorderRadius.circular(MassRadio.tarjeta),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EstadoPedido(estado: pedido.estado, sinConfirmar: sinConfirmar),
                const SizedBox(height: 10),
                Text(
                  pedido.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textoMass(
                    tamano: 15,
                    peso: FontWeight.w800,
                    color: tokens.profundo,
                  ),
                ),
                if (pedido.items.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    pedido.items.length == 1
                        ? pedido.items.first.nombre
                        : '${pedido.items.first.nombre} y ${pedido.items.length - 1} más',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textoMass(
                      tamano: 14,
                      peso: FontWeight.w700,
                      color: tokens.tinta,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${textoFechaPedido(pedido)} · $textoUnidades · $modalidad',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textoMass(tamano: 13, color: tokens.tintaSuave),
                ),
                if (sinConfirmar) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Registro local sin confirmación del servidor',
                    style: textoMass(
                      tamano: 13,
                      peso: FontWeight.w700,
                      color: tokens.tinta,
                    ),
                  ),
                ],
                _VistasPrevias(pedido: pedido),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total de productos',
                            style: textoMass(tamano: 12, color: tokens.tintaSuave),
                          ),
                          Text(
                            formatoPrecio(pedido.total),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textoMass(
                              tamano: 18,
                              peso: FontWeight.w800,
                              color: tokens.profundo,
                              tabular: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: alVerDetalle,
                      style: TextButton.styleFrom(
                        foregroundColor: tokens.accion,
                        minimumSize: const Size(48, 48),
                      ),
                      child: const Text('Ver detalle'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VistasPrevias extends StatelessWidget {
  final Pedido pedido;

  const _VistasPrevias({required this.pedido});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CatalogoSesion.instancia,
      builder: (context, _) {
        final catalogo = CatalogoSesion.instancia.productos;
        final fotos = <Widget>[];
        for (final item in pedido.items) {
          final producto = productoCoincidente(item.productoId, catalogo);
          if (producto == null) continue;
          fotos.add(
            SizedBox(
              width: 48,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: TokensMass.de(context).fondo,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FotoProducto(producto: producto),
                ),
              ),
            ),
          );
          if (fotos.length == 3) break;
        }
        if (fotos.isEmpty) return const SizedBox.shrink();
        final restantes = pedido.items.length - fotos.length;
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              for (final foto in fotos) ...[foto, const SizedBox(width: 8)],
              if (restantes > 0)
                Text(
                  '+$restantes',
                  style: textoMass(
                    tamano: 13,
                    peso: FontWeight.w700,
                    color: TokensMass.de(context).tintaSuave,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
