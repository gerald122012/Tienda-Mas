import 'dart:convert';

import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/usuario.dart';
import '../../services/auth_service.dart';
import '../../utils/utilidades.dart';
import '../alquila_local/locales_screen.dart';
import '../pedidos/pedidos_screen.dart';
import '../perfil/perfil_screen.dart';
import '../precios_mass/productos_screen.dart';
import '../ubicame/tiendas_screen.dart';
import 'admin_panel_screen.dart';

class _SeccionAdmin {
  final String titulo;
  final String etiqueta;
  final IconData icono;
  final Widget pantalla;

  const _SeccionAdmin(this.titulo, this.etiqueta, this.icono, this.pantalla);
}

class AdminWebShell extends StatefulWidget {
  final Usuario usuario;

  const AdminWebShell({super.key, required this.usuario});

  @override
  State<AdminWebShell> createState() => _AdminWebShellState();
}

class _AdminWebShellState extends State<AdminWebShell> {
  int _indice = 0;

  late final List<_SeccionAdmin> _secciones = [
    _SeccionAdmin(
      'Panel de Administrador',
      'Resumen',
      Icons.dashboard_rounded,
      AdminPanelScreen(onCambiarPestana: _cambiarSeccion),
    ),
    const _SeccionAdmin(
      'Catálogo de Productos (CRUD)',
      'Productos',
      Icons.inventory_2_rounded,
      ProductosScreen(esAdmin: true),
    ),
    const _SeccionAdmin(
      'Tiendas Mass (CRUD)',
      'Tiendas',
      Icons.storefront_rounded,
      TiendasScreen(esAdmin: true),
    ),
    const _SeccionAdmin(
      'Alquila tu Local (CRUD)',
      'Locales',
      Icons.real_estate_agent_rounded,
      LocalesScreen(),
    ),
    const _SeccionAdmin(
      'Pedidos de Clientes',
      'Pedidos',
      Icons.receipt_long_rounded,
      PedidosScreen(),
    ),
  ];

  void _cambiarSeccion(int nuevo) {
    if (nuevo < 0 || nuevo >= _secciones.length) return;
    setState(() => _indice = nuevo);
  }

  @override
  Widget build(BuildContext context) {
    final usuario = widget.usuario;
    final tieneFoto =
        usuario.fotoBase64 != null && usuario.fotoBase64!.isNotEmpty;
    final esPantallaAncha = MediaQuery.sizeOf(context).width >= 820;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: kMassBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Mass Admin',
                style: TextStyle(
                  color: kMassYellow,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _secciones[_indice].titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: kMassBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'WEB CRUD · v$kAppVersion',
              style: TextStyle(
                color: kMassBlue,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Cuenta administrador',
            onSelected: (accion) {
              if (accion == 'perfil') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PerfilScreen()),
                );
              } else if (accion == 'salir') {
                AuthService.instance.cerrarSesion();
              }
            },
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: kMassBlue,
              foregroundColor: kMassYellow,
              backgroundImage: tieneFoto
                  ? MemoryImage(base64Decode(usuario.fotoBase64!))
                  : null,
              child: !tieneFoto
                  ? const Icon(Icons.admin_panel_settings, size: 18)
                  : null,
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  '${usuario.nombre}\nAdministrador Web',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const PopupMenuItem(
                value: 'perfil',
                child: ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Mi perfil'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'salir',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Cerrar sesión'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          if (esPantallaAncha)
            NavigationRail(
              selectedIndex: _indice,
              onDestinationSelected: _cambiarSeccion,
              extended: MediaQuery.sizeOf(context).width >= 1100,
              backgroundColor: Colors.white,
              indicatorColor: kMassYellow,
              selectedIconTheme: const IconThemeData(color: kMassBlue),
              selectedLabelTextStyle: const TextStyle(
                color: kMassBlue,
                fontWeight: FontWeight.w900,
              ),
              destinations: [
                for (final s in _secciones)
                  NavigationRailDestination(
                    icon: Icon(s.icono),
                    label: Text(s.etiqueta),
                  ),
              ],
            ),
          if (esPantallaAncha)
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: kMassBlue.withValues(alpha: 0.1),
            ),
          Expanded(
            child: IndexedStack(
              index: _indice,
              children: [for (final s in _secciones) s.pantalla],
            ),
          ),
        ],
      ),
      bottomNavigationBar: esPantallaAncha
          ? null
          : BottomNavigationBar(
              currentIndex: _indice,
              type: BottomNavigationBarType.fixed,
              backgroundColor: kMassYellow,
              selectedItemColor: kMassBlue,
              unselectedItemColor: kMassDark.withValues(alpha: 0.65),
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11.5,
              ),
              onTap: _cambiarSeccion,
              items: [
                for (final s in _secciones)
                  BottomNavigationBarItem(
                    icon: Icon(s.icono),
                    label: s.etiqueta,
                  ),
              ],
            ),
    );
  }
}
