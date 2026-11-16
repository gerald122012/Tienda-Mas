import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/producto.dart';
import '../../services/carrito_service.dart';
import '../../services/firebase_service.dart';
import '../../utils/utilidades.dart';
import '../../widgets/aparecer.dart';
import '../../widgets/producto_catalogo_card.dart';
import '../carrito/carrito_screen.dart';
import 'producto_form_screen.dart';

class ProductosScreen extends StatefulWidget {
  // Administrador: edita el catálogo. Cliente: solo compra.
  final bool esAdmin;

  const ProductosScreen({super.key, this.esAdmin = false});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final _servicio = FirebaseService('productos_mass');
  late final _datos = _servicio.coleccion.snapshots();
  late final _ejemplos = Producto.ejemplos();
  String _categoriaFiltro = 'todas';
  String _busqueda = '';
  bool _importando = false;
  final _carrito = CarritoService.instance;

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
        'Producto eliminado de la bodega',
        () => _servicio.restaurar(producto.id, producto.toMap()),
      );
    } catch (_) {
      if (mounted) {
        mostrarMensaje(
          context,
          'No se pudo eliminar. Revisa la conexión e inténtalo de nuevo.',
        );
      }
    }
  }

  Future<void> _cargarEjemplos() async {
    if (_importando) return;
    setState(() => _importando = true);
    try {
      // La transacción evita duplicar o sobrescribir productos ya importados,
      // incluso si dos personas cargan el catálogo al mismo tiempo.
      final cantidad = await FirebaseFirestore.instance.runTransaction<int>((
        tx,
      ) async {
        final referencias = _ejemplos
            .map((p) => _servicio.coleccion.doc(p.id))
            .toList();
        final existentes = <DocumentSnapshot<Map<String, dynamic>>>[];
        for (final ref in referencias) {
          existentes.add(await tx.get(ref));
        }
        var nuevos = 0;
        for (var i = 0; i < referencias.length; i++) {
          if (!existentes[i].exists) {
            tx.set(referencias[i], _ejemplos[i].toMap());
            nuevos++;
          }
        }
        return nuevos;
      });
      if (mounted) {
        mostrarMensaje(
          context,
          cantidad == 0
              ? 'Los 40 productos de ejemplo ya están guardados.'
              : '$cantidad productos de ejemplo guardados en Firebase.',
        );
      }
    } catch (_) {
      if (mounted) {
        mostrarMensaje(
          context,
          'No se pudo guardar el catálogo. Revisa la conexión y los permisos de Firebase.',
        );
      }
    } finally {
      if (mounted) setState(() => _importando = false);
    }
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
          : ListenableBuilder(
              listenable: _carrito,
              builder: (context, _) => FloatingActionButton.extended(
                heroTag: 'carrito_mass',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CarritoScreen()),
                ),
                icon: Badge(
                  isLabelVisible: _carrito.unidades > 0,
                  label: Text('${_carrito.unidades}'),
                  child: const Icon(Icons.shopping_cart),
                ),
                label: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: Text(
                    _carrito.vacio
                        ? 'CARRITO'
                        : 'CARRITO · S/ ${_carrito.total.toStringAsFixed(2)}',
                    key: ValueKey(_carrito.total),
                  ),
                ),
              ),
            ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Explora productos para todos los días',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (valor) =>
                      setState(() => _busqueda = valor.trim()),
                  decoration: const InputDecoration(
                    hintText: 'Buscar productos o marcas',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(),
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
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _datos,
              builder: (context, snapshot) {
                final locales =
                    !snapshot.hasData ||
                    snapshot.hasError ||
                    snapshot.data!.docs.isEmpty;
                final todos = locales
                    ? _ejemplos
                    : snapshot.data!.docs
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
                                '${p.nombre} ${p.marca} ${p.categoria}',
                              ).contains(consulta),
                        )
                        .toList()
                      ..sort((a, b) => a.nombre.compareTo(b.nombre));
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
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
                          if (widget.esAdmin && (locales || todos.length < 40))
                            TextButton.icon(
                              onPressed: _importando ? null : _cargarEjemplos,
                              icon: _importando
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.cloud_upload_outlined,
                                      size: 18,
                                    ),
                              label: Text(
                                _importando
                                    ? 'Guardando…'
                                    : 'Cargar 40 ejemplos',
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (locales || todos.any((p) => p.esEjemplo))
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            snapshot.hasError
                                ? 'Sin conexión con Firebase. Mostrando ejemplos locales.'
                                : locales
                                ? 'Catálogo de ejemplo · precios referenciales · aún sin guardar'
                                : 'Precios referenciales para este catálogo.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: productos.isEmpty
                          ? const Center(
                              child: Text(
                                'No encontramos productos con esos filtros.',
                              ),
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                final columnas = (constraints.maxWidth / 180)
                                    .floor()
                                    .clamp(1, 6);
                                return GridView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    4,
                                    12,
                                    88,
                                  ),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: columnas,
                                        mainAxisExtent: 380,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                      ),
                                  itemCount: productos.length,
                                  itemBuilder: (context, i) {
                                    return Aparecer(
                                      indice: i,
                                      child: _tarjeta(productos[i], locales),
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

  Widget _tarjeta(Producto producto, bool locales) {
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
      onEditar: () =>
          locales ? _duplicar(producto) : _abrirFormulario(producto),
      onDuplicar: locales ? null : () => _duplicar(producto),
      onEliminar: locales ? null : () => _eliminar(producto),
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
