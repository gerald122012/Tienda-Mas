class DniResultado {
  final String nombres;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final bool simulado;

  const DniResultado({
    required this.nombres,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.simulado,
  });

  String get nombreCompleto {
    return [
      nombres,
      apellidoPaterno,
      apellidoMaterno,
    ].where((parte) => parte.trim().isNotEmpty).join(' ');
  }
}
