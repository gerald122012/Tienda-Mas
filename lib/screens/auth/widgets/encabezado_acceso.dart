import 'package:flutter/material.dart';

import 'logo_mass.dart';
import 'tema_acceso.dart';

class MarcaAcceso extends StatelessWidget {
  final String titulo;
  final String mensaje;
  final bool compacto;

  const MarcaAcceso({
    super.key,
    required this.titulo,
    required this.mensaje,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    final puedeVolver = Navigator.canPop(context);
    final duracion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 240);

    return LayoutBuilder(
      builder: (context, cajas) {
        var altoLogo = compacto ? 32.0 : 42.0;
        const aspecto = 442 / 120;
        final relleno = compacto ? 28.0 : 36.0;
        final anchoLogo = cajas.maxWidth - 88;
        if (altoLogo * aspecto + relleno > anchoLogo) {
          altoLogo = (anchoLogo - relleno) / aspecto;
        }
        return Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: puedeVolver
                      ? IconButton(
                          tooltip: 'Volver',
                          onPressed: () => Navigator.maybePop(context),
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.14,
                            ),
                            foregroundColor: Colors.white,
                            fixedSize: const Size(40, 40),
                            minimumSize: const Size(40, 40),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.arrow_back_rounded, size: 20),
                        )
                      : null,
                ),
                Expanded(
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: kAmarilloLogo,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: compacto ? 14 : 18,
                          vertical: compacto ? 6 : 8,
                        ),
                        child: LogoMass(alto: altoLogo),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 40, height: 40),
              ],
            ),
            SizedBox(height: compacto ? 14 : 18),
            AnimatedSwitcher(
              duration: duracion,
              child: Column(
                key: ValueKey(titulo),
                children: [
                  Text(
                    titulo,
                    textAlign: TextAlign.center,
                    style: textoAcceso(
                      tamano: compacto ? 22 : 26,
                      peso: FontWeight.w600,
                      color: Colors.white,
                      alto: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    mensaje,
                    textAlign: TextAlign.center,
                    style: textoAcceso(
                      tamano: 14,
                      peso: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
