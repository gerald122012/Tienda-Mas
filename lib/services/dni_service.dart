import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/dni_resultado.dart';

class DniConsultaException implements Exception {
  final String mensaje;

  const DniConsultaException(this.mensaje);

  @override
  String toString() => mensaje;
}

class DniService {
  final http.Client _cliente;
  final bool _cerrarCliente;
  final String urlBase;
  final Duration tiempoLimite;

  DniService({
    http.Client? cliente,
    String? urlBase,
    this.tiempoLimite = const Duration(seconds: 6),
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

  Future<DniResultado> consultar(String dni) async {
    final limpio = dni.trim();
    if (!RegExp(r'^\d{8}$').hasMatch(limpio)) {
      throw const DniConsultaException('El DNI debe tener 8 dígitos.');
    }
    final uri = Uri.parse('$urlBase/api/dni/consultar');
    if (uri.host == 'dniruc.apisperu.com') {
      throw const DniConsultaException(
        'El servicio de consulta no está disponible.',
      );
    }

    http.Response respuesta;
    try {
      respuesta = await _cliente
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'dni': limpio}),
          )
          .timeout(tiempoLimite);
    } catch (error) {
      if (error is DniConsultaException) rethrow;
      throw const DniConsultaException(
        'El servicio de consulta no está disponible.',
      );
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

    if (respuesta.statusCode == 200 && json != null) {
      final nombres = (json['nombres'] ?? '').toString().trim();
      final paterno = (json['apellidoPaterno'] ?? '').toString().trim();
      final materno = (json['apellidoMaterno'] ?? '').toString().trim();
      if (nombres.isEmpty || paterno.isEmpty || materno.isEmpty) {
        throw const DniConsultaException(
          'El servicio de consulta no está disponible.',
        );
      }
      return DniResultado(
        nombres: nombres,
        apellidoPaterno: paterno,
        apellidoMaterno: materno,
        simulado: json['simulado'] == true,
      );
    }

    const mensajesSeguros = {
      'El DNI debe tener 8 dígitos.',
      'No se encontró información para ese DNI.',
      'La consulta real no está configurada.',
      'El servicio de consulta no está disponible.',
      'Demasiadas consultas. Intenta más tarde.',
    };
    final mensaje = (json?['error'] ?? '').toString().trim();
    throw DniConsultaException(
      mensajesSeguros.contains(mensaje)
          ? mensaje
          : 'El servicio de consulta no está disponible.',
    );
  }
}
