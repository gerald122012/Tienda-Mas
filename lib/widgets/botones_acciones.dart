import 'package:flutter/material.dart';

// Botones que aparecen en cada tarjeta de las 3 listas.
class BotonesAcciones extends StatelessWidget {
  final VoidCallback onDuplicar;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const BotonesAcciones({
    super.key,
    required this.onDuplicar,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Duplicar',
          icon: const Icon(Icons.copy),
          onPressed: onDuplicar,
        ),
        IconButton(
          tooltip: 'Editar',
          icon: const Icon(Icons.edit),
          onPressed: onEditar,
        ),
        IconButton(
          tooltip: 'Eliminar',
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onEliminar,
        ),
      ],
    );
  }
}
