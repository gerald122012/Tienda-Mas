function crearLimitadorChat({
  maxPorVentana,
  ventanaMs,
  maxConcurrentes,
  ahora = () => Date.now(),
}) {
  const ventanas = new Map();
  let activas = 0;

  function evaluar(ip) {
    const ahoraMs = ahora();
    const clave = String(ip || 'local');
    const vigentes = (ventanas.get(clave) || []).filter(
      (marca) => ahoraMs - marca < ventanaMs,
    );
    if (vigentes.length >= maxPorVentana || activas >= maxConcurrentes) {
      ventanas.set(clave, vigentes);
      return { ok: false };
    }
    vigentes.push(ahoraMs);
    ventanas.set(clave, vigentes);
    activas += 1;
    let liberada = false;
    return {
      ok: true,
      liberar() {
        if (liberada) return;
        liberada = true;
        activas -= 1;
      },
    };
  }

  return { evaluar };
}

module.exports = { crearLimitadorChat };
