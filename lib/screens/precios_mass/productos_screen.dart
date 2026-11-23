import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/producto.dart';
import '../../services/carrito_service.dart';
import '../../services/catalogo_inicial_service.dart';
import '../../services/firebase_service.dart';
import '../../utils/utilidades.dart';
import '../../widgets/aparecer.dart';
import '../../widgets/producto_catalogo_card.dart';
import '../escaner/escaner_herramientas_screen.dart';
import 'producto_form_screen.dart';

class ProductosScreen extends StatefulWidget {
  final bool esAdmin;

  const ProductosScreen({super.key, this.esAdmin = false});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final _servicio = FirebaseService('productos_mass');
  late final _datos = _servicio.coleccion.snapshots();
  List<Producto> _respaldo = const [];
  String _categoriaFiltro = 'todas';
  String _busqueda = '';
  final _carrito = CarritoService.instance;

  @override
  void initState() {
    super.initState();
    _cargarRespaldo();
  }

  Future<void> _cargarRespaldo() async {
    try {
      final lista = await CatalogoInicialService.productosLocales();
      if (mounted) setState(() => _respaldo = lista);
    } catch (_) {}
  }

  void _agregar(Producto producto) {
    final ok = _carrito.agregar(producto);
    mostrarMensaje(
      context,
      ok
          ? '${producto.nombre} agregado al carrito'
          : 'No hay más stock disponible de este producto.',
    );
  }

