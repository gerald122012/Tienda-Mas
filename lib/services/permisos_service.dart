import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../main.dart';

class PermisosService {
  static bool get _usaPermissionHandler =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<bool> solicitarPermisoCamara(
    BuildContext context, {
    required String motivo,
  }) async {
    final aceptado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: kMassMint,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.camera_alt_rounded,
            color: kMassBlue,
            size: 32,
          ),
        ),
        title: const Text(
          'Permiso de cámara',
          textAlign: TextAlign.center,
          style: TextStyle(color: kMassBlue, fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Tiendas Mass necesita acceso a tu cámara para $motivo.\n\n'
          'Solo se activará cuando decidas usarla y tus fotos se usan únicamente dentro de la aplicación.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ahora no'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Permitir cámara'),
          ),
        ],
      ),
    );

    if (aceptado != true) return false;
    if (!_usaPermissionHandler) return true;

    try {
      var estado = await Permission.camera.status;
      if (estado.isGranted) return true;
      estado = await Permission.camera.request();
      if (estado.isGranted) return true;

      if (context.mounted && estado.isPermanentlyDenied) {
        await _mostrarDialogoConfiguracion(
          context,
          titulo: 'Cámara bloqueada',
          mensaje:
              'El permiso de cámara fue denegado permanentemente. Habilítalo desde los ajustes del sistema para continuar.',
        );
      }
      return false;
    } catch (_) {
      return true;
    }
  }

  static Future<bool> solicitarPermisoUbicacion(BuildContext context) async {
    final aceptado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: kMassMint,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.my_location_rounded,
            color: kMassBlue,
            size: 32,
          ),
        ),
        title: const Text(
          'Permiso de ubicación',
          textAlign: TextAlign.center,
          style: TextStyle(color: kMassBlue, fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'Tiendas Mass usará tu ubicación actual para calcular la ruta más cercana, el tiempo estimado de llegada y la tarifa de entrega.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.location_on_outlined, size: 18),
            label: const Text('Activar GPS'),
          ),
        ],
      ),
    );
    return aceptado == true;
  }

  static Future<void> _mostrarDialogoConfiguracion(
    BuildContext context, {
    required String titulo,
    required String mensaje,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Abrir ajustes'),
          ),
        ],
      ),
    );
  }
}
