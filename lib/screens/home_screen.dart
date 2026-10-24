import 'package:flutter/material.dart';

import '../main.dart';
import 'alquila_local/locales_screen.dart';
import 'inicio/inicio_screen.dart';
import 'precios_mass/productos_screen.dart';
import 'ubicame/tiendas_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indice = 1;

  final _titulos = const [
    'Conóceme',
    'Catálogo',
    'Ubícame',
    'Alquila tu Local',
  ];

  void _cambiarPestana(int nuevoIndice) {
    setState(() => _indice = nuevoIndice);
  }

  @override
  Widget build(BuildContext context) {
    final pantallas = [
      InicioScreen(onCambiarPestana: _cambiarPestana),
      const ProductosScreen(),
      const TiendasScreen(),
      const LocalesScreen(),
    ];

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
              child: Text(_titulos[_indice], overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          // Botón rápido "ALQUILA TU LOCAL" como en el menú de la web Mass
          if (_indice != 3)
            Padding(
              padding: const EdgeInsets.only(right: 10),
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
        ],
      ),
      body: IndexedStack(index: _indice, children: pantallas),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indice,
        type: BottomNavigationBarType.fixed,
        backgroundColor: kMassYellow,
        selectedItemColor: kMassBlue,
        unselectedItemColor: kMassDark.withValues(alpha: 0.65),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900),
        onTap: _cambiarPestana,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront),
            label: 'Conóceme',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: 'Catálogo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Ubícame',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.real_estate_agent),
            label: 'Alquila Local',
          ),
        ],
      ),
    );
  }
}
