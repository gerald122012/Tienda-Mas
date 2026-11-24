import 'package:flutter/material.dart';

/// Identidad de la tienda móvil. El panel web conserva su tema anterior.
class TokensMass extends ThemeExtension<TokensMass> {
  final Color profundo;
  final Color accion;
  final Color sello;
  final Color fondo;
  final Color superficie;
  final Color tinta;
  final Color tintaSuave;
  final Color exito;
  final Color error;
  final Color linea;

  const TokensMass({
    required this.profundo,
    required this.accion,
    required this.sello,
    required this.fondo,
    required this.superficie,
    required this.tinta,
    required this.tintaSuave,
    required this.exito,
    required this.error,
    required this.linea,
  });

  static const estandar = TokensMass(
    profundo: Color(0xFF06206A),
    accion: Color(0xFF082EB7),
    sello: Color(0xFFFFD101),
    fondo: Color(0xFFF4F6FB),
    superficie: Color(0xFFFFFFFF),
    tinta: Color(0xFF1A1A1A),
    tintaSuave: Color(0xFF5C6370),
    exito: Color(0xFF0E7A43),
    error: Color(0xFFB42318),
    linea: Color(0xFFE3E7F0),
  );

  static TokensMass de(BuildContext context) {
    return Theme.of(context).extension<TokensMass>() ?? estandar;
  }

  @override
  TokensMass copyWith({
    Color? profundo,
    Color? accion,
    Color? sello,
    Color? fondo,
    Color? superficie,
    Color? tinta,
    Color? tintaSuave,
    Color? exito,
    Color? error,
    Color? linea,
  }) {
    return TokensMass(
      profundo: profundo ?? this.profundo,
      accion: accion ?? this.accion,
      sello: sello ?? this.sello,
      fondo: fondo ?? this.fondo,
      superficie: superficie ?? this.superficie,
      tinta: tinta ?? this.tinta,
      tintaSuave: tintaSuave ?? this.tintaSuave,
      exito: exito ?? this.exito,
      error: error ?? this.error,
      linea: linea ?? this.linea,
    );
  }

  @override
  TokensMass lerp(ThemeExtension<TokensMass>? other, double t) {
    if (other is! TokensMass) return this;
    return TokensMass(
      profundo: Color.lerp(profundo, other.profundo, t)!,
      accion: Color.lerp(accion, other.accion, t)!,
      sello: Color.lerp(sello, other.sello, t)!,
      fondo: Color.lerp(fondo, other.fondo, t)!,
      superficie: Color.lerp(superficie, other.superficie, t)!,
      tinta: Color.lerp(tinta, other.tinta, t)!,
      tintaSuave: Color.lerp(tintaSuave, other.tintaSuave, t)!,
      exito: Color.lerp(exito, other.exito, t)!,
      error: Color.lerp(error, other.error, t)!,
      linea: Color.lerp(linea, other.linea, t)!,
    );
  }
}

class MassEspacio {
  static const p4 = 4.0;
  static const p8 = 8.0;
  static const p12 = 12.0;
  static const p16 = 16.0;
  static const p24 = 24.0;
  static const p32 = 32.0;
}

class MassRadio {
  static const control = 12.0;
  static const tarjeta = 16.0;
  static const superficie = 20.0;
}

TextStyle textoMass({
  double tamano = 15,
  FontWeight peso = FontWeight.w500,
  Color color = const Color(0xFF1A1A1A),
  double alto = 1.3,
  bool tabular = false,
}) {
  return TextStyle(
    fontFamily: 'Manrope',
    fontSize: tamano,
    fontWeight: peso,
    color: color,
    height: alto,
    fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
  );
}

List<BoxShadow> sombraMass() {
  return [
    BoxShadow(
      color: TokensMass.estandar.profundo.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
}

ThemeData temaClienteMovil() {
  const tokens = TokensMass.estandar;
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Manrope',
    extensions: const [tokens],
    colorScheme: ColorScheme.fromSeed(
      seedColor: tokens.accion,
      primary: tokens.accion,
      secondary: tokens.sello,
      surface: tokens.superficie,
    ),
    scaffoldBackgroundColor: tokens.fondo,
    appBarTheme: AppBarTheme(
      backgroundColor: tokens.superficie,
      foregroundColor: tokens.profundo,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: textoMass(
        tamano: 18,
        peso: FontWeight.w700,
        color: tokens.profundo,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: tokens.accion,
        foregroundColor: tokens.sello,
        textStyle: textoMass(peso: FontWeight.w800, color: tokens.sello),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF082EB7),
      foregroundColor: Color(0xFFFFD101),
    ),
    cardTheme: CardThemeData(
      color: tokens.superficie,
      elevation: 1.5,
      shadowColor: tokens.profundo.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: tokens.accion.withValues(alpha: 0.08)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tokens.superficie,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: tokens.accion.withValues(alpha: 0.18)),
      ),
    ),
  );
}
