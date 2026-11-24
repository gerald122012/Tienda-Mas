import 'package:flutter/material.dart';

import '../../tema/tema_mass.dart';
import '../../utils/utilidades.dart';

class ResumenCompra extends StatelessWidget {
  final double subtotal;
  final double descuento;
  final String? codigoCupon;
  final double total;
  final bool delivery;

  const ResumenCompra({
    super.key,
    required this.subtotal,
    required this.descuento,
    required this.codigoCupon,
    required this.total,
    required this.delivery,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Material(
      color: tokens.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MassRadio.tarjeta),
        side: BorderSide(color: tokens.linea),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _linea(context, 'Subtotal', formatoPrecio(subtotal), tokens.tinta),
            if (descuento > 0) ...[
              const SizedBox(height: 8),
              _linea(
                context,
                codigoCupon == null || codigoCupon!.isEmpty
                    ? 'Descuento'
                    : 'Descuento $codigoCupon',
                '- ${formatoPrecio(descuento)}',
                tokens.exito,
              ),
            ],
            const SizedBox(height: 12),
            Divider(height: 1, color: tokens.linea),
            const SizedBox(height: 12),
            _linea(
              context,
              'Total de productos',
              formatoPrecio(total),
              tokens.profundo,
              destacado: true,
            ),
            const SizedBox(height: 8),
            Text(
              delivery
                  ? 'Este importe es el de los productos. No incluye un costo de entrega: la aplicación no lo calcula.'
                  : 'Este importe es el de los productos. No es un cobro de pasarela.',
              style: textoMass(tamano: 12, color: tokens.tintaSuave, alto: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linea(
    BuildContext context,
    String etiqueta,
    String monto,
    Color color, {
    bool destacado = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            etiqueta,
            style: textoMass(
              tamano: destacado ? 15 : 14,
              peso: destacado ? FontWeight.w800 : FontWeight.w600,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          monto,
          style: textoMass(
            tamano: destacado ? 18 : 14,
            peso: FontWeight.w800,
            color: color,
            tabular: true,
          ),
        ),
      ],
    );
  }
}

class BarraConfirmacionCarrito extends StatelessWidget {
  final int unidades;
  final double total;
  final double descuento;
  final bool enviando;
  final bool invitado;
  final VoidCallback? alConfirmar;

  const BarraConfirmacionCarrito({
    super.key,
    required this.unidades,
    required this.total,
    required this.descuento,
    required this.enviando,
    required this.invitado,
    required this.alConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final etiqueta = enviando
        ? 'Registrando pedido'
        : invitado
        ? 'Ingresar para continuar'
        : 'Confirmar pedido';
    final boton = SizedBox(
      height: 48,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.accion,
          foregroundColor: Colors.white,
          disabledBackgroundColor: tokens.linea,
          disabledForegroundColor: tokens.tintaSuave,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MassRadio.control),
          ),
          textStyle: textoMass(tamano: 15, peso: FontWeight.w700),
        ),
        onPressed: enviando ? null : alConfirmar,
        child: enviando
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Registrando pedido'),
                ],
              )
            : Text(etiqueta, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
    final resumen = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          descuento > 0
              ? '$unidades ${unidades == 1 ? 'unidad' : 'unidades'} · Ahorro ${formatoPrecio(descuento)}'
              : '$unidades ${unidades == 1 ? 'unidad' : 'unidades'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textoMass(
            tamano: 12,
            peso: FontWeight.w700,
            color: descuento > 0 ? tokens.exito : tokens.tintaSuave,
          ),
        ),
        Text(
          formatoPrecio(total),
          style: textoMass(
            tamano: 22,
            peso: FontWeight.w800,
            color: tokens.profundo,
            tabular: true,
          ),
        ),
      ],
    );

    return Material(
      color: tokens.superficie,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: tokens.linea)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: LayoutBuilder(
              builder: (context, limites) {
                if (limites.maxWidth < 480) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      resumen,
                      const SizedBox(height: 10),
                      boton,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: resumen),
                    const SizedBox(width: 12),
                    Flexible(child: boton),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
