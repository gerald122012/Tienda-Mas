const { aCentavos, desdeCentavos, normalizar } = require('./textoComercial');

const PREFERENCIAS = {
  desayuno: ['leche', 'avena', 'mantequilla', 'yogurt', 'galleta', 'pan'],
  almuerzo: ['arroz', 'fideo', 'aceite', 'lenteja', 'atun'],
  cena: ['arroz', 'fideo', 'leche', 'avena', 'galleta'],
  general: [],
};

function raiz(producto) {
  return normalizar(producto.nombre).split(' ').find((parte) => parte.length > 2) || '';
}

function prioridad(producto, palabras) {
  const texto = normalizar(
    `${producto.nombre} ${producto.marca} ${producto.categoria}`,
  );
  const puesto = palabras.findIndex((palabra) => texto.includes(palabra));
  const grupo = puesto === -1 ? palabras.length + 1 : puesto;
  return grupo * 1_000_000 + aCentavos(producto.precio);
}

function armarLista(productos, presupuestoSoles, preferencia, limite) {
  const tope = aCentavos(presupuestoSoles);
  const palabras = PREFERENCIAS[preferencia] || [];
  const disponibles = productos.filter((producto) => {
    const centavos = aCentavos(producto.precio);
    return (
      producto.disponible &&
      producto.stock > 0 &&
      centavos > 0 &&
      centavos <= tope
    );
  });
  const ordenados = [...disponibles].sort(
    (a, b) => prioridad(a, palabras) - prioridad(b, palabras),
  );
  const elegidos = [];
  const vistos = new Set();
  let usado = 0;

  function intentar(producto, soloPreferidos) {
    if (elegidos.length >= limite) return;
    const texto = normalizar(`${producto.nombre} ${producto.marca}`);
    const preferido = palabras.some((palabra) => texto.includes(palabra));
    if (soloPreferidos && palabras.length > 0 && !preferido) return;
    const clave = raiz(producto);
    if (clave && vistos.has(clave)) return;
    const centavos = aCentavos(producto.precio);
    if (usado + centavos > tope) return;
    if (producto.stock < 1) return;
    elegidos.push({
      ...producto,
      cantidad: 1,
      subtotal: desdeCentavos(centavos),
    });
    usado += centavos;
    if (clave) vistos.add(clave);
  }

  for (const producto of ordenados) intentar(producto, true);
  if (palabras.length === 0) {
    for (const producto of ordenados) intentar(producto, false);
  }

  return {
    productos: elegidos,
    presupuesto: desdeCentavos(tope),
    total: desdeCentavos(usado),
    restante: desdeCentavos(tope - usado),
    alcanza: elegidos.length > 0,
  };
}

module.exports = { armarLista, PREFERENCIAS };
