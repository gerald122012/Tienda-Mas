const https = require('https');

const { armarLista } = require('./presupuesto');
const {
  aCentavos,
  desdeCentavos,
  normalizar,
  soles,
  tokens,
} = require('./textoComercial');

const CAMPOS_PRODUCTO = [
  'nombre',
  'descripcion',
  'marca',
  'precio',
  'stock',
  'categoria',
  'disponible',
  'presentaciones',
  'imagenAsset',
];
const CAMPOS_TIENDA = [
  'nombre',
  'ciudad',
  'distrito',
  'direccion',
  'horario',
  'abierta',
  'servicios',
];
const CAMPOS_CUPON = [
  'codigo',
  'descripcion',
  'tipo',
  'valor',
  'montoMinimo',
  'activo',
];

function producto(datos) {
  return {
    id: datos.id,
    nombre: datos.nombre,
    marca: datos.marca,
    categoria: datos.categoria,
    presentaciones: datos.presentaciones,
    precio: datos.precio,
    stock: datos.stock,
    disponible: datos.disponible,
    imagenAsset: datos.imagenAsset || '',
    cantidad: datos.cantidad || 0,
    subtotal: datos.subtotal ?? null,
    similar: Boolean(datos.similar),
  };
}

function catalogoFicticio(consultadoEn = '2026-11-23T15:00:00.000Z') {
  const productos = [
    producto({
      id: 'catalogo_001',
      nombre: 'Arroz Extra COSTEÑO Bolsa 5Kg',
      marca: 'COSTEÑO',
      categoria: 'abarrotes',
      presentaciones: ['Bolsa 5Kg'],
      precio: 20.9,
      stock: 30,
      disponible: true,
      imagenAsset: 'assets/productos/marcas/catalogo_001.jpg',
    }),
    producto({
      id: 'catalogo_003',
      nombre: 'Aceite Vegetal PRIMOR Clásico Botella 900ml',
      marca: 'PRIMOR',
      categoria: 'abarrotes',
      presentaciones: ['Botella 900ml'],
      precio: 8.5,
      stock: 40,
      disponible: true,
      imagenAsset: 'assets/productos/marcas/catalogo_003-limpia.png',
    }),
    producto({
      id: 'fixture_aceite_002',
      nombre: 'Aceite Vegetal PRIMOR Premium Botella 1L',
      marca: 'PRIMOR',
      categoria: 'abarrotes',
      presentaciones: ['Botella 1L'],
      precio: 12.9,
      stock: 12,
      disponible: true,
      imagenAsset: '',
    }),
    producto({
      id: 'catalogo_006',
      nombre: 'Avena QUAKER Tradicional Bolsa 500g',
      marca: 'QUAKER',
      categoria: 'abarrotes',
      presentaciones: ['Bolsa 500g'],
      precio: 6.5,
      stock: 55,
      disponible: true,
      imagenAsset: 'assets/productos/marcas/catalogo_006-limpia.png',
    }),
    producto({
      id: 'catalogo_017',
      nombre: 'Leche Evaporada Entera GLORIA Lata 390g Paquete 6un',
      marca: 'GLORIA',
      categoria: 'lácteos',
      presentaciones: ['Paquete 6un'],
      precio: 21.9,
      stock: 30,
      disponible: true,
      imagenAsset: 'assets/productos/marcas/catalogo_017.jpg',
    }),
    producto({
      id: 'catalogo_019',
      nombre: 'Leche Light GLORIA Lata 390g',
      marca: 'GLORIA',
      categoria: 'lácteos',
      presentaciones: ['Lata 390g'],
      precio: 4.4,
      stock: 40,
      disponible: true,
      imagenAsset: 'assets/productos/marcas/catalogo_019.jpg',
    }),
    producto({
      id: 'catalogo_018',
      nombre: 'Leche Entera UHT LAIVE Caja 946ml',
      marca: 'LAIVE',
      categoria: 'lácteos',
      presentaciones: ['Caja 946ml'],
      precio: 6.2,
      stock: 0,
      disponible: false,
      imagenAsset: 'assets/productos/marcas/catalogo_018.jpg',
    }),
    producto({
      id: 'catalogo_024',
      nombre: 'Mantequilla con Sal GLORIA Paquete 180g',
      marca: 'GLORIA',
      categoria: 'lácteos',
      presentaciones: ['Paquete 180g'],
      precio: 9.4,
      stock: 65,
      disponible: true,
      imagenAsset: 'assets/productos/marcas/catalogo_024-limpia.jpg',
    }),
  ];
  return {
    simulado: true,
    consultadoEn,
    lecturas: { productos: 'ok', tiendas: 'ok', cupones: 'ok' },
    productos,
    tiendas: [
      {
        id: 'tienda_san_borja',
        nombre: 'Mass San Borja',
        ciudad: 'Lima',
        distrito: 'San Borja',
        direccion: 'Av. San Borja Norte 455',
        horario: '7:00 AM - 10:00 PM',
        abierta: true,
      },
    ],
    cupones: [
      {
        codigo: 'MASS10',
        descripcion: '10% de descuento en tu compra',
        tipo: 'porcentaje',
        valor: 10,
        montoMinimo: 10,
        activo: true,
      },
      {
        codigo: 'VENCIDO1',
        descripcion: 'Cupón inactivo de prueba',
        tipo: 'monto',
        valor: 5,
        montoMinimo: 20,
        activo: false,
      },
    ],
  };
}

