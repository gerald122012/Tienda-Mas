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

String? dniOpcional(String? valor) {
  if (valor == null || valor.trim().isEmpty) return null;
  return documentoValido(valor);
}

String? correoCliente(String? valor) {
  final texto = valor?.trim() ?? '';
  if (texto.isEmpty) return 'Ingresa tu correo';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(texto)) {
    return 'Ingresa un correo válido';
  }
  return null;
}

String? claveCliente(String? valor, {required bool registro}) {
  if (valor == null || valor.isEmpty) return 'Ingresa tu contraseña';
  if (registro && valor.length < 6) return 'Mínimo 6 caracteres';
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

String? nombreCompleto(String? valor) {
  final texto = (valor ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
  if (texto.isEmpty) return 'Escribe tu nombre completo';
  if (!RegExp(r"^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ' ]+$").hasMatch(texto)) {
    return 'Usa solo letras';
  }
  if (texto.split(' ').length < 2) return 'Incluye nombre y apellido';
  return null;
}
