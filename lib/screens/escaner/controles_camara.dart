import 'package:flutter/material.dart';

import '../../tema/tema_mass.dart';

class ControlesCamara extends StatelessWidget {
  final bool linterna;
  final bool cambiarCamara;
  final VoidCallback? alLinterna;
  final VoidCallback? alCambiarCamara;
  final VoidCallback alReiniciar;
  final VoidCallback alCerrar;

  const ControlesCamara({
    super.key,
    required this.linterna,
    required this.cambiarCamara,
    required this.alLinterna,
    required this.alCambiarCamara,
    required this.alReiniciar,
    required this.alCerrar,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (linterna)
            _Control(
              clave: 'linterna',
              icono: Icons.flashlight_on_rounded,
              ayuda: 'Linterna',
              alPulsar: alLinterna,
              tokens: tokens,
            ),
          if (cambiarCamara)
            _Control(
              clave: 'cambiar-camara',
              icono: Icons.cameraswitch_rounded,
              ayuda: 'Cambiar cámara',
              alPulsar: alCambiarCamara,
              tokens: tokens,
            ),
          _Control(
            clave: 'reiniciar-lectura',
            icono: Icons.refresh_rounded,
            ayuda: 'Reiniciar lectura',
            alPulsar: alReiniciar,
            tokens: tokens,
          ),
          _Control(
            clave: 'cerrar-camara',
            icono: Icons.close_rounded,
            ayuda: 'Cerrar cámara',
            alPulsar: alCerrar,
            tokens: tokens,
          ),
        ],
      ),
    );
  }
}

class _Control extends StatelessWidget {
  final String clave;
  final IconData icono;
  final String ayuda;
  final VoidCallback? alPulsar;
  final TokensMass tokens;

  const _Control({
    required this.clave,
    required this.icono,
    required this.ayuda,
    required this.alPulsar,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: IconButton(
        key: Key(clave),
        tooltip: ayuda,
        onPressed: alPulsar,
        style: IconButton.styleFrom(
          backgroundColor: tokens.superficie,
          foregroundColor: tokens.profundo,
          minimumSize: const Size(48, 48),
          fixedSize: const Size(48, 48),
        ),
        icon: Icon(icono, size: 22),
      ),
    );
  }
}
