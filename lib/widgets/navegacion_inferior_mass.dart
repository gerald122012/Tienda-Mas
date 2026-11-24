import 'package:flutter/material.dart';

import '../tema/tema_mass.dart';

class DestinoNavegacion {
  final String etiqueta;
  final IconData icono;

  const DestinoNavegacion(this.etiqueta, this.icono);
}

class NavegacionInferiorMass extends StatelessWidget {
  final int indice;
  final List<DestinoNavegacion> destinos;
  final ValueChanged<int> alElegir;

  const NavegacionInferiorMass({
    super.key,
    required this.indice,
    required this.destinos,
    required this.alElegir,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final reducir = MediaQuery.disableAnimationsOf(context);
    return Material(
      color: tokens.superficie,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: tokens.linea)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < destinos.length; i++)
                  Expanded(
                    child: _PestanaNav(
                      destino: destinos[i],
                      activa: i == indice,
                      reducir: reducir,
                      alElegir: () => alElegir(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PestanaNav extends StatelessWidget {
  final DestinoNavegacion destino;
  final bool activa;
  final bool reducir;
  final VoidCallback alElegir;

  const _PestanaNav({
    required this.destino,
    required this.activa,
    required this.reducir,
    required this.alElegir,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final color = activa ? tokens.accion : tokens.tintaSuave;
    return Semantics(
      button: true,
      selected: activa,
      label: destino.etiqueta,
      child: InkWell(
        onTap: alElegir,
        child: SizedBox(
          height: 64,
          child: ExcludeSemantics(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: reducir
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  width: activa ? 18 : 0,
                  height: 3,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: activa ? tokens.sello : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Icon(destino.icono, size: 22, color: color),
                const SizedBox(height: 2),
                Text(
                  destino.etiqueta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textoMass(
                    tamano: 11,
                    peso: activa ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                    alto: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
