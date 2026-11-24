const http = require('http');
const path = require('path');

const { cargarArchivoEntorno, leerConfiguracion } = require('./config');
const { crearLimitador } = require('./seguridad/limiteConsultas');
const { crearLimitadorChat } = require('./seguridad/limiteChat');
const { enviar } = require('./http');
const { esSalud } = require('./rutas/salud');
const { esRutaDni, responderDni } = require('./rutas/dni');
const { esRutaChat, responderChat } = require('./rutas/chat');

function crearAplicacion(opciones) {
  const config = opciones.config;
  const limitador =
    opciones.limitador ||
    crearLimitador({
      maxPorVentana: config.maxPorVentana,
      ventanaMs: config.ventanaMs,
      repeticionMs: config.repeticionMs,
      maxConcurrentes: config.maxConcurrentes,
    });
  const limitadorChat =
    opciones.limitadorChat ||
    crearLimitadorChat({
      maxPorVentana: config.chatMaxPorVentana,
      ventanaMs: config.chatVentanaMs,
      maxConcurrentes: config.chatMaxConcurrentes,
    });
  const contexto = {
    config,
    limitador,
    limitadorChat,
    solicitar: opciones.solicitar,
    solicitarGemini: opciones.solicitarGemini,
    solicitarFirestore: opciones.solicitarFirestore,
    interpretar: opciones.interpretar,
    leerDatos: opciones.leerDatos,
    ahora: opciones.ahora,
  };

  return function manejar(req, res) {
    const chat = esRutaChat(req);
    req.setTimeout(chat ? config.chatTimeoutMs || 20_000 : 10_000, () => {
      enviar(res, 408, {
        error: chat
          ? 'MassBot no respondió a tiempo.'
          : 'El servicio de consulta no está disponible.',
      });
      req.destroy();
    });

    if (esSalud(req)) {
      enviar(res, 200, { ok: true });
      return;
    }
    if (esRutaDni(req)) {
      responderDni(req, res, contexto).catch(() => {
        enviar(res, 500, { error: 'El servicio de consulta no está disponible.' });
      });
      return;
    }
    if (chat) {
      responderChat(req, res, contexto).catch(() => {
        enviar(res, 502, { error: 'MassBot no está disponible.' });
      });
      return;
    }
    enviar(res, 404, { error: 'No encontrado.' });
  };
}

function iniciarServidor(opciones) {
  const config = opciones.config;
  const servidor = http.createServer(crearAplicacion(opciones));
  return new Promise((resolve, reject) => {
    servidor.once('error', reject);
    servidor.listen(config.puerto, config.host, () => resolve(servidor));
  });
}

async function main() {
  cargarArchivoEntorno(path.join(__dirname, '..', '.env'));
  const config = leerConfiguracion();
  const servidor = await iniciarServidor({ config });
  const direccion = servidor.address();
  process.stdout.write(
    `TiendasMass backend escuchando en http://${direccion.address}:${direccion.port} (dni ${config.modo}, chat ${config.chatModo})\n`,
  );
}

if (require.main === module) {
  main().catch((error) => {
    process.stderr.write(`${error.message}\n`);
    process.exit(1);
  });
}

module.exports = { crearAplicacion, iniciarServidor };
