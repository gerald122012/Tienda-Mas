import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/producto.dart';
import '../../services/firebase_service.dart';
import '../../tema/tema_gestion.dart';
import '../../utils/utilidades.dart';
import '../../widgets/foto_producto.dart';
import '../precios_mass/producto_form_screen.dart';
import 'piezas_gestion.dart';

enum _OrdenProducto { nombre, precioMenor, precioMayor, stockMenor, stockMayor }

class GestionProductos extends StatefulWidget {
  const GestionProductos({super.key});

  @override
  State<GestionProductos> createState() => _GestionProductosState();
}

class _GestionProductosState extends State<GestionProductos> {
  final _servicio = FirebaseService('productos_mass');
  final _busqueda = TextEditingController();
  String _categoria = 'todas';
  String _disponibilidad = 'todas';
  _OrdenProducto _orden = _OrdenProducto.nombre;

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  void _abrir([Producto? producto]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductoFormScreen(producto: producto)),
    );
  }

  void _duplicar(Producto producto) => _abrir(Producto.fromMap('', producto.toMap()));

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
        mostrarMensaje(context, 'No se pudo eliminar. Revisa tu conexión e inténtalo de nuevo.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PaginaGestion(
      titulo: 'Productos e inventario',
      detalle: 'Catálogo registrado. El stock es la cantidad guardada, no una reserva.',
      accion: FilledButton.icon(
        onPressed: () => _abrir(),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Nuevo producto'),
      ),
      child: Column(
        children: [
          _filtros(),
          const SizedBox(height: 14),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _servicio.coleccion.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const EstadoGestion(
                    icono: Icons.cloud_off_rounded,
                    titulo: 'No pudimos consultar los productos',
                    mensaje: 'Revisa la conexión e inténtalo nuevamente.',
                  );
                }
                if (!snapshot.hasData) return const CargandoGestion();
                final todos = snapshot.data!.docs
                    .map((doc) => Producto.fromMap(doc.id, doc.data()))
                    .toList();
                final visibles = _filtrar(todos);
                if (todos.isEmpty) {
                  return const EstadoGestion(
                    icono: Icons.inventory_2_outlined,
                    titulo: 'No hay productos registrados',
                    mensaje: 'Crea el primero o carga el catálogo inicial desde el resumen.',
                  );
                }
                if (visibles.isEmpty) {
                  return const EstadoGestion(
                    icono: Icons.search_off_rounded,
                    titulo: 'Ningún producto coincide',
                    mensaje: 'Prueba con otro nombre, categoría o disponibilidad.',
                  );
                }
                return SuperficieGestion(child: _tabla(visibles));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtros() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            controller: _busqueda,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Buscar por nombre, marca o código',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        _menu(
          valor: _categoria,
          opciones: ['todas', ...Producto.categorias],
          etiqueta: (valor) => valor == 'todas' ? 'Todas las categorías' : valor,
          alElegir: (valor) => setState(() => _categoria = valor),
        ),
        _menu(
          valor: _disponibilidad,
          opciones: const ['todas', 'disponibles', 'agotados'],
          etiqueta: (valor) => switch (valor) {
            'disponibles' => 'Disponibles',
            'agotados' => 'Agotados',
            _ => 'Toda la disponibilidad',
          },
          alElegir: (valor) => setState(() => _disponibilidad = valor),
        ),
        _menu(
          valor: _orden.name,
          opciones: _OrdenProducto.values.map((orden) => orden.name).toList(),
          etiqueta: (valor) => switch (_OrdenProducto.values.byName(valor)) {
            _OrdenProducto.nombre => 'Nombre',
            _OrdenProducto.precioMenor => 'Menor precio',
            _OrdenProducto.precioMayor => 'Mayor precio',
            _OrdenProducto.stockMenor => 'Menor stock',
            _OrdenProducto.stockMayor => 'Mayor stock',
          },
          alElegir: (valor) => setState(() => _orden = _OrdenProducto.values.byName(valor)),
        ),
      ],
    );
  }

  Widget _menu({
    required String valor,
    required List<String> opciones,
    required String Function(String) etiqueta,
    required ValueChanged<String> alElegir,
  }) {
    return PopupMenuButton<String>(
      onSelected: alElegir,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: GestionColores.superficie,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GestionColores.linea),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(etiqueta(valor), style: textoGestion(peso: FontWeight.w700)),
            const SizedBox(width: 6),
            const Icon(Icons.expand_more, size: 18, color: GestionColores.tintaSuave),
          ],
        ),
      ),
      itemBuilder: (_) => [
        for (final opcion in opciones)
          PopupMenuItem(value: opcion, child: Text(etiqueta(opcion))),
      ],
    );
  }

  List<Producto> _filtrar(List<Producto> productos) {
    final consulta = _busqueda.text.trim().toLowerCase();
    final lista = productos.where((producto) {
      final texto = '${producto.nombre} ${producto.marca} ${producto.codigoBarras}'.toLowerCase();
      final categoriaOk = _categoria == 'todas' || producto.categoria == _categoria;
      final disponible = producto.disponible && producto.stock > 0;
      final disponibilidadOk = switch (_disponibilidad) {
        'disponibles' => disponible,
        'agotados' => producto.stock <= 0,
        _ => true,
      };
      return categoriaOk && disponibilidadOk && (consulta.isEmpty || texto.contains(consulta));
    }).toList();
    lista.sort((a, b) => switch (_orden) {
      _OrdenProducto.nombre => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
      _OrdenProducto.precioMenor => a.precio.compareTo(b.precio),
      _OrdenProducto.precioMayor => b.precio.compareTo(a.precio),
      _OrdenProducto.stockMenor => a.stock.compareTo(b.stock),
      _OrdenProducto.stockMayor => b.stock.compareTo(a.stock),
    });
    return lista;
  }

  Widget _tabla(List<Producto> productos) {
    return Scrollbar(
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1180),
            child: Column(
              children: [
                _encabezado(),
                for (final producto in productos) _fila(producto),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _encabezado() {
    return ColoredBox(
      color: GestionColores.fondo,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            _celda('Foto', 64),
            _celda('Código', 120),
            _celda('Nombre', 240),
            _celda('Marca', 120),
            _celda('Categoría', 110),
            _celda('Presentación', 150),
            _celda('Precio', 90),
            _celda('Stock', 70),
            _celda('Disponibilidad', 130),
            _celda('Acciones', 140),
          ],
        ),
      ),
    );
  }

  Widget _fila(Producto producto) {
    final disponible = producto.disponible && producto.stock > 0;
    final presentacion = producto.presentaciones.isEmpty
        ? '—'
        : producto.presentaciones.join(', ');
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: GestionColores.linea)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: GestionColores.fondo,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FotoProducto(producto: producto),
              ),
            ),
          ),
          _texto(producto.codigoBarras.isEmpty ? '—' : producto.codigoBarras, 120),
          _texto(producto.nombre, 240, fuerte: true),
          _texto(producto.marca, 120),
          _texto(producto.categoria, 110),
          _texto(presentacion, 150),
          _texto(formatoPrecio(producto.precio), 90),
          _texto('${producto.stock}', 70),
          SizedBox(
            width: 130,
            child: ChipGestion(
              texto: disponible ? 'Disponible' : producto.stock <= 0 ? 'Agotado' : 'No disponible',
              color: disponible ? GestionColores.exito : GestionColores.error,
              icono: disponible ? Icons.check_rounded : Icons.remove_rounded,
            ),
          ),
          SizedBox(
            width: 140,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Editar ${producto.nombre}',
                  onPressed: () => _abrir(producto),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
                IconButton(
                  tooltip: 'Duplicar ${producto.nombre}',
                  onPressed: () => _duplicar(producto),
                  icon: const Icon(Icons.copy_outlined, size: 18),
                ),
                IconButton(
                  tooltip: 'Eliminar ${producto.nombre}',
                  onPressed: () => _eliminar(producto),
                  icon: const Icon(Icons.delete_outline, size: 18, color: GestionColores.error),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _celda(String texto, double ancho) {
    return SizedBox(
      width: ancho,
      child: Text(
        texto,
        style: textoGestion(tamano: 12, peso: FontWeight.w800, color: GestionColores.tintaSuave),
      ),
    );
  }

  Widget _texto(String texto, double ancho, {bool fuerte = false}) {
    return SizedBox(
      width: ancho,
      child: Text(
        texto,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: textoGestion(peso: fuerte ? FontWeight.w700 : FontWeight.w500),
      ),
    );
  }
}
