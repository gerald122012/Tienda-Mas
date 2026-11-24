const assert = require('node:assert/strict');
const { describe, it } = require('node:test');

const { dniValido } = require('../src/validacion/dni');
const { leerConfiguracion } = require('../src/config');
const { consultarDni } = require('../src/servicios/consultaDni');
const { consultarProveedor } = require('../src/servicios/proveedorApisPeru');

const persona = {
  dni: '00000001',
  nombres: 'ANA',
  apellidoPaterno: 'QUISPE',
  apellidoMaterno: 'GARCIA',
  codVerifica: '9',
};

function solicitarOk(body, statusCode = 200) {
  return async (url) => {
    assert.equal(url.pathname, '/api/v1/dni/00000001');
    assert.equal(url.searchParams.get('token'), 'token-de-prueba');
    return { statusCode, body: JSON.stringify(body) };
  };
}

describe('validación de DNI', () => {
  it('acepta ocho dígitos y conserva ceros iniciales', () => {
    assert.equal(dniValido('00000001'), true);
    assert.equal(dniValido('12345678'), true);
  });

  it('rechaza texto, números JSON, incompletos y valores de más', () => {
    assert.equal(dniValido('1234567A'), false);
    assert.equal(dniValido('1234'), false);
    assert.equal(dniValido('123456789'), false);
    assert.equal(dniValido(12345678), false);
    assert.equal(dniValido(''), false);
    assert.equal(dniValido(null), false);
  });
});

describe('configuración', () => {
  it('usa modo simulado y localhost cuando no hay variables', () => {
    const config = leerConfiguracion({});
    assert.equal(config.modo, 'mock');
    assert.equal(config.host, '127.0.0.1');
    assert.equal(config.puerto, 3000);
    assert.equal(config.token, '');
  });

  it('rechaza escuchar fuera de localhost', () => {
    assert.throws(() => leerConfiguracion({ HOST: '0.0.0.0' }), /127\.0\.0\.1/);
  });
});

describe('modo simulado', () => {
  it('devuelve datos ficticios sin llamar al proveedor', async () => {
    let llamadas = 0;
    const resultado = await consultarDni('00000001', {
      modo: 'mock',
      solicitar: async () => {
        llamadas += 1;
      },
    });
    assert.equal(llamadas, 0);
    assert.deepEqual(resultado.cuerpo, {
      nombres: 'ANA',
      apellidoPaterno: 'QUISPE',
      apellidoMaterno: 'GARCIA',
      simulado: true,
    });
    assert.equal('codVerifica' in resultado.cuerpo, false);
  });

  it('informa que el DNI ficticio reservado no existe', async () => {
    const resultado = await consultarDni('00000000', { modo: 'mock' });
    assert.equal(resultado.estado, 404);
    assert.equal(resultado.cuerpo.nombres, undefined);
  });

  it('no reemplaza un fallo real con datos ficticios', async () => {
    const resultado = await consultarDni('00000001', {
      modo: 'live',
      token: 'token-de-prueba',
      timeoutMs: 50,
      solicitar: async () => {
        throw Object.assign(new Error('CONEXION'), { codigo: 'CONEXION' });
      },
    });
    assert.equal(resultado.estado, 502);
    assert.equal(resultado.cuerpo.simulado, undefined);
    assert.equal(resultado.cuerpo.nombres, undefined);
  });
});

describe('proveedor API Perú', () => {
  it('interpreta una respuesta válida y omite codVerifica', async () => {
    const datos = await consultarProveedor('00000001', {
      token: 'token-de-prueba',
      timeoutMs: 1000,
      solicitar: solicitarOk(persona),
    });
    assert.deepEqual(datos, {
      nombres: 'ANA',
      apellidoPaterno: 'QUISPE',
      apellidoMaterno: 'GARCIA',
      simulado: false,
    });
  });

  it('reconoce un error del proveedor aunque el HTTP sea 200', async () => {
    await assert.rejects(
      () =>
        consultarProveedor('00000001', {
          token: 'token-de-prueba',
          timeoutMs: 1000,
          solicitar: solicitarOk({ success: false, message: 'No existe' }),
        }),
      (error) => error.codigo === 'NO_ENCONTRADO',
    );
  });

  it('rechaza una estructura incorrecta', async () => {
    await assert.rejects(
      () =>
        consultarProveedor('00000001', {
          token: 'token-de-prueba',
          timeoutMs: 1000,
          solicitar: solicitarOk({ nombres: 'ANA' }),
        }),
      (error) => error.codigo === 'ESTRUCTURA',
    );
  });

  it('distingue un error HTTP', async () => {
    await assert.rejects(
      () =>
        consultarProveedor('00000001', {
          token: 'token-de-prueba',
          timeoutMs: 1000,
          solicitar: solicitarOk(persona, 500),
        }),
      (error) => error.codigo === 'HTTP',
    );
  });

  it('distingue el tiempo de espera agotado', async () => {
    await assert.rejects(
      () =>
        consultarProveedor('00000001', {
          token: 'token-de-prueba',
          timeoutMs: 1000,
          solicitar: async () => {
            throw Object.assign(new Error('TIEMPO'), { codigo: 'TIEMPO' });
          },
        }),
      (error) => error.codigo === 'TIEMPO',
    );
  });

  it('no llama al proveedor si el token real está ausente', async () => {
    let llamadas = 0;
    const resultado = await consultarDni('00000001', {
      modo: 'live',
      token: '',
      solicitar: async () => {
        llamadas += 1;
      },
    });
    assert.equal(llamadas, 0);
    assert.equal(resultado.estado, 503);
    assert.match(resultado.cuerpo.error, /no está configurada/);
  });
});
