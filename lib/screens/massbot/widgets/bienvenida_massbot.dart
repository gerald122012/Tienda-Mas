import 'package:flutter/material.dart';

import 'avatar_massbot.dart';
import 'tema_massbot.dart';

class SugerenciaMassBot {
  final String titulo;
  final String consulta;
  final IconData icono;

  const SugerenciaMassBot(this.titulo, this.consulta, this.icono);
}

const sugerenciasMassBot = [
  SugerenciaMassBot(
    'Tengo S/ 30 para comprar',
    'Tengo 30 soles, ¿qué puedo comprar?',
    Icons.account_balance_wallet_outlined,
  ),
  SugerenciaMassBot(
    'Encuentra el mejor precio',
    '¿Cuál es el aceite más económico?',
    Icons.balance_rounded,
  ),
  SugerenciaMassBot(
    'Ayúdame con mi desayuno',
    'Recomiéndame productos para preparar un desayuno. Tengo 30 soles',
    Icons.free_breakfast_outlined,
  ),
  SugerenciaMassBot(
    'Consultar promociones',
    '¿Qué promociones tienen?',
    Icons.local_offer_outlined,
  ),
];

class BienvenidaMassBot extends StatelessWidget {
  final ValueChanged<String> alElegir;

  const BienvenidaMassBot({super.key, required this.alElegir});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE3E7F0)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AvatarMassBot(tamano: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '¡Hola! ¿Qué compramos hoy?',
                      style: textoMassBot(
                        tamano: 17,
                        peso: FontWeight.w800,
                        color: kAzulBot,
                        alto: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Encuentra productos, compara precios y aprovecha mejor tu presupuesto.',
                style: textoMassBot(color: kTintaSuaveBot),
              ),
              const SizedBox(height: 12),
              for (final sugerencia in sugerenciasMassBot)
                _FilaSugerencia(sugerencia: sugerencia, alElegir: alElegir),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilaSugerencia extends StatelessWidget {
  final SugerenciaMassBot sugerencia;
  final ValueChanged<String> alElegir;

  const _FilaSugerencia({required this.sugerencia, required this.alElegir});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: kFondoMassBot,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => alElegir(sugerencia.consulta),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(sugerencia.icono, color: kAzulBot, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    sugerencia.titulo,
                    style: textoMassBot(peso: FontWeight.w700, color: kAzulBot),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: kAzulBot,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
