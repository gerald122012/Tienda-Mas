import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/producto.dart';
import '../../services/carrito_service.dart';
import '../../services/catalogo_sesion.dart';
import '../../services/catalogo_visual.dart';
import '../../services/filtro_catalogo.dart';
import '../../tema/tema_mass.dart';
import '../../utils/utilidades.dart';
import '../../widgets/foto_producto.dart';
import '../delivery/delivery_mapa_screen.dart';
import '../escaner/escaner_herramientas_screen.dart';
import 'seleccion_inicio.dart';

class _TemaAprende {
  final String etiqueta;
  final String titulo;
  final String resumen;
  final String contenido;
  final IconData icono;

  const _TemaAprende({
    required this.etiqueta,
    required this.titulo,
    required this.resumen,
    required this.contenido,
    required this.icono,
  });
}

class InicioScreen extends StatelessWidget {
  final ValueChanged<int> onCambiarPestana;
  final bool mostrarAlquiler;

  const InicioScreen({
    super.key,
    required this.onCambiarPestana,
    this.mostrarAlquiler = true,
  });

  static const _temas = [
    _TemaAprende(
      etiqueta: 'Receta · 15 min',
      titulo: 'Almuerzos con arroz',
      resumen: '2 ideas rendidoras',
      contenido:
          '1. Arroz tapado exprés: saltea cebolla, ajo, carne molida y pasas, sirve con arroz graneado y huevo frito.\n\n'
          '2. Chaufa casero Mass: aprovecha arroz del día anterior con sillao, cebollita china, tortilla picada y hot dog en cubitos.',
      icono: Icons.restaurant_rounded,
    ),
    _TemaAprende(
      etiqueta: 'Snacks · 5 min',
      titulo: 'Bocaditos crocantitos',
      resumen: 'Para compartir hoy',
      contenido:
          'Prepara una tabla económica combinando galletas saladas, queso edam en cubos y dips rápidos de palta o yogurt natural con limón.',
      icono: Icons.cookie_outlined,
    ),
    _TemaAprende(
      etiqueta: 'Ahorro Mass',
      titulo: 'Compra inteligente',
      resumen: 'Cuida tu presupuesto',
      contenido:
          '• Compara el precio por kg o litro que aparece en cada tarjeta del catálogo.\n'
          '• Activa el Modo Bolsillo en Productos para controlar tu gasto en tiempo real.\n'
          '• Escanea los códigos QR promocionales antes de pagar.',
      icono: Icons.savings_outlined,
    ),
    _TemaAprende(
      etiqueta: 'Hogar limpio',
      titulo: 'Tips de limpieza',
      resumen: 'Rinde más tu compra',
      contenido:
          'Dosifica el detergente líquido usando la tapa medidora y separa prendas claras de oscuras para duplicar el rendimiento de cada botella.',
      icono: Icons.cleaning_services_outlined,
    ),
  ];

  void _verTodo() {
    FiltroCatalogo.instancia.verTodo();
    onCambiarPestana(1);
  }

  void _buscar(String texto) {
    if (texto.trim().isEmpty) {
      _verTodo();
      return;
    }
    FiltroCatalogo.instancia.buscar(texto);
    onCambiarPestana(1);
  }

  void _abrirCategoria(String id) {
    FiltroCatalogo.instancia.abrirCategoria(id);
    onCambiarPestana(1);
  }

