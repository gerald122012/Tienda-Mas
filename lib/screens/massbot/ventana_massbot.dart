import 'package:flutter/material.dart';

import 'conversacion_massbot.dart';
import 'massbot_screen.dart';
import 'widgets/tema_massbot.dart';

Future<void> abrirVentanaMassBot(
  BuildContext context, {
  required ConversacionMassBot conversacion,
  required VoidCallback alVerCatalogo,
}) {
  conversacion.marcarAbierta(true);
  final reducir = MediaQuery.disableAnimationsOf(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    barrierColor: kAzulProfundoBot.withValues(alpha: 0.45),
    sheetAnimationStyle: reducir ? AnimationStyle.noAnimation : null,
    builder: (contexto) {
      return _VentanaMassBot(
        conversacion: conversacion,
        alVerCatalogo: () {
          Navigator.of(contexto).pop();
          alVerCatalogo();
        },
        alOcultar: () => Navigator.of(contexto).pop(),
      );
    },
  ).whenComplete(() => conversacion.marcarAbierta(false));
}

class _VentanaMassBot extends StatefulWidget {
  final ConversacionMassBot conversacion;
  final VoidCallback alVerCatalogo;
  final VoidCallback alOcultar;

  const _VentanaMassBot({
    required this.conversacion,
    required this.alVerCatalogo,
    required this.alOcultar,
  });

  @override
  State<_VentanaMassBot> createState() => _VentanaMassBotState();
}

class _VentanaMassBotState extends State<_VentanaMassBot>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final medio = MediaQuery.of(context);
    final cruda = MediaQueryData.fromView(View.of(context));
    final teclado = medio.viewInsets.bottom > cruda.viewInsets.bottom
        ? medio.viewInsets.bottom
        : cruda.viewInsets.bottom;
    final reservaSuperior = cruda.viewPadding.top > cruda.padding.top
        ? cruda.viewPadding.top
        : cruda.padding.top;
    final superior = reservaSuperior + 12;
    final conTeclado = teclado > 0;

    return Padding(
      padding: EdgeInsets.only(top: superior, bottom: teclado),
      child: LayoutBuilder(
        builder: (context, limites) {
          final ancho = limites.maxWidth >= 720 ? 560.0 : limites.maxWidth;
          return Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: ancho,
              height: limites.maxHeight,
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: conTeclado ? 1 : 0.88,
                minChildSize: conTeclado ? 1 : 0.84,
                maxChildSize: 1,
                builder: (context, controlador) {
                  return ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    child: MassBotScreen(
                      embebido: true,
                      conversacion: widget.conversacion,
                      desplazamiento: controlador,
                      alVerCatalogo: widget.alVerCatalogo,
                      alMinimizar: widget.alOcultar,
                      alCerrar: widget.alOcultar,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
