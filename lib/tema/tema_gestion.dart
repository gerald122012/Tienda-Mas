import 'package:flutter/material.dart';

/// Sistema visual exclusivo del panel web. No lo usa el aplicativo móvil.
class GestionColores {
  static const profundo = Color(0xFF06206A);
  static const accion = Color(0xFF082EB7);
  static const sello = Color(0xFFFFD101);
  static const fondo = Color(0xFFF4F6FB);
  static const superficie = Color(0xFFFFFFFF);
  static const tinta = Color(0xFF1A1A1A);
  static const tintaSuave = Color(0xFF5C6370);
  static const exito = Color(0xFF0E7A43);
  static const error = Color(0xFFB42318);
  static const linea = Color(0xFFE3E7F0);
}

TextStyle textoGestion({
  double tamano = 14,
  FontWeight peso = FontWeight.w500,
  Color color = GestionColores.tinta,
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

ThemeData temaGestionEmpresarial() {
  const borde = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: GestionColores.linea),
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Manrope',
    scaffoldBackgroundColor: GestionColores.fondo,
    colorScheme: const ColorScheme.light(
      primary: GestionColores.accion,
      onPrimary: Colors.white,
      secondary: GestionColores.sello,
      onSecondary: GestionColores.profundo,
      surface: GestionColores.superficie,
      onSurface: GestionColores.tinta,
      error: GestionColores.error,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: GestionColores.sello,
      foregroundColor: GestionColores.profundo,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: textoGestion(
        tamano: 18,
        peso: FontWeight.w700,
        color: GestionColores.profundo,
      ),
    ),
    dividerColor: GestionColores.linea,
    cardTheme: CardThemeData(
      color: GestionColores.superficie,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: GestionColores.linea),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: GestionColores.superficie,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: textoGestion(
        tamano: 18,
        peso: FontWeight.w800,
        color: GestionColores.profundo,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: GestionColores.accion,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        textStyle: textoGestion(peso: FontWeight.w700, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: GestionColores.accion,
        minimumSize: const Size(48, 44),
        side: const BorderSide(color: GestionColores.linea),
        textStyle: textoGestion(peso: FontWeight.w700, color: GestionColores.accion),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: GestionColores.accion,
        textStyle: textoGestion(peso: FontWeight.w700, color: GestionColores.accion),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: GestionColores.superficie,
      labelStyle: textoGestion(color: GestionColores.tintaSuave),
      hintStyle: textoGestion(color: GestionColores.tintaSuave),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: borde,
      enabledBorder: borde,
      focusedBorder: borde.copyWith(
        borderSide: const BorderSide(color: GestionColores.accion, width: 1.4),
      ),
      errorBorder: borde.copyWith(
        borderSide: const BorderSide(color: GestionColores.error),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: GestionColores.profundo,
      contentTextStyle: textoGestion(color: Colors.white, peso: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: GestionColores.accion,
    ),
    tooltipTheme: TooltipThemeData(
      textStyle: textoGestion(tamano: 12, color: Colors.white, peso: FontWeight.w600),
      decoration: BoxDecoration(
        color: GestionColores.profundo,
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: GestionColores.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: GestionColores.linea),
      ),
      textStyle: textoGestion(),
    ),
  );
}
