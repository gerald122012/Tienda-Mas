import 'package:flutter/material.dart';

import '../../tema/tema_mass.dart';

class EstadoTiendas extends StatelessWidget {
  final IconData icono;
  final Color? colorIcono;
  final String titulo;
  final String mensaje;
  final String? accion;
  final VoidCallback? alAccionar;

  const EstadoTiendas({
    super.key,
    required this.icono,
    required this.titulo,
    required this.mensaje,
    this.colorIcono,
    this.accion,
    this.alAccionar,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tokens.profundo,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icono, color: colorIcono ?? tokens.sello, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: textoMass(
              tamano: 18,
              peso: FontWeight.w800,
              color: tokens.profundo,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: textoMass(tamano: 14, color: tokens.tintaSuave, alto: 1.4),
          ),
          if (accion != null && alAccionar != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: alAccionar,
              style: FilledButton.styleFrom(
                backgroundColor: tokens.accion,
                foregroundColor: Colors.white,
                minimumSize: const Size(48, 48),
                textStyle: textoMass(
                  tamano: 14,
                  peso: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              child: Text(accion!),
            ),
          ],
        ],
      ),
    );
  }
}
