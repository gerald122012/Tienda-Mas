import 'package:flutter/material.dart';

import '../utils/utilidades.dart';

// Campo que muestra una fecha y abre el DatePicker al tocarlo.
class CampoFecha extends StatelessWidget {
  final String etiqueta;
  final DateTime fecha;
  final DateTime? fechaMaxima;
  final ValueChanged<DateTime> onChanged;

  const CampoFecha({
    super.key,
    required this.etiqueta,
    required this.fecha,
    required this.onChanged,
    this.fechaMaxima,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final elegida = await showDatePicker(
          context: context,
          initialDate: fecha,
          firstDate: DateTime(1900),
          lastDate: fechaMaxima ?? DateTime(2100),
        );
        if (elegida != null) onChanged(elegida);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: etiqueta,
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(formatoFecha(fecha)),
      ),
    );
  }
}
