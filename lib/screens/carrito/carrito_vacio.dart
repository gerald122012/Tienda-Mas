import 'package:flutter/material.dart';

import '../../tema/tema_mass.dart';

class CarritoVacio extends StatelessWidget {
  final VoidCallback alVerProductos;

  const CarritoVacio({super.key, required this.alVerProductos});

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: tokens.accion.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shopping_basket_outlined,
                    size: 36,
                    color: tokens.accion,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Tu carrito está vacío',
                  textAlign: TextAlign.center,
                  style: textoMass(
                    tamano: 22,
                    peso: FontWeight.w800,
                    color: tokens.profundo,
                    alto: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Elige lo que necesitas en el catálogo. Tus cantidades se guardan aquí.',
                  textAlign: TextAlign.center,
                  style: textoMass(
                    tamano: 15,
                    color: tokens.tintaSuave,
                    alto: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: tokens.accion,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(MassRadio.control),
                      ),
                      textStyle: textoMass(tamano: 15, peso: FontWeight.w700),
                    ),
                    onPressed: alVerProductos,
                    child: const Text('Ver productos'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
