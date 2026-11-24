import 'package:flutter/material.dart';

import '../../tema/tema_mass.dart';

class AvisoContextual extends StatelessWidget {
  final String mensaje;
  final IconData icono;
  final String? accion;
  final VoidCallback? alAccionar;

  const AvisoContextual({
    super.key,
    required this.mensaje,
    required this.icono,
    this.accion,
    this.alAccionar,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: tokens.error.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: tokens.error.withValues(alpha: 0.28)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icono, color: tokens.error, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mensaje,
                      style: textoMass(
                        tamano: 13,
                        peso: FontWeight.w600,
                        color: tokens.error,
                        alto: 1.35,
                      ),
                    ),
                    if (accion != null && alAccionar != null) ...[
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: alAccionar,
                        style: TextButton.styleFrom(
                          foregroundColor: tokens.error,
                          minimumSize: const Size(48, 48),
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          accion!,
                          style: textoMass(
                            tamano: 13,
                            peso: FontWeight.w800,
                            color: tokens.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
