function normalizar(valor) {
  return String(valor || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9.\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function aCentavos(valor) {
  const numero = Number(valor);
  if (!Number.isFinite(numero)) return null;
  return Math.round(numero * 100);
}

function desdeCentavos(centavos) {
  return centavos / 100;
}

function soles(centavos) {
  return desdeCentavos(centavos).toFixed(2);
}

const PARADA = new Set([
  'el',
  'la',
  'los',
  'las',
  'de',
  'del',
  'un',
  'una',
  'con',
  'para',
  'por',
  'que',
  'cual',
  'cuanto',
  'cuesta',
  'precio',
  'precios',
  'tienen',
  'tiene',
  'hay',
  'disponible',
  'disponibles',
  'producto',
  'productos',
  'mass',
  'tienda',
  'tiendas',
  'recomiendame',
  'recomiendas',
  'quiero',
  'busco',
  'buscar',
  'comprar',
  'puedo',
]);

function tokens(consulta) {
  return normalizar(consulta)
    .split(' ')
    .filter((parte) => parte.length > 2 && !PARADA.has(parte));
}

module.exports = { normalizar, aCentavos, desdeCentavos, soles, tokens };
