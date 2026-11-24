import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../main.dart';
import 'tema_acceso.dart';

class CampoAcceso extends StatelessWidget {
  final TextEditingController controller;
  final String etiqueta;
  final IconData icono;
  final String? Function(String?)? validador;
  final bool oculto;
  final Widget? sufijo;
  final TextInputType? teclado;
  final List<TextInputFormatter>? formatos;
  final int? longitudMaxima;
  final ValueChanged<String>? alCambiar;
  final TextInputAction accion;
  final ValueChanged<String>? alEnviar;
  final Iterable<String>? autofill;
  final String? ayuda;
  final AutovalidateMode validacion;

  const CampoAcceso({
    super.key,
    required this.controller,
    required this.etiqueta,
    required this.icono,
    this.validador,
    this.oculto = false,
    this.sufijo,
    this.teclado,
    this.formatos,
    this.longitudMaxima,
    this.alCambiar,
    this.accion = TextInputAction.next,
    this.alEnviar,
    this.autofill,
    this.ayuda,
    this.validacion = AutovalidateMode.onUserInteraction,
  });

  @override
  Widget build(BuildContext context) {
    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(kRadioAcceso),
      borderSide: const BorderSide(color: Color(0xFFE3E7F0)),
    );

    return TextFormField(
      controller: controller,
      obscureText: oculto,
      keyboardType: teclado,
      textInputAction: accion,
      autofillHints: autofill,
      maxLength: longitudMaxima,
      inputFormatters: formatos,
      onChanged: alCambiar,
      onFieldSubmitted: alEnviar,
      validator: validador,
      autovalidateMode: validacion,
      style: textoAcceso(tamano: 16, peso: FontWeight.w600),
      decoration: InputDecoration(
        labelText: etiqueta,
        helperText: ayuda,
        helperMaxLines: 2,
        counterText: '',
        prefixIcon: Icon(icono, color: kMassBlue, size: 22),
        suffixIcon: sufijo,
        filled: true,
        fillColor: kCampoAcceso,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        labelStyle: textoAcceso(peso: FontWeight.w600, color: kTintaSuave),
        helperStyle: textoAcceso(tamano: 12, color: kTintaSuave, alto: 1.3),
        border: borde,
        enabledBorder: borde,
        focusedBorder: borde.copyWith(
          borderSide: const BorderSide(color: kMassBlue, width: 1.6),
        ),
        errorBorder: borde.copyWith(
          borderSide: const BorderSide(color: kErrorAcceso),
        ),
        focusedErrorBorder: borde.copyWith(
          borderSide: const BorderSide(color: kErrorAcceso, width: 1.6),
        ),
        errorStyle: textoAcceso(
          tamano: 12,
          peso: FontWeight.w600,
          color: kErrorAcceso,
        ),
      ),
    );
  }
}
