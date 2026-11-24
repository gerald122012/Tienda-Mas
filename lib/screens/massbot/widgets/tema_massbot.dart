import 'package:flutter/material.dart';

const kFondoMassBot = Color(0xFFF4F6FB);
const kAzulProfundoBot = Color(0xFF06206A);
const kAzulBot = Color(0xFF082EB7);
const kAmarilloBot = Color(0xFFFFD101);
const kTintaBot = Color(0xFF1A1A1A);
const kTintaSuaveBot = Color(0xFF5C6370);

TextStyle textoMassBot({
  double tamano = 14,
  FontWeight peso = FontWeight.w500,
  Color color = kTintaBot,
  double alto = 1.35,
  double espaciado = 0,
}) {
  return TextStyle(
    fontFamily: 'Manrope',
    fontSize: tamano,
    fontWeight: peso,
    color: color,
    height: alto,
    letterSpacing: espaciado,
  );
}
