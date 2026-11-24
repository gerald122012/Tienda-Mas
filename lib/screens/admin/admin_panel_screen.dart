import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/cupon.dart';
import '../../models/pedido.dart';
import '../../models/producto.dart';
import '../../models/tienda.dart';
import '../../services/catalogo_inicial_service.dart';
import '../../tema/tema_gestion.dart';
import '../../utils/utilidades.dart';
import 'conteo_gestion.dart';
import 'piezas_gestion.dart';

class AdminPanelScreen extends StatefulWidget {
  final ValueChanged<int> onCambiarPestana;

  const AdminPanelScreen({super.key, required this.onCambiarPestana});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _subs = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];
  List<Producto>? _productos;
  List<Pedido>? _pedidos;
  List<Tienda>? _tiendas;
  List<CuponDescuento>? _cupones;
  int? _locales;
  String? _error;
  bool _cargandoCatalogo = false;

  @override
  void initState() {
    super.initState();
    _escuchar('productos_mass', (docs) {
      _productos = docs.map((d) => Producto.fromMap(d.id, d.data())).toList();
    });
    _escuchar('pedidos', (docs) {
      _pedidos = docs.map((d) => Pedido.fromMap(d.id, d.data())).toList();
    });
    _escuchar('tiendas_mass', (docs) {
      _tiendas = docs.map((d) => Tienda.fromMap(d.id, d.data())).toList();
    });
    _escuchar('cupones_mass', (docs) {
      _cupones = docs.map((d) => CuponDescuento.fromMap(d.id, d.data())).toList();
    });
    _escuchar('locales_mass', (docs) => _locales = docs.length);
  }

  void _escuchar(
    String coleccion,
    void Function(List<QueryDocumentSnapshot<Map<String, dynamic>>>) aplicar,
  ) {
    final sub = FirebaseFirestore.instance.collection(coleccion).snapshots().listen(
      (snap) {
        if (!mounted) return;
        setState(() {
          _error = null;
          aplicar(snap.docs);
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _error = 'No pudimos consultar $coleccion.');
      },
    );
    _subs.add(sub);
  }

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    super.dispose();
  }

  Future<void> _cargarCatalogoInicial() async {
    setState(() => _cargandoCatalogo = true);
    try {
      final nuevos = await CatalogoInicialService.cargar();
      if (!mounted) return;
      mostrarMensaje(
        context,
        nuevos == 0
            ? 'El catálogo ya tenía los 50 productos.'
            : '$nuevos productos cargados en Firebase.',
      );
    } catch (_) {
      if (mounted) {
        mostrarMensaje(
          context,
          'No se pudo cargar. Ingresa con una cuenta administradora de Firebase.',
        );
      }
    } finally {
      if (mounted) setState(() => _cargandoCatalogo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listo = _productos != null &&
        _pedidos != null &&
        _tiendas != null &&
        _cupones != null &&
        _locales != null;
    return PaginaGestion(
      titulo: 'Resumen ejecutivo',
      detalle: 'Cifras leídas de los registros actuales. Un pedido registrado no es un cobro.',
      child: !listo && _error == null
          ? const CargandoGestion()
          : _error != null && !listo
          ? EstadoGestion(
              icono: Icons.cloud_off_rounded,
              titulo: 'No pudimos abrir el resumen',
              mensaje: _error!,
            )
          : _contenido(
              ConteoGestion.desde(
                productos: _productos!,
                pedidos: _pedidos!,
                tiendas: _tiendas!,
                cupones: _cupones!,
                locales: _locales!,
              ),
            ),
    );
  }

  Widget _contenido(ConteoGestion conteo) {
    return ListView(
      children: [
        _grilla([
          TarjetaIndicador(
            icono: Icons.inventory_2_outlined,
            etiqueta: 'Productos registrados',
            valor: '${conteo.productos}',
            detalle: 'Documentos del catálogo',
          ),
          TarjetaIndicador(
            icono: Icons.check_circle_outline,
            etiqueta: 'Productos disponibles',
            valor: '${conteo.disponibles}',
            detalle: 'Marcados disponibles y con stock',
          ),
          TarjetaIndicador(
            icono: Icons.remove_shopping_cart_outlined,
            etiqueta: 'Productos agotados',
            valor: '${conteo.agotados}',
            detalle: 'Stock registrado en cero',
          ),
          TarjetaIndicador(
            icono: Icons.layers_outlined,
            etiqueta: 'Stock registrado',
            valor: '${conteo.stockUnidades}',
            detalle: 'Suma de unidades, no es una reserva',
          ),
        ]),
        const SizedBox(height: 14),
        _grilla([
          TarjetaIndicador(
            icono: Icons.receipt_long_outlined,
            etiqueta: 'Pedidos registrados',
            valor: '${conteo.pedidos}',
            detalle: 'Incluye todos los estados',
          ),
          TarjetaIndicador(
            icono: Icons.schedule_outlined,
            etiqueta: 'Pedidos pendientes',
            valor: '${conteo.pendientes}',
            detalle: 'Estado pendiente',
          ),
          TarjetaIndicador(
            icono: Icons.kitchen_outlined,
            etiqueta: 'En preparación',
            valor: '${conteo.preparando}',
            detalle: 'Estado en preparación',
          ),
          TarjetaIndicador(
            icono: Icons.task_alt_outlined,
            etiqueta: 'Pedidos entregados',
            valor: '${conteo.entregados}',
            detalle: 'Entrega registrada, no un pago',
          ),
          TarjetaIndicador(
            icono: Icons.cancel_outlined,
            etiqueta: 'Pedidos cancelados',
            valor: '${conteo.cancelados}',
            detalle: 'Estado cancelado',
          ),
          TarjetaIndicador(
            icono: Icons.storefront_outlined,
            etiqueta: 'Establecimientos',
            valor: '${conteo.tiendas}',
            detalle: conteo.tiendasSinCoordenadas == 0
                ? 'Con coordenadas registradas'
                : '${conteo.tiendasSinCoordenadas} sin coordenadas válidas',
          ),
          TarjetaIndicador(
            icono: Icons.confirmation_number_outlined,
            etiqueta: 'Cupones activos',
            valor: '${conteo.cuponesActivos}',
            detalle: '${conteo.cupones} cupones en la colección',
          ),
          TarjetaIndicador(
            icono: Icons.apartment_outlined,
            etiqueta: 'Locales',
            valor: '${conteo.locales}',
            detalle: 'Postulaciones registradas',
          ),
        ]),
        if (conteo.noDisponiblesConStock > 0) ...[
          const SizedBox(height: 12),
          Text(
            '${conteo.noDisponiblesConStock} productos tienen stock y están marcados como no disponibles.',
            style: textoGestion(color: GestionColores.tintaSuave),
          ),
        ],
        if (conteo.estadosNoReconocidos > 0) ...[
          const SizedBox(height: 8),
          Text(
            '${conteo.estadosNoReconocidos} pedidos tienen un estado no reconocido.',
            style: textoGestion(color: GestionColores.tintaSuave),
          ),
        ],
        const SizedBox(height: 18),
        SuperficieGestion(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: BarrasPedidos(conteo: conteo),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Accesos',
          style: textoGestion(
            tamano: 16,
            peso: FontWeight.w800,
            color: GestionColores.profundo,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _acceso('Productos', 1),
            _acceso('Pedidos', 2),
            _acceso('Tiendas', 3),
            _acceso('Cupones', 4),
            _acceso('Locales', 5),
          ],
        ),
        const SizedBox(height: 16),
        SuperficieGestion(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            leading: const Icon(Icons.cloud_upload_outlined, color: GestionColores.accion),
            title: Text(
              'Cargar catálogo inicial',
              style: textoGestion(peso: FontWeight.w800),
            ),
            subtitle: Text(
              'Sube los 50 productos base si todavía no están. No duplica los existentes.',
              style: textoGestion(tamano: 13, color: GestionColores.tintaSuave),
            ),
            trailing: _cargandoCatalogo
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right, color: GestionColores.profundo),
            onTap: _cargandoCatalogo ? null : _cargarCatalogoInicial,
          ),
        ),
      ],
    );
  }

  Widget _grilla(List<Widget> tarjetas) {
    return LayoutBuilder(
      builder: (context, limites) {
        final columnas = limites.maxWidth >= 1100
            ? 4
            : limites.maxWidth >= 760
            ? 2
            : 1;
        const espacio = 12.0;
        final ancho = (limites.maxWidth - espacio * (columnas - 1)) / columnas;
        return Wrap(
          spacing: espacio,
          runSpacing: espacio,
          children: [for (final tarjeta in tarjetas) SizedBox(width: ancho, child: tarjeta)],
        );
      },
    );
  }

  Widget _acceso(String texto, int indice) {
    return OutlinedButton(
      onPressed: () => widget.onCambiarPestana(indice),
      child: Text(texto),
    );
  }
}
