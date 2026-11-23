import 'dart:convert';

import 'package:flutter/material.dart';

import '../main.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';
import '../services/carrito_service.dart';
import '../utils/utilidades.dart';
import 'auth/login_screen.dart';
import 'carrito/carrito_screen.dart';
import 'delivery/delivery_mapa_screen.dart';
import 'escaner/escaner_herramientas_screen.dart';
import 'inicio/inicio_screen.dart';
import 'pedidos/historial_compras_screen.dart';
import 'perfil/perfil_screen.dart';
import 'precios_mass/productos_screen.dart';
import 'sensores/sensores_screen.dart';
import 'ubicame/tiendas_screen.dart';

class _Pestana {
  final String titulo;
  final String etiqueta;
  final IconData icono;
  final Widget pantalla;
  const _Pestana(this.titulo, this.etiqueta, this.icono, this.pantalla);
}

class HomeScreen extends StatefulWidget {
  final Usuario? usuario;

  const HomeScreen({super.key, this.usuario});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final List<_Pestana> _pestanas = [
    _Pestana(
      'Inicio',
      'Inicio',
      Icons.storefront_rounded,
      InicioScreen(onCambiarPestana: _cambiarPestana, mostrarAlquiler: false),
    ),
    const _Pestana(
      'Productos',
      'Productos',
      Icons.local_offer_rounded,
      ProductosScreen(),
    ),
    const _Pestana(
      'Ubícame',
      'Ubícame',
      Icons.location_on_rounded,
      TiendasScreen(),
    ),
    const _Pestana(
      'Mis Compras',
      'Compras',
      Icons.history_rounded,
      HistorialComprasScreen(),
    ),
    const _Pestana(
      'Sensores',
      'Sensores',
      Icons.sensors_rounded,
      SensoresScreen(),
    ),
  ];

  int _indice = 0;

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
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CarritoScreen()),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: tieneItems ? 10 : 8,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: tieneItems
                    ? kMassBlue
                    : kMassBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Badge(
                    isLabelVisible: tieneItems,
                    backgroundColor: kMassYellow,
                    textColor: kMassBlue,
                    label: Text(
                      '${carrito.unidades}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    child: Icon(
                      Icons.shopping_cart_rounded,
                      size: 20,
                      color: tieneItems ? kMassYellow : kMassBlue,
                    ),
                  ),
                  if (tieneItems) ...[
                    const SizedBox(width: 6),
                    Text(
                      formatoPrecio(carrito.total),
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
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
    final tieneFoto =
        usuario?.fotoBase64 != null && usuario!.fotoBase64!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: kMassBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Mass',
                style: TextStyle(
                  color: kMassYellow,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _pestanas[_indice].titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Escáner QR, Barras y Archivos',
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const EscanerHerramientasScreen(),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Delivery y rutas GPS',
            icon: const Icon(Icons.delivery_dining_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DeliveryMapaScreen()),
            ),
          ),
          _botonCarritoAppBar(),
          if (usuario == null)
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              style: TextButton.styleFrom(
                foregroundColor: kMassBlue,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text(
                'INGRESAR',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
              ),
            )
          else
            PopupMenuButton<String>(
              tooltip: 'Cuenta y perfil',
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
                radius: 15,
                backgroundColor: kMassBlue,
                foregroundColor: kMassYellow,
                backgroundImage: tieneFoto
                    ? MemoryImage(base64Decode(usuario.fotoBase64!))
                    : null,
                child: !tieneFoto
                    ? Text(
                        usuario.nombre.isNotEmpty
                            ? usuario.nombre[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      )
                    : null,
              ),
              itemBuilder: (_) => [
                PopupMenuItem(
                  enabled: false,
                  child: Text(
                    '${usuario.nombre}\nCliente Mass',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const PopupMenuItem(
                  value: 'perfil',
                  child: ListTile(
                    leading: Icon(Icons.person_outline),
                    title: Text('Mi perfil y foto'),
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
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _indice,
        children: [for (final p in _pestanas) p.pantalla],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indice,
        type: BottomNavigationBarType.fixed,
        backgroundColor: kMassYellow,
        selectedItemColor: kMassBlue,
        unselectedItemColor: kMassDark.withValues(alpha: 0.65),
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 11.5,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        onTap: _cambiarPestana,
        items: [
          for (final p in _pestanas)
            BottomNavigationBarItem(icon: Icon(p.icono), label: p.etiqueta),
        ],
      ),
    );
  }
}
