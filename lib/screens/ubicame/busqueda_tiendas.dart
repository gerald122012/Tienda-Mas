import 'package:flutter/material.dart';

import '../../tema/tema_mass.dart';

class BusquedaTiendas extends StatelessWidget {
  final TextEditingController controlador;
  final FocusNode foco;
  final ValueChanged<String> alCambiar;
  final VoidCallback alLimpiar;

  const BusquedaTiendas({
    super.key,
    required this.controlador,
    required this.foco,
    required this.alCambiar,
    required this.alLimpiar,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final enfocado = foco.hasFocus;
    final hayTexto = controlador.text.isNotEmpty;
    return TextField(
      key: const Key('busqueda-tiendas'),
      controller: controlador,
      focusNode: foco,
      onChanged: alCambiar,
      textInputAction: TextInputAction.search,
      style: textoMass(tamano: 15, peso: FontWeight.w600, color: tokens.tinta),
      decoration: InputDecoration(
        hintText: 'Busca por nombre, ciudad o dirección',
        hintStyle: textoMass(tamano: 14, color: tokens.tintaSuave),
        prefixIcon: Icon(Icons.search_rounded, color: tokens.accion),
        suffixIcon: hayTexto
            ? IconButton(
                tooltip: 'Limpiar búsqueda',
                onPressed: alLimpiar,
                icon: Icon(Icons.close_rounded, color: tokens.tintaSuave),
              )
            : null,
        filled: true,
        fillColor: tokens.superficie,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        constraints: const BoxConstraints(minHeight: 48),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: tokens.linea),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: enfocado ? tokens.accion : tokens.linea, width: 1.5),
        ),
      ),
    );
  }
}
