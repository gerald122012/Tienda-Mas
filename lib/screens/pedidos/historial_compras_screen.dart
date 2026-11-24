import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/pedido.dart';
import '../../services/auth_service.dart';
import '../../services/historial_pedidos.dart';
import '../../services/pedidos_local_service.dart';
import '../../tema/tema_mass.dart';
import '../auth/login_screen.dart';
import 'detalle_pedido_screen.dart';
import 'estado_pedido.dart';
import 'tarjeta_pedido_cliente.dart';

Stream<ResultadoLecturaPedidos> lecturaRemotaDeFirestore(String uid) {
  if (uid.isEmpty) {
    return Stream.value(const ResultadoLecturaPedidos());
  }
  return FirebaseFirestore.instance
      .collection('pedidos')
      .where('clienteUid', isEqualTo: uid)
      .snapshots()
      .map((snap) {
        return ResultadoLecturaPedidos(
          desdeCache: snap.metadata.isFromCache,
          pedidos: [
            for (final doc in snap.docs)
              LecturaRemota(
                Pedido.fromMap(doc.id, doc.data()),
                escrituraPendiente: doc.metadata.hasPendingWrites,
              ),
          ],
        );
      });
}

class HistorialComprasScreen extends StatefulWidget {
  final bool mostrarAppBar;
  final Stream<ResultadoLecturaPedidos>? lecturaRemota;
  final String uid;
  final VoidCallback? alExplorar;
  final VoidCallback? alIngresar;

  const HistorialComprasScreen({
    super.key,
    this.mostrarAppBar = false,
    this.lecturaRemota,
    this.uid = '',
    this.alExplorar,
    this.alIngresar,
  });

  @override
  State<HistorialComprasScreen> createState() => _HistorialComprasScreenState();
}

class _HistorialComprasScreenState extends State<HistorialComprasScreen> {
  FiltroPedidos _filtro = FiltroPedidos.todos;
  var _localesListos = false;
  var _ciclo = 0;
  String _firma = '';
  Stream<ResultadoLecturaPedidos>? _stream;

  @override
  void initState() {
    super.initState();
    PedidosLocalService.instance.cargar().whenComplete(() {
      if (mounted) setState(() => _localesListos = true);
    });
  }

