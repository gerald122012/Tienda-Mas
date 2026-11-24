import 'package:flutter/material.dart';

import '../../services/permisos_service.dart';
import '../../tema/tema_mass.dart';

class EstadoPermisoCamara extends StatelessWidget {
  final SituacionCamara situacion;
  final VoidCallback? alReintentar;

  const EstadoPermisoCamara({
    super.key,
    required this.situacion,
    required this.alReintentar,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final (titulo, mensaje) = switch (situacion) {
      SituacionCamara.denegada => (
        'Cámara no autorizada',
        'No diste permiso de cámara. Puedes escribir el código o usar Archivos.',
      ),
      SituacionCamara.denegadaPermanentemente => (
        'Cámara bloqueada',
        'El permiso de cámara está bloqueado. Puedes activarlo en los ajustes del sistema.',
      ),
      SituacionCamara.noDisponible => (
        'Cámara no disponible',
        'Este dispositivo no tiene una cámara que podamos usar.',
      ),
      SituacionCamara.error => (
        'No se pudo abrir la cámara',
        'Inténtalo nuevamente o continúa sin escanear.',
      ),
      SituacionCamara.concedida => (
        'Cámara lista',
        'Puedes iniciar la lectura.',
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Icon(
            situacion == SituacionCamara.concedida
                ? Icons.photo_camera_rounded
                : Icons.no_photography_rounded,
            color: situacion == SituacionCamara.concedida
                ? tokens.accion
                : tokens.error,
          ),
          const SizedBox(height: 8),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: textoMass(
              tamano: 15,
              peso: FontWeight.w700,
              color: tokens.profundo,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: textoMass(tamano: 13, color: tokens.tintaSuave),
          ),
          if (alReintentar != null && situacion != SituacionCamara.concedida) ...[
            const SizedBox(height: 8),
            TextButton(
              key: const Key('reintentar-camara'),
              onPressed: alReintentar,
              child: const Text('Intentar de nuevo'),
            ),
          ],
        ],
      ),
    );
  }
}
