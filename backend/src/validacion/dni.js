function dniValido(valor) {
  return typeof valor === 'string' && /^\d{8}$/.test(valor);
}

module.exports = { dniValido };