  String _uidRemoto() {
    if (widget.uid.isNotEmpty || widget.lecturaRemota != null) return widget.uid;
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  Stream<ResultadoLecturaPedidos> _fuente(String uid) {
    final firma = '$uid|$_ciclo|${identityHashCode(widget.lecturaRemota)}';
    if (_stream != null && _firma == firma) return _stream!;
    _firma = firma;
    _stream = widget.lecturaRemota ?? lecturaRemotaDeFirestore(uid);
    return _stream!;
  }

  void _explorar() {
    final accion = widget.alExplorar;
    if (accion != null) {
      accion();
      return;
    }
    Navigator.maybePop(context);
  }

  void _ingresar() {
    final accion = widget.alIngresar;
    if (accion != null) {
      accion();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    );
  }

  void _abrirDetalle(Pedido pedido, {required bool sinConfirmar}) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DetallePedidoScreen(
          pedido: pedido,
          sinConfirmar: sinConfirmar,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Scaffold(
      backgroundColor: tokens.fondo,
      appBar: widget.mostrarAppBar
          ? AppBar(title: const Text('Mis compras'))
          : null,
      body: ListenableBuilder(
        listenable: Listenable.merge([
          AuthService.instance,
          PedidosLocalService.instance,
        ]),
        builder: (context, _) {
          final usuario = AuthService.instance.usuario;
          if (usuario == null) return _Invitado(alIngresar: _ingresar);
          if (!_localesListos) return const _Cargando();
          final uid = _uidRemoto();
          return StreamBuilder<ResultadoLecturaPedidos>(
            key: ValueKey('${usuario.correo}|$uid|$_ciclo'),
            stream: _fuente(uid),
            builder: (context, snapshot) {
              final fallo = snapshot.hasError;
              final esperando = !snapshot.hasData && !fallo;
              if (esperando) return const _Cargando();
              final lectura = snapshot.data ?? const ResultadoLecturaPedidos();
              final historial = clasificarHistorial(
                remotos: fallo ? const [] : lectura.pedidos,
                locales: PedidosLocalService.instance.pedidos,
                uid: uid,
                correo: usuario.correo,
                filtro: _filtro,
              );
              final sinDatos =
                  historial.confirmados.isEmpty &&
                  historial.localesSinConfirmar.isEmpty;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Encabezado(
                    mostrarTitulo: !widget.mostrarAppBar,
                    total: historial.totalConfirmados,
                  ),
                  const SizedBox(height: 12),
                  FiltrosPedidos(
                    seleccionado: _filtro,
                    alElegir: (filtro) => setState(() => _filtro = filtro),
                  ),
                  if ((lectura.desdeCache && !fallo) || (fallo && !sinDatos))
                    _Aviso(
                      texto: fallo
                          ? 'No pudimos actualizar tus pedidos. Si hay compras guardadas en este dispositivo, siguen visibles.'
                          : 'Mostramos lo guardado en este dispositivo. Todavía no pudimos actualizarlo con el servidor.',
                      accion: fallo ? 'Reintentar' : null,
                      alPulsar: fallo
                          ? () => setState(() {
                              _ciclo++;
                              _stream = null;
                            })
                          : null,
                    ),
                  Expanded(
                    child: _Cuerpo(
                      historial: historial,
                      fallo: fallo,
                      filtro: _filtro,
                      alExplorar: _explorar,
                      alReintentar: () => setState(() {
                        _ciclo++;
                        _stream = null;
                      }),
                      alAbrir: _abrirDetalle,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  final bool mostrarTitulo;
  final int total;

  const _Encabezado({required this.mostrarTitulo, required this.total});

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mostrarTitulo)
            Text(
              'Mis compras',
              style: textoMass(
                tamano: 26,
                peso: FontWeight.w800,
                color: tokens.profundo,
                alto: 1.1,
              ),
            ),
          Text(
            'Consulta el estado de tus pedidos',
            style: textoMass(tamano: 14, color: tokens.tintaSuave),
          ),
          if (total > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: tokens.superficie,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: tokens.linea),
              ),
              child: Text(
                total == 1 ? '1 pedido' : '$total pedidos',
                style: textoMass(
                  tamano: 12,
                  peso: FontWeight.w700,
                  color: tokens.profundo,
                  tabular: true,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Cuerpo extends StatelessWidget {
  final HistorialClasificado historial;
  final bool fallo;
  final FiltroPedidos filtro;
  final VoidCallback alExplorar;
  final VoidCallback alReintentar;
  final void Function(Pedido pedido, {required bool sinConfirmar}) alAbrir;

  const _Cuerpo({
    required this.historial,
    required this.fallo,
    required this.filtro,
    required this.alExplorar,
    required this.alReintentar,
    required this.alAbrir,
  });

  @override
  Widget build(BuildContext context) {
    final confirmados = historial.confirmados;
    final locales = historial.localesSinConfirmar;
    if (fallo && confirmados.isEmpty && locales.isEmpty) {
      return _MensajeEstado(
        icono: Icons.wifi_off_rounded,
        titulo: 'No pudimos consultar tus pedidos',
        mensaje: 'Revisa tu conexión e inténtalo nuevamente.',
        accion: 'Reintentar',
        alPulsar: alReintentar,
      );
    }
    if (confirmados.isEmpty && locales.isEmpty) {
      if (filtro == FiltroPedidos.todos) {
        return _MensajeEstado(
          icono: Icons.shopping_bag_outlined,
          titulo: 'Aún no tienes pedidos',
          mensaje: 'Cuando confirmes una compra, podrás seguirla desde aquí.',
          accion: 'Explorar productos',
          alPulsar: alExplorar,
        );
      }
      return _MensajeEstado(
        icono: Icons.filter_alt_outlined,
        titulo: 'Sin pedidos en este estado',
        mensaje: 'No hay compras confirmadas con el filtro seleccionado.',
      );
    }

    final filas = <Object>[
      if (confirmados.isEmpty)
        filtro == FiltroPedidos.todos
            ? 'No hay pedidos confirmados en el servidor.'
            : 'Ningún pedido confirmado coincide con este filtro.',
      for (final pedido in confirmados) pedido,
      if (locales.isNotEmpty) 'Registros locales sin confirmación',
      ...locales,
    ];
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: filas.length,
      itemBuilder: (context, indice) {
        final fila = filas[indice];
        if (fila is String) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10, top: 4),
            child: Text(
              fila,
              style: textoMass(
                tamano: fila.startsWith('Registros') ? 16 : 14,
                peso: FontWeight.w800,
                color: TokensMass.de(context).profundo,
              ),
            ),
          );
        }
        final pedido = fila as Pedido;
        final sinConfirmar = locales.contains(pedido);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TarjetaPedidoCliente(
            key: ValueKey(pedido.id),
            pedido: pedido,
            sinConfirmar: sinConfirmar,
            alVerDetalle: () => alAbrir(pedido, sinConfirmar: sinConfirmar),
          ),
        );
      },
    );
  }
}

class _Aviso extends StatelessWidget {
  final String texto;
  final String? accion;
  final VoidCallback? alPulsar;

  const _Aviso({required this.texto, this.accion, this.alPulsar});

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tokens.superficie,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.linea),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_queue_rounded, color: tokens.profundo, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                texto,
                style: textoMass(tamano: 13, color: tokens.tinta),
              ),
            ),
            if (accion != null)
              TextButton(
                onPressed: alPulsar,
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                child: Text(accion!),
              ),
          ],
        ),
      ),
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final quieto = MediaQuery.disableAnimationsOf(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (quieto)
            Icon(Icons.hourglass_top_rounded, color: tokens.accion, size: 28)
          else
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: tokens.accion,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Consultando tus pedidos',
            style: textoMass(color: tokens.tintaSuave),
          ),
        ],
      ),
    );
  }
}

class _Invitado extends StatelessWidget {
  final VoidCallback alIngresar;

  const _Invitado({required this.alIngresar});

  @override
  Widget build(BuildContext context) {
    return _MensajeEstado(
      icono: Icons.receipt_long_outlined,
      titulo: 'Tus pedidos, en un solo lugar',
      mensaje:
          'Inicia sesión para consultar tus compras y conocer el estado de tus pedidos',
      accion: 'Iniciar sesión',
      alPulsar: alIngresar,
    );
  }
}

class _MensajeEstado extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String mensaje;
  final String? accion;
  final VoidCallback? alPulsar;

  const _MensajeEstado({
    required this.icono,
    required this.titulo,
    required this.mensaje,
    this.accion,
    this.alPulsar,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: tokens.superficie,
                  shape: BoxShape.circle,
                  border: Border.all(color: tokens.linea),
                ),
                child: Icon(icono, color: tokens.accion, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: textoMass(
                  tamano: 22,
                  peso: FontWeight.w800,
                  color: tokens.profundo,
                  alto: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: textoMass(tamano: 14, color: tokens.tintaSuave),
              ),
              if (accion != null) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: alPulsar,
                    style: FilledButton.styleFrom(
                      backgroundColor: tokens.accion,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(48, 48),
                      textStyle: textoMass(
                        peso: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    child: Text(accion!),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
