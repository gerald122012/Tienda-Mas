const fs = require('fs');

function cargarArchivoEntorno(ruta) {
  if (!fs.existsSync(ruta)) return;
  const texto = fs.readFileSync(ruta, 'utf8');
  for (const linea of texto.split(/\r?\n/)) {
    const limpia = linea.trim();
    if (!limpia || limpia.startsWith('#')) continue;
    const separador = limpia.indexOf('=');
    if (separador <= 0) continue;
    const clave = limpia.slice(0, separador).trim();
    let valor = limpia.slice(separador + 1).trim();
    if (
      (valor.startsWith('"') && valor.endsWith('"')) ||
      (valor.startsWith("'") && valor.endsWith("'"))
    ) {
      valor = valor.slice(1, -1);
    }
    if (process.env[clave] === undefined) process.env[clave] = valor;
  }
}

function leerConfiguracion(env = process.env) {
  const modo = String(env.DNI_MODE || 'mock').trim().toLowerCase();
  if (modo !== 'mock' && modo !== 'live') {
    throw new Error('DNI_MODE debe ser mock o live');
  }
  const host = String(env.HOST || '127.0.0.1').trim();
  if (host !== '127.0.0.1') {
    throw new Error('El servidor local solo puede escuchar en 127.0.0.1');
  }
  const puerto = env.PORT === undefined ? 3000 : Number(env.PORT);
  if (!Number.isInteger(puerto) || puerto < 1 || puerto > 65535) {
    throw new Error('PORT no es válido');
  }
  const chatModo = String(env.CHAT_MODE || 'mock').trim().toLowerCase();
  if (chatModo !== 'mock' && chatModo !== 'live') {
    throw new Error('CHAT_MODE debe ser mock o live');
  }
  const geminiModelo = String(
    env.GEMINI_MODEL || 'gemini-3.5-flash-lite',
  ).trim();
  if (!/^gemini-[a-z0-9.\-]{3,80}$/i.test(geminiModelo)) {
    throw new Error('GEMINI_MODEL no es válido');
  }
  return {
    modo,
    host,
    puerto,
    token: String(env.APISPERU_TOKEN || '').trim(),
    timeoutMs: 8000,
    maxCuerpo: 1024,
    maxConcurrentes: 2,
    maxPorVentana: 8,
    ventanaMs: 60_000,
    repeticionMs: 15_000,
    chatModo,
    geminiApiKey: String(env.GEMINI_API_KEY || '').trim(),
    geminiModelo,
    firebaseProjectId: String(env.FIREBASE_PROJECT_ID || '').trim(),
    firebaseWebApiKey: String(env.FIREBASE_WEB_API_KEY || '').trim(),
    chatTimeoutMs: 20_000,
    chatMaxCuerpo: 8192,
    chatMaxPorVentana: 8,
    chatVentanaMs: 60_000,
    chatMaxConcurrentes: 1,
  };
}

module.exports = { cargarArchivoEntorno, leerConfiguracion };
