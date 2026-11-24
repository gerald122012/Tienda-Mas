import 'package:flutter/material.dart';

import '../conversacion_massbot.dart';
import 'avatar_massbot.dart';
import 'tema_massbot.dart';

/// Inicio = 0 y Productos = 1. El resto de la navegación no muestra a MassBot.
bool muestraAsistenteMassBot(int indice) => indice == 0 || indice == 1;

class BotonFlotanteMassBot extends StatefulWidget {
  final ConversacionMassBot conversacion;
  final VoidCallback alAbrir;

  const BotonFlotanteMassBot({
    super.key,
    required this.conversacion,
    required this.alAbrir,
  });

  @override
  State<BotonFlotanteMassBot> createState() => _BotonFlotanteMassBotState();
}

class _BotonFlotanteMassBotState extends State<BotonFlotanteMassBot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrada;
  late final CurvedAnimation _curva;
  var _pulsado = false;

  @override
  void initState() {
    super.initState();
    _entrada = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _curva = CurvedAnimation(parent: _entrada, curve: Curves.easeOutCubic);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reducir = MediaQuery.disableAnimationsOf(context);
      if (reducir) {
        _entrada.value = 1;
      } else {
        _entrada.forward();
      }
    });
  }

  @override
  void dispose() {
    _curva.dispose();
    _entrada.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducir = MediaQuery.disableAnimationsOf(context);
    return FadeTransition(
      opacity: _curva,
      child: Semantics(
        button: true,
        label: 'MassBot',
        child: GestureDetector(
          onTapDown: (_) {
            if (reducir) return;
            setState(() => _pulsado = true);
          },
          onTapCancel: () => setState(() => _pulsado = false),
          onTapUp: (_) {
            setState(() => _pulsado = false);
            widget.conversacion.consumirInvitacion();
            widget.alAbrir();
          },
          child: AnimatedScale(
            scale: _pulsado ? 0.94 : 1,
            duration: Duration(milliseconds: reducir ? 0 : 120),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kAzulProfundoBot.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const AvatarMassBot(tamano: 60),
            ),
          ),
        ),
      ),
    );
  }
}
