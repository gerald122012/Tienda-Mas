function rutaDe(req) {
  return (req.url || '').split('?')[0];
}

function enviar(res, estado, cuerpo) {
  if (res.writableEnded || res.headersSent) return;
  const json = JSON.stringify(cuerpo);
  res.writeHead(estado, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(json),
    'Cache-Control': 'no-store',
    'X-Content-Type-Options': 'nosniff',
  });
  res.end(json);
}

function leerCuerpo(req, maximo) {
  return new Promise((resolve, reject) => {
    const trozos = [];
    let total = 0;
    let cerrado = false;
    const fallar = (error) => {
      if (cerrado) return;
      cerrado = true;
      reject(error);
    };
    req.on('data', (trozo) => {
      if (cerrado) return;
      total += trozo.length;
      if (total > maximo) {
        const error = new Error('GRANDE');
        error.codigo = 'GRANDE';
        fallar(error);
        return;
      }
      trozos.push(trozo);
    });
    req.on('end', () => {
      if (cerrado) return;
      cerrado = true;
      resolve(Buffer.concat(trozos).toString('utf8'));
    });
    req.on('error', () => fallar(new Error('LECTURA')));
  });
}

module.exports = { rutaDe, enviar, leerCuerpo };