function coincide(productoItem, consulta, marca) {
  const texto = normalizar(
    `${productoItem.nombre} ${productoItem.marca} ${productoItem.categoria} ${productoItem.presentaciones.join(' ')}`,
  );
  if (normalizar(consulta) === '*') {
    return !marca || texto.includes(normalizar(marca));
  }
  const pedidos = tokens(`${consulta || ''} ${marca || ''}`);
  if (pedidos.length === 0) return false;
  return pedidos.every((pieza) => texto.includes(pieza));
}

function ordenar(lista, orden) {
  const copia = [...lista];
  if (orden === 'precio_asc') {
    copia.sort((a, b) => aCentavos(a.precio) - aCentavos(b.precio));
  } else if (orden === 'precio_desc') {
    copia.sort((a, b) => aCentavos(b.precio) - aCentavos(a.precio));
  }
  return copia;
}

function similares(base, todos, ya, cupo) {
  if (base.length === 0 || cupo <= 0) return [];
  const categoria = base[0].categoria;
  return todos
    .filter(
      (item) =>
        item.categoria === categoria &&
        item.disponible &&
        item.stock > 0 &&
        !ya.has(item.id),
    )
    .sort((a, b) => aCentavos(a.precio) - aCentavos(b.precio))
    .slice(0, cupo)
    .map((item) => ({ ...item, similar: true, cantidad: 0, subtotal: null }));
}

function buscarProductos(datos, args) {
  const limite = args.limite;
  let lista = datos.productos.filter((item) =>
    coincide(item, args.consulta, args.marca),
  );
  if (args.categoria) {
    lista = lista.filter((item) => item.categoria === args.categoria);
  }
  if (args.soloDisponibles) {
    lista = lista.filter((item) => item.disponible && item.stock > 0);
  }
  lista = ordenar(lista, args.orden).slice(0, limite);
  const ids = new Set(lista.map((item) => item.id));
  const extra = args.incluirSimilares
    ? similares(lista, datos.productos, ids, 2)
    : [];
  return { tipo: 'productos', productos: [...lista, ...extra] };
}

function compararProductos(datos, args) {
  const lista = ordenar(
    datos.productos.filter((item) => coincide(item, args.consulta, args.marca)),
    'precio_asc',
  ).slice(0, args.limite);
  return { tipo: 'comparacion', productos: lista };
}

function listarCupones(datos) {
  if (datos.lecturas.cupones === 'denegada') {
    return { tipo: 'permiso', recurso: 'cupones' };
  }
  return {
    tipo: 'cupones',
    cupones: datos.cupones.filter((cupon) => cupon.activo === true),
  };
}

function buscarTiendas(datos, args) {
  if (datos.lecturas.tiendas === 'denegada') {
    return { tipo: 'permiso', recurso: 'tiendas' };
  }
  const pedido = tokens(`${args.consulta || ''} ${args.ciudad || ''} ${args.distrito || ''}`);
  const lista = datos.tiendas.filter((tienda) => {
    if (pedido.length === 0) return true;
    const texto = normalizar(
      `${tienda.nombre} ${tienda.ciudad} ${tienda.distrito} ${tienda.direccion}`,
    );
    return pedido.every((pieza) => texto.includes(pieza));
  });
  return { tipo: 'tiendas', tiendas: lista.slice(0, args.limite) };
}

