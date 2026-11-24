import 'package:flutter/material.dart';

/// Reserva una franja real bajo el contenido. El asistente no flota encima.
class ZonaConAsistente extends StatelessWidget {
  final Widget contenido;
  final Widget? asistente;

  const ZonaConAsistente({
    super.key,
    required this.contenido,
    required this.asistente,
  });

  static const alto = 76.0;

  @override
  Widget build(BuildContext context) {
    final visible = asistente != null;
    final reducir = MediaQuery.disableAnimationsOf(context);
    return Column(
      children: [
        Expanded(child: contenido),
        AnimatedContainer(
          duration: Duration(milliseconds: reducir ? 0 : 180),
          curve: Curves.easeOutCubic,
          height: visible ? alto : 0,
          child: visible
              ? Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: asistente,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
