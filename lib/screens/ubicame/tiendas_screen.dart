import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../models/tienda.dart';
import '../../services/consulta_tiendas.dart';
import '../../services/firebase_service.dart';
import '../../services/formato_recorrido.dart';
import '../../services/lectura_ubicacion.dart';
import '../../tema/tema_mass.dart';
import '../../utils/utilidades.dart';
import '../delivery/delivery_mapa_screen.dart';
import 'busqueda_tiendas.dart';
import 'estado_tiendas.dart';
import 'estado_ubicacion.dart';
import 'filtro_ciudades.dart';
import 'tarjeta_tienda_cliente.dart';
import 'tienda_form_screen.dart';

class TiendasScreen extends StatefulWidget {
  final bool esAdmin;
  final Stream<List<Tienda>> Function()? lectura;
  final Future<LecturaUbicacion> Function()? leerUbicacion;
  final Future<void> Function()? abrirAjustes;
  final Widget Function(Tienda tienda)? pantallaRuta;

  const TiendasScreen({
    super.key,
    this.esAdmin = false,
    this.lectura,
    this.leerUbicacion,
    this.abrirAjustes,
    this.pantallaRuta,
  });

  @override
  State<TiendasScreen> createState() => _TiendasScreenState();
}

class _TiendasScreenState extends State<TiendasScreen> {
  final _busqueda = TextEditingController();
  final _foco = FocusNode();
  late Stream<List<Tienda>> _fuente;
  String _ciudad = 'Todas';
  LatLng? _origen;
  SituacionUbicacion? _situacion;
  bool _obteniendo = false;
  String? _avisoCoordenadas;
  FirebaseService? _servicio;

  FirebaseService get _admin => _servicio ??= FirebaseService('tiendas_mass');

  @override
  void initState() {
    super.initState();
    _fuente = _abrirFuente();
    _foco.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(TiendasScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lectura != widget.lectura) {
      _fuente = _abrirFuente();
    }
  }

  @override
  void dispose() {
    _busqueda.dispose();
    _foco.dispose();
    super.dispose();
  }

  Stream<List<Tienda>> _abrirFuente() {
    final inyectada = widget.lectura;
    if (inyectada != null) return inyectada();
    return _admin.coleccion.snapshots().map(
      (snap) => snap.docs.map((doc) => Tienda.fromMap(doc.id, doc.data())).toList(),
    );
  }

  void _reintentar() {
    setState(() => _fuente = _abrirFuente());
  }

  Future<void> _usarUbicacion() async {
    if (_obteniendo) return;
    setState(() => _obteniendo = true);
    final lectura = widget.leerUbicacion != null
        ? await widget.leerUbicacion!()
        : await leerUbicacionDelDispositivo(context);
    if (!mounted) return;
    setState(() {
      _obteniendo = false;
      _situacion = lectura.situacion;
      if (lectura.situacion == SituacionUbicacion.concedida &&
          lectura.punto != null) {
        _origen = lectura.punto;
      }
    });
  }

