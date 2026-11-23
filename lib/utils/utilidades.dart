import 'package:flutter/material.dart';

const kAppVersion = '2.1.0';
const kAppBuild = '3';

String formatoFecha(DateTime fecha) {
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  return '$dia/$mes/${fecha.year}';
}

String formatoFechaHora(DateTime fecha) {
  final hora = fecha.hour.toString().padLeft(2, '0');
  final min = fecha.minute.toString().padLeft(2, '0');
  return '${formatoFecha(fecha)} $hora:$min';
}

String formatoPrecio(double valor) => 'S/ ${valor.toStringAsFixed(2)}';

Widget precioUnaLinea(
  String texto, {
  required TextStyle style,
  Alignment alignment = Alignment.centerLeft,
}) {
  return FittedBox(
    fit: BoxFit.scaleDown,
    alignment: alignment,
    child: Text(
      texto,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.visible,
      style: style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
    ),
  );
}

double leerDouble(String texto) {
  return double.tryParse(texto.trim().replaceAll(',', '.')) ?? 0;
}

int leerEntero(String texto) => int.tryParse(texto.trim()) ?? 0;

void mostrarMensaje(BuildContext context, String texto) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(texto),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
}

void mostrarDeshacer(
  BuildContext context,
  String texto,
  VoidCallback alDeshacer,
) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(texto),
        duration: const Duration(seconds: 5),
        persist: false,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(label: 'DESHACER', onPressed: alDeshacer),
      ),
    );
}

Future<bool> confirmarEliminar(BuildContext context, String nombre) async {
  final respuesta = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirmar eliminación'),
      content: Text('¿Seguro que deseas eliminar "$nombre"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
  return respuesta ?? false;
}
