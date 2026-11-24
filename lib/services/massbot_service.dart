import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/respuesta_massbot.dart';

class MassBotException implements Exception {
  final String mensaje;

  const MassBotException(this.mensaje);

  @override
  String toString() => mensaje;
}

class MassBotServicio {
  final http.Client _cliente;
  final bool _cerrarCliente;
  final String urlBase;
  final Duration tiempoLimite;
  final Future<RespuestaMassBot> Function(
    String mensaje,
    List<TurnoMassBot> historial,
  )?
  enviarDirecto;

  MassBotServicio({
    http.Client? cliente,
    String? urlBase,
    this.tiempoLimite = const Duration(seconds: 25),
    this.enviarDirecto,
  }) : _cliente = cliente ?? http.Client(),
       _cerrarCliente = cliente == null,
       urlBase = _normalizar(urlBase ?? urlBasePredeterminada);

  static const String urlBasePredeterminada = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static String _normalizar(String valor) {
    return valor.endsWith('/') ? valor.substring(0, valor.length - 1) : valor;
  }

  void close() {
    if (_cerrarCliente) _cliente.close();
  }

  Future<RespuestaMassBot> consultar({
    required String mensaje,
    required List<TurnoMassBot> historial,
  }) async {
    if (enviarDirecto != null) return enviarDirecto!(mensaje, historial);
    final uri = Uri.parse('$urlBase/api/chat');
    http.Response respuesta;
    try {
      respuesta = await _cliente
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'mensaje': mensaje,
              'historial': historial.map((turno) => turno.toJson()).toList(),
            }),
          )
          .timeout(tiempoLimite);
    } catch (_) {
      throw const MassBotException('MassBot no está disponible.');
    }

    Map<String, dynamic>? json;
    try {
      final decodificado = jsonDecode(respuesta.body);
      if (decodificado is Map) {
        json = decodificado.map(
          (clave, valor) => MapEntry(clave.toString(), valor),
        );
      }
    } catch (_) {
      json = null;
    }
    if (respuesta.statusCode != 200 ||
        json == null ||
        json['texto'] is! String) {
      throw MassBotException(
        (json?['error'] ?? 'MassBot no está disponible.').toString(),
      );
    }
    return RespuestaMassBot.fromJson(json);
  }
}
