String? obligatorio(String? valor) {
  if (valor == null || valor.trim().isEmpty) return 'Campo obligatorio';
  return null;
}

String? minimoCaracteres(String? valor, int minimo) {
  if (valor == null || valor.trim().isEmpty) return 'Campo obligatorio';
  if (valor.trim().length < minimo) {
    return 'Debe tener al menos $minimo caracteres';
  }
  return null;
}

String? mayorACero(String? valor) {
  if (valor == null || valor.trim().isEmpty) return 'Campo obligatorio';
  final numero = double.tryParse(valor.trim().replaceAll(',', '.'));
  if (numero == null || numero <= 0) return 'Debe ser un número mayor a 0';
  return null;
}

String? enteroMinimo(String? valor, int minimo) {
  if (valor == null || valor.trim().isEmpty) return 'Campo obligatorio';
  final numero = int.tryParse(valor.trim());
  if (numero == null || numero < minimo) {
    return 'Debe ser un entero mayor o igual a $minimo';
  }
  return null;
}

String? numeroEnRango(String? valor, double minimo, double maximo) {
  if (valor == null || valor.trim().isEmpty) return 'Campo obligatorio';
  final numero = double.tryParse(valor.trim().replaceAll(',', '.'));
  if (numero == null || numero < minimo || numero > maximo) {
    return 'Debe estar entre ${minimo.toInt()} y ${maximo.toInt()}';
  }
  return null;
}

String? documentoValido(String? valor) {
  if (valor == null || valor.trim().isEmpty) return 'Campo obligatorio';
  if (!RegExp(r'^\d{8}$').hasMatch(valor.trim())) {
    return 'El documento debe tener 8 dígitos numéricos';
  }
  return null;
}

String? fechaNoFutura(DateTime fecha) {
  if (fecha.isAfter(DateTime.now())) return 'La fecha no puede ser futura';
  return null;
}

// Regla de negocio: una postulación rechazada no puede pasar directamente a aprobado.
bool puedeCambiarEstado(String actual, String nuevo) {
  if (actual == 'rechazado' && nuevo == 'aprobado') return false;
  if (actual == 'cancelado' && nuevo == 'confirmado') return false;
  return true;
}
