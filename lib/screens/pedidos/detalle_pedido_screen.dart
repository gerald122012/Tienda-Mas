import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/pedido.dart';
import '../../models/producto.dart';
import '../../services/catalogo_sesion.dart';
import '../../services/historial_pedidos.dart';
import '../../tema/tema_mass.dart';
import '../../utils/utilidades.dart';
import '../../widgets/foto_producto.dart';
import 'estado_pedido.dart';

class DetallePedidoScreen extends StatelessWidget {
  final Pedido pedido;
  final bool sinConfirmar;

  const DetallePedidoScreen({
    super.key,
    required this.pedido,
    this.sinConfirmar = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final modalidad = pedido.tipoEntrega == 'delivery'
        ? 'Delivery'
        : 'Recojo en tienda';
    return Scaffold(
      backgroundColor: tokens.fondo,
      appBar: AppBar(title: const Text('Detalle del pedido')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text(
            'Identificación',
            style: textoMass(
              tamano: 13,
              peso: FontWeight.w800,
              color: tokens.tintaSuave,
            ),
          ),
          const SizedBox(height: 8),
          _Superficie(
            tokens: tokens,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Número de pedido',
                  style: textoMass(tamano: 12, color: tokens.tintaSuave),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  pedido.id,
                  style: textoMass(
                    tamano: 16,
                    peso: FontWeight.w800,
                    color: tokens.profundo,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  textoFechaPedido(pedido),
                  style: textoMass(tamano: 14, color: tokens.tinta),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SeguimientoPedido(pedido: pedido, sinConfirmar: sinConfirmar),
          const SizedBox(height: 20),
          Text(
            'Productos',
            style: textoMass(
              tamano: 13,
              peso: FontWeight.w800,
              color: tokens.tintaSuave,
            ),
          ),
          const SizedBox(height: 8),
          _Superficie(
            tokens: tokens,
            child: ListenableBuilder(
              listenable: CatalogoSesion.instancia,
              builder: (context, _) {
                final catalogo = CatalogoSesion.instancia.productos;
                return Column(
                  children: [
                    for (var i = 0; i < pedido.items.length; i++) ...[
                      if (i > 0) Divider(height: 20, color: tokens.linea),
                      _LineaProducto(
                        item: pedido.items[i],
                        producto: productoCoincidente(
                          pedido.items[i].productoId,
                          catalogo,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          if (pedido.cuponCodigo.isNotEmpty || pedido.descuento > 0) ...[
            const SizedBox(height: 20),
            Text(
              'Ahorro',
              style: textoMass(
                tamano: 13,
                peso: FontWeight.w800,
                color: tokens.tintaSuave,
              ),
            ),
            const SizedBox(height: 8),
            _Superficie(
              tokens: tokens,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (pedido.cuponCodigo.isNotEmpty)
                    Text(
                      'Cupón ${pedido.cuponCodigo}',
                      style: textoMass(
                        tamano: 15,
                        peso: FontWeight.w700,
                        color: tokens.tinta,
                      ),
                    ),
                  if (pedido.descuento > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Descuento ${formatoPrecio(pedido.descuento)}',
                      style: textoMass(
                        tamano: 15,
                        peso: FontWeight.w800,
                        color: tokens.exito,
                        tabular: true,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'Entrega',
            style: textoMass(
              tamano: 13,
              peso: FontWeight.w800,
              color: tokens.tintaSuave,
            ),
          ),
          const SizedBox(height: 8),
          _Superficie(
            tokens: tokens,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  modalidad,
                  style: textoMass(
                    tamano: 16,
                    peso: FontWeight.w800,
                    color: tokens.profundo,
                  ),
                ),
                if (pedido.personaRecojo.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Persona autorizada: ${pedido.personaRecojo}',
                    style: textoMass(tamano: 14, color: tokens.tinta),
                  ),
                ],
                if (pedido.rutaResumen.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    pedido.rutaResumen,
                    style: textoMass(tamano: 14, color: tokens.tinta),
                  ),
                ],
                if (pedido.fotoRecojoBase64.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _FotoVerificacion(base64: pedido.fotoRecojoBase64),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Resumen económico',
            style: textoMass(
              tamano: 13,
              peso: FontWeight.w800,
              color: tokens.tintaSuave,
            ),
          ),
          const SizedBox(height: 8),
          _Superficie(
            tokens: tokens,
            child: Column(
              children: [
                _Importe(
                  etiqueta: 'Subtotal',
                  valor: formatoPrecio(pedido.subtotalCalculado),
                  tokens: tokens,
                ),
                if (pedido.descuento > 0) ...[
                  const SizedBox(height: 8),
                  _Importe(
                    etiqueta: 'Descuento',
                    valor: '- ${formatoPrecio(pedido.descuento)}',
                    tokens: tokens,
                    color: tokens.exito,
                  ),
                ],
                Divider(height: 22, color: tokens.linea),
                _Importe(
                  etiqueta: 'Total de productos',
                  valor: formatoPrecio(pedido.total),
                  tokens: tokens,
                  destacado: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LineaProducto extends StatelessWidget {
  final ItemPedido item;
  final Producto? producto;

  const _LineaProducto({required this.item, required this.producto});

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Miniatura(producto: producto),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.nombre,
                style: textoMass(tamano: 15, peso: FontWeight.w700),
              ),
              if (item.marca.isNotEmpty)
                Text(
                  item.marca,
                  style: textoMass(tamano: 13, color: tokens.tintaSuave),
                ),
              const SizedBox(height: 4),
              Text(
                '${item.cantidad} × ${formatoPrecio(item.precio)}',
                style: textoMass(
                  tamano: 13,
                  color: tokens.tintaSuave,
                  tabular: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          formatoPrecio(item.subtotal),
          style: textoMass(
            tamano: 14,
            peso: FontWeight.w800,
            color: tokens.profundo,
            tabular: true,
          ),
        ),
      ],
    );
  }
}

class _Miniatura extends StatelessWidget {
  final Producto? producto;

  const _Miniatura({required this.producto});

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return SizedBox(
      width: 56,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.fondo,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: producto == null
              ? Icon(Icons.shopping_bag_outlined, color: tokens.accion)
              : FotoProducto(producto: producto!),
        ),
      ),
    );
  }
}

class _FotoVerificacion extends StatelessWidget {
  final String base64;

  const _FotoVerificacion({required this.base64});

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    try {
      final bytes = base64Decode(base64);
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          bytes,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Text(
            'No se pudo mostrar la foto de verificación.',
            style: textoMass(tamano: 13, color: tokens.tintaSuave),
          ),
        ),
      );
    } catch (_) {
      return Text(
        'No se pudo mostrar la foto de verificación.',
        style: textoMass(tamano: 13, color: tokens.tintaSuave),
      );
    }
  }
}

class _Superficie extends StatelessWidget {
  final TokensMass tokens;
  final Widget child;

  const _Superficie({required this.tokens, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.superficie,
        borderRadius: BorderRadius.circular(MassRadio.tarjeta),
        border: Border.all(color: tokens.linea),
      ),
      child: child,
    );
  }
}

class _Importe extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final TokensMass tokens;
  final Color? color;
  final bool destacado;

  const _Importe({
    required this.etiqueta,
    required this.valor,
    required this.tokens,
    this.color,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    final tinta = color ?? (destacado ? tokens.profundo : tokens.tinta);
    return Row(
      children: [
        Expanded(
          child: Text(
            etiqueta,
            style: textoMass(
              tamano: destacado ? 16 : 14,
              peso: destacado ? FontWeight.w800 : FontWeight.w600,
              color: tinta,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            valor,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textoMass(
              tamano: destacado ? 18 : 14,
              peso: FontWeight.w800,
              color: tinta,
              tabular: true,
            ),
          ),
        ),
      ],
    );
  }
}