function validarArgs(nombre, crudo) {
  const args = crudo && typeof crudo === 'object' && !Array.isArray(crudo) ? crudo : {};
  const permitidas = {
    buscar_productos: ['consulta', 'marca', 'categoria', 'soloDisponibles', 'orden', 'limite', 'incluirSimilares'],
    comparar_productos: ['consulta', 'marca', 'limite'],
    armar_lista: ['presupuesto', 'preferencia', 'limite'],
    listar_cupones: [],
    buscar_tiendas: ['consulta', 'ciudad', 'distrito', 'limite'],
    responder_faq: ['tema'],
    fuera_de_tienda: [],
    rechazo: ['motivo'],
  };
  if (!permitidas[nombre]) return null;
  for (const clave of Object.keys(args)) {
    if (!permitidas[nombre].includes(clave)) return null;
  }
  const texto = (clave, maximo) => {
    if (args[clave] === undefined) return '';
    if (typeof args[clave] !== 'string') return null;
    const limpio = args[clave].trim();
    if (limpio.length > maximo) return null;
    return limpio;
  };
  const entero = (valor, minimo, maximo, omision) => {
    if (valor === undefined) return omision;
    const numero = Number(valor);
    if (!Number.isInteger(numero) || numero < minimo || numero > maximo) return null;
    return numero;
  };

  if (nombre === 'buscar_productos' || nombre === 'comparar_productos') {
    const consulta = texto('consulta', 80);
    const marca = texto('marca', 40);
    if (consulta === null || marca === null) return null;
    const categorias = ['', 'abarrotes', 'bebidas', 'lácteos', 'limpieza', 'snacks'];
    const categoria = args.categoria === undefined ? '' : args.categoria;
    if (!categorias.includes(categoria)) return null;
    const ordenes = ['relevancia', 'precio_asc', 'precio_desc'];
    const orden = args.orden === undefined ? 'relevancia' : args.orden;
    if (!ordenes.includes(orden)) return null;
    if (
      args.soloDisponibles !== undefined &&
      typeof args.soloDisponibles !== 'boolean'
    ) {
      return null;
    }
    if (
      args.incluirSimilares !== undefined &&
      typeof args.incluirSimilares !== 'boolean'
    ) {
      return null;
    }
    const limite = entero(args.limite, 1, nombre === 'comparar_productos' ? 4 : 6, nombre === 'comparar_productos' ? 3 : 4);
    if (limite === null || (!consulta && !marca)) return null;
    return {
      consulta,
      marca,
      categoria,
      orden,
      soloDisponibles: Boolean(args.soloDisponibles),
      incluirSimilares: Boolean(args.incluirSimilares),
      limite,
    };
  }
  if (nombre === 'armar_lista') {
    const presupuesto = Number(args.presupuesto);
    const centavos = aCentavos(presupuesto);
    if (centavos === null || centavos < 50 || centavos > 500_000) return null;
    const preferencias = ['general', 'desayuno', 'almuerzo', 'cena'];
    const preferencia = args.preferencia || 'general';
    if (!preferencias.includes(preferencia)) return null;
    const limite = entero(args.limite, 1, 6, 4);
    if (limite === null) return null;
    return { presupuesto: desdeCentavos(centavos), preferencia, limite };
  }
  if (nombre === 'buscar_tiendas') {
    const consulta = texto('consulta', 40);
    const ciudad = texto('ciudad', 40);
    const distrito = texto('distrito', 40);
    if (consulta === null || ciudad === null || distrito === null) return null;
    const limite = entero(args.limite, 1, 4, 3);
    if (limite === null) return null;
    return { consulta, ciudad, distrito, limite };
  }
  if (nombre === 'responder_faq') {
    if (!['cambios', 'horario', 'general'].includes(args.tema)) return null;
    return { tema: args.tema };
  }
  if (nombre === 'fuera_de_tienda' || nombre === 'rechazo' || nombre === 'listar_cupones') {
    return {};
  }
  return null;
}

