import 'package:flutter/material.dart';

import '../../services/massbot_service.dart';
import 'conversacion_massbot.dart';
import 'widgets/bienvenida_massbot.dart';
import 'widgets/burbuja_massbot.dart';
import 'widgets/compositor_massbot.dart';
import 'widgets/encabezado_massbot.dart';
import 'widgets/tema_massbot.dart';

class MassBotScreen extends StatefulWidget {
  final MassBotServicio? servicio;
  final ConversacionMassBot? conversacion;
  final ScrollController? desplazamiento;
  final VoidCallback? alVerCatalogo;
  final VoidCallback? alMinimizar;
  final VoidCallback? alCerrar;
  final bool embebido;

  const MassBotScreen({
    super.key,
    this.servicio,
    this.conversacion,
    this.desplazamiento,
    this.alVerCatalogo,
    this.alMinimizar,
    this.alCerrar,
    this.embebido = false,
  });

  @override
  State<MassBotScreen> createState() => _MassBotScreenState();
}

class _MassBotScreenState extends State<MassBotScreen> {
  final _campo = TextEditingController();
  late final ConversacionMassBot _conversacion;
  late final bool _conversacionPropia;
  late final ScrollController _desplazamiento;
  late final bool _desplazamientoPropio;

  @override
  void initState() {
    super.initState();
    _conversacionPropia = widget.conversacion == null;
    _conversacion =
        widget.conversacion ?? ConversacionMassBot(servicio: widget.servicio);
    _desplazamientoPropio = widget.desplazamiento == null;
    _desplazamiento = widget.desplazamiento ?? ScrollController();
    _conversacion.addListener(_alCambiar);
    WidgetsBinding.instance.addPostFrameCallback((_) => _restaurar());
  }

  var _firmaVista = '';
  var _activa = true;

  void _alCambiar() {
    if (!_activa || !mounted) return;
    final firma =
        '${_conversacion.entradas.length}|${_conversacion.ocupado}|${_conversacion.error}';
    final debeBajar = firma != _firmaVista;
    _firmaVista = firma;
    setState(() {});
    if (debeBajar) _bajar();
  }

  void _restaurar() {
    if (!_activa || !_desplazamiento.hasClients) return;
    final guardado = _conversacion.desplazamiento;
    final maximo = _desplazamiento.position.maxScrollExtent;
    if (maximo <= 0) return;
    final destino = guardado > 0 && guardado < maximo ? guardado : maximo;
    _desplazamiento.jumpTo(destino);
  }

  void _bajar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_activa || !_desplazamiento.hasClients) return;
      final reducir = MediaQuery.disableAnimationsOf(context);
      final destino = _desplazamiento.position.maxScrollExtent;
      if (reducir) {
        _desplazamiento.jumpTo(destino);
        return;
      }
      _desplazamiento.animateTo(
        destino,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _enviar([String? texto]) async {
    final mensaje = (texto ?? _campo.text).trim();
    if (mensaje.isEmpty || _conversacion.ocupado) return;
    if (texto == null) _campo.clear();
    await _conversacion.enviar(mensaje);
  }

  Future<void> _nueva() async {
    if (!_conversacion.tieneMensajes || _conversacion.ocupado) return;
    final borrar = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: Text(
          'Nueva conversación',
          style: textoMassBot(peso: FontWeight.w800, color: kAzulProfundoBot),
        ),
        content: Text(
          'Se borrarán los mensajes de esta sesión.',
          style: textoMassBot(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (borrar == true) _conversacion.nueva();
  }

  void _minimizar() {
    if (_desplazamiento.hasClients) {
      _conversacion.guardarDesplazamiento(_desplazamiento.offset);
    }
    final accion = widget.alMinimizar;
    if (accion != null) {
      accion();
      return;
    }
    Navigator.maybePop(context);
  }

  void _cerrar() {
    if (_desplazamiento.hasClients) {
      _conversacion.guardarDesplazamiento(_desplazamiento.offset);
    }
    final accion = widget.alCerrar ?? widget.alMinimizar;
    if (accion != null) {
      accion();
      return;
    }
    Navigator.maybePop(context);
  }

  @override
  void dispose() {
    _activa = false;
    if (_desplazamiento.hasClients) {
      _conversacion.guardarDesplazamiento(_desplazamiento.offset);
    }
    _conversacion.removeListener(_alCambiar);
    _campo.dispose();
    if (_desplazamientoPropio) _desplazamiento.dispose();
    if (_conversacionPropia) _conversacion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final panel = Column(
      children: [
        EncabezadoMassBot(
          alMinimizar: _minimizar,
          alCerrar: _cerrar,
          alNueva: _conversacion.tieneMensajes ? _nueva : null,
          enDemostracion: _conversacion.enDemostracion,
        ),
        Expanded(
          child: ListView(
            controller: _desplazamiento,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            children: [
              if (!_conversacion.tieneMensajes)
                BienvenidaMassBot(alElegir: (texto) => _enviar(texto)),
              for (final entrada in _conversacion.entradas) ...[
                if (entrada.usuario)
                  BurbujaMassBot(usuario: true, texto: entrada.texto)
                else ...[
                  BurbujaMassBot(
                    usuario: false,
                    texto: entrada.respuesta!.texto,
                  ),
                  if (entrada.respuesta!.productos.any(
                    (producto) => producto.cantidad > 0,
                  ))
                    ListaCompraMassBot(
                      productos: entrada.respuesta!.productos,
                      alVerCatalogo: widget.alVerCatalogo,
                    )
                  else
                    TarjetasMassBot(
                      productos: entrada.respuesta!.productos,
                      alVerCatalogo: widget.alVerCatalogo,
                    ),
                  CuponesMassBot(cupones: entrada.respuesta!.cupones),
                  if (entrada.respuesta!.presupuesto != null &&
                      entrada.respuesta!.total != null &&
                      entrada.respuesta!.restante != null)
                    FichaPresupuesto(
                      presupuesto: entrada.respuesta!.presupuesto!,
                      total: entrada.respuesta!.total!,
                      restante: entrada.respuesta!.restante!,
                    ),
                  if (entrada.respuesta!.simulado)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Demostración con datos simulados.',
                        style: textoMassBot(
                          tamano: 11.5,
                          color: kTintaSuaveBot,
                        ),
                      ),
                    ),
                  if (entrada.respuesta!.sinConexion)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.wifi_off_rounded,
                            size: 14,
                            color: kTintaSuaveBot,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Modo sin conexión al asistente IA: respondo con el catálogo de la tienda.',
                              style: textoMassBot(
                                tamano: 11.5,
                                color: kTintaSuaveBot,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 12),
              ],
              if (_conversacion.ocupado) const IndicadorMassBot(),
              if (_conversacion.error != null)
                AvisoErrorMassBot(
                  mensaje: _conversacion.error!,
                  alReintentar: _conversacion.reintentar,
                ),
            ],
          ),
        ),
        CompositorMassBot(
          controlador: _campo,
          ocupado: _conversacion.ocupado,
          alEnviar: _enviar,
        ),
      ],
    );

    if (widget.embebido) {
      return Theme(
        data: Theme.of(context).copyWith(
          textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Manrope'),
        ),
        child: ColoredBox(color: kFondoMassBot, child: panel),
      );
    }
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Manrope'),
      ),
      child: Scaffold(
        backgroundColor: kFondoMassBot,
        resizeToAvoidBottomInset: true,
        body: SafeArea(child: panel),
      ),
    );
  }
}
