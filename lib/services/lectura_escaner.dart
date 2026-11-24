import '../models/cupon.dart';
import '../models/producto.dart';

enum EstadoCuponVisual {
  reconocido,
  aplicado,
  inactivo,
  inexistente,
  condiciones,
  error,
}

class DecisionCupon {
  final String codigo;
  final EstadoCuponVisual estado;
  final String mensaje;

  /// True solo cuando las validaciones locales permiten llamar a CarritoService.
  final bool aplicar;

  const DecisionCupon({
    required this.codigo,
    required this.estado,
    required this.mensaje,
    required this.aplicar,
  });
}

/// No abre enlaces ni ejecuta el contenido del QR.
DecisionCupon decidirCupon({
  required String raw,
  required CuponDescuento? cupon,
  required bool carritoVacio,
  required double subtotal,
}) {
  final codigo = CuponDescuento.extraerCodigoDesdeQr(raw);
  if (codigo.isEmpty) {
    return const DecisionCupon(
      codigo: '',
      estado: EstadoCuponVisual.inexistente,
      mensaje: 'El código no tiene un cupón reconocible.',
      aplicar: false,
    );
  }
  if (cupon == null) {
    return DecisionCupon(
      codigo: codigo,
      estado: EstadoCuponVisual.inexistente,
      mensaje: 'El código $codigo no corresponde a un cupón.',
      aplicar: false,
    );
  }
  if (!cupon.activo) {
    return DecisionCupon(
      codigo: cupon.codigo,
      estado: EstadoCuponVisual.inactivo,
      mensaje: 'Este cupón ya no está activo.',
      aplicar: false,
    );
  }
  if (carritoVacio) {
    return DecisionCupon(
      codigo: cupon.codigo,
      estado: EstadoCuponVisual.reconocido,
      mensaje:
          'Cupón ${cupon.codigo} reconocido. Agrega productos al carrito para aplicarlo.',
      aplicar: false,
    );
  }
  if (subtotal < cupon.montoMinimo) {
    return DecisionCupon(
      codigo: cupon.codigo,
      estado: EstadoCuponVisual.condiciones,
      mensaje:
          'Compra mínima de S/ ${cupon.montoMinimo.toStringAsFixed(2)} para usar ${cupon.codigo}.',
      aplicar: false,
    );
  }
  return DecisionCupon(
    codigo: cupon.codigo,
    estado: EstadoCuponVisual.reconocido,
    mensaje: 'Cupón ${cupon.codigo} listo para aplicar.',
    aplicar: true,
  );
}

/// La cámara solo acepta código de barras o id exactos.
/// La búsqueda manual también acepta un nombre exacto, no parecidos.
Producto? productoPorCodigo(
  List<Producto> productos,
  String codigo, {
  bool permitirNombre = false,
}) {
  final limpio = codigo.trim();
  if (limpio.isEmpty) return null;
  for (final producto in productos) {
    if (producto.codigoBarras.trim() == limpio || producto.id == limpio) {
      return producto;
    }
  }
  if (!permitirNombre) return null;
  final nombre = limpio.toLowerCase();
  final coincidencias = productos
      .where((producto) => producto.nombre.trim().toLowerCase() == nombre)
      .toList();
  if (coincidencias.length == 1) return coincidencias.single;
  return null;
}

class CompuertaLectura {
  bool ocupada = false;
  String? codigo;

  bool aceptar(String codigo) {
    final limpio = codigo.trim();
    if (limpio.isEmpty || ocupada) return false;
    ocupada = true;
    this.codigo = limpio;
    return true;
  }

  void reanudar() {
    ocupada = false;
    codigo = null;
  }
}

const extensionesArchivoPermitidas = {
  'jpg',
  'jpeg',
  'png',
  'pdf',
  'doc',
  'docx',
  'txt',
};

const int maxBytesArchivo = 8 * 1024 * 1024;

enum EstadoArchivoLectura {
  valido,
  formatoInvalido,
  vacio,
  demasiadoGrande,
}

class ArchivoElegido {
  final String nombre;
  final String extension;
  final int tamanoBytes;

  const ArchivoElegido({
    required this.nombre,
    required this.extension,
    required this.tamanoBytes,
  });
}

EstadoArchivoLectura validarArchivoElegido(ArchivoElegido archivo) {
  final extension = archivo.extension.trim().toLowerCase().replaceAll('.', '');
  if (!extensionesArchivoPermitidas.contains(extension)) {
    return EstadoArchivoLectura.formatoInvalido;
  }
  if (archivo.tamanoBytes <= 0) return EstadoArchivoLectura.vacio;
  if (archivo.tamanoBytes > maxBytesArchivo) {
    return EstadoArchivoLectura.demasiadoGrande;
  }
  return EstadoArchivoLectura.valido;
}

String textoTamanoArchivo(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
}

class ResultadoRegistroArchivo {
  final bool enNube;
  final String? error;

  const ResultadoRegistroArchivo({required this.enNube, this.error});
}

String mensajeArchivoInvalido(EstadoArchivoLectura estado) => switch (estado) {
  EstadoArchivoLectura.valido => '',
  EstadoArchivoLectura.formatoInvalido =>
    'El archivo debe ser JPG, PNG, PDF, DOC, DOCX o TXT.',
  EstadoArchivoLectura.vacio => 'El archivo está vacío.',
  EstadoArchivoLectura.demasiadoGrande =>
    'El archivo supera el máximo de 8 MB.',
};
