class CuponDescuento {
  final String id;
  final String codigo;
  final String descripcion;
  final String tipo; // 'porcentaje' o 'monto'
  final double valor;
  final double montoMinimo;
  final bool activo;

  const CuponDescuento({
    this.id = '',
    required this.codigo,
    required this.descripcion,
    required this.tipo,
    required this.valor,
    this.montoMinimo = 0,
    this.activo = true,
  });

  static const List<CuponDescuento> predeterminados = [
    CuponDescuento(
      id: 'default_mass10',
      codigo: 'MASS10',
      descripcion: '10% de descuento en tu compra',
      tipo: 'porcentaje',
      valor: 10,
      montoMinimo: 10,
    ),
    CuponDescuento(
      id: 'default_mass15',
      codigo: 'MASS15',
      descripcion: '15% de descuento por compras desde S/ 30',
      tipo: 'porcentaje',
      valor: 15,
      montoMinimo: 30,
    ),
    CuponDescuento(
      id: 'default_ahorro5',
      codigo: 'AHORRO5',
      descripcion: 'S/ 5.00 menos en compras desde S/ 20',
      tipo: 'monto',
      valor: 5,
      montoMinimo: 20,
    ),
    CuponDescuento(
      id: 'default_bienvenido20',
      codigo: 'BIENVENIDO20',
      descripcion: '20% de descuento de bienvenida',
      tipo: 'porcentaje',
      valor: 20,
      montoMinimo: 15,
    ),
  ];

  String get etiquetaDescuento => tipo == 'porcentaje'
      ? '${valor.toStringAsFixed(0)}% OFF'
      : 'S/ ${valor.toStringAsFixed(2)} OFF';

  double calcularDescuento(double subtotal) {
    if (!activo || subtotal <= 0 || subtotal < montoMinimo) return 0;
    final monto = tipo == 'porcentaje' ? subtotal * (valor / 100) : valor;
    return monto.clamp(0, subtotal);
  }

  Map<String, dynamic> toMap() => {
    'codigo': codigo.trim().toUpperCase(),
    'descripcion': descripcion.trim(),
    'tipo': tipo,
    'valor': valor,
    'montoMinimo': montoMinimo,
    'activo': activo,
  };

  factory CuponDescuento.fromMap(String id, Map<String, dynamic> d) {
    return CuponDescuento(
      id: id,
      codigo: (d['codigo'] ?? '').toString().toUpperCase(),
      descripcion: (d['descripcion'] ?? '').toString(),
      tipo: d['tipo'] == 'monto' ? 'monto' : 'porcentaje',
      valor: (d['valor'] as num?)?.toDouble() ?? 0,
      montoMinimo: (d['montoMinimo'] as num?)?.toDouble() ?? 0,
      activo: d['activo'] ?? true,
    );
  }

  static String extraerCodigoDesdeQr(String raw) {
    final limpio = raw.trim();
    final uri = Uri.tryParse(limpio);
    if (uri != null && uri.queryParameters.isNotEmpty) {
      final param =
          uri.queryParameters['code'] ??
          uri.queryParameters['cupon'] ??
          uri.queryParameters['promo'];
      if (param != null && param.trim().isNotEmpty) {
        return param.trim().toUpperCase();
      }
    }
    final upper = limpio.toUpperCase();
    for (final prefix in ['MASS:', 'CUPON:', 'PROMO:', 'DESCUENTO:']) {
      if (upper.startsWith(prefix)) {
        return upper.substring(prefix.length).trim();
      }
    }
    return upper;
  }
}
