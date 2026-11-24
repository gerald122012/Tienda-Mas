import 'package:flutter/material.dart';

import '../../tema/tema_mass.dart';

class ControlesMapa extends StatelessWidget {
  final bool puedeCentrar;
  final bool puedeVerRuta;
  final VoidCallback alCentrar;
  final VoidCallback alVerRuta;

  const ControlesMapa({
    super.key,
    required this.puedeCentrar,
    required this.puedeVerRuta,
    required this.alCentrar,
    required this.alVerRuta,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Control(
          icono: Icons.my_location_rounded,
          tooltip: 'Centrar en mi ubicación',
          onPressed: puedeCentrar ? alCentrar : null,
        ),
        if (puedeVerRuta) ...[
          const SizedBox(height: 8),
          _Control(
            icono: Icons.fit_screen_rounded,
            tooltip: 'Ver la ruta completa',
            onPressed: alVerRuta,
          ),
        ],
      ],
    );
  }
}

class _Control extends StatelessWidget {
  final IconData icono;
  final String tooltip;
  final VoidCallback? onPressed;

  const _Control({
    required this.icono,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Material(
      color: tokens.superficie,
      elevation: 1,
      shadowColor: tokens.profundo.withValues(alpha: 0.16),
      shape: CircleBorder(side: BorderSide(color: tokens.linea)),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icono, color: tokens.accion, size: 20),
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      ),
    );
  }
}
