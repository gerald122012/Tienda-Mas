const NO_ENCONTRADO = '00000000';

const NOMBRES = [
  'ANA',
  'LUIS',
  'MARIA',
  'CARLOS',
  'ROSA',
  'PEDRO',
  'ELENA',
  'MIGUEL',
  'SOFIA',
  'DIEGO',
];
const PATERNOS = [
  'QUISPE',
  'HUAMAN',
  'FLORES',
  'DIAZ',
  'RAMOS',
  'SOTO',
  'VEGA',
  'CASTRO',
  'PAREDES',
  'ROJAS',
];
const MATERNOS = [
  'LOPEZ',
  'GARCIA',
  'TORRES',
  'MENDOZA',
  'CHAVEZ',
  'SILVA',
  'RUIZ',
  'ORTEGA',
  'CAMPOS',
  'NAVARRO',
];

function consultarSimulado(dni) {
  if (dni === NO_ENCONTRADO) return { ok: false };
  const nombres = NOMBRES[Number(dni[0])];
  const apellidoPaterno = PATERNOS[Number(dni[0])];
  const apellidoMaterno = MATERNOS[Number(dni[7])];
  return { ok: true, nombres, apellidoPaterno, apellidoMaterno };
}

module.exports = { consultarSimulado, NO_ENCONTRADO };
