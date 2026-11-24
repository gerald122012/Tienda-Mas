const { rutaDe, enviar, leerCuerpo } = require('../http');
const { interpretarLocal } = require('../servicios/modoSimuladoChat');
const { interpretarConGemini } = require('../servicios/proveedorGemini');
const {
  catalogoFicticio,
  ejecutarHerramienta,
  respuestaPublica,
  leerFirestore,
  solicitarFirestore,
} = require('../servicios/catalogoComercial');

const MAX_MENSAJE = 500;
const MAX_HISTORIAL = 6;
const CORREO = /[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}/i;
const DNI = /\b\d{8}\b/;
const SECRETO = /contraseñ|password|clave de gemini|api[_ ]?key/i;

function esRutaChat(req) {
  return rutaDe(req) === '/api/chat';
}

function contienePersonal(texto) {
  return CORREO.test(texto) || DNI.test(texto) || SECRETO.test(texto);
}

function validarEntrada(json) {
  if (!json || typeof json !== 'object' || Array.isArray(json)) return null;
  const claves = Object.keys(json);
  if (claves.some((clave) => clave !== 'mensaje' && clave !== 'historial')) return null;
  if (typeof json.mensaje !== 'string') return null;
  const mensaje = json.mensaje.trim();
  if (!mensaje || mensaje.length > MAX_MENSAJE) return null;
  const historial = json.historial === undefined ? [] : json.historial;
  if (!Array.isArray(historial) || historial.length > MAX_HISTORIAL) return null;
  const limpio = [];
  for (const turno of historial) {
    if (!turno || typeof turno !== 'object' || Array.isArray(turno)) return null;
    const campos = Object.keys(turno);
    if (campos.some((campo) => campo !== 'rol' && campo !== 'texto')) return null;
    if (turno.rol !== 'usuario' && turno.rol !== 'asistente') return null;
    if (typeof turno.texto !== 'string' || turno.texto.trim().length > MAX_MENSAJE) {
      return null;
    }
    limpio.push({ rol: turno.rol, texto: turno.texto.trim() });
  }
  return { mensaje, historial: limpio };
}

async function atenderChat(entrada, contexto) {
  const config = contexto.config;
  const simulado = config.chatModo === 'mock';
  if (!simulado && (!config.geminiApiKey || !config.geminiModelo)) {
    const error = new Error('CONFIG');
    error.codigo = 'CONFIG';
    throw error;
  }
  const interpretar = contexto.interpretar
    ? contexto.interpretar
    : simulado
      ? async (mensaje) => interpretarLocal(mensaje)
      : async (mensaje, historial) =>
          interpretarConGemini(mensaje, historial, {
            apiKey: config.geminiApiKey,
            modelo: config.geminiModelo,
            timeoutMs: config.chatTimeoutMs,
            solicitar: contexto.solicitarGemini,
          });
  const leer = contexto.leerDatos
    ? contexto.leerDatos
    : simulado
      ? async () => catalogoFicticio(new Date().toISOString())
      : async () =>
          leerFirestore(
            config,
            contexto.solicitarFirestore || solicitarFirestore,
            contexto.ahora || Date.now,
          );
  const decision = await interpretar(entrada.mensaje, entrada.historial);
  const datos = await leer();
  if (datos && datos.lecturas && datos.lecturas.productos === 'denegada') {
    const error = new Error('PERMISO');
    error.codigo = 'PERMISO';
    throw error;
  }
  const ejecutado = ejecutarHerramienta(
    decision && decision.herramienta,
    decision && decision.argumentos,
    datos,
  );
  if (ejecutado.tipo === 'permiso' && ejecutado.recurso === 'productos') {
    const error = new Error('PERMISO');
    error.codigo = 'PERMISO';
    throw error;
  }
  return respuestaPublica(ejecutado, {
    simulado: Boolean(datos.simulado),
    consultadoEn: datos.consultadoEn,
  });
}

function estadoDe(error) {
  const codigo = error && error.codigo;
  if (codigo === 'CONFIG' || codigo === 'PERMISO') return 503;
  if (codigo === 'CUOTA') return 429;
  if (codigo === 'TIEMPO') return 504;
  return 502;
}

async function responderChat(req, res, contexto) {
  if (req.method !== 'POST') {
    enviar(res, 405, { error: 'Método no permitido.' });
    return;
  }
  const tipo = String(req.headers['content-type'] || '');
  if (!tipo.toLowerCase().startsWith('application/json')) {
    enviar(res, 415, { error: 'Solicitud no válida.' });
    return;
  }
  let crudo;
  try {
    crudo = await leerCuerpo(req, contexto.config.chatMaxCuerpo);
  } catch (error) {
    enviar(res, error && error.codigo === 'GRANDE' ? 413 : 400, {
      error: 'Solicitud no válida.',
    });
    req.destroy();
    return;
  }
  let json;
  try {
    json = JSON.parse(crudo || '');
  } catch {
    enviar(res, 400, { error: 'Solicitud no válida.' });
    return;
  }
  const entrada = validarEntrada(json);
  if (!entrada) {
    enviar(res, 400, { error: 'Solicitud no válida.' });
    return;
  }
  if (
    contienePersonal(entrada.mensaje) ||
    entrada.historial.some((turno) => contienePersonal(turno.texto))
  ) {
    enviar(res, 400, {
      error: 'No envíes DNI, correos ni contraseñas por el chat.',
    });
    return;
  }

  const permiso = contexto.limitadorChat.evaluar(req.socket.remoteAddress || 'local');
  if (!permiso.ok) {
    enviar(res, 429, { error: 'Demasiadas consultas. Intenta más tarde.' });
    return;
  }
  try {
    const respuesta = await atenderChat(entrada, contexto);
    enviar(res, 200, respuesta);
  } catch (error) {
    const estado = estadoDe(error);
    const mensaje =
      estado === 503
        ? 'MassBot no pudo consultar la información comercial.'
        : estado === 429
          ? 'MassBot está recibiendo muchas consultas. Intenta más tarde.'
          : estado === 504
            ? 'MassBot no respondió a tiempo.'
            : 'MassBot no está disponible.';
    enviar(res, estado, { error: mensaje });
  } finally {
    permiso.liberar();
  }
}

module.exports = { esRutaChat, responderChat, atenderChat, validarEntrada };
