const { dniValido } = require('../validacion/dni');
const { consultarSimulado } = require('./modoSimulado');
const { consultarProveedor } = require('./proveedorApisPeru');

function respuesta(estado, error) {
  return { estado, cuerpo: { error } };
}

function desdeProveedor(error) {
  switch (error && error.codigo) {
    case 'NO_ENCONTRADO':
      return respuesta(404, 'No se encontró información para ese DNI.');
    case 'TOKEN_AUSENTE':
      return respuesta(503, 'La consulta real no está configurada.');
    case 'TIEMPO':
      return respuesta(504, 'El servicio de consulta no está disponible.');
    case 'HTTP':
    case 'ESTRUCTURA':
    case 'CONEXION':
      return respuesta(502, 'El servicio de consulta no está disponible.');
    default:
      return respuesta(502, 'El servicio de consulta no está disponible.');
  }
}

async function consultarDni(dni, opciones) {
  if (!dniValido(dni)) {
    return respuesta(400, 'El DNI debe tener 8 dígitos.');
  }
  if (opciones.modo === 'live') {
    try {
      const datos = await consultarProveedor(dni, opciones);
      return { estado: 200, cuerpo: datos };
    } catch (error) {
      return desdeProveedor(error);
    }
  }
  const simulado = consultarSimulado(dni);
  if (!simulado.ok) {
    return respuesta(404, 'No se encontró información para ese DNI.');
  }
  return {
    estado: 200,
    cuerpo: {
      nombres: simulado.nombres,
      apellidoPaterno: simulado.apellidoPaterno,
      apellidoMaterno: simulado.apellidoMaterno,
      simulado: true,
    },
  };
}

module.exports = { consultarDni };