function ejecutarHerramienta(nombre, crudo, datos) {
  if (datos.lecturas.productos === 'denegada') {
    return { tipo: 'permiso', recurso: 'productos' };
  }
  const args = validarArgs(nombre, crudo);
  if (!args) return { tipo: 'invalido' };
  if (nombre === 'buscar_productos') return buscarProductos(datos, args);
  if (nombre === 'comparar_productos') return compararProductos(datos, args);
  if (nombre === 'armar_lista') {
    const lista = armarLista(
      datos.productos,
      args.presupuesto,
      args.preferencia,
      args.limite,
    );
    return { tipo: 'presupuesto', preferencia: args.preferencia, ...lista };
  }
  if (nombre === 'listar_cupones') return listarCupones(datos);
  if (nombre === 'buscar_tiendas') return buscarTiendas(datos, args);
  if (nombre === 'responder_faq') return { tipo: 'faq', tema: args.tema };
  if (nombre === 'fuera_de_tienda') return { tipo: 'fuera' };
  if (nombre === 'rechazo') return { tipo: 'rechazo' };
  return { tipo: 'invalido' };
}

function diferencia(a, b) {
  return soles(Math.abs(aCentavos(a) - aCentavos(b)));
}

function redactar(resultado, simulado) {
  const aviso = simulado ? ' Estos datos son de demostración.' : '';
  if (resultado.tipo === 'permiso') {
    return `No pude consultar ${resultado.recurso} con el permiso actual. Detuve esa parte para no mostrar una lista vacía como si no existiera información.`;
  }
  if (resultado.tipo === 'invalido' || resultado.tipo === 'rechazo') {
    return 'Solo respondo consultas comerciales de TiendasMass. No revelo claves ni modifico precios, stock o pedidos.';
  }
  if (resultado.tipo === 'fuera') {
    return 'Puedo ayudarte con productos, precios, stock, cupones y tiendas Mass.';
  }
  if (resultado.tipo === 'faq') {
    if (resultado.tema === 'cambios') {
      return 'Los cambios se atienden en la tienda de la compra, con comprobante y empaque cerrado. Perecibles: 24 horas. No perecibles: hasta 7 días.';
    }
    if (resultado.tema === 'horario') {
      return 'El horario que puedo confirmar es el de cada tienda consultada. Revísalo en la ficha de la tienda.';
    }
    return 'Puedo consultar productos, precios, stock, cupones activos y tiendas Mass.';
  }
  if (resultado.tipo === 'cupones') {
    if (resultado.cupones.length === 0) {
      return `No encontré cupones activos en la consulta.${aviso}`;
    }
    const lineas = resultado.cupones
      .map((cupon) => {
        const beneficio =
          cupon.tipo === 'porcentaje'
            ? `${cupon.valor}%`
            : `S/ ${Number(cupon.valor).toFixed(2)}`;
        return `${cupon.codigo}: ${beneficio}, desde S/ ${Number(cupon.montoMinimo).toFixed(2)}. ${cupon.descripcion}`;
      })
      .join(' ');
    return `Cupones activos: ${lineas} No los apliqué a tu carrito.${aviso}`;
  }
  if (resultado.tipo === 'tiendas') {
    if (resultado.tiendas.length === 0) {
      return `No encuentro una tienda Mass con ese dato en la consulta.${aviso}`;
    }
    const lineas = resultado.tiendas
      .map(
        (tienda) =>
          `${tienda.nombre}, ${tienda.direccion}, ${tienda.distrito}. Horario: ${tienda.horario}. ${tienda.abierta ? 'Figura abierta.' : 'Figura cerrada.'}`,
      )
      .join(' ');
    return lineas + aviso;
  }
  if (resultado.tipo === 'presupuesto') {
    if (!resultado.alcanza) {
      return `Con S/ ${Number(resultado.presupuesto).toFixed(2)} no alcancé a armar una selección con los productos disponibles.${aviso}`;
    }
    return `Armé una lista por S/ ${Number(resultado.total).toFixed(2)} dentro de un presupuesto de S/ ${Number(resultado.presupuesto).toFixed(2)}. Quedan S/ ${Number(resultado.restante).toFixed(2)}. Es una selección variada, no una combinación matemáticamente óptima.${aviso}`;
  }
  const principales = (resultado.productos || []).filter((item) => !item.similar);
  if (principales.length === 0) {
    return `No tengo ese producto en el catálogo consultado.${aviso}`;
  }
  if (resultado.tipo === 'comparacion') {
    const primero = principales[0];
    const segundo = principales[1];
    const base = `La opción más económica de esta comparación es ${primero.nombre} a S/ ${Number(primero.precio).toFixed(2)}.`;
    const extra = segundo
      ? ` La diferencia con ${segundo.nombre} es S/ ${diferencia(primero.precio, segundo.precio)}.`
      : '';
    return `${base}${extra} El orden sale del precio registrado, no de una estimación.${aviso}`;
  }
  if (principales.length === 1) {
    const item = principales[0];
    const estado =
      item.disponible && item.stock > 0
        ? `hay ${item.stock} unidades`
        : 'figura agotado';
    return `${item.nombre} está a S/ ${Number(item.precio).toFixed(2)} y ${estado}.${aviso}`;
  }
  return `Encontré ${principales.length} productos que coinciden. El precio y el stock están en cada tarjeta.${
    (resultado.productos || []).some((item) => item.similar)
      ? ' Las tarjetas marcadas como similares son de la misma categoría, no otra coincidencia.'
      : ''
  }${aviso}`;
}

