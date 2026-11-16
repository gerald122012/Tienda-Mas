import 'package:flutter/material.dart';

import '../main.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';
import 'alquila_local/locales_screen.dart';
import 'auth/login_screen.dart';
import 'delivery/delivery_mapa_screen.dart';
import 'inicio/inicio_screen.dart';
import 'pedidos/pedidos_screen.dart';
import 'precios_mass/productos_screen.dart';
import 'ubicame/tiendas_screen.dart';

class _Pestana {
  final String titulo;
  final String etiqueta;
  final IconData icono;
  final Widget pantalla;
  const _Pestana(this.titulo, this.etiqueta, this.icono, this.pantalla);
}

class HomeScreen extends StatefulWidget {
  // null = invitado (cliente anónimo).
  final Usuario? usuario;

  const HomeScreen({super.key, this.usuario});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final List<_Pestana> _pestanas = _armarPestanas();
  late int _indice;

  @override
  void initState() {
    super.initState();
    _indice = 1; // Catálogo / Productos; Conóceme es la 0
  }

  // El cliente solo compra y ubica tiendas; el administrador gestiona todo.
  List<_Pestana> _armarPestanas() {
    if (widget.usuario?.esAdmin == true) {
      return [
        _Pestana(
          'Conóceme',
          'Conóceme',
          Icons.storefront,
          InicioScreen(onCambiarPestana: _cambiarPestana),
        ),
        const _Pestana(
          'Catálogo',
          'Catálogo',
          Icons.local_offer,
          ProductosScreen(esAdmin: true),
        ),
        const _Pestana(
          'Ubícame',
          'Ubícame',
          Icons.location_on,
          TiendasScreen(esAdmin: true),
        ),
        const _Pestana(
          'Alquila tu Local',
          'Alquila Local',
          Icons.real_estate_agent,
          LocalesScreen(),
        ),
        const _Pestana(
          'Pedidos',
          'Pedidos',
          Icons.receipt_long,
          PedidosScreen(),
        ),
      ];
    }
    return [
      _Pestana(
        'Conóceme',
        'Conóceme',
        Icons.storefront,
        InicioScreen(onCambiarPestana: _cambiarPestana, mostrarAlquiler: false),
      ),
      const _Pestana(
        'Productos',
        'Productos',
        Icons.local_offer,
        ProductosScreen(),
      ),
      const _Pestana('Ubícame', 'Ubícame', Icons.location_on, TiendasScreen()),
    ];
  }

  void _cambiarPestana(int nuevoIndice) {
    setState(() => _indice = nuevoIndice);
  }

  @override
  Widget build(BuildContext context) {
    final usuario = widget.usuario;
    final esAdmin = usuario?.esAdmin == true;
    return Scaffold(
      // AppBar amarillo estilo .navbar-principal de https://www.tiendasmass.com.pe
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: kMassBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Mass',
                style: TextStyle(
                  color: kMassYellow,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _pestanas[_indice].titulo,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Delivery es una función de compra: solo para clientes e invitados.
          if (!esAdmin)
            IconButton(
              tooltip: 'Delivery y mapa',
              icon: const Icon(Icons.delivery_dining),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeliveryMapaScreen()),
              ),
            ),
          // Botón rápido "ALQUILA TU LOCAL" como en el menú de la web Mass
          if (esAdmin && _indice != 3)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: FilledButton(
                onPressed: () => _cambiarPestana(3),
                style: FilledButton.styleFrom(
                  backgroundColor: kMassBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text(
                  'ALQUILA TU LOCAL',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          if (usuario == null)
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              icon: const Icon(Icons.login),
              label: const Text('INGRESAR'),
            )
          else
            PopupMenuButton<String>(
              tooltip: 'Cuenta',
              icon: const Icon(Icons.account_circle),
              onSelected: (_) => AuthService.instance.cerrarSesion(),
              itemBuilder: (_) => [
                PopupMenuItem(
                  enabled: false,
                  child: Text(
                    '${usuario.nombre}\n${esAdmin ? 'Administrador' : 'Cliente'}',
                  ),
                ),
                const PopupMenuItem(
                  value: 'salir',
                  child: ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('Cerrar sesión'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
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
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900),
        onTap: _cambiarPestana,
        items: [
          for (final p in _pestanas)
            BottomNavigationBarItem(icon: Icon(p.icono), label: p.etiqueta),
        ],
      ),
    );
  }
}
