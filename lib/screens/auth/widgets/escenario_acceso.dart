import 'package:flutter/material.dart';

import 'encabezado_acceso.dart';
import 'tema_acceso.dart';

class EscenarioAcceso extends StatelessWidget {
  final String titulo;
  final String mensaje;
  final bool compacto;
  final Widget formulario;

  const EscenarioAcceso({
    super.key,
    required this.titulo,
    required this.mensaje,
    required this.formulario,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    final reducir = MediaQuery.disableAnimationsOf(context);
    return Stack(
      children: [
        const Positioned.fill(child: CustomPaint(painter: _MarcasMass())),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, restricciones) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (restricciones.maxHeight - 24).clamp(
                      0,
                      double.infinity,
                    ),
                  ),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: reducir ? 1 : 0, end: 1),
                    duration: reducir
                        ? Duration.zero
                        : const Duration(milliseconds: 380),
                    curve: Curves.easeOutCubic,
                    builder: (context, valor, child) {
                      return Opacity(
                        opacity: valor,
                        child: Transform.translate(
                          offset: Offset(0, (1 - valor) * 16),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        MarcaAcceso(
                          titulo: titulo,
                          mensaje: mensaje,
                          compacto: compacto,
                        ),
                        SizedBox(height: compacto ? 14 : 20),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x1A01163F),
                                    blurRadius: 18,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  compacto ? 20 : 26,
                                  compacto ? 20 : 28,
                                  compacto ? 20 : 26,
                                  18,
                                ),
                                child: formulario,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MarcasMass extends CustomPainter {
  const _MarcasMass();

  @override
  void paint(Canvas canvas, Size size) {
    final amarillo = Paint()..color = kAmarilloLogo.withValues(alpha: 0.16);
    canvas.drawCircle(
      Offset(size.width * 0.92, size.height * 0.04),
      78,
      amarillo,
    );
    final azul = Paint()
      ..color = const Color(0xFF3E68F0).withValues(alpha: 0.22);
    canvas.drawCircle(Offset(-18, size.height * 0.92), 118, azul);
    final arco = Paint()
      ..color = kAmarilloLogo.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, -30),
        width: size.width * 1.35,
        height: size.width * 0.72,
      ),
      0.25,
      2.65,
      false,
      arco,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