function respuestaPublica(resultado, meta) {
  const productos = (resultado.productos || []).map((item) => ({
    id: item.id,
    nombre: item.nombre,
    marca: item.marca,
    categoria: item.categoria,
    presentaciones: item.presentaciones,
    precio: item.precio,
    stock: item.stock,
    disponible: item.disponible,
    cantidad: item.cantidad || 0,
    subtotal: item.subtotal,
    similar: Boolean(item.similar),
    imagenAsset:
      typeof item.imagenAsset === 'string' &&
      item.imagenAsset.startsWith('assets/')
        ? item.imagenAsset
        : '',
  }));
  return {
    texto: redactar(resultado, meta.simulado),
    productos,
    tiendas: resultado.tiendas || [],
    cupones: resultado.cupones || [],
    presupuesto: resultado.presupuesto ?? null,
    total: resultado.total ?? null,
    restante: resultado.restante ?? null,
    consultadoEn: meta.consultadoEn,
    simulado: meta.simulado,
  };
}

function valorFirestore(campo) {
  if (!campo || typeof campo !== 'object') return undefined;
  if ('stringValue' in campo) return campo.stringValue;
  if ('doubleValue' in campo) return campo.doubleValue;
  if ('integerValue' in campo) return Number(campo.integerValue);
  if ('booleanValue' in campo) return campo.booleanValue;
  if ('arrayValue' in campo) {
    return (campo.arrayValue.values || [])
      .map(valorFirestore)
      .filter((item) => typeof item === 'string');
  }
  return undefined;
}

function documento(entrada) {
  const campos = entrada.fields || {};
  const id = String(entrada.name || '').split('/').pop();
  const datos = { id };
  for (const [clave, valor] of Object.entries(campos)) {
    if (clave.toLowerCase().includes('imagenbase64')) continue;
    datos[clave] = valorFirestore(valor);
  }
  return datos;
}

function solicitarFirestore(url, { timeoutMs }) {
  return new Promise((resolve, reject) => {
    const req = https.request(url, { method: 'GET', timeout: timeoutMs }, (respuesta) => {
      const trozos = [];
      let tamano = 0;
      respuesta.on('data', (trozo) => {
        tamano += trozo.length;
        if (tamano > 1_500_000) {
          req.destroy();
          reject(Object.assign(new Error('GRANDE'), { codigo: 'GRANDE' }));
          return;
        }
        trozos.push(trozo);
      });
      respuesta.on('end', () => {
        resolve({
          statusCode: respuesta.statusCode,
          body: Buffer.concat(trozos).toString('utf8'),
        });
      });
    });
    req.on('timeout', () => {
      req.destroy();
      reject(Object.assign(new Error('TIEMPO'), { codigo: 'TIEMPO' }));
    });
    req.on('error', () => reject(Object.assign(new Error('CONEXION'), { codigo: 'CONEXION' })));
    req.end();
  });
}

let cache = null;

function limpiarCacheComercial() {
  cache = null;
}

