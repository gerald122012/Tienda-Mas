import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/producto.dart';
import '../../services/carrito_service.dart';
import '../../tema/tema_mass.dart';
import '../../utils/utilidades.dart';
import '../escaner/escaner_herramientas_screen.dart';
import '../inicio/seleccion_inicio.dart';
import 'consulta_catalogo.dart';
import 'tarjeta_producto_cliente.dart';

class CatalogoCliente extends StatefulWidget {
  final List<Producto> productos;
  final bool cargando;
  final bool fallo;
  final TextEditingController busqueda;
  final String categoria;
  final ValueChanged<String> alCategoria;
  final VoidCallback alReintentar;
  final VoidCallback alBolsillo;
  final ValueChanged<List<Producto>> alCanasta;

  const CatalogoCliente({
    super.key,
    required this.productos,
    required this.cargando,
    required this.fallo,
    required this.busqueda,
    required this.categoria,
    required this.alCategoria,
    required this.alReintentar,
    required this.alBolsillo,
    required this.alCanasta,
  });

  @override
  State<CatalogoCliente> createState() => _CatalogoClienteState();
}

class _CatalogoClienteState extends State<CatalogoCliente> {
  OrdenCatalogo _orden = OrdenCatalogo.az;
  var _soloDisponibles = false;
  String? _marca;
  double? _desde;
  double? _hasta;

  ConsultaCatalogo get _consulta => ConsultaCatalogo(
    texto: widget.busqueda.text,
    categoria: widget.categoria,
    orden: _orden,
    soloDisponibles: _soloDisponibles,
    marca: _marca,
    precioDesde: _desde,
    precioHasta: _hasta,
  );

  void _sumar(Producto producto) {
    final ok = CarritoService.instance.agregar(producto);
    if (!ok && mounted) {
      mostrarMensaje(context, 'No hay más stock disponible de este producto.');
    }
  }

  void _limpiarAjustes() {
    setState(() {
      _orden = OrdenCatalogo.az;
      _soloDisponibles = false;
      _marca = null;
      _desde = null;
      _hasta = null;
    });
  }

  void _limpiarTodo() {
    widget.busqueda.clear();
    widget.alCategoria('todas');
    _limpiarAjustes();
  }

