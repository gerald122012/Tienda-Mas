const crypto = require('crypto');

function crearLimitador({
  maxPorVentana,
  ventanaMs,
  repeticionMs,
  maxConcurrentes,
  ahora = () => Date.now(),
}) {
  const ventanas = new Map();
  const exitosas = new Map();
  let activas = 0;

  function evaluar(ip, dni) {
    const ahoraMs = ahora();
    const vigentes = (ventanas.get(ip) || []).filter(
      (marca) => ahoraMs - marca < ventanaMs,
    );
    if (vigentes.length >= maxPorVentana) {
      ventanas.set(ip, vigentes);
      return { ok: false };
    }
    const clave = crypto
      .createHash('sha256')
      .update(`${ip}\n${dni}`)
      .digest('hex');
    const previa = exitosas.get(clave);
    if (previa && ahoraMs - previa < repeticionMs) return { ok: false };
    if (activas >= maxConcurrentes) return { ok: false };

    vigentes.push(ahoraMs);
    ventanas.set(ip, vigentes);
    activas += 1;
    let liberada = false;
    return {
      ok: true,
      liberar() {
        if (liberada) return;
        liberada = true;
        activas -= 1;
      },
      marcarExitosa() {
        exitosas.set(clave, ahora());
      },
    };
  }

  return { evaluar };
}

module.exports = { crearLimitador };
