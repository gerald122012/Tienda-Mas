import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/cupon.dart';
import '../../models/pedido.dart';
import '../../models/producto.dart';
import '../../services/catalogo_inicial_service.dart';
import '../../services/firebase_service.dart';
import '../../utils/utilidades.dart';
import '../alquila_local/locales_screen.dart';
import '../precios_mass/producto_form_screen.dart';
import '../ubicame/tienda_form_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  final ValueChanged<int> onCambiarPestana;

  const AdminPanelScreen({super.key, required this.onCambiarPestana});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _cuponesService = FirebaseService('cupones_mass');
  bool _cargandoCatalogo = false;

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

  Future<void> _abrirFormularioCupon([CuponDescuento? cupon]) async {
    final codigoCtrl = TextEditingController(text: cupon?.codigo ?? '');
    final descCtrl = TextEditingController(text: cupon?.descripcion ?? '');
    final valorCtrl = TextEditingController(
      text: cupon != null ? cupon.valor.toString() : '10',
    );
    final minCtrl = TextEditingController(
      text: cupon != null ? cupon.montoMinimo.toString() : '15',
    );
    var tipo = cupon?.tipo ?? 'porcentaje';
    var activo = cupon?.activo ?? true;
    final formKey = GlobalKey<FormState>();

    final guardado = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(
            cupon == null ? 'Nuevo cupón QR' : 'Editar cupón ${cupon.codigo}',
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 10,
                children: [
                  TextFormField(
                    controller: codigoCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Código (ej. MASS25) *',
                    ),
                    validator: (v) => (v == null || v.trim().length < 3)
                        ? 'Mín. 3 caracteres'
                        : null,
                  ),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Descripción *',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: tipo,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: const [
                      DropdownMenuItem(
                        value: 'porcentaje',
                        child: Text('Porcentaje (%)'),
                      ),
                      DropdownMenuItem(
                        value: 'monto',
                        child: Text('Monto fijo (S/)'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setLocal(() => tipo = v);
                    },
                  ),
                  TextFormField(
                    controller: valorCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: tipo == 'porcentaje'
                          ? 'Porcentaje (%) *'
                          : 'Descuento (S/) *',
                    ),
                    validator: (v) {
                      final n = leerDouble(v ?? '');
                      if (n <= 0) return 'Debe ser mayor a 0';
                      if (tipo == 'porcentaje' && n > 90) return 'Máximo 90%';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: minCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Compra mínima (S/)',
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Cupón activo'),
                    value: activo,
                    onChanged: (v) => setLocal(() => activo = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final nuevo = CuponDescuento(
                  id: cupon?.id ?? '',
                  codigo: codigoCtrl.text.trim().toUpperCase(),
                  descripcion: descCtrl.text.trim(),
                  tipo: tipo,
                  valor: leerDouble(valorCtrl.text),
                  montoMinimo: leerDouble(minCtrl.text),
                  activo: activo,
                );
                try {
                  await _cuponesService.guardar(nuevo.id, nuevo.toMap());
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (_) {
                  if (ctx.mounted) {
                    mostrarMensaje(
                      ctx,
                      'No se pudo guardar el cupón. Revisa Firebase.',
                    );
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    codigoCtrl.dispose();
    descCtrl.dispose();
    valorCtrl.dispose();
    minCtrl.dispose();

    if (guardado == true && mounted) {
      mostrarMensaje(context, 'Cupón guardado correctamente.');
    }
  }

  Future<void> _eliminarCupon(CuponDescuento cupon) async {
    if (!await confirmarEliminar(context, 'cupón ${cupon.codigo}')) return;
    try {
      await _cuponesService.eliminar(cupon.id);
      if (mounted) {
        mostrarDeshacer(
          context,
          'Cupón ${cupon.codigo} eliminado',
          () => _cuponesService.restaurar(cupon.id, cupon.toMap()),
        );
      }
    } catch (_) {
      if (mounted) mostrarMensaje(context, 'No se pudo eliminar el cupón.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: kMassCream,
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              decoration: const BoxDecoration(
                color: kMassBlue,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings_rounded,
                        color: kMassYellow,
                        size: 28,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Panel de Administrador',
                          style: TextStyle(
                            color: kMassYellow,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Chip(
                        label: Text(
                          'v$kAppVersion',
                          style: TextStyle(
                            color: kMassBlue,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: kMassYellow,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  TabBar(
                    labelColor: kMassYellow,
                    unselectedLabelColor: Colors.white70,
                    indicatorColor: kMassYellow,
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(text: 'Resumen CRUD'),
                      Tab(text: 'Cupones QR'),
                      Tab(text: 'Locales'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _tabResumen(),
                  _tabCuponesCrud(),
                  const LocalesScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabResumen() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('productos_mass')
                    .snapshots(),
                builder: (context, snap) {
                  final docs = snap.data?.docs ?? [];
                  final bajoStock = docs
                      .map((d) => Producto.fromMap(d.id, d.data()))
                      .where((p) => p.stock <= 5)
                      .length;
                  return _kpiCard(
                    icono: Icons.inventory_2_outlined,
                    titulo: 'Productos',
                    valor: '${docs.length}',
                    pie: '$bajoStock con stock bajo',
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('pedidos')
                    .snapshots(),
                builder: (context, snap) {
                  final pedidos = (snap.data?.docs ?? [])
                      .map((d) => Pedido.fromMap(d.id, d.data()))
                      .toList();
                  final ventas = pedidos.fold<double>(
                    0,
                    (s, p) => s + (p.estado == 'cancelado' ? 0 : p.total),
                  );
                  return _kpiCard(
                    icono: Icons.point_of_sale,
                    titulo: 'Pedidos (${pedidos.length})',
                    valor: formatoPrecio(ventas),
                    pie: 'Ventas acumuladas',
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('tiendas_mass')
                    .snapshots(),
                builder: (context, snap) => _kpiCard(
                  icono: Icons.storefront,
                  titulo: 'Tiendas',
                  valor: '${snap.data?.docs.length ?? 0}',
                  pie: 'Sedes activas',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('locales_mass')
                    .snapshots(),
                builder: (context, snap) => _kpiCard(
                  icono: Icons.real_estate_agent,
                  titulo: 'Locales',
                  valor: '${snap.data?.docs.length ?? 0}',
                  pie: 'Postulaciones',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Gestión CRUD rápida',
          style: TextStyle(
            color: kMassBlue,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: kMassYellow,
              foregroundColor: kMassBlue,
              child: Icon(Icons.cloud_upload_outlined),
            ),
            title: const Text(
              'Cargar catálogo inicial',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: const Text(
              'Sube a Firebase los 50 productos base (no duplica los existentes)',
            ),
            trailing: _cargandoCatalogo
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _cargandoCatalogo ? null : _cargarCatalogoInicial,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: kMassMint,
                  foregroundColor: kMassBlue,
                  child: Icon(Icons.add_box_outlined),
                ),
                title: const Text(
                  'Crear / Administrar Productos',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: const Text('Crear, editar, duplicar y eliminar'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Nuevo producto',
                      icon: const Icon(Icons.add_circle, color: kMassBlue),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProductoFormScreen(),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Ver catálogo',
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () => widget.onCambiarPestana(1),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: kMassMint,
                  foregroundColor: kMassBlue,
                  child: Icon(Icons.add_location_alt_outlined),
                ),
                title: const Text(
                  'Crear / Administrar Tiendas',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: const Text('Sedes, horarios y coordenadas GPS'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Nueva tienda',
                      icon: const Icon(Icons.add_circle, color: kMassBlue),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TiendaFormScreen(),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Ver tiendas',
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () => widget.onCambiarPestana(2),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: kMassMint,
                  foregroundColor: kMassBlue,
                  child: Icon(Icons.real_estate_agent_outlined),
                ),
                title: const Text(
                  'Administrar Locales Comerciales',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: const Text(
                  'Crear, evaluar estado, editar y eliminar postulaciones',
                ),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => widget.onCambiarPestana(3),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: kMassMint,
                  foregroundColor: kMassBlue,
                  child: Icon(Icons.receipt_long_outlined),
                ),
                title: const Text(
                  'Gestionar Pedidos de Clientes',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: const Text(
                  'Ver verificación de recojo, cambiar estado y eliminar',
                ),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => widget.onCambiarPestana(4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Card(
          color: kMassBlue,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.verified_outlined, color: kMassYellow, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tiendas Mass · Versión $kAppVersion (Build $kAppBuild)',
                        style: TextStyle(
                          color: kMassYellow,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Sistema actualizado con geolocalización avanzada, cámara, escáner QR/barras, sensores en tiempo real y CRUD administrativo.',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tabCuponesCrud() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'cupones_admin',
        onPressed: () => _abrirFormularioCupon(),
        icon: const Icon(Icons.add),
        label: const Text('NUEVO CUPÓN'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _cuponesService.coleccion.snapshots(),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];
          final cupones = docs
              .map((d) => CuponDescuento.fromMap(d.id, d.data()))
              .toList();

          if (cupones.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_offer_outlined,
                      size: 54,
                      color: kMassBlue,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No hay cupones personalizados en Firebase',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kMassBlue,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Crea cupones QR de descuento desde el botón inferior.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 84),
            itemCount: cupones.length,
            itemBuilder: (context, i) {
              final c = cupones[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: c.activo
                        ? kMassYellow
                        : Colors.grey.shade300,
                    foregroundColor: kMassBlue,
                    child: const Icon(Icons.qr_code_2),
                  ),
                  title: Text(
                    '${c.codigo} · ${c.etiquetaDescuento}',
                    style: const TextStyle(
                      color: kMassBlue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  subtitle: Text(
                    '${c.descripcion}\nMínimo: ${formatoPrecio(c.montoMinimo)} · ${c.activo ? 'Activo' : 'Inactivo'}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Editar',
                        icon: const Icon(Icons.edit, color: kMassBlue),
                        onPressed: () => _abrirFormularioCupon(c),
                      ),
                      IconButton(
                        tooltip: 'Eliminar',
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _eliminarCupon(c),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _kpiCard({
    required IconData icono,
    required String titulo,
    required String valor,
    required String pie,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, color: kMassBlue, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            precioUnaLinea(
              valor,
              style: const TextStyle(
                color: kMassBlue,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              pie,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}
