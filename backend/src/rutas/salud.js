const { rutaDe } = require('../http');

function esSalud(req) {
  return req.method === 'GET' && rutaDe(req) === '/api/health';
}

module.exports = { esSalud };
