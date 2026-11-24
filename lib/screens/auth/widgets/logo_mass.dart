import 'package:flutter/material.dart';

class LogoMass extends StatelessWidget {
  final double alto;

  const LogoMass({super.key, this.alto = 76});

  /// Marca azul recortada del archivo original, sin el cuadrado amarillo.
  static const ruta = 'assets/branding/mass_logo_transparente.png';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Logotipo de Tiendas Mass',
      image: true,
      child: Image.asset(
        ruta,
        height: alto,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        excludeFromSemantics: true,
      ),
    );
  }
}
