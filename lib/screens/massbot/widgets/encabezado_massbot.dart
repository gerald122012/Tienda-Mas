import 'package:flutter/material.dart';

import 'avatar_massbot.dart';
import 'tema_massbot.dart';

class EncabezadoMassBot extends StatelessWidget {
  final VoidCallback alMinimizar;
  final VoidCallback alCerrar;
  final VoidCallback? alNueva;
  final bool enDemostracion;

  const EncabezadoMassBot({
    super.key,
    required this.alMinimizar,
    required this.alCerrar,
    this.alNueva,
    this.enDemostracion = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: kAzulProfundoBot,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 4, 12),
        child: Column(
          children: [
            const _Asa(),
            const SizedBox(height: 6),
            Row(
              children: [
                const SizedBox(width: 8),
                const AvatarMassBot(tamano: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MassBot',
                        style: textoMassBot(
                          tamano: 18,
                          peso: FontWeight.w800,
                          color: Colors.white,
                          alto: 1.05,
                        ),
                      ),
                      Text(
                        'Tu asistente de compras',
                        style: textoMassBot(
                          tamano: 12,
                          peso: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.82),
                          alto: 1.15,
                        ),
                      ),
                      if (enDemostracion)
                        Text(
                          'Demostración',
                          style: textoMassBot(
                            tamano: 11,
                            peso: FontWeight.w700,
                            color: kAmarilloBot,
                            alto: 1.2,
                          ),
                        ),
                    ],
                  ),
                ),
                if (alNueva != null)
                  IconButton(
                    tooltip: 'Nueva conversación',
                    onPressed: alNueva,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.auto_awesome_rounded,
                      color: kAmarilloBot,
                    ),
                  ),
                IconButton(
                  tooltip: 'Minimizar',
                  onPressed: alMinimizar,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: alCerrar,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Asa extends StatelessWidget {
  const _Asa();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const SizedBox(width: 36, height: 4),
      ),
    );
  }
}
