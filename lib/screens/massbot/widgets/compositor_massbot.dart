import 'package:flutter/material.dart';

import 'tema_massbot.dart';

class CompositorMassBot extends StatelessWidget {
  final TextEditingController controlador;
  final bool ocupado;
  final VoidCallback alEnviar;

  const CompositorMassBot({
    super.key,
    required this.controlador,
    required this.ocupado,
    required this.alEnviar,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No escribas DNI, correos ni contraseñas.',
                style: textoMassBot(tamano: 11.5, color: kTintaSuaveBot),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controlador,
                      enabled: !ocupado,
                      maxLength: 500,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => alEnviar(),
                      style: textoMassBot(peso: FontWeight.w600),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'Escribe tu consulta',
                        hintStyle: textoMassBot(color: kTintaSuaveBot),
                        filled: true,
                        fillColor: kFondoMassBot,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Enviar',
                    onPressed: ocupado ? null : alEnviar,
                    style: IconButton.styleFrom(
                      backgroundColor: kAmarilloBot,
                      foregroundColor: kAzulProfundoBot,
                      disabledBackgroundColor: const Color(0xFFE6E8ED),
                      fixedSize: const Size(48, 48),
                    ),
                    icon: const Icon(Icons.arrow_upward_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IndicadorMassBot extends StatelessWidget {
  const IndicadorMassBot({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: kAzulBot),
          ),
          const SizedBox(width: 10),
          Text(
            'Consultando',
            style: textoMassBot(peso: FontWeight.w700, color: kAzulBot),
          ),
        ],
      ),
    );
  }
}

class AvisoErrorMassBot extends StatelessWidget {
  final String mensaje;
  final VoidCallback alReintentar;

  const AvisoErrorMassBot({
    super.key,
    required this.mensaje,
    required this.alReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFB42318),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mensaje,
                  style: textoMassBot(
                    tamano: 13,
                    peso: FontWeight.w600,
                    color: const Color(0xFFB42318),
                  ),
                ),
              ),
              TextButton(
                onPressed: alReintentar,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