  void _politicas(BuildContext context) {
    final tokens = TokensMass.de(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: tokens.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MassRadio.superficie),
        ),
        title: Text(
          'Políticas de cambios y devoluciones',
          style: textoMass(
            tamano: 18,
            peso: FontWeight.w700,
            color: tokens.profundo,
          ),
        ),
        content: Text(
          '1. Acércate a la tienda donde realizaste la compra.\n'
          '2. Presenta tu comprobante y el producto con empaque cerrado.\n\n'
          '• Perecibles: dentro de las 24 horas.\n'
          '• No perecibles: hasta 7 días posteriores.',
          style: textoMass(tamano: 14, color: tokens.tinta, alto: 1.4),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _detalle(BuildContext context, _TemaAprende tema) {
    final tokens = TokensMass.de(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: tokens.superficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MassRadio.superficie),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MassEspacio.p24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tema.etiqueta,
                style: textoMass(
                  tamano: 12,
                  peso: FontWeight.w700,
                  color: tokens.accion,
                ),
              ),
              const SizedBox(height: MassEspacio.p4),
              Text(
                tema.titulo,
                style: textoMass(
                  tamano: 20,
                  peso: FontWeight.w700,
                  color: tokens.profundo,
                ),
              ),
              const SizedBox(height: MassEspacio.p12),
              Text(
                tema.contenido,
                style: textoMass(tamano: 15, color: tokens.tinta, alto: 1.45),
              ),
              const SizedBox(height: MassEspacio.p16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _verTodo();
                  },
                  child: const Text('Ver productos'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BusquedaInicio(alBuscar: _buscar),
        Expanded(
          child: ListenableBuilder(
            listenable: Listenable.merge([
              CatalogoSesion.instancia,
              CarritoService.instance,
            ]),
            builder: (context, _) {
              final sesion = CatalogoSesion.instancia;
              final destacados = productosParaInicio(sesion.productos);
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _HeroeInicio(productos: destacados, alVerProductos: _verTodo),
                  const SizedBox(height: MassEspacio.p16),
                  _CategoriasInicio(
                    alElegir: _abrirCategoria,
                    alVerTodo: _verTodo,
                  ),
                  const SizedBox(height: MassEspacio.p16),
                  _VitrinaInicio(
                    sesion: sesion,
                    productos: destacados,
                    alVerTodos: _verTodo,
                    alAgregar: (producto) {
                      final ok = CarritoService.instance.agregar(producto);
                      mostrarMensaje(
                        context,
                        ok
                            ? '${producto.nombre} agregado al carrito'
                            : 'No hay más stock disponible de este producto.',
                      );
                    },
                  ),
                  const SizedBox(height: MassEspacio.p24),
                  _ServiciosInicio(
                    mostrarAlquiler: mostrarAlquiler,
                    alAlquilar: () => onCambiarPestana(0),
                  ),
                  const SizedBox(height: MassEspacio.p24),
                  _AprendeInicio(
                    temas: _temas,
                    alAbrir: (tema) => _detalle(context, tema),
                  ),
                  const SizedBox(height: MassEspacio.p16),
                  _PieInicio(alPoliticas: () => _politicas(context)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BusquedaInicio extends StatefulWidget {
  final ValueChanged<String> alBuscar;

  const _BusquedaInicio({required this.alBuscar});

  @override
  State<_BusquedaInicio> createState() => _BusquedaInicioState();
}

class _BusquedaInicioState extends State<_BusquedaInicio> {
  final _campo = TextEditingController();

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  void _enviar() => widget.alBuscar(_campo.text);

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _campo,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _enviar(),
        style: textoMass(tamano: 15, color: tokens.tinta),
        decoration: InputDecoration(
          hintText: '¿Qué necesitas comprar hoy?',
          hintStyle: textoMass(tamano: 15, color: tokens.tintaSuave),
          prefixIcon: Icon(Icons.search_rounded, color: tokens.accion),
          suffixIcon: IconButton(
            tooltip: 'Buscar',
            onPressed: _enviar,
            icon: Icon(Icons.arrow_forward_rounded, color: tokens.profundo),
          ),
          filled: true,
          fillColor: tokens.superficie,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(MassRadio.control),
            borderSide: BorderSide(color: tokens.linea),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(MassRadio.control),
            borderSide: BorderSide(color: tokens.linea),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(MassRadio.control),
            borderSide: BorderSide(color: tokens.accion, width: 1.4),
          ),
        ),
      ),
    );
  }
}

class _HeroeInicio extends StatelessWidget {
  final List<Producto> productos;
  final VoidCallback alVerProductos;

  const _HeroeInicio({required this.productos, required this.alVerProductos});

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final fotos = [
      for (final producto in productos)
        if (bytesImagenProductoEnCache(producto) != null ||
            producto.imagenUrl.trim().isNotEmpty ||
            producto.imagenAsset.trim().startsWith('assets/'))
          producto,
    ].take(2).toList();
    return LayoutBuilder(
      builder: (context, limites) {
        final estrecho = limites.maxWidth < 360;
        final texto = _HeroeTexto(alVerProductos: alVerProductos);
        final vitrina = fotos.isEmpty
            ? const SizedBox.shrink()
            : _HeroeFotos(productos: fotos);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.profundo,
            borderRadius: BorderRadius.circular(MassRadio.superficie),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(MassRadio.superficie),
            child: estrecho
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        texto,
                        if (fotos.isNotEmpty) ...[
                          const SizedBox(height: MassEspacio.p8),
                          _HeroeFotosEstrecho(productos: fotos),
                        ],
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 5, child: texto),
                        if (fotos.isNotEmpty) ...[
                          const SizedBox(width: MassEspacio.p8),
                          SizedBox(width: 148, height: 156, child: vitrina),
                        ],
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _HeroeTexto extends StatelessWidget {
  final VoidCallback alVerProductos;

  const _HeroeTexto({required this.alVerProductos});

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: tokens.sello,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: MassEspacio.p12),
        Text(
          'Compra más,\ngasta menos.',
          style: textoMass(
            tamano: 26,
            peso: FontWeight.w800,
            color: Colors.white,
            alto: 1.05,
          ),
        ),
        const SizedBox(height: MassEspacio.p8),
        Text(
          'Todo lo que necesitas,\ncerca de ti.',
          style: textoMass(
            tamano: 14,
            peso: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.82),
            alto: 1.3,
          ),
        ),
        const SizedBox(height: MassEspacio.p12),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: tokens.sello,
            foregroundColor: tokens.profundo,
            minimumSize: const Size(48, 48),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MassRadio.control),
            ),
            textStyle: textoMass(
              tamano: 14,
              peso: FontWeight.w700,
              color: tokens.profundo,
            ),
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            alVerProductos();
          },
          child: const Text('Ver productos'),
        ),
      ],
    );
  }
}