  void _abrirFormulario([Tienda? tienda]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TiendaFormScreen(tienda: tienda)),
    );
  }

  void _duplicar(Tienda tienda) {
    _abrirFormulario(Tienda.fromMap('', tienda.toMap()));
  }

  Future<void> _eliminar(Tienda tienda) async {
    if (!await confirmarEliminar(context, tienda.nombre)) return;
    await _admin.eliminar(tienda.id);
    if (!mounted) return;
    mostrarDeshacer(
      context,
      'Tienda Mass eliminada',
      () => _admin.restaurar(tienda.id, tienda.toMap()),
    );
  }

  void _abrirRuta(Tienda tienda) {
    if (!coordenadasValidas(tienda.latitud, tienda.longitud)) {
      setState(() => _avisoCoordenadas = tienda.nombre.trim());
      return;
    }
    final detalle = [
      tienda.distrito.trim(),
      tienda.ciudad.trim(),
      tienda.direccion.trim(),
    ].where((parte) => parte.isNotEmpty).join(' · ');
    setState(() => _avisoCoordenadas = null);
    final nombre = tienda.nombre.trim().isEmpty ? 'Establecimiento' : tienda.nombre.trim();
    final personalizada = widget.pantallaRuta;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => personalizada != null
            ? personalizada(tienda)
            : DeliveryMapaScreen(
                nombreDestinoInicial: nombre,
                detalleDestinoInicial: detalle,
                destinoInicial: LatLng(tienda.latitud!, tienda.longitud!),
                destinoDeTienda: true,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Scaffold(
      backgroundColor: tokens.fondo,
      floatingActionButton: widget.esAdmin
          ? FloatingActionButton.extended(
              heroTag: 'tiendas_mass',
              onPressed: () => _abrirFormulario(),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Nueva tienda'),
            )
          : null,
      body: StreamBuilder<List<Tienda>>(
        key: ValueKey(identityHashCode(_fuente)),
        stream: _fuente,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _cuerpo(
              tokens: tokens,
              contenido: EstadoTiendas(
                icono: Icons.cloud_off_rounded,
                colorIcono: tokens.sello,
                titulo: 'No pudimos consultar las tiendas',
                mensaje: 'Revisa tu conexión e inténtalo nuevamente.',
                accion: 'Reintentar',
                alAccionar: _reintentar,
              ),
            );
          }
          if (!snapshot.hasData) {
            return _cuerpo(
              tokens: tokens,
              contenido: const EstadoTiendas(
                icono: Icons.hourglass_top_rounded,
                titulo: 'Consultando tiendas',
                mensaje: 'Estamos leyendo los establecimientos.',
              ),
            );
          }
          final todas = snapshot.data!;
          if (todas.isEmpty) {
            return _cuerpo(
              tokens: tokens,
              contenido: EstadoTiendas(
                icono: Icons.storefront_rounded,
                titulo: 'Aún no hay tiendas registradas',
                mensaje: 'Cuando haya establecimientos publicados, aparecerán en esta lista.',
                accion: widget.esAdmin ? 'Registrar tienda' : null,
                alAccionar: widget.esAdmin ? () => _abrirFormulario() : null,
              ),
            );
          }
          final ciudades = ciudadesDe(todas);
          final ciudadActiva = ciudades.contains(_ciudad) || _ciudad == 'Todas'
              ? _ciudad
              : 'Todas';
          final filtradas = ordenarTiendas(
            filtrarTiendas(
              tiendas: todas,
              consulta: _busqueda.text,
              ciudad: ciudadActiva,
            ),
            _origen,
          );
          final hayCercania =
              _origen != null &&
              filtradas.any(
                (tienda) => coordenadasValidas(tienda.latitud, tienda.longitud),
              );
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _encabezado(tokens, ciudades, ciudadActiva, filtradas.length, hayCercania)),
              if (_avisoCoordenadas != null)
                SliverToBoxAdapter(
                  child: AvisoContextual(
                    icono: Icons.location_off_outlined,
                    mensaje: _avisoCoordenadas!.isEmpty
                        ? 'Esta tienda no tiene coordenadas para trazar una ruta.'
                        : 'La tienda $_avisoCoordenadas no tiene coordenadas para trazar una ruta.',
                  ),
                ),
              if (_situacion != null &&
                  mensajeSituacionUbicacion(_situacion!, enMapa: false) != null)
                SliverToBoxAdapter(
                  child: AvisoContextual(
                    icono: Icons.my_location_outlined,
                    mensaje: mensajeSituacionUbicacion(_situacion!, enMapa: false)!,
                    accion: _situacion == SituacionUbicacion.denegadaPermanentemente
                        ? 'Abrir ajustes'
                        : null,
                    alAccionar: _situacion == SituacionUbicacion.denegadaPermanentemente
                        ? () {
                            final abrir = widget.abrirAjustes;
                            if (abrir != null) {
                              abrir();
                            } else {
                              abrirAjustesUbicacion();
                            }
                          }
                        : null,
                  ),
                ),
              if (filtradas.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Align(
                    alignment: const Alignment(0, -0.2),
                    child: EstadoTiendas(
                      icono: _busqueda.text.trim().isEmpty
                          ? Icons.location_city_outlined
                          : Icons.search_off_rounded,
                      titulo: _busqueda.text.trim().isEmpty
                          ? 'No hay tiendas en esta ciudad'
                          : 'Ninguna tienda coincide con tu búsqueda',
                      mensaje: _busqueda.text.trim().isEmpty
                          ? 'Prueba con otra ciudad o mira el listado completo.'
                          : 'Revisa el nombre, la ciudad o la dirección.',
                      accion: _busqueda.text.trim().isEmpty
                          ? 'Ver todas'
                          : 'Limpiar búsqueda',
                      alAccionar: _busqueda.text.trim().isEmpty
                          ? () => setState(() => _ciudad = 'Todas')
                          : () {
                              _busqueda.clear();
                              setState(() {});
                            },
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, widget.esAdmin ? 96 : 24),
                  sliver: SliverList.separated(
                    itemCount: filtradas.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, indice) {
                      final tienda = filtradas[indice];
                      final valida = coordenadasValidas(tienda.latitud, tienda.longitud);
                      String? distancia;
                      if (_origen != null && valida) {
                        distancia = textoDistanciaAproximada(
                          distanciaLineaRectaMetros(
                            _origen!,
                            LatLng(tienda.latitud!, tienda.longitud!),
                          ),
                        );
                      }
                      return TarjetaTiendaCliente(
                        tienda: tienda,
                        lugar: lugarTienda(tienda),
                        horario: tienda.horario.trim().isEmpty ? null : tienda.horario.trim(),
                        distanciaAproximada: distancia,
                        alVerRuta: valida ? () => _abrirRuta(tienda) : null,
                        alSinCoordenadas: valida ? null : () => _abrirRuta(tienda),
                        esAdmin: widget.esAdmin,
                        alDuplicar: () => _duplicar(tienda),
                        alEditar: () => _abrirFormulario(tienda),
                        alEliminar: () => _eliminar(tienda),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _cuerpo({required TokensMass tokens, required Widget contenido}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _titulo(tokens),
        ),
        Expanded(
          child: Align(
            alignment: const Alignment(0, -0.2),
            child: contenido,
          ),
        ),
      ],
    );
  }

  Widget _titulo(TokensMass tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Encuentra tu Mass',
          style: textoMass(tamano: 22, peso: FontWeight.w800, color: tokens.profundo),
        ),
        const SizedBox(height: 2),
        Text(
          'Encuentra nuestras tiendas y planifica tu recorrido.',
          style: textoMass(tamano: 13, color: tokens.tintaSuave, alto: 1.35),
        ),
      ],
    );
  }

  Widget _encabezado(
    TokensMass tokens,
    List<String> ciudades,
    String ciudadActiva,
    int total,
    bool hayCercania,
  ) {
    final etiquetaUbicacion = _obteniendo
        ? 'Obteniendo tu ubicación'
        : _origen == null
        ? 'Usar mi ubicación'
        : 'Actualizar ubicación';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titulo(tokens),
          const SizedBox(height: 12),
          BusquedaTiendas(
            controlador: _busqueda,
            foco: _foco,
            alCambiar: (_) => setState(() {}),
            alLimpiar: () {
              _busqueda.clear();
              setState(() {});
            },
          ),
          const SizedBox(height: 10),
          FiltroCiudades(
            ciudades: ciudades,
            seleccion: ciudadActiva,
            alElegir: (ciudad) => setState(() => _ciudad = ciudad),
          ),
          const SizedBox(height: 8),
          Text(
            total == 1 ? '1 tienda' : '$total tiendas',
            style: textoMass(tamano: 13, peso: FontWeight.w800, color: tokens.profundo),
          ),
          if (hayCercania)
            Text(
              'Ordenadas por cercanía en línea recta.',
              style: textoMass(tamano: 12, color: tokens.tintaSuave),
            ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('usar-ubicacion-tiendas'),
              onPressed: _obteniendo ? null : _usarUbicacion,
              style: TextButton.styleFrom(
                foregroundColor: tokens.accion,
                minimumSize: const Size(48, 48),
              ),
              icon: Icon(
                _origen == null ? Icons.my_location_outlined : Icons.near_me_outlined,
                size: 18,
              ),
              label: Text(etiquetaUbicacion),
            ),
          ),
        ],
      ),
    );
  }
}
