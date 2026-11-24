import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/carrito_service.dart';
import '../tema/tema_mass.dart';
import '../utils/utilidades.dart';
import '../widgets/barra_superior_mass.dart';
import '../widgets/navegacion_inferior_mass.dart';
import 'auth/login_screen.dart';
import 'carrito/carrito_screen.dart';
import 'inicio/inicio_screen.dart';
import 'pedidos/historial_compras_screen.dart';
import 'massbot/conversacion_massbot.dart';
import 'massbot/ventana_massbot.dart';
import 'massbot/widgets/boton_flotante_massbot.dart';
import 'massbot/widgets/zona_asistente.dart';
import 'perfil/perfil_screen.dart';
import 'precios_mass/productos_screen.dart';
import 'sensores/sensores_screen.dart';
import 'ubicame/tiendas_screen.dart';

class _Pestana {
  final String etiqueta;
  final IconData icono;
  final Widget pantalla;
  const _Pestana(this.etiqueta, this.icono, this.pantalla);
}

class HomeScreen extends StatefulWidget {
  final Usuario? usuario;

  const HomeScreen({super.key, this.usuario});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

final observadorRutasMass = RouteObserver<PageRoute<dynamic>>();

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, RouteAware {
  late final List<_Pestana> _pestanas = [
    _Pestana(
      'Inicio',
      Icons.storefront_rounded,
      InicioScreen(onCambiarPestana: _cambiarPestana, mostrarAlquiler: false),
    ),
    const _Pestana('Productos', Icons.local_offer_rounded, ProductosScreen()),
    const _Pestana('Ubícame', Icons.location_on_rounded, TiendasScreen()),
    _Pestana(
      'Compras',
      Icons.history_rounded,
      HistorialComprasScreen(alExplorar: () => _cambiarPestana(1)),
    ),
    const _Pestana('Sensores', Icons.sensors_rounded, SizedBox.shrink()),
  ];

  int _indice = 0;
  var _teclado = false;
  var _enPrimerPlano = true;
  var _cubierta = false;
  PageRoute<dynamic>? _ruta;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ConversacionMassBot.instancia.vincular(widget.usuario?.correo);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ruta = ModalRoute.of(context);
    if (ruta is! PageRoute<dynamic> || ruta == _ruta) return;
    if (_ruta != null) observadorRutasMass.unsubscribe(this);
    _ruta = ruta;
    observadorRutasMass.subscribe(this, ruta);
  }

  @override
  void dispose() {
    observadorRutasMass.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didPushNext() {
    if (!mounted || _cubierta) return;
    setState(() => _cubierta = true);
  }

  @override
  void didPopNext() {
    if (!mounted || !_cubierta) return;
    setState(() => _cubierta = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final activo = state == AppLifecycleState.resumed;
    if (!mounted || activo == _enPrimerPlano) return;
    setState(() => _enPrimerPlano = activo);
  }

  @override
  void didChangeMetrics() {
    final vista = WidgetsBinding.instance.platformDispatcher.views.first;
    final abierto = vista.viewInsets.bottom > 0;
    if (!mounted || abierto == _teclado) return;
    setState(() => _teclado = abierto);
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.usuario?.correo != widget.usuario?.correo) {
      ConversacionMassBot.instancia.vincular(widget.usuario?.correo);
    }
  }

  Future<void> _abrirMassBot() {
    return abrirVentanaMassBot(
      context,
      conversacion: ConversacionMassBot.instancia,
      alVerCatalogo: () => _cambiarPestana(1),
    );
  }

  void _cambiarPestana(int nuevoIndice) {
    if (nuevoIndice < 0 || nuevoIndice >= _pestanas.length) return;
    setState(() => _indice = nuevoIndice);
  }

  Widget _botonCarritoAppBar() {
    final carrito = CarritoService.instance;
    return ListenableBuilder(
      listenable: carrito,
      builder: (context, _) {
        final tieneItems = carrito.unidades > 0;
        final tokens = TokensMass.de(context);
        final etiqueta = tieneItems
            ? 'Carrito, ${carrito.unidades} unidades, total ${formatoPrecio(carrito.total)}'
            : 'Carrito vacío';
        final reducir = MediaQuery.disableAnimationsOf(context);
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Semantics(
            button: true,
            label: etiqueta,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CarritoScreen(
                    alVerProductos: () {
                      Navigator.pop(context);
                      _cambiarPestana(1);
                    },
                  ),
                ),
              ),
              child: ExcludeSemantics(
                child: AnimatedContainer(
                  duration: Duration(milliseconds: reducir ? 0 : 220),
                  curve: Curves.easeOutCubic,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: tieneItems ? 10 : 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: tieneItems
                        ? tokens.accion
                        : tokens.accion.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Badge(
                        isLabelVisible: tieneItems,
                        backgroundColor: tokens.sello,
                        textColor: tokens.profundo,
                        label: Text(
                          '${carrito.unidades}',
                          style: textoMass(
                            tamano: 11,
                            peso: FontWeight.w800,
                            color: tokens.profundo,
                            tabular: true,
                          ),
                        ),
                        child: Icon(
                          Icons.shopping_cart_rounded,
                          size: 20,
                          color: tieneItems ? tokens.sello : tokens.accion,
                        ),
                      ),
                      if (tieneItems) ...[
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 84),
                          child: Text(
                            formatoPrecio(carrito.total),
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: textoMass(
                              tamano: 12,
                              peso: FontWeight.w800,
                              color: Colors.white,
                              tabular: true,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = widget.usuario;

    return Scaffold(
      appBar: BarraSuperiorMass(
        carrito: _botonCarritoAppBar(),
        cuenta: BotonCuentaAppBar(
          usuario: usuario,
          alExplorarProductos: () => _cambiarPestana(1),
        ),
      ),
      body: ListenableBuilder(
        listenable: ConversacionMassBot.instancia,
        builder: (context, _) {
          final visible =
              muestraAsistenteMassBot(_indice) &&
              !ConversacionMassBot.instancia.abierta &&
              !_teclado;
          return ZonaConAsistente(
            contenido: IndexedStack(
              index: _indice,
              children: [
                for (var i = 0; i < _pestanas.length; i++)
                  i == 4
                      ? SensoresScreen(
                          key: const ValueKey('sensores-tab'),
                          visible:
                              _indice == 4 && _enPrimerPlano && !_cubierta,
                        )
                      : _pestanas[i].pantalla,
              ],
            ),
            asistente: visible
                ? BotonFlotanteMassBot(
                    key: ValueKey(_indice),
                    conversacion: ConversacionMassBot.instancia,
                    alAbrir: _abrirMassBot,
                  )
                : null,
          );
        },
      ),
      bottomNavigationBar: NavegacionInferiorMass(
        indice: _indice,
        alElegir: _cambiarPestana,
        destinos: [
          for (final p in _pestanas) DestinoNavegacion(p.etiqueta, p.icono),
        ],
      ),
    );
  }
}

class BotonCuentaAppBar extends StatelessWidget {
  final Usuario? usuario;
  final VoidCallback? alExplorarProductos;

  const BotonCuentaAppBar({
    super.key,
    required this.usuario,
    this.alExplorarProductos,
  });

  @override
  Widget build(BuildContext context) {
    final invitado = usuario == null;
    return IconButton(
      tooltip: invitado ? 'Ingresar' : 'Mi perfil',
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => invitado
              ? const LoginScreen()
              : PerfilScreen(alExplorarProductos: alExplorarProductos),
        ),
      ),
      icon: Icon(
        invitado ? Icons.person_outline_rounded : Icons.person_rounded,
      ),
    );
  }
}