class _HeroeFotos extends StatelessWidget {
  final List<Producto> productos;

  const _HeroeFotos({required this.productos});

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Stack(
      children: [
        Positioned(
          right: 0,
          top: 8,
          bottom: 8,
          width: 96,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.sello,
              borderRadius: BorderRadius.circular(MassRadio.tarjeta),
            ),
          ),
        ),
        Positioned(top: 0, right: 14, child: _marco(productos.first, 100)),
        if (productos.length > 1)
          Positioned(left: 0, bottom: 0, child: _marco(productos[1], 84)),
      ],
    );
  }

  Widget _marco(Producto producto, double lado) {
    return Container(
      width: lado,
      height: lado,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MassRadio.tarjeta),
        boxShadow: sombraMass(),
      ),
      child: FotoProducto(producto: producto),
    );
  }
}

class _HeroeFotosEstrecho extends StatelessWidget {
  final List<Producto> productos;

  const _HeroeFotosEstrecho({required this.productos});

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return SizedBox(
      height: 96,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Positioned(
            right: 0,
            bottom: 4,
            child: Container(
              width: 168,
              height: 48,
              decoration: BoxDecoration(
                color: tokens.sello,
                borderRadius: BorderRadius.circular(MassRadio.tarjeta),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (productos.length > 1) ...[
                _marcoFoto(productos[1], 76),
                const SizedBox(width: 8),
              ],
              _marcoFoto(productos.first, 90),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _marcoFoto(Producto producto, double lado) {
  return Container(
    width: lado,
    height: lado,
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(MassRadio.tarjeta),
      boxShadow: sombraMass(),
    ),
    child: FotoProducto(producto: producto),
  );
}

class _CategoriasInicio extends StatelessWidget {
  final ValueChanged<String> alElegir;
  final VoidCallback alVerTodo;

  const _CategoriasInicio({required this.alElegir, required this.alVerTodo});

  static const _iconos = {
    'abarrotes': Icons.kitchen_outlined,
    'bebidas': Icons.local_drink_outlined,
    'lácteos': Icons.breakfast_dining_outlined,
    'limpieza': Icons.cleaning_services_outlined,
    'snacks': Icons.cookie_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Encabezado(
          titulo: 'Compra por categoría',
          accion: 'Ver todo',
          alAccion: alVerTodo,
        ),
        const SizedBox(height: MassEspacio.p12),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: Producto.categorias.length,
            separatorBuilder: (_, _) => const SizedBox(width: MassEspacio.p8),
            itemBuilder: (context, i) {
              final id = Producto.categorias[i];
              return _Categoria(
                icono: _iconos[id] ?? Icons.shopping_bag_outlined,
                etiqueta: etiquetaCategoria(id),
                colorIcono: tokens.accion,
                alElegir: () => alElegir(id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Categoria extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final Color colorIcono;
  final VoidCallback alElegir;

  const _Categoria({
    required this.icono,
    required this.etiqueta,
    required this.colorIcono,
    required this.alElegir,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Semantics(
      button: true,
      label: etiqueta,
      child: InkWell(
        borderRadius: BorderRadius.circular(MassRadio.tarjeta),
        onTap: () {
          HapticFeedback.selectionClick();
          alElegir();
        },
        child: ExcludeSemantics(
          child: SizedBox(
            width: 76,
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: tokens.superficie,
                    borderRadius: BorderRadius.circular(MassRadio.tarjeta),
                    border: Border.all(color: tokens.linea),
                  ),
                  child: Icon(icono, color: colorIcono, size: 24),
                ),
                const SizedBox(height: MassEspacio.p8),
                Text(
                  etiqueta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textoMass(
                    tamano: 12,
                    peso: FontWeight.w600,
                    color: tokens.tinta,
                    alto: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VitrinaInicio extends StatelessWidget {
  final CatalogoSesion sesion;
  final List<Producto> productos;
  final VoidCallback alVerTodos;
  final ValueChanged<Producto> alAgregar;

  const _VitrinaInicio({
    required this.sesion,
    required this.productos,
    required this.alVerTodos,
    required this.alAgregar,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Encabezado(
          titulo: 'Explora nuestros productos',
          subtitulo: 'Una selección de lo disponible hoy.',
          accion: productos.isEmpty ? null : 'Ver todos',
          alAccion: alVerTodos,
        ),
        const SizedBox(height: MassEspacio.p12),
        if (sesion.cargando)
          const _EsperaProductos()
        else if (sesion.fallo && productos.isEmpty)
          Text(
            'No pudimos cargar los productos. Revisa tu conexión.',
            style: textoMass(tamano: 14, color: tokens.error),
          )
        else if (productos.isEmpty)
          Text(
            'Todavía no hay productos disponibles.',
            style: textoMass(tamano: 14, color: tokens.tintaSuave),
          )
        else
          SizedBox(
            height: 252,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: productos.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: MassEspacio.p12),
              itemBuilder: (context, i) {
                final producto = productos[i];
                return _TarjetaInicio(
                  producto: producto,
                  enCarrito: CarritoService.instance.cantidadDe(producto),
                  alAgregar: () => alAgregar(producto),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _EsperaProductos extends StatelessWidget {
  const _EsperaProductos();

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return SizedBox(
      height: 160,
      child: Row(
        children: [
          for (var i = 0; i < 2; i++)
            Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i == 0 ? 12 : 0),
                decoration: BoxDecoration(
                  color: tokens.superficie,
                  borderRadius: BorderRadius.circular(MassRadio.tarjeta),
                  border: Border.all(color: tokens.linea),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TarjetaInicio extends StatelessWidget {
  final Producto producto;
  final int enCarrito;
  final VoidCallback alAgregar;

  const _TarjetaInicio({
    required this.producto,
    required this.enCarrito,
    required this.alAgregar,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final presentacion = producto.presentaciones.join(' · ');
    return Container(
      width: 156,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: tokens.superficie,
        borderRadius: BorderRadius.circular(MassRadio.tarjeta),
        border: Border.all(color: tokens.linea),
        boxShadow: sombraMass(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 72,
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: tokens.fondo,
              borderRadius: BorderRadius.circular(MassRadio.control),
            ),
            child: FotoProducto(producto: producto),
          ),
          const SizedBox(height: 6),
          Text(
            producto.marca.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textoMass(
              tamano: 11,
              peso: FontWeight.w700,
              color: tokens.accion,
              alto: 1.1,
            ),
          ),
          Text(
            producto.nombre,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textoMass(
              tamano: 13,
              peso: FontWeight.w700,
              color: tokens.profundo,
              alto: 1.15,
            ),
          ),
          if (presentacion.isNotEmpty)
            Text(
              presentacion,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textoMass(tamano: 12, color: tokens.tintaSuave, alto: 1.2),
            ),
          const Spacer(),
          precioUnaLinea(
            formatoPrecio(producto.precio),
            style: textoMass(
              tamano: 20,
              peso: FontWeight.w800,
              color: tokens.profundo,
              alto: 1,
              tabular: true,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Disponible',
            style: textoMass(
              tamano: 11,
              peso: FontWeight.w600,
              color: tokens.exito,
              alto: 1.1,
            ),
          ),
          const SizedBox(height: MassEspacio.p8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: tokens.accion,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MassRadio.control),
                ),
                textStyle: textoMass(
                  tamano: 13,
                  peso: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              onPressed: alAgregar,
              child: Text(enCarrito > 0 ? 'Agregar ($enCarrito)' : 'Agregar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiciosInicio extends StatelessWidget {
  final bool mostrarAlquiler;
  final VoidCallback alAlquilar;

  const _ServiciosInicio({
    required this.mostrarAlquiler,
    required this.alAlquilar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Encabezado(
          titulo: 'Servicios Mass',
          subtitulo: 'Herramientas para completar tu compra.',
        ),
        const SizedBox(height: MassEspacio.p12),
        Row(
          children: [
            Expanded(
              child: _Servicio(
                icono: Icons.qr_code_scanner_rounded,
                titulo: 'Escáner',
                detalle: 'QR, barras y archivos',
                alAbrir: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EscanerHerramientasScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: MassEspacio.p12),
            Expanded(
              child: _Servicio(
                icono: Icons.delivery_dining_rounded,
                titulo: 'Delivery',
                detalle: 'Rutas GPS',
                alAbrir: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DeliveryMapaScreen()),
                ),
              ),
            ),
          ],
        ),
        if (mostrarAlquiler) ...[
          const SizedBox(height: MassEspacio.p12),
          _Servicio(
            icono: Icons.real_estate_agent_outlined,
            titulo: 'Alquila tu local',
            detalle: 'Espacios de más de 200 m²',
            alAbrir: alAlquilar,
          ),
        ],
      ],
    );
  }
}

class _Servicio extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String detalle;
  final VoidCallback alAbrir;

  const _Servicio({
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.alAbrir,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Material(
      color: tokens.superficie,
      borderRadius: BorderRadius.circular(MassRadio.tarjeta),
      child: InkWell(
        borderRadius: BorderRadius.circular(MassRadio.tarjeta),
        onTap: alAbrir,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MassRadio.tarjeta),
            border: Border.all(color: tokens.linea),
          ),
          child: Row(
            children: [
              Icon(icono, color: tokens.accion, size: 22),
              const SizedBox(width: MassEspacio.p8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textoMass(
                        tamano: 14,
                        peso: FontWeight.w700,
                        color: tokens.profundo,
                        alto: 1.1,
                      ),
                    ),
                    Text(
                      detalle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textoMass(
                        tamano: 12,
                        color: tokens.tintaSuave,
                        alto: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AprendeInicio extends StatelessWidget {
  final List<_TemaAprende> temas;
  final ValueChanged<_TemaAprende> alAbrir;

  const _AprendeInicio({required this.temas, required this.alAbrir});

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Encabezado(
          titulo: 'Aprende Mass',
          subtitulo: 'Ideas para aprovechar mejor tu compra.',
        ),
        const SizedBox(height: MassEspacio.p12),
        for (final tema in temas) ...[
          Material(
            color: tokens.superficie,
            borderRadius: BorderRadius.circular(MassRadio.tarjeta),
            child: InkWell(
              borderRadius: BorderRadius.circular(MassRadio.tarjeta),
              onTap: () => alAbrir(tema),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(MassRadio.tarjeta),
                  border: Border.all(color: tokens.linea),
                ),
                child: Row(
                  children: [
                    Icon(tema.icono, color: tokens.accion, size: 22),
                    const SizedBox(width: MassEspacio.p12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tema.etiqueta,
                            style: textoMass(
                              tamano: 11,
                              peso: FontWeight.w700,
                              color: tokens.tintaSuave,
                            ),
                          ),
                          Text(
                            tema.titulo,
                            style: textoMass(
                              tamano: 15,
                              peso: FontWeight.w700,
                              color: tokens.profundo,
                            ),
                          ),
                          Text(
                            tema.resumen,
                            style: textoMass(
                              tamano: 13,
                              color: tokens.tintaSuave,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: tokens.tintaSuave),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: MassEspacio.p8),
        ],
      ],
    );
  }
}

class _PieInicio extends StatelessWidget {
  final VoidCallback alPoliticas;

  const _PieInicio({required this.alPoliticas});

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Row(
      children: [
        TextButton.icon(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: const Size(48, 48),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: alPoliticas,
          icon: Icon(Icons.policy_outlined, size: 18, color: tokens.accion),
          label: Text(
            'Políticas',
            style: textoMass(
              tamano: 13,
              peso: FontWeight.w700,
              color: tokens.accion,
            ),
          ),
        ),
        const SizedBox(width: MassEspacio.p8),
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Tiendas Mass · v$kAppVersion',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textoMass(tamano: 12, color: tokens.tintaSuave),
            ),
          ),
        ),
      ],
    );
  }
}

class _Encabezado extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final String? accion;
  final VoidCallback? alAccion;

  const _Encabezado({
    required this.titulo,
    this.subtitulo,
    this.accion,
    this.alAccion,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: textoMass(
                  tamano: 20,
                  peso: FontWeight.w700,
                  color: tokens.profundo,
                  alto: 1.15,
                ),
              ),
              if (subtitulo != null)
                Text(
                  subtitulo!,
                  style: textoMass(tamano: 13, color: tokens.tintaSuave),
                ),
            ],
          ),
        ),
        if (accion != null)
          TextButton(
            onPressed: alAccion,
            child: Text(
              accion!,
              style: textoMass(
                tamano: 13,
                peso: FontWeight.w700,
                color: tokens.accion,
              ),
            ),
          ),
      ],
    );
  }
}
