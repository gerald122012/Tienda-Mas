import '../../models/producto.dart';

enum OrdenCatalogo { az, za, menorPrecio, mayorPrecio }

class ConsultaCatalogo {
  final String texto;
  final String categoria;
  final OrdenCatalogo orden;
  final bool soloDisponibles;
  final String? marca;
  final double? precioDesde;
  final double? precioHasta;

  const ConsultaCatalogo({
    this.texto = '',
    this.categoria = 'todas',
    this.orden = OrdenCatalogo.az,
    this.soloDisponibles = false,
    this.marca,
    this.precioDesde,
    this.precioHasta,
  });

  bool get tieneAjuste =>
      orden != OrdenCatalogo.az ||
      soloDisponibles ||
      (marca != null && marca!.isNotEmpty) ||
      precioDesde != null ||
      precioHasta != null;

  ConsultaCatalogo copiar({
    String? texto,
    String? categoria,
    OrdenCatalogo? orden,
    bool? soloDisponibles,
    String? marca,
    bool limpiarMarca = false,
    double? precioDesde,
    bool limpiarDesde = false,
    double? precioHasta,
    bool limpiarHasta = false,
  }) {
    return ConsultaCatalogo(
      texto: texto ?? this.texto,
      categoria: categoria ?? this.categoria,
      orden: orden ?? this.orden,
      soloDisponibles: soloDisponibles ?? this.soloDisponibles,
      marca: limpiarMarca ? null : marca ?? this.marca,
      precioDesde: limpiarDesde ? null : precioDesde ?? this.precioDesde,
      precioHasta: limpiarHasta ? null : precioHasta ?? this.precioHasta,
    );
  }
}

String normalizarConsulta(String texto) {
  var resultado = texto.toLowerCase();
  const conTilde = 'áéíóúü';
  const sinTilde = 'aeiouu';
  for (var i = 0; i < conTilde.length; i++) {
    resultado = resultado.replaceAll(conTilde[i], sinTilde[i]);
  }
  return resultado;
}

bool productoDisponible(Producto producto) =>
    producto.disponible && producto.stock > 0;

int columnasCatalogo(double ancho) {
  final util = ancho - 32;
  if (util < 300) return 1;
  if (util < 560) return 2;
  if (util < 840) return 3;
  return 4;
}

List<Producto> productosConsultados(
  List<Producto> origen,
  ConsultaCatalogo consulta,
) {
  final termino = normalizarConsulta(consulta.texto.trim());
  final lista = origen.where((producto) {
    if (consulta.categoria != 'todas' &&
        producto.categoria != consulta.categoria) {
      return false;
    }
    if (consulta.soloDisponibles && !productoDisponible(producto)) {
      return false;
    }
    final marca = consulta.marca?.trim();
    if (marca != null && marca.isNotEmpty && producto.marca != marca) {
      return false;
    }
    if (consulta.precioDesde != null &&
        producto.precio < consulta.precioDesde!) {
      return false;
    }
    if (consulta.precioHasta != null &&
        producto.precio > consulta.precioHasta!) {
      return false;
    }
    if (termino.isEmpty) return true;
    final ficha = normalizarConsulta(
      '${producto.nombre} ${producto.marca} ${producto.categoria} ${producto.codigoBarras}',
    );
    return ficha.contains(termino);
  }).toList();

  lista.sort((a, b) {
    final precio = switch (consulta.orden) {
      OrdenCatalogo.menorPrecio => a.precio.compareTo(b.precio),
      OrdenCatalogo.mayorPrecio => b.precio.compareTo(a.precio),
      OrdenCatalogo.za => b.nombre.toLowerCase().compareTo(
        a.nombre.toLowerCase(),
      ),
      OrdenCatalogo.az => a.nombre.toLowerCase().compareTo(
        b.nombre.toLowerCase(),
      ),
    };
    if (precio != 0) return precio;
    final nombre = a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
    if (nombre != 0) return nombre;
    return a.id.compareTo(b.id);
  });
  return lista;
}

List<String> marcasDelCatalogo(List<Producto> productos) {
  final marcas =
      productos
          .map((producto) => producto.marca.trim())
          .where((m) => m.isNotEmpty)
          .toSet()
          .toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return marcas;
}