async function leerColeccion(config, solicitar, nombre, campos) {
  const mascara = campos
    .map((campo) => `mask.fieldPaths=${encodeURIComponent(campo)}`)
    .join('&');
  const documentos = [];
  let pagina = '';
  for (let vuelta = 0; vuelta < 3; vuelta += 1) {
    const url = new URL(
      `https://firestore.googleapis.com/v1/projects/${encodeURIComponent(config.firebaseProjectId)}/databases/(default)/documents/${nombre}`,
    );
    url.searchParams.set('key', config.firebaseWebApiKey);
    url.searchParams.set('pageSize', '200');
    if (pagina) url.searchParams.set('pageToken', pagina);
    const destino = new URL(`${url.toString()}&${mascara}`);
    const respuesta = await solicitar(destino, { timeoutMs: config.chatTimeoutMs });
    if (respuesta.statusCode === 403 || respuesta.statusCode === 401) {
      const error = new Error('PERMISO');
      error.codigo = 'PERMISO';
      throw error;
    }
    if (respuesta.statusCode !== 200) {
      const error = new Error('LECTURA');
      error.codigo = 'LECTURA';
      throw error;
    }
    const json = JSON.parse(respuesta.body);
    if (json.error) {
      const codigo = String(json.error.status || '');
      const error = new Error(codigo === 'PERMISSION_DENIED' ? 'PERMISO' : 'LECTURA');
      error.codigo = error.message;
      throw error;
    }
    for (const entrada of json.documents || []) documentos.push(documento(entrada));
    pagina = json.nextPageToken || '';
    if (!pagina) break;
  }
  return documentos;
}

function mapearProducto(datos) {
  const precio = Number(datos.precio);
  const stock = Number(datos.stock);
  if (!datos.id || !datos.nombre || !Number.isFinite(precio)) return null;
  return producto({
    id: datos.id,
    nombre: String(datos.nombre),
    marca: String(datos.marca || ''),
    categoria: String(datos.categoria || ''),
    presentaciones: Array.isArray(datos.presentaciones) ? datos.presentaciones : [],
    precio,
    stock: Number.isFinite(stock) ? stock : 0,
    disponible: datos.disponible !== false && stock > 0,
    imagenAsset: String(datos.imagenAsset || ''),
  });
}

async function leerFirestore(config, solicitar, ahora) {
  if (!config.firebaseProjectId || !config.firebaseWebApiKey) {
    const error = new Error('CONFIG');
    error.codigo = 'CONFIG';
    throw error;
  }
  const marca = `${config.firebaseProjectId}:${config.chatModo}`;
  const momento = ahora();
  if (cache && cache.marca === marca && momento - cache.momento < 60_000) {
    return { ...cache.datos, consultadoEn: new Date(cache.datosMomento).toISOString() };
  }
  const [productos, tiendas, cupones] = await Promise.all([
    leerColeccion(config, solicitar, 'productos_mass', CAMPOS_PRODUCTO),
    leerColeccion(config, solicitar, 'tiendas_mass', CAMPOS_TIENDA),
    leerColeccion(config, solicitar, 'cupones_mass', CAMPOS_CUPON),
  ]);
  const datos = {
    simulado: false,
    consultadoEn: new Date(momento).toISOString(),
    lecturas: { productos: 'ok', tiendas: 'ok', cupones: 'ok' },
    productos: productos.map(mapearProducto).filter(Boolean),
    tiendas: tiendas
      .filter((item) => item.nombre)
      .map((item) => ({
        id: item.id,
        nombre: String(item.nombre),
        ciudad: String(item.ciudad || ''),
        distrito: String(item.distrito || ''),
        direccion: String(item.direccion || ''),
        horario: String(item.horario || ''),
        abierta: item.abierta !== false,
      })),
    cupones: cupones
      .filter((item) => item.codigo)
      .map((item) => ({
        codigo: String(item.codigo).toUpperCase(),
        descripcion: String(item.descripcion || ''),
        tipo: item.tipo === 'monto' ? 'monto' : 'porcentaje',
        valor: Number(item.valor) || 0,
        montoMinimo: Number(item.montoMinimo) || 0,
        activo: item.activo !== false,
      })),
  };
  cache = { marca, momento, datosMomento: momento, datos };
  return datos;
}

module.exports = {
  catalogoFicticio,
  ejecutarHerramienta,
  respuestaPublica,
  leerFirestore,
  solicitarFirestore,
  limpiarCacheComercial,
  validarArgs,
};
