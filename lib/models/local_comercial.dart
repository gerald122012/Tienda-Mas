import 'package:cloud_firestore/cloud_firestore.dart';

// Módulo 3 - Alquila tu Local (Ofrece tu local de +200 m² a Tiendas Mass)
class LocalComercial {
  String id;
  String propietario;
  String documento;
  String distritoCiudad;
  String modalidad;
  double precioPorM2;
  int areaM2;
  double bonificacionPorcentaje;
  double rentaFinal;
  DateTime fechaRegistro;
  DateTime fechaDisponibilidad;
  String estado;
  bool enEsquina;
  List<String> caracteristicas;
  String notas;

  static const modalidades = ['alquiler', 'usufructo', 'asociación'];
  static const estados = ['evaluando', 'aprobado', 'rechazado'];
  static const caracteristicasDisponibles = [
    'Puerta a calle',
    'Agua y desagüe',
    'Luz trifásica',
    'Zonificación comercial',
    'Zona de carga',
  ];
  static const bonoEsquinaPorM2 = 5.0;

  LocalComercial({
    this.id = '',
    required this.propietario,
    required this.documento,
    required this.distritoCiudad,
    required this.modalidad,
    required this.precioPorM2,
    required this.areaM2,
    required this.bonificacionPorcentaje,
    required this.rentaFinal,
    required this.fechaRegistro,
    required this.fechaDisponibilidad,
    required this.estado,
    required this.enEsquina,
    required this.caracteristicas,
    required this.notas,
  });

  // rentaFinal = (precioPorM2 x areaM2) - descuento/ajuste% + bono por esquina
  static double calcularRentaFinal(
    double precioPorM2,
    int areaM2,
    double ajustePorcentaje,
    bool enEsquina,
  ) {
    double total = precioPorM2 * areaM2;
    total = total - (total * ajustePorcentaje / 100);
    if (enEsquina) total = total + bonoEsquinaPorM2 * areaM2;
    return total;
  }

  Map<String, dynamic> toMap() {
    return {
      'propietario': propietario,
      'documento': documento,
      'distritoCiudad': distritoCiudad,
      'modalidad': modalidad,
      'precioPorM2': precioPorM2,
      'areaM2': areaM2,
      'bonificacionPorcentaje': bonificacionPorcentaje,
      'rentaFinal': rentaFinal,
      'fechaRegistro': Timestamp.fromDate(fechaRegistro),
      'fechaDisponibilidad': Timestamp.fromDate(fechaDisponibilidad),
      'estado': estado,
      'enEsquina': enEsquina,
      'caracteristicas': caracteristicas,
      'notas': notas,
    };
  }

  factory LocalComercial.fromMap(String id, Map datos) {
    final fReg = datos['fechaRegistro'];
    final fDisp = datos['fechaDisponibilidad'];
    final mod = (datos['modalidad'] ?? '').toString();
    final est = (datos['estado'] ?? '').toString();
    return LocalComercial(
      id: id,
      propietario: datos['propietario'] ?? '',
      documento: datos['documento'] ?? '',
      distritoCiudad: datos['distritoCiudad'] ?? '',
      modalidad: modalidades.contains(mod) ? mod : modalidades.first,
      precioPorM2: (datos['precioPorM2'] ?? 0).toDouble(),
      areaM2: (datos['areaM2'] ?? 200).toInt(),
      bonificacionPorcentaje: (datos['bonificacionPorcentaje'] ?? 0).toDouble(),
      rentaFinal: (datos['rentaFinal'] ?? 0).toDouble(),
      fechaRegistro: fReg is Timestamp ? fReg.toDate() : DateTime.now(),
      fechaDisponibilidad: fDisp is Timestamp
          ? fDisp.toDate()
          : DateTime.now().add(const Duration(days: 15)),
      estado: estados.contains(est) ? est : 'evaluando',
      enEsquina: datos['enEsquina'] ?? false,
      caracteristicas: List<String>.from(datos['caracteristicas'] ?? []),
      notas: datos['notas'] ?? '',
    );
  }
}
