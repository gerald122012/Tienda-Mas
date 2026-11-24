import 'package:flutter/material.dart';

import '../../../main.dart';
import 'tema_acceso.dart';

class BotonAcceso extends StatelessWidget {
  final String texto;
  final IconData icono;
  final VoidCallback? alPresionar;
  final bool cargando;
  final bool contorno;

  const BotonAcceso({
    super.key,
    required this.texto,
    required this.icono,
    required this.alPresionar,
    this.cargando = false,
    this.contorno = false,
  });

  @override
  Widget build(BuildContext context) {
    final activo = cargando || alPresionar != null;
    final colorTexto = !activo
        ? const Color(0xFF8B919C)
        : contorno
        ? kMassBlue
        : kMassYellow;
    final estiloTexto = textoAcceso(
      tamano: 15,
      peso: FontWeight.w700,
      color: colorTexto,
      alto: 1,
    ).copyWith(letterSpacing: 0.4);
    final iconoVisible = cargando
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: colorTexto),
          )
        : Icon(icono, size: 20, color: colorTexto);
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(kRadioAcceso),
    );
    final accion = cargando ? null : alPresionar;

    if (contorno) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          onPressed: accion,
          icon: iconoVisible,
          label: Text(cargando ? 'Consultando' : texto, style: estiloTexto),
          style: OutlinedButton.styleFrom(
            foregroundColor: kMassBlue,
            backgroundColor: activo
                ? const Color(0xFFEEF2FF)
                : const Color(0xFFF4F5F7),
            disabledForegroundColor: const Color(0xFF8B919C),
            side: BorderSide(
              color: activo ? kMassBlue : const Color(0xFFE1E4EA),
            ),
            shape: forma,
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: accion,
        icon: iconoVisible,
        label: Text(cargando ? 'Procesando' : texto, style: estiloTexto),
        style: FilledButton.styleFrom(
          backgroundColor: kMassBlue,
          foregroundColor: kMassYellow,
          disabledBackgroundColor: const Color(0xFFE6E8ED),
          disabledForegroundColor: const Color(0xFF8B919C),
          shape: forma,
        ),
      ),
    );
  }
}
