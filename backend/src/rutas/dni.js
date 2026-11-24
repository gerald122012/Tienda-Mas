const { rutaDe, enviar, leerCuerpo } = require('../http');
const { consultarDni } = require('../servicios/consultaDni');
const { dniValido } = require('../validacion/dni');

function esRutaDni(req) {
  return rutaDe(req) === '/api/dni/consultar';
}

async function responderDni(req, res, contexto) {
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
    crudo = await leerCuerpo(req, contexto.config.maxCuerpo);
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
  if (!json || typeof json !== 'object' || Array.isArray(json)) {
    enviar(res, 400, { error: 'Solicitud no válida.' });
    return;
  }
  const claves = Object.keys(json);
  if (claves.length !== 1 || claves[0] !== 'dni' || !dniValido(json.dni)) {
    enviar(res, 400, {
      error: dniValido(json.dni)
        ? 'Solicitud no válida.'
        : 'El DNI debe tener 8 dígitos.',
    });
    return;
  }

  const permiso = contexto.limitador.evaluar(
    req.socket.remoteAddress || 'local',
    json.dni,
  );
  if (!permiso.ok) {
    enviar(res, 429, { error: 'Demasiadas consultas. Intenta más tarde.' });
    return;
  }

  try {
    const resultado = await consultarDni(json.dni, {
      modo: contexto.config.modo,
      token: contexto.config.token,
      timeoutMs: contexto.config.timeoutMs,
      solicitar: contexto.solicitar,
    });
    if (resultado.estado === 200) permiso.marcarExitosa();
    enviar(res, resultado.estado, resultado.cuerpo);
  } finally {
    permiso.liberar();
  }
}

module.exports = { esRutaDni, responderDni };
