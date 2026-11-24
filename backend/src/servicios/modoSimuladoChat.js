const { normalizar, tokens } = require('./textoComercial');

function rechazo(motivo) {
  return { herramienta: 'rechazo', argumentos: { motivo } };
}

function consultaLimpia(texto) {
  const ruido = new Set([
    'economico',
    'barato',
    'compara',
    'comparar',
    'diferencia',
    'mas',
    'mejor',
    'opcion',
  ]);
  return tokens(texto)
    .filter((pieza) => !ruido.has(pieza))
    .join(' ');
}

function interpretarLocal(mensaje) {
  const texto = normalizar(mensaje);
  if (
    /ignora|instrucciones del sistema|api key|clave secreta|gemini_api|system prompt|firebase|contrasena|password/.test(
      texto,
    )
  ) {
    return rechazo('inyeccion');
  }
  if (/devolucion|devolver|cambiar un producto|politica de cambio/.test(texto)) {
    return { herramienta: 'responder_faq', argumentos: { tema: 'cambios' } };
  }
  if (/promocion|cupon|oferta/.test(texto)) {
    return { herramienta: 'listar_cupones', argumentos: {} };
  }
  if (/donde|tienda|horario|ubicacion|sucursal/.test(texto)) {
    const ciudad = /cusco/.test(texto)
      ? 'Cusco'
      : /lima|san borja/.test(texto)
        ? 'Lima'
        : '';
    return {
      herramienta: 'buscar_tiendas',
      argumentos: { consulta: ciudad, ciudad, limite: 3 },
    };
  }
  if (
    /clima|lluvia|tarea|matematica|politica|futbol|javascript|dolar|bitcoin/.test(
      texto,
    )
  ) {
    return { herramienta: 'fuera_de_tienda', argumentos: {} };
  }

  const presupuesto = texto.match(/(\d+(?:[.,]\d{1,2})?)\s*soles?/);
  const monto = presupuesto
    ? Number(presupuesto[1].replace(',', '.'))
    : null;
  const preferencia = /desayuno/.test(texto)
    ? 'desayuno'
    : /almuerzo/.test(texto)
      ? 'almuerzo'
      : /cena/.test(texto)
        ? 'cena'
        : null;
  if (monto !== null || preferencia) {
    return {
      herramienta: 'armar_lista',
      argumentos: {
        presupuesto: monto === null ? 80 : monto,
        preferencia: preferencia || 'general',
        limite: 4,
      },
    };
  }
  if (/economico|barato|compara|comparar|diferencia/.test(texto)) {
    return {
      herramienta: 'comparar_productos',
      argumentos: { consulta: consultaLimpia(texto), limite: 3 },
    };
  }
  if (/que productos|disponibles|que hay/.test(texto)) {
    return {
      herramienta: 'buscar_productos',
      argumentos: {
        consulta: '*',
        soloDisponibles: true,
        orden: 'precio_asc',
        limite: 4,
      },
    };
  }
  if (/similar|parecid|recomiend/.test(texto)) {
    return {
      herramienta: 'buscar_productos',
      argumentos: {
        consulta: consultaLimpia(texto) || texto,
        incluirSimilares: true,
        limite: 4,
      },
    };
  }
  return {
    herramienta: 'buscar_productos',
    argumentos: { consulta: consultaLimpia(texto) || texto, limite: 4 },
  };
}

module.exports = { interpretarLocal };