  void _abrirFiltros(List<Producto> base) {
    final tokens = TokensMass.de(context);
    final precios = [for (final p in base) p.precio];
    final minimo = precios.isEmpty
        ? 0.0
        : precios.reduce((a, b) => a < b ? a : b);
    final maximo = precios.isEmpty
        ? 0.0
        : precios.reduce((a, b) => a > b ? a : b);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: tokens.superficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MassRadio.superficie),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, refrescar) {
            void cambiar(VoidCallback accion) {
              setState(accion);
              refrescar(() {});
            }

            final desde = _desde ?? minimo;
            final hasta = _hasta ?? maximo;
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.86,
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  shrinkWrap: true,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: tokens.linea,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ordenar y filtrar',
                      style: textoMass(
                        tamano: 20,
                        peso: FontWeight.w700,
                        color: tokens.profundo,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final opcion in OrdenCatalogo.values)
                      _OpcionOrden(
                        titulo: _tituloOrden(opcion),
                        activa: _orden == opcion,
                        alElegir: () => cambiar(() => _orden = opcion),
                      ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Solo disponibles',
                        style: textoMass(tamano: 15, peso: FontWeight.w700),
                      ),
                      value: _soloDisponibles,
                      activeThumbColor: tokens.superficie,
                      activeTrackColor: tokens.accion,
                      onChanged: (v) => cambiar(() => _soloDisponibles = v),
                    ),
                    if (maximo - minimo >= 0.5) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Precio  ${formatoPrecio(desde)} – ${formatoPrecio(hasta)}',
                        style: textoMass(tamano: 14, peso: FontWeight.w700),
                      ),
                      RangeSlider(
                        values: RangeValues(
                          desde.clamp(minimo, maximo),
                          hasta.clamp(minimo, maximo),
                        ),
                        min: minimo,
                        max: maximo,
                        activeColor: tokens.accion,
                        onChanged: (rango) => cambiar(() {
                          _desde = (rango.start - minimo).abs() < 0.05
                              ? null
                              : rango.start;
                          _hasta = (rango.end - maximo).abs() < 0.05
                              ? null
                              : rango.end;
                        }),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _limpiarAjustes();
                              refrescar(() {});
                            },
                            child: const Text('Limpiar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: tokens.accion,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Listo'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final consulta = _consulta;
    final visibles = widget.fallo || widget.cargando
        ? const <Producto>[]
        : productosConsultados(widget.productos, consulta);
    final base = widget.productos.where((producto) {
      return consulta.categoria == 'todas' ||
          producto.categoria == consulta.categoria;
    }).toList();

    return ColoredBox(
      color: tokens.fondo,
      child: Column(
        children: [
          _Encabezado(
            busqueda: widget.busqueda,
            categoria: widget.categoria,
            tieneAjuste: consulta.tieneAjuste,
            alCategoria: widget.alCategoria,
            alFiltros: () => _abrirFiltros(base),
            alCambio: () => setState(() {}),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                if (!widget.cargando && !widget.fallo)
                  SliverToBoxAdapter(
                    child: _Resumen(
                      cantidad: visibles.length,
                      alCanasta: widget.productos.isEmpty
                          ? null
                          : () => widget.alCanasta(widget.productos),
                      alBolsillo: widget.alBolsillo,
                    ),
                  ),
                _Cuerpo(
                  cargando: widget.cargando,
                  fallo: widget.fallo,
                  consulta: consulta,
                  visibles: visibles,
                  alReintentar: widget.alReintentar,
                  alLimpiar: _limpiarTodo,
                  alSumar: _sumar,
                  alRestar: CarritoService.instance.quitarUna,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _tituloOrden(OrdenCatalogo orden) => switch (orden) {
  OrdenCatalogo.az => 'Nombre de A a Z',
  OrdenCatalogo.za => 'Nombre de Z a A',
  OrdenCatalogo.menorPrecio => 'Menor precio',
  OrdenCatalogo.mayorPrecio => 'Mayor precio',
};

class _Encabezado extends StatelessWidget {
  final TextEditingController busqueda;
  final String categoria;
  final bool tieneAjuste;
  final ValueChanged<String> alCategoria;
  final VoidCallback alFiltros;
  final VoidCallback alCambio;

  const _Encabezado({
    required this.busqueda,
    required this.categoria,
    required this.tieneAjuste,
    required this.alCategoria,
    required this.alFiltros,
    required this.alCambio,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final categorias = ['todas', ...Producto.categorias];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Productos',
                  style: textoMass(
                    tamano: 26,
                    peso: FontWeight.w800,
                    color: tokens.profundo,
                    alto: 1.1,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Ordenar y filtrar',
                onPressed: alFiltros,
                icon: Badge(
                  isLabelVisible: tieneAjuste,
                  backgroundColor: tokens.sello,
                  smallSize: 8,
                  child: Icon(
                    Icons.tune_rounded,
                    color: tieneAjuste ? tokens.accion : tokens.profundo,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextField(
              controller: busqueda,
              textInputAction: TextInputAction.search,
              onChanged: (_) => alCambio(),
              style: textoMass(tamano: 15),
              decoration: InputDecoration(
                hintText: 'Busca tus productos favoritos',
                hintStyle: textoMass(tamano: 15, color: tokens.tintaSuave),
                prefixIcon: Icon(Icons.search_rounded, color: tokens.accion),
                suffixIcon: ValueListenableBuilder(
                  valueListenable: busqueda,
                  builder: (context, valor, _) {
                    if (valor.text.isNotEmpty) {
                      return IconButton(
                        tooltip: 'Limpiar búsqueda',
                        onPressed: () {
                          busqueda.clear();
                          alCambio();
                        },
                        icon: Icon(
                          Icons.close_rounded,
                          color: tokens.tintaSuave,
                        ),
                      );
                    }
                    return IconButton(
                      tooltip: 'Buscar con código de barras',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const EscanerHerramientasScreen(tabInicial: 1),
                        ),
                      ),
                      icon: Icon(
                        Icons.qr_code_scanner_rounded,
                        color: tokens.accion,
                      ),
                    );
                  },
                ),
                filled: true,
                fillColor: tokens.superficie,
                isDense: true,
                constraints: const BoxConstraints(minHeight: 48),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: _borde(tokens.linea),
                enabledBorder: _borde(tokens.linea),
                focusedBorder: _borde(tokens.accion, 1.4),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: Stack(
              children: [
                ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: 28),
                  itemCount: categorias.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final id = categorias[i];
                    final nombre = id == 'todas'
                        ? 'Todas'
                        : etiquetaCategoria(id);
                    return _ChipCategoria(
                      nombre: nombre,
                      activa: categoria == id,
                      alElegir: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        HapticFeedback.selectionClick();
                        alCategoria(id);
                      },
                    );
                  },
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 28,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            tokens.fondo.withValues(alpha: 0),
                            tokens.fondo,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  OutlineInputBorder _borde(Color color, [double ancho = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(MassRadio.control),
      borderSide: BorderSide(color: color, width: ancho),
    );
  }
}

class _ChipCategoria extends StatelessWidget {
  final String nombre;
  final bool activa;
  final VoidCallback alElegir;

  const _ChipCategoria({
    required this.nombre,
    required this.activa,
    required this.alElegir,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final reducir = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      selected: activa,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: alElegir,
          child: AnimatedContainer(
            duration: Duration(milliseconds: reducir ? 0 : 160),
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: activa ? tokens.accion : tokens.superficie,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: activa ? tokens.accion : tokens.linea),
            ),
            child: Text(
              nombre,
              style: textoMass(
                tamano: 13,
                peso: FontWeight.w700,
                color: activa ? Colors.white : tokens.tinta,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  final int cantidad;
  final VoidCallback? alCanasta;
  final VoidCallback alBolsillo;

  const _Resumen({
    required this.cantidad,
    required this.alCanasta,
    required this.alBolsillo,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final carrito = CarritoService.instance;
    final texto = cantidad == 1 ? '1 producto' : '$cantidad productos';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  texto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textoMass(
                    tamano: 13,
                    peso: FontWeight.w700,
                    color: tokens.tintaSuave,
                  ),
                ),
              ),
              if (alCanasta != null)
                TextButton(
                  onPressed: alCanasta,
                  style: TextButton.styleFrom(
                    foregroundColor: tokens.accion,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(48, 48),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Canasta Express',
                    style: textoMass(
                      tamano: 13,
                      peso: FontWeight.w700,
                      color: tokens.accion,
                    ),
                  ),
                ),
            ],
          ),
          ListenableBuilder(
            listenable: carrito,
            builder: (context, _) => _Bolsillo(alAbrir: alBolsillo),
          ),
        ],
      ),
    );
  }
}

class _Bolsillo extends StatelessWidget {
  final VoidCallback alAbrir;

  const _Bolsillo({required this.alAbrir});

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final carrito = CarritoService.instance;
    final meta = carrito.presupuesto;
    if (meta == null) {
      return _linea(
        tokens,
        icono: Icons.savings_outlined,
        texto: 'Modo Bolsillo',
        accion: 'Fijar',
        color: tokens.accion,
      );
    }
    final progreso = (carrito.total / meta).clamp(0.0, 1.0);
    final excedido = carrito.excedePresupuesto;
    final color = excedido ? tokens.error : tokens.exito;
    final detalle = excedido
        ? 'Excediste el presupuesto por ${formatoPrecio(carrito.total - meta)}'
        : 'Te quedan ${formatoPrecio(carrito.restantePresupuesto ?? 0)}';
    return Material(
      color: tokens.superficie,
      borderRadius: BorderRadius.circular(MassRadio.control),
      child: InkWell(
        borderRadius: BorderRadius.circular(MassRadio.control),
        onTap: alAbrir,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MassRadio.control),
            border: Border.all(color: tokens.linea),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.savings_rounded, size: 18, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      detalle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textoMass(
                        tamano: 13,
                        peso: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                  Text(
                    formatoPrecio(meta),
                    style: textoMass(
                      tamano: 12,
                      peso: FontWeight.w700,
                      color: tokens.tintaSuave,
                      tabular: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progreso,
                  minHeight: 4,
                  backgroundColor: tokens.linea,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _linea(
    TokensMass tokens, {
    required IconData icono,
    required String texto,
    required String accion,
    required Color color,
  }) {
    return Material(
      color: tokens.superficie,
      borderRadius: BorderRadius.circular(MassRadio.control),
      child: InkWell(
        borderRadius: BorderRadius.circular(MassRadio.control),
        onTap: alAbrir,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MassRadio.control),
            border: Border.all(color: tokens.linea),
          ),
          child: Row(
            children: [
              Icon(icono, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  texto,
                  style: textoMass(
                    tamano: 13,
                    peso: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              Text(
                accion,
                style: textoMass(
                  tamano: 13,
                  peso: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cuerpo extends StatelessWidget {
  final bool cargando;
  final bool fallo;
  final ConsultaCatalogo consulta;
  final List<Producto> visibles;
  final VoidCallback alReintentar;
  final VoidCallback alLimpiar;
  final ValueChanged<Producto> alSumar;
  final ValueChanged<Producto> alRestar;

  const _Cuerpo({
    required this.cargando,
    required this.fallo,
    required this.consulta,
    required this.visibles,
    required this.alReintentar,
    required this.alLimpiar,
    required this.alSumar,
    required this.alRestar,
  });

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const SliverToBoxAdapter(child: _Espera());
    }
    if (fallo || visibles.isEmpty) {
      final busco =
          !fallo &&
          (consulta.texto.trim().isNotEmpty ||
              consulta.tieneAjuste ||
              consulta.categoria != 'todas');
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _Aviso(
          icono: fallo
              ? Icons.cloud_off_rounded
              : busco
              ? Icons.search_off_rounded
              : Icons.inventory_2_outlined,
          titulo: fallo
              ? 'No pudimos cargar los productos'
              : busco
              ? 'No hay coincidencias'
              : 'Todavía no hay productos',
          detalle: fallo
              ? 'Revisa tu conexión e inténtalo de nuevo.'
              : busco
              ? 'Prueba con otro nombre, marca o quita los filtros.'
              : 'Cuando el catálogo tenga artículos, aparecerán aquí.',
          accion: fallo
              ? 'Reintentar'
              : busco
              ? 'Limpiar búsqueda'
              : null,
          alAccion: fallo
              ? alReintentar
              : busco
              ? alLimpiar
              : null,
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final ancho = constraints.crossAxisExtent;
          final columnas = columnasCatalogo(ancho + 32);
          if (columnas == 1) {
            return SliverList.separated(
              itemCount: visibles.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _Tarjeta(
                producto: visibles[i],
                horizontal: true,
                alSumar: alSumar,
                alRestar: alRestar,
              ),
            );
          }
          final celda = (ancho - 12 * (columnas - 1)) / columnas;
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columnas,
              mainAxisExtent: celda + 150,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _Tarjeta(
                producto: visibles[i],
                alSumar: alSumar,
                alRestar: alRestar,
              ),
              childCount: visibles.length,
            ),
          );
        },
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  final Producto producto;
  final bool horizontal;
  final ValueChanged<Producto> alSumar;
  final ValueChanged<Producto> alRestar;

  const _Tarjeta({
    required this.producto,
    required this.alSumar,
    required this.alRestar,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CarritoService.instance,
      builder: (context, _) {
        return TarjetaProductoCliente(
          producto: producto,
          horizontal: horizontal,
          cantidad: CarritoService.instance.cantidadDe(producto),
          alAgregar: () => alSumar(producto),
          alQuitar: () => alRestar(producto),
        );
      },
    );
  }
}

class _Espera extends StatelessWidget {
  const _Espera();

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(
        children: [
          for (var i = 0; i < 2; i++)
            Expanded(
              child: Container(
                height: 220,
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

class _Aviso extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String detalle;
  final String? accion;
  final VoidCallback? alAccion;

  const _Aviso({
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.accion,
    required this.alAccion,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 36, color: tokens.accion),
            const SizedBox(height: 12),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: textoMass(
                tamano: 18,
                peso: FontWeight.w700,
                color: tokens.profundo,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              detalle,
              textAlign: TextAlign.center,
              style: textoMass(
                tamano: 14,
                color: tokens.tintaSuave,
                alto: 1.35,
              ),
            ),
            if (accion != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: tokens.accion,
                  foregroundColor: Colors.white,
                ),
                onPressed: alAccion,
                child: Text(accion!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OpcionOrden extends StatelessWidget {
  final String titulo;
  final bool activa;
  final VoidCallback alElegir;

  const _OpcionOrden({
    required this.titulo,
    required this.activa,
    required this.alElegir,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return InkWell(
      onTap: alElegir,
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            Icon(
              activa ? Icons.radio_button_checked : Icons.radio_button_off,
              color: activa ? tokens.accion : tokens.tintaSuave,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                titulo,
                style: textoMass(
                  tamano: 15,
                  peso: activa ? FontWeight.w700 : FontWeight.w500,
                  color: tokens.tinta,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
