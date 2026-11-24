import 'package:flutter/material.dart';

import '../../models/pedido.dart';
import '../../services/historial_pedidos.dart';
import '../../tema/tema_mass.dart';

String etiquetaEstadoPedido(String estado) => switch (estado) {
  'pendiente' => 'Pendiente',
  'preparando' => 'En preparación',
  'entregado' => 'Entregado',
  'cancelado' => 'Cancelado',
  _ => 'Estado no reconocido',
};

String etiquetaFiltroPedido(FiltroPedidos filtro) => switch (filtro) {
  FiltroPedidos.todos => 'Todos',
  FiltroPedidos.pendiente => 'Pendientes',
  FiltroPedidos.preparando => 'En preparación',
  FiltroPedidos.entregado => 'Entregados',
  FiltroPedidos.cancelado => 'Cancelados',
};

IconData iconoEstadoPedido(String estado) => switch (estado) {
  'pendiente' => Icons.schedule_rounded,
  'preparando' => Icons.inventory_2_outlined,
  'entregado' => Icons.check_circle_outline_rounded,
  'cancelado' => Icons.cancel_outlined,
  _ => Icons.help_outline_rounded,
};

Color colorEstadoPedido(TokensMass tokens, String estado) => switch (estado) {
  'pendiente' => tokens.profundo,
  'preparando' => tokens.accion,
  'entregado' => tokens.exito,
  'cancelado' => tokens.error,
  _ => tokens.tintaSuave,
};

class EstadoPedido extends StatelessWidget {
  final String estado;
  final bool sinConfirmar;

  const EstadoPedido({
    super.key,
    required this.estado,
    this.sinConfirmar = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final color = sinConfirmar
        ? tokens.tintaSuave
        : colorEstadoPedido(tokens, estado);
    final texto = sinConfirmar
        ? 'Sin confirmación'
        : etiquetaEstadoPedido(estado);
    final icono = sinConfirmar
        ? Icons.cloud_off_outlined
        : iconoEstadoPedido(estado);
    return Semantics(
      label: sinConfirmar
          ? 'Registro local sin confirmación del servidor'
          : 'Estado $texto',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                texto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textoMass(
                  tamano: 12,
                  peso: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FiltrosPedidos extends StatelessWidget {
  final FiltroPedidos seleccionado;
  final ValueChanged<FiltroPedidos> alElegir;

  const FiltrosPedidos({
    super.key,
    required this.seleccionado,
    required this.alElegir,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final filtro in FiltroPedidos.values)
            _ChipFiltro(
              etiqueta: etiquetaFiltroPedido(filtro),
              activo: filtro == seleccionado,
              tokens: tokens,
              alElegir: () => alElegir(filtro),
            ),
        ],
      ),
    );
  }
}

class _ChipFiltro extends StatelessWidget {
  final String etiqueta;
  final bool activo;
  final TokensMass tokens;
  final VoidCallback alElegir;

  const _ChipFiltro({
    required this.etiqueta,
    required this.activo,
    required this.tokens,
    required this.alElegir,
  });

  @override
  Widget build(BuildContext context) {
    final fondo = activo ? tokens.accion : tokens.superficie;
    final tinta = activo ? Colors.white : tokens.tinta;
    return Semantics(
      button: true,
      selected: activo,
      label: 'Filtro $etiqueta',
      child: Material(
        color: fondo,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: activo ? tokens.accion : tokens.linea),
        ),
        child: InkWell(
          onTap: alElegir,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox(
              height: 48,
              child: Center(
                widthFactor: 1,
                child: Text(
                  etiqueta,
                  style: textoMass(
                    tamano: 13,
                    peso: FontWeight.w700,
                    color: tinta,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SeguimientoPedido extends StatelessWidget {
  final Pedido pedido;
  final bool sinConfirmar;

  const SeguimientoPedido({
    super.key,
    required this.pedido,
    this.sinConfirmar = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    if (sinConfirmar) {
      return _TarjetaEstado(
        tokens: tokens,
        color: tokens.tintaSuave,
        icono: Icons.cloud_off_outlined,
        titulo: 'Registro local sin confirmación del servidor',
        detalle:
            'Este registro se guardó en el dispositivo. No hay confirmación de que exista en la tienda.',
      );
    }
    if (pedido.estado == 'cancelado') {
      return _TarjetaEstado(
        tokens: tokens,
        color: tokens.error,
        icono: Icons.cancel_outlined,
        titulo: 'Cancelado',
        detalle: 'La tienda marcó este pedido como cancelado.',
      );
    }
    const secuencia = ['pendiente', 'preparando', 'entregado'];
    return _TarjetaEstado(
      tokens: tokens,
      color: colorEstadoPedido(tokens, pedido.estado),
      icono: iconoEstadoPedido(pedido.estado),
      titulo: etiquetaEstadoPedido(pedido.estado),
      detalle:
          'Solo se muestra el estado guardado. No hay fechas de cada cambio.',
      pie: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final paso in secuencia)
            _Paso(
              tokens: tokens,
              etiqueta: etiquetaEstadoPedido(paso),
              activo: pedido.estado == paso,
              color: colorEstadoPedido(tokens, paso),
            ),
        ],
      ),
    );
  }
}

class _Paso extends StatelessWidget {
  final TokensMass tokens;
  final String etiqueta;
  final bool activo;
  final Color color;

  const _Paso({
    required this.tokens,
    required this.etiqueta,
    required this.activo,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: activo ? '$etiqueta, estado actual' : '$etiqueta, sin registro',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: activo ? color.withValues(alpha: 0.12) : tokens.fondo,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: activo ? color : tokens.linea),
        ),
        child: Text(
          etiqueta,
          style: textoMass(
            tamano: 12,
            peso: activo ? FontWeight.w800 : FontWeight.w600,
            color: activo ? color : tokens.tintaSuave,
          ),
        ),
      ),
    );
  }
}

class _TarjetaEstado extends StatelessWidget {
  final TokensMass tokens;
  final Color color;
  final IconData icono;
  final String titulo;
  final String detalle;
  final Widget? pie;

  const _TarjetaEstado({
    required this.tokens,
    required this.color,
    required this.icono,
    required this.titulo,
    required this.detalle,
    this.pie,
  });

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: textoMass(
                    tamano: 16,
                    peso: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            detalle,
            style: textoMass(tamano: 13, color: tokens.tintaSuave),
          ),
          if (pie != null) ...[const SizedBox(height: 12), pie!],
        ],
      ),
    );
  }
}
