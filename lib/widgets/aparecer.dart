import 'package:flutter/material.dart';

// Animación ligera de entrada: aparece con fundido y un pequeño desplazamiento.
// [indice] escalona un poco las tarjetas de una lista (máx. 8 pasos).
class Aparecer extends StatelessWidget {
  final Widget child;
  final int indice;

  const Aparecer({super.key, required this.child, this.indice = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 250 + (indice.clamp(0, 8)) * 50),
      curve: Curves.easeOutCubic,
      builder: (context, t, hijo) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 14),
          child: hijo,
        ),
      ),
      child: child,
    );
  }
}
