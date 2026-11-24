import 'package:flutter/material.dart';

/// Amarillo medido en el archivo original del logotipo.
const kAmarilloLogo = Color(0xFFFFD101);

/// Azul institucional llevado a un tono más profundo para el escenario.
const kAzulProfundo = Color(0xFF06206A);
const kTinta = Color(0xFF1A1A1A);
const kTintaSuave = Color(0xFF5C6370);
const kErrorAcceso = Color(0xFFB42318);
const kExitoAcceso = Color(0xFF0E7A43);
const kCampoAcceso = Color(0xFFF3F5FA);

const kRadioAcceso = 16.0;

TextStyle textoAcceso({
  double tamano = 14,
  FontWeight peso = FontWeight.w500,
  Color color = kTinta,
  double alto = 1.35,
}) {
  return TextStyle(
    fontFamily: 'Manrope',
    fontSize: tamano,
    fontWeight: peso,
    color: color,
    height: alto,
  );
}
