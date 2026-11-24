const https = require('https');

const BASE = 'https://dniruc.apisperu.com/api/v1';

function errorCodigo(codigo) {
  const error = new Error(codigo);
  error.codigo = codigo;
  return error;
}

function solicitarHttps(url, { timeoutMs }) {
  return new Promise((resolve, reject) => {
    const req = https.request(
      url,
      { method: 'GET', timeout: timeoutMs },
      (respuesta) => {
        const trozos = [];
        let tamano = 0;
        respuesta.on('data', (trozo) => {
          tamano += trozo.length;
          if (tamano > 16_384) {
            req.destroy();
            reject(errorCodigo('ESTRUCTURA'));
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
      },
    );
    req.on('timeout', () => {
      req.destroy();
      reject(errorCodigo('TIEMPO'));
    });
    req.on('error', () => reject(errorCodigo('CONEXION')));
    req.end();
  });
}

function textoPersona(valor) {
  if (typeof valor !== 'string') return '';
  const limpio = valor
    .replace(/[\u0000-\u001F]/g, '')
    .trim()
    .replace(/\s+/g, ' ');
  if (!limpio || limpio.length > 80) return '';
  return limpio;
}

async function consultarProveedor(dni, opciones) {
  if (!opciones.token) throw errorCodigo('TOKEN_AUSENTE');
  if (!/^\d{8}$/.test(dni)) throw errorCodigo('DNI_INVALIDO');

  const url = new URL(`${BASE}/dni/${dni}`);
  url.searchParams.set('token', opciones.token);
  const solicitar = opciones.solicitar || solicitarHttps;
  let respuesta;
  try {
    respuesta = await solicitar(url, { timeoutMs: opciones.timeoutMs });
  } catch (error) {
    if (error && error.codigo) throw error;
    throw errorCodigo('CONEXION');
  }
  if (!respuesta || respuesta.statusCode !== 200) throw errorCodigo('HTTP');

  let json;
  try {
    json = JSON.parse(respuesta.body);
  } catch {
    throw errorCodigo('ESTRUCTURA');
  }
  if (!json || typeof json !== 'object' || Array.isArray(json)) {
    throw errorCodigo('ESTRUCTURA');
  }
  if (json.success === false) throw errorCodigo('NO_ENCONTRADO');

  const nombres = textoPersona(json.nombres);
  const apellidoPaterno = textoPersona(json.apellidoPaterno);
  const apellidoMaterno = textoPersona(json.apellidoMaterno);
  if (!nombres || !apellidoPaterno || !apellidoMaterno) {
    throw errorCodigo('ESTRUCTURA');
  }
  return { nombres, apellidoPaterno, apellidoMaterno, simulado: false };
}

module.exports = { consultarProveedor, solicitarHttps };
