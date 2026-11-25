import 'package:flutter/material.dart';

import '../tema/tema_mass.dart';

class BarraSuperiorMass extends StatelessWidget implements PreferredSizeWidget {
  final Widget carrito;
  final Widget cuenta;

  const BarraSuperiorMass({
    super.key,
    required this.carrito,
    required this.cuenta,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Material(
      color: tokens.sello,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: tokens.profundo.withValues(alpha: 0.12)),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 64,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: MassEspacio.p8),
              child: Row(
                children: [
                  const SizedBox(width: MassEspacio.p8),
                  Semantics(
                    header: true,
                    label: 'Tiendas Mass',
                    child: Image.asset(
                      'assets/branding/mass_logo_transparente.png',
                      height: 34,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
                  ),
                  const Spacer(),
                  carrito,
                  cuenta,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
