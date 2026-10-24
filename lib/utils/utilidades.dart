import 'package:flutter/material.dart';

String formatoFecha(DateTime fecha) {
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  return '$dia/$mes/${fecha.year}';
}

double leerDouble(String texto) {
  return double.tryParse(texto.trim().replaceAll(',', '.')) ?? 0;
}

int leerEntero(String texto) => int.tryParse(texto.trim()) ?? 0;

void mostrarMensaje(BuildContext context, String texto) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
}

// Funcionalidad extra 1: mensaje con botón DESHACER después de eliminar.
void mostrarDeshacer(
  BuildContext context,
  String texto,
  VoidCallback alDeshacer,
) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(texto),
      duration: const Duration(seconds: 5),
      persist: false, // se oculta solo después de 5 segundos
      action: SnackBarAction(label: 'DESHACER', onPressed: alDeshacer),
    ),
  );
}

// Muestra un diálogo y devuelve true si el usuario confirma la eliminación.
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
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
  return respuesta ?? false;
}
