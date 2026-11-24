import 'package:flutter/material.dart';

import '../../tema/tema_gestion.dart';
import 'conteo_gestion.dart';

class PaginaGestion extends StatelessWidget {
  final String titulo;
  final String detalle;
  final Widget? accion;
  final Widget child;

  const PaginaGestion({
    super.key,
    required this.titulo,
    required this.detalle,
    required this.child,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: GestionColores.fondo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 22, 28, 0),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: textoGestion(
                          tamano: 26,
                          peso: FontWeight.w800,
                          color: GestionColores.profundo,
                          alto: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(detalle, style: textoGestion(color: GestionColores.tintaSuave)),
                    ],
                  ),
                ),
                ?accion,
              ],
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class TarjetaIndicador extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final String detalle;
  final IconData icono;

  const TarjetaIndicador({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.detalle,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GestionColores.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GestionColores.linea),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 3, color: GestionColores.sello),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icono, size: 18, color: GestionColores.accion),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          etiqueta,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textoGestion(
                            tamano: 13,
                            peso: FontWeight.w700,
                            color: GestionColores.tintaSuave,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    valor,
                    style: textoGestion(
                      tamano: 28,
                      peso: FontWeight.w800,
                      color: GestionColores.profundo,
                      alto: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    detalle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textoGestion(tamano: 12, color: GestionColores.tintaSuave),
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

class EstadoGestion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String mensaje;
  final Widget? accion;

  const EstadoGestion({
    super.key,
    required this.icono,
    required this.titulo,
    required this.mensaje,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 36, color: GestionColores.accion),
            const SizedBox(height: 12),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: textoGestion(
                tamano: 18,
                peso: FontWeight.w800,
                color: GestionColores.profundo,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: textoGestion(color: GestionColores.tintaSuave),
            ),
            if (accion != null) ...[const SizedBox(height: 16), accion!],
          ],
        ),
      ),
    );
  }
}

class CargandoGestion extends StatelessWidget {
  final String mensaje;

  const CargandoGestion({super.key, this.mensaje = 'Consultando la información'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(height: 12),
          Text(mensaje, style: textoGestion(color: GestionColores.tintaSuave)),
        ],
      ),
    );
  }
}

class ChipGestion extends StatelessWidget {
  final String texto;
  final Color color;
  final IconData icono;

  const ChipGestion({
    super.key,
    required this.texto,
    required this.color,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: texto,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                texto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textoGestion(tamano: 12, peso: FontWeight.w700, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SuperficieGestion extends StatelessWidget {
  final Widget child;

  const SuperficieGestion({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GestionColores.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GestionColores.linea),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(16), child: child),
    );
  }
}

class BarrasPedidos extends StatelessWidget {
  final ConteoGestion conteo;

  const BarrasPedidos({super.key, required this.conteo});

  @override
  Widget build(BuildContext context) {
    if (!conteo.hayPedidosParaGrafico) {
      return Text(
        'Todavía no hay pedidos registrados para graficar.',
        style: textoGestion(color: GestionColores.tintaSuave),
      );
    }
    const filas = [
      ('Pendientes', 'pendiente'),
      ('En preparación', 'preparando'),
      ('Entregados', 'entregado'),
      ('Cancelados', 'cancelado'),
    ];
    final valores = {
      'pendiente': conteo.pendientes,
      'preparando': conteo.preparando,
      'entregado': conteo.entregados,
      'cancelado': conteo.cancelados,
    };
    final maximo = valores.values.fold<int>(1, (a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pedidos registrados por estado',
          style: textoGestion(peso: FontWeight.w800, color: GestionColores.profundo),
        ),
        const SizedBox(height: 4),
        Text(
          'Cada barra compara la cantidad registrada. No representa cobros ni variación en el tiempo.',
          style: textoGestion(tamano: 12, color: GestionColores.tintaSuave),
        ),
        const SizedBox(height: 14),
        for (final fila in filas) ...[
          _barra(fila.$1, valores[fila.$2]!, maximo),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _barra(String etiqueta, int valor, int maximo) {
    return Row(
      children: [
        SizedBox(
          width: 132,
          child: Text(etiqueta, style: textoGestion(tamano: 13, peso: FontWeight.w600)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: valor / maximo,
              backgroundColor: GestionColores.fondo,
              color: valor == 0 ? GestionColores.linea : GestionColores.accion,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 36,
          child: Text(
            '$valor',
            textAlign: TextAlign.end,
            style: textoGestion(peso: FontWeight.w800, color: GestionColores.profundo),
          ),
        ),
      ],
    );
  }
}
