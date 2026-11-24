import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../tema/tema_mass.dart';

class ControlCantidadProducto extends StatelessWidget {
  final int cantidad;
  final bool disponible;
  final bool puedeAumentar;
  final VoidCallback alAgregar;
  final VoidCallback alQuitar;

  const ControlCantidadProducto({
    super.key,
    required this.cantidad,
    required this.disponible,
    required this.puedeAumentar,
    required this.alAgregar,
    required this.alQuitar,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final reducir = MediaQuery.disableAnimationsOf(context);
    final enCarrito = cantidad > 0;
    return AnimatedSwitcher(
      duration: Duration(milliseconds: reducir ? 0 : 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      child: enCarrito
          ? _Paso(
              key: const ValueKey('paso'),
              cantidad: cantidad,
              puedeAumentar: puedeAumentar && disponible,
              alAgregar: alAgregar,
              alQuitar: alQuitar,
            )
          : SizedBox(
              key: const ValueKey('agregar'),
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: disponible ? tokens.accion : tokens.linea,
                  foregroundColor: disponible
                      ? Colors.white
                      : tokens.tintaSuave,
                  disabledBackgroundColor: tokens.linea,
                  disabledForegroundColor: tokens.tintaSuave,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MassRadio.control),
                  ),
                  textStyle: textoMass(tamano: 14, peso: FontWeight.w700),
                ),
                onPressed: disponible
                    ? () {
                        HapticFeedback.selectionClick();
                        alAgregar();
                      }
                    : null,
                child: Text(disponible ? 'Agregar' : 'Agotado'),
              ),
            ),
    );
  }
}

class _Paso extends StatelessWidget {
  final int cantidad;
  final bool puedeAumentar;
  final VoidCallback alAgregar;
  final VoidCallback alQuitar;

  const _Paso({
    super.key,
    required this.cantidad,
    required this.puedeAumentar,
    required this.alAgregar,
    required this.alQuitar,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return SizedBox(
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.accion,
          borderRadius: BorderRadius.circular(MassRadio.control),
        ),
        child: Row(
          children: [
            _Tecla(
              icono: Icons.remove_rounded,
              etiqueta: 'Quitar una unidad',
              color: Colors.white,
              alPulsar: () {
                HapticFeedback.selectionClick();
                alQuitar();
              },
            ),
            Expanded(
              child: Text(
                '$cantidad',
                textAlign: TextAlign.center,
                style: textoMass(
                  tamano: 16,
                  peso: FontWeight.w800,
                  color: Colors.white,
                  tabular: true,
                ),
              ),
            ),
            _Tecla(
              icono: Icons.add_rounded,
              etiqueta: puedeAumentar
                  ? 'Agregar una unidad'
                  : 'Sin más stock registrado',
              color: puedeAumentar ? Colors.white : Colors.white54,
              alPulsar: puedeAumentar
                  ? () {
                      HapticFeedback.selectionClick();
                      alAgregar();
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Tecla extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final Color color;
  final VoidCallback? alPulsar;

  const _Tecla({
    required this.icono,
    required this.etiqueta,
    required this.color,
    required this.alPulsar,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        tooltip: etiqueta,
        onPressed: alPulsar,
        icon: Icon(icono, color: color, size: 22),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
