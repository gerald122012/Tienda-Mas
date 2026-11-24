class TurnoMassBot {
  final String rol;
  final String texto;

  const TurnoMassBot({required this.rol, required this.texto});

  Map<String, String> toJson() => {'rol': rol, 'texto': texto};
}

class ProductoMassBot {
  final String id;
  final String nombre;
  final String marca;
  final String categoria;
  final List<String> presentaciones;
  final double precio;
  final int stock;
  final bool disponible;
  final int cantidad;
  final double? subtotal;
  final bool similar;
  final String imagenAsset;

  const ProductoMassBot({
    required this.id,
    required this.nombre,
    required this.marca,
    required this.categoria,
    required this.presentaciones,
    required this.precio,
    required this.stock,
    required this.disponible,
    this.cantidad = 0,
    this.subtotal,
    this.similar = false,
    this.imagenAsset = '',
  });

  factory ProductoMassBot.fromJson(Map<String, dynamic> json) {
    final lista = json['presentaciones'];
    return ProductoMassBot(
      id: (json['id'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      marca: (json['marca'] ?? '').toString(),
      categoria: (json['categoria'] ?? '').toString(),
      presentaciones: lista is List
          ? lista.map((item) => item.toString()).toList()
          : const [],
      precio: (json['precio'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      disponible: json['disponible'] == true,
      cantidad: (json['cantidad'] as num?)?.toInt() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble(),
      similar: json['similar'] == true,
      imagenAsset: (json['imagenAsset'] ?? '').toString(),
    );
  }
}

class TiendaMassBot {
  final String nombre;
  final String distrito;
  final String direccion;
  final String horario;
  final bool abierta;

  const TiendaMassBot({
    required this.nombre,
    required this.distrito,
    required this.direccion,
    required this.horario,
    required this.abierta,
  });

  factory TiendaMassBot.fromJson(Map<String, dynamic> json) {
    return TiendaMassBot(
      nombre: (json['nombre'] ?? '').toString(),
      distrito: (json['distrito'] ?? '').toString(),
      direccion: (json['direccion'] ?? '').toString(),
      horario: (json['horario'] ?? '').toString(),
      abierta: json['abierta'] == true,
    );
  }
}

class CuponMassBot {
  final String codigo;
  final String descripcion;
  final String tipo;
  final double valor;
  final double montoMinimo;

  const CuponMassBot({
    required this.codigo,
    required this.descripcion,
    required this.tipo,
    required this.valor,
    required this.montoMinimo,
  });

  factory CuponMassBot.fromJson(Map<String, dynamic> json) {
    return CuponMassBot(
      codigo: (json['codigo'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      tipo: (json['tipo'] ?? '').toString(),
      valor: (json['valor'] as num?)?.toDouble() ?? 0,
      montoMinimo: (json['montoMinimo'] as num?)?.toDouble() ?? 0,
    );
  }

  String get etiqueta => tipo == 'porcentaje'
      ? '${valor.toStringAsFixed(0)}%'
      : 'S/ ${valor.toStringAsFixed(2)}';
}

class RespuestaMassBot {
  final String texto;
  final List<ProductoMassBot> productos;
  final List<TiendaMassBot> tiendas;
  final List<CuponMassBot> cupones;
  final double? presupuesto;
  final double? total;
  final double? restante;
  final String consultadoEn;
  final bool simulado;
  final bool sinConexion;

  const RespuestaMassBot({
    required this.texto,
    required this.productos,
    required this.tiendas,
    required this.cupones,
    required this.presupuesto,
    required this.total,
    required this.restante,
    required this.consultadoEn,
    required this.simulado,
    this.sinConexion = false,
  });

  factory RespuestaMassBot.fromJson(Map<String, dynamic> json) {
    List<T> lista<T>(String clave, T Function(Map<String, dynamic>) crear) {
      final cruda = json[clave];
      if (cruda is! List) return [];
      return cruda
          .whereType<Map>()
          .map((item) => crear(item.map((k, v) => MapEntry(k.toString(), v))))
          .toList();
    }

    return RespuestaMassBot(
      texto: (json['texto'] ?? '').toString(),
      productos: lista('productos', ProductoMassBot.fromJson),
      tiendas: lista('tiendas', TiendaMassBot.fromJson),
      cupones: lista('cupones', CuponMassBot.fromJson),
      presupuesto: (json['presupuesto'] as num?)?.toDouble(),
      total: (json['total'] as num?)?.toDouble(),
      restante: (json['restante'] as num?)?.toDouble(),
      consultadoEn: (json['consultadoEn'] ?? '').toString(),
      simulado: json['simulado'] == true,
    );
  }
}
