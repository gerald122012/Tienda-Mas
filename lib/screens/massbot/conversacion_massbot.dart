import 'package:flutter/foundation.dart';

import '../../models/respuesta_massbot.dart';
import '../../services/massbot_service.dart';

class EntradaMassBot {
  final bool usuario;
  final String texto;
  final RespuestaMassBot? respuesta;

  const EntradaMassBot.usuario(this.texto) : usuario = true, respuesta = null;

  const EntradaMassBot.asistente(this.respuesta) : usuario = false, texto = '';
}

/// Historial de la sesión. Vive fuera de la ventana para sobrevivir al minimizar.
class ConversacionMassBot extends ChangeNotifier {
  ConversacionMassBot({MassBotServicio? servicio})
    : _servicio = servicio ?? MassBotServicio(),
      _servicioPropio = servicio == null;

  static final ConversacionMassBot instancia = ConversacionMassBot();

  final MassBotServicio _servicio;
  final bool _servicioPropio;
  final List<EntradaMassBot> entradas = [];

  var ocupado = false;
  var abierta = false;
  var invitacionConsumida = false;
  String? error;
  String? ultimaConsulta;
  double desplazamiento = 0;
  String? _cuenta;
  var _ciclo = 0;

  bool get enDemostracion =>
      entradas.any((entrada) => entrada.respuesta?.simulado == true);

  bool get tieneMensajes => entradas.isNotEmpty;

  void marcarAbierta(bool valor) {
    if (abierta == valor) return;
    abierta = valor;
    notifyListeners();
  }

  void consumirInvitacion() {
    if (invitacionConsumida) return;
    invitacionConsumida = true;
    notifyListeners();
  }

  void guardarDesplazamiento(double pixels) {
    desplazamiento = pixels < 0 ? 0 : pixels;
  }

  /// La primera cuenta observada no borra nada. Un cambio de cuenta o un
  /// cierre de sesión sí vacía el historial de esta sesión.
  void vincular(String? cuenta) {
    final clave = (cuenta ?? '').trim().toLowerCase();
    if (_cuenta == null) {
      _cuenta = clave;
      return;
    }
    if (_cuenta == clave) return;
    _cuenta = clave;
    _vaciar();
  }

  Future<void> enviar([String? texto]) async {
    final mensaje = (texto ?? '').trim();
    if (ocupado || mensaje.isEmpty) return;
    final ciclo = ++_ciclo;
    ocupado = true;
    error = null;
    ultimaConsulta = mensaje;
    entradas.add(EntradaMassBot.usuario(mensaje));
    notifyListeners();

    final historial = entradas
        .where((entrada) => entrada.usuario || entrada.respuesta != null)
        .map(
          (entrada) => TurnoMassBot(
            rol: entrada.usuario ? 'usuario' : 'asistente',
            texto: entrada.usuario ? entrada.texto : entrada.respuesta!.texto,
          ),
        )
        .toList();
    if (historial.isNotEmpty && historial.last.texto == mensaje) {
      historial.removeLast();
    }
    final recientes = historial.length > 6
        ? historial.sublist(historial.length - 6)
        : historial;

    try {
      final respuesta = await _servicio.consultar(
        mensaje: mensaje,
        historial: recientes,
      );
      if (ciclo != _ciclo) return;
      ocupado = false;
      entradas.add(EntradaMassBot.asistente(respuesta));
    } on MassBotException catch (fallo) {
      if (ciclo != _ciclo) return;
      ocupado = false;
      error = fallo.mensaje;
    } catch (_) {
      if (ciclo != _ciclo) return;
      ocupado = false;
      error = 'MassBot no está disponible.';
    }
    notifyListeners();
  }

  void reintentar() {
    final consulta = ultimaConsulta;
    if (consulta == null) return;
    enviar(consulta);
  }

  void nueva() {
    if (ocupado) return;
    _ciclo++;
    _vaciar();
  }

  void _vaciar() {
    entradas.clear();
    error = null;
    ultimaConsulta = null;
    desplazamiento = 0;
    ocupado = false;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_servicioPropio) _servicio.close();
    super.dispose();
  }
}
