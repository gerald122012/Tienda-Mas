const assert = require('node:assert/strict');
const http = require('node:http');
const { describe, it, afterEach } = require('node:test');

const { crearAplicacion } = require('../src/server');
const { leerConfiguracion } = require('../src/config');
const { crearLimitador } = require('../src/seguridad/limiteConsultas');

const servidores = [];

function configMock(extra = {}) {
  return {
    ...leerConfiguracion({ DNI_MODE: 'mock' }),
    ...extra,
  };
}

async function levantar(opciones) {
  const servidor = http.createServer(crearAplicacion(opciones));
  servidores.push(servidor);
  await new Promise((resolve) => servidor.listen(0, '127.0.0.1', resolve));
  const { port } = servidor.address();
  return port;
}

function pedir(puerto, ruta, opciones = {}) {
  const cuerpo = opciones.cuerpo;
  return new Promise((resolve, reject) => {
    const req = http.request(
      {
        host: '127.0.0.1',
        port: puerto,
        path: ruta,
        method: opciones.metodo || 'GET',
        headers: cuerpo
          ? {
              'Content-Type': opciones.tipo || 'application/json',
              'Content-Length': Buffer.byteLength(cuerpo),
            }
          : undefined,
      },
      (res) => {
        const trozos = [];
        res.on('data', (trozo) => trozos.push(trozo));
        res.on('end', () => {
          const texto = Buffer.concat(trozos).toString('utf8');
          resolve({
            estado: res.statusCode,
            texto,
            json: texto ? JSON.parse(texto) : null,
          });
        });
      },
    );
    req.on('error', reject);
    if (cuerpo) req.write(cuerpo);
    req.end();
  });
}

afterEach(async () => {
  await Promise.all(
    servidores.splice(0).map(
      (servidor) =>
        new Promise((resolve) => servidor.close(() => resolve())),
    ),
  );
});

describe('servidor local', () => {
  it('el estado de salud no revela configuración ni secretos', async () => {
    const puerto = await levantar({
      config: configMock({ modo: 'live', token: 'token-de-prueba' }),
    });
    const respuesta = await pedir(puerto, '/api/health');
    assert.equal(respuesta.estado, 200);
    assert.deepEqual(respuesta.json, { ok: true });
    assert.equal(respuesta.texto.includes('token-de-prueba'), false);
    assert.equal(respuesta.texto.includes('live'), false);
  });

  it('consulta un DNI simulado de ocho dígitos con ceros iniciales', async () => {
    const puerto = await levantar({ config: configMock() });
    const respuesta = await pedir(puerto, '/api/dni/consultar', {
      metodo: 'POST',
      cuerpo: JSON.stringify({ dni: '00000001' }),
    });
    assert.equal(respuesta.estado, 200);
    assert.equal(respuesta.json.simulado, true);
    assert.equal(respuesta.json.nombres, 'ANA');
    assert.equal(respuesta.json.apellidoMaterno, 'GARCIA');
    assert.equal('codVerifica' in respuesta.json, false);
  });

  it('rechaza caracteres inválidos, DNI incompleto y tipos que no son texto', async () => {
    const puerto = await levantar({ config: configMock() });
    for (const dni of ['1234567A', '1234', 12345678]) {
      const respuesta = await pedir(puerto, '/api/dni/consultar', {
        metodo: 'POST',
        cuerpo: JSON.stringify({ dni }),
      });
      assert.equal(respuesta.estado, 400);
      assert.match(respuesta.json.error, /8 dígitos/);
    }
  });

  it('bloquea una consulta repetida del mismo DNI', async () => {
    const puerto = await levantar({ config: configMock() });
    const cuerpo = JSON.stringify({ dni: '12345678' });
    const primera = await pedir(puerto, '/api/dni/consultar', {
      metodo: 'POST',
      cuerpo,
    });
    const segunda = await pedir(puerto, '/api/dni/consultar', {
      metodo: 'POST',
      cuerpo,
    });
    assert.equal(primera.estado, 200);
    assert.equal(segunda.estado, 429);
  });

  it('limita las solicitudes simultáneas', async () => {
    let liberar;
    const pendiente = new Promise((resolve) => {
      liberar = resolve;
    });
    const config = configMock({
      modo: 'live',
      token: 'token-de-prueba',
      maxConcurrentes: 1,
    });
    const puerto = await levantar({
      config,
      limitador: crearLimitador(config),
      solicitar: () => pendiente,
    });
    const primera = pedir(puerto, '/api/dni/consultar', {
      metodo: 'POST',
      cuerpo: JSON.stringify({ dni: '12345678' }),
    });
    await new Promise((resolve) => setTimeout(resolve, 30));
    const segunda = await pedir(puerto, '/api/dni/consultar', {
      metodo: 'POST',
      cuerpo: JSON.stringify({ dni: '87654321' }),
    });
    assert.equal(segunda.estado, 429);
    liberar({
      statusCode: 200,
      body: JSON.stringify({
        nombres: 'ANA',
        apellidoPaterno: 'QUISPE',
        apellidoMaterno: 'GARCIA',
      }),
    });
    const terminada = await primera;
    assert.equal(terminada.estado, 200);
    assert.equal(terminada.json.simulado, false);
  });

  it('rechaza un cuerpo demasiado grande', async () => {
    const puerto = await levantar({ config: configMock({ maxCuerpo: 32 }) });
    const respuesta = await pedir(puerto, '/api/dni/consultar', {
      metodo: 'POST',
      cuerpo: JSON.stringify({ dni: '12345678', relleno: 'x'.repeat(80) }),
    });
    assert.equal(respuesta.estado, 413);
    assert.equal(respuesta.texto.includes('12345678'), false);
  });
});