  void _abrirFormulario([Producto? producto]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductoFormScreen(producto: producto)),
    );
  }

  void _duplicar(Producto producto) {
    _abrirFormulario(Producto.fromMap('', producto.toMap()));
  }

  Future<void> _eliminar(Producto producto) async {
    if (!await confirmarEliminar(context, producto.nombre)) return;
    try {
      await _servicio.eliminar(producto.id);
      if (!mounted) return;
      mostrarDeshacer(
        context,
        'Producto eliminado del catálogo',
        () => _servicio.restaurar(producto.id, producto.toMap()),
      );
    } catch (_) {
      if (mounted) {
        mostrarMensaje(
          context,
          'No se pudo eliminar. Revisa tu conexión e inténtalo de nuevo.',
        );
      }
    }
  }

  Future<void> _configurarPresupuesto() async {
    final ctrl = TextEditingController(
      text: _carrito.presupuesto?.toStringAsFixed(0) ?? '40',
    );
    final resultado = await showDialog<double?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Modo Bolsillo Mass',
          style: TextStyle(color: kMassBlue, fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Define cuánto deseas gastar hoy y te avisaremos en tiempo real cuánto te queda disponible.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Presupuesto máximo (S/)',
                prefixIcon: Icon(Icons.savings_outlined),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: [
                for (final monto in [20, 40, 60, 100])
                  ActionChip(
                    label: Text('S/ $monto'),
                    onPressed: () => ctrl.text = '$monto',
                  ),
              ],
            ),
          ],
        ),
        actions: [
          if (_carrito.presupuesto != null)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 0.0),
              child: const Text('Desactivar'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, leerDouble(ctrl.text)),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (resultado != null) {
      _carrito.setPresupuesto(resultado > 0 ? resultado : null);
    }
  }

  void _abrirCanastaExpress(List<Producto> disponibles) {
    if (disponibles.isEmpty) {
      mostrarMensaje(context, 'No hay productos disponibles para armar combo.');
      return;
    }
    var presupuesto = _carrito.presupuesto ?? 30.0;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kMassCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final ordenados =
              disponibles.where((p) => p.disponible && p.stock > 0).toList()
                ..sort((a, b) => a.precio.compareTo(b.precio));
          final combo = <Producto>[];
          var suma = 0.0;
          final categoriasUsadas = <String>{};
          for (final p in ordenados) {
            if (!categoriasUsadas.contains(p.categoria) &&
                suma + p.precio <= presupuesto) {
              combo.add(p);
              suma += p.precio;
              categoriasUsadas.add(p.categoria);
            }
          }
          for (final p in ordenados) {
            if (!combo.contains(p) && suma + p.precio <= presupuesto) {
              combo.add(p);
              suma += p.precio;
            }
            if (combo.length >= 6) break;
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: kMassBlue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Canasta Express Inteligente',
                          style: TextStyle(
                            color: kMassBlue,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Presupuesto objetivo: ${formatoPrecio(presupuesto)}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Slider(
                    value: presupuesto.clamp(10, 150),
                    min: 10,
                    max: 150,
                    divisions: 28,
                    activeColor: kMassBlue,
                    label: formatoPrecio(presupuesto),
                    onChanged: (v) => setModal(() => presupuesto = v),
                  ),
                  if (combo.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Sube el presupuesto para sugerirte una canasta balanceada.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else ...[
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: combo.length,
                        itemBuilder: (_, i) {
                          final p = combo[i];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.check_circle,
                              color: kMassBlue,
                              size: 20,
                            ),
                            title: Text(
                              p.nombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              formatoPrecio(p.precio),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: kMassBlue,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${combo.length} productos sugeridos',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        precioUnaLinea(
                          'Total ${formatoPrecio(suma)}',
                          style: const TextStyle(
                            color: kMassBlue,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                          alignment: Alignment.centerRight,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () {
                        for (final p in combo) {
                          _carrito.agregar(p);
                        }
                        Navigator.pop(ctx);
                        mostrarMensaje(
                          context,
                          '¡Canasta Express (${combo.length} prod.) agregada al carrito!',
                        );
                      },
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('AGREGAR CANASTA AL CARRITO'),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _normalizar(String texto) {
    var resultado = texto.toLowerCase();
    const conTilde = 'áéíóúü';
    const sinTilde = 'aeiouu';
    for (var i = 0; i < conTilde.length; i++) {
      resultado = resultado.replaceAll(conTilde[i], sinTilde[i]);
    }
    return resultado;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMassCream,
      floatingActionButton: widget.esAdmin
          ? FloatingActionButton.extended(
              heroTag: 'productos_mass',
              onPressed: () => _abrirFormulario(),
              icon: const Icon(Icons.add),
              label: const Text('NUEVO PRODUCTO'),
            )
          : null,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              color: kMassBlue,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tu tienda, a un toque',
                  style: TextStyle(
                    color: kMassYellow,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  onChanged: (valor) =>
                      setState(() => _busqueda = valor.trim()),
                  decoration: InputDecoration(
                    hintText: 'Buscar productos, marcas o código',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      tooltip: 'Buscar con código de barras',
                      icon: const Icon(Icons.barcode_reader, color: kMassBlue),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const EscanerHerramientasScreen(tabInicial: 1),
                        ),
                      ),
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    spacing: 6,
                    children: [
                      _chipCategoria('todas', 'Todas'),
                      ...Producto.categorias.map(
                        (c) => _chipCategoria(
                          c,
                          c[0].toUpperCase() + c.substring(1),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!widget.esAdmin)
            ListenableBuilder(
              listenable: _carrito,
              builder: (context, _) => _barraModoBolsillo(),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _datos,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No se pudo cargar el catálogo. Revisa tu conexión a internet.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                final todos = docs.isEmpty && !widget.esAdmin
                    ? _respaldo
                    : docs
                          .map((doc) => Producto.fromMap(doc.id, doc.data()))
                          .toList();
                final consulta = _normalizar(_busqueda);
                final productos =
                    todos
                        .where(
                          (p) =>
                              (_categoriaFiltro == 'todas' ||
                                  p.categoria == _categoriaFiltro) &&
                              _normalizar(
                                '${p.nombre} ${p.marca} ${p.categoria} ${p.codigoBarras}',
                              ).contains(consulta),
                        )
                        .toList()
                      ..sort((a, b) => a.nombre.compareTo(b.nombre));

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 12, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${productos.length} productos',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: kMassBlue,
                              ),
                            ),
                          ),
                          if (!widget.esAdmin && todos.isNotEmpty)
                            TextButton.icon(
                              onPressed: () => _abrirCanastaExpress(todos),
                              icon: const Icon(Icons.auto_awesome, size: 17),
                              label: const Text('Canasta Express'),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: productos.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.inventory_2_outlined,
                                      size: 58,
                                      color: kMassBlue,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      todos.isEmpty
                                          ? 'Aún no hay productos registrados en el catálogo.'
                                          : 'No encontramos productos con esos filtros.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: kMassBlue,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (widget.esAdmin && todos.isEmpty) ...[
                                      const SizedBox(height: 12),
                                      FilledButton.icon(
                                        onPressed: () => _abrirFormulario(),
                                        icon: const Icon(Icons.add),
                                        label: const Text(
                                          'AGREGAR PRIMER PRODUCTO',
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                final columnas = (constraints.maxWidth / 180)
                                    .floor()
                                    .clamp(1, 6);
                                return GridView.builder(
                                  padding: EdgeInsets.fromLTRB(
                                    12,
                                    4,
                                    12,
                                    widget.esAdmin ? 88 : 20,
                                  ),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: columnas,
                                        mainAxisExtent: 365,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                      ),
                                  itemCount: productos.length,
                                  itemBuilder: (context, i) {
                                    return Aparecer(
                                      indice: i,
                                      child: _tarjeta(productos[i]),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _barraModoBolsillo() {
    final presupuesto = _carrito.presupuesto;
    if (presupuesto == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _configurarPresupuesto,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: kMassMint,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kMassBlue.withValues(alpha: 0.16)),
            ),
            child: const Row(
              children: [
                Icon(Icons.savings_outlined, color: kMassBlue, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Activa Modo Bolsillo para controlar tu presupuesto en vivo',
                    style: TextStyle(
                      color: kMassBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  'Fijar',
                  style: TextStyle(
                    color: kMassBlue,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final progreso = (_carrito.total / presupuesto).clamp(0.0, 1.0);
    final excedido = _carrito.excedePresupuesto;
    final color = excedido
        ? Colors.red.shade700
        : progreso > 0.8
        ? Colors.orange.shade800
        : Colors.green.shade700;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _configurarPresupuesto,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.savings_rounded, color: color, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      excedido
                          ? 'Excediste tu presupuesto por ${formatoPrecio(_carrito.total - presupuesto)}'
                          : 'Modo Bolsillo · Te quedan ${formatoPrecio(_carrito.restantePresupuesto ?? 0)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    'Meta ${formatoPrecio(presupuesto)}',
                    style: const TextStyle(
                      color: kMassBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progreso,
                  minHeight: 7,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tarjeta(Producto producto) {
    if (!widget.esAdmin) {
      return ListenableBuilder(
        listenable: _carrito,
        builder: (context, _) => ProductoCatalogoCard(
          producto: producto,
          enCarrito: _carrito.cantidadDe(producto),
          onAgregar: () => _agregar(producto),
        ),
      );
    }
    return ProductoCatalogoCard(
      producto: producto,
      onEditar: () => _abrirFormulario(producto),
      onDuplicar: () => _duplicar(producto),
      onEliminar: () => _eliminar(producto),
    );
  }

  Widget _chipCategoria(String valor, String texto) {
    final activo = _categoriaFiltro == valor;
    return ChoiceChip(
      label: Text(
        texto,
        style: TextStyle(
          color: activo ? kMassBlue : Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      selected: activo,
      selectedColor: kMassYellow,
      backgroundColor: kMassBlue,
      side: const BorderSide(color: kMassYellow),
      showCheckmark: false,
      onSelected: (_) => setState(() => _categoriaFiltro = valor),
    );
  }
}
