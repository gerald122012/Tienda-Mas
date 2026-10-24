import 'package:flutter/material.dart';

import '../../main.dart';

// Pantalla principal que lleva la web de Tiendas Mass (Inicio, Conóceme y Aprende Mass) a la app.
class InicioScreen extends StatelessWidget {
  final ValueChanged<int> onCambiarPestana;

  const InicioScreen({super.key, required this.onCambiarPestana});

  void _mostrarPoliticas(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kMassCream,
        title: const Text(
          'Políticas de cambios y devoluciones',
          style: TextStyle(color: kMassBlue, fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'Si necesitas hacer un cambio y/o devolución de algún producto, '
          'te la hacemos facilito nomás:\n\n'
          '1. Acércate a mi tienda (donde realizaste la compra).\n'
          '2. Presenta el ticket de compra, el producto en buenas condiciones '
          'y con el empaque cerrado.\n'
          '3. ¡Y listo!\n\n'
          '* En productos perecibles: dentro de las 24 horas posteriores a la compra.\n'
          '* En productos no perecibles: hasta 7 días posteriores a la compra.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ENTENDIDO'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. BANNER PRINCIPAL (Hero de tiendasmass.com.pe)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            decoration: const BoxDecoration(
              color: kMassBlue,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: kMassYellow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'LLEVA MASS PAGANDO MENOS',
                    style: TextStyle(
                      color: kMassBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  '¡LOS MEJORES PRECIOS DEL BARRIO!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Caser@, a mí nadie me gana, yo tengo siempre los mejores '
                  'precios, y además, estoy cerca a tu hogar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kMassYellow,
                    foregroundColor: kMassBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () => onCambiarPestana(1), // Va a Precios Mass
                  icon: const Icon(Icons.local_offer),
                  label: const Text(
                    'QUIERO VER PRECIOS MASS',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),

          // 2. SECCIÓN CONÓCEME Y PROPUESTA DE VALOR (#D6F8F4 menta y #33DDC8 turquesa)
          Container(
            color: kMassMint,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '¡HOLA! SOY TU TIENDA MASS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kMassBlue,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Soy la tienda Mass, la más Mass de todos los barrios con '
                  'productos de calidad y a los mejores precios para que tú y '
                  'tu familia siempre puedan ahorrar en sus compras diarias.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kMassDark, fontSize: 14),
                ),
                const SizedBox(height: 16),
                // Indicadores de la web
                Row(
                  children: [
                    _indicador(Icons.storefront, '+900', 'Tiendas'),
                    const SizedBox(width: 8),
                    _indicador(Icons.shopping_basket, '+1000', 'Productos'),
                    const SizedBox(width: 8),
                    _indicador(Icons.map, '15', 'Regiones'),
                  ],
                ),
                const SizedBox(height: 16),
                // Tarjeta turquesa de propuesta de valor (como .concepto .valor-cont)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kMassTurquoise,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'MI PROPUESTA DE VALOR',
                        style: TextStyle(
                          color: kMassBlue,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '“Manteniendo siempre procesos simples y costos bajos, '
                        'logro tener los mejores precios todos los días con '
                        'marcas propias de calidad cerquita a tu hogar.”',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: kMassDark, fontSize: 13.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => onCambiarPestana(2), // Va a Ubícame
                  icon: const Icon(Icons.location_on),
                  label: const Text('UBICA AQUÍ TU TIENDA MÁS CERCANA'),
                ),
              ],
            ),
          ),

          // 3. SECCIÓN APRENDE MASS (Recetas Mass Caseras y Tips de la web)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'APRENDE MASS: FÁCIL, PRÁCTICO Y CASERO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kMassBlue,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                _tarjetaAprende(
                  icono: Icons.restaurant,
                  categoria: 'RECETAS MASS CASERAS',
                  titulo: '2 Ideas de almuerzo con arroz VALLE BLANCO',
                  detalle:
                      'Recetas fáciles con ingredientes al precio Mass bajo para toda la familia.',
                ),
                _tarjetaAprende(
                  icono: Icons.fastfood,
                  categoria: 'RECETAS MASS CASERAS',
                  titulo: '3 snacks crocantitos con BUEN PUNTO y DEVOCIÓN',
                  detalle:
                      'En pocos minutos prepara bocaditos deliciosos sin gastar de más.',
                ),
                _tarjetaAprende(
                  icono: Icons.lightbulb,
                  categoria: 'EL TIP MASS ÚTIL / CUÍDATE MASS',
                  titulo: 'Cocina mejor con un ahorro inteligente',
                  detalle:
                      'Secretitos para mantener tu hogar limpio y ordenado cuidando tu bolsillo.',
                ),
              ],
            ),
          ),

          // 4. SECCIÓN ALQUILA TU LOCAL & TRABAJA CON NOSOTROS
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kMassBlue,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                const Text(
                  '¿TIENES UN LOCAL DE MÁS DE 200 m²?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kMassYellow,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '¡Cada vez quiero estar más cerca de tu hogar y sigo buscando '
                  'locales! Regístralo aquí para evaluarlo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kMassYellow,
                    foregroundColor: kMassBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () => onCambiarPestana(3), // Va a Alquila tu Local
                  icon: const Icon(Icons.real_estate_agent),
                  label: const Text(
                    'ALQUILA TU LOCAL AQUÍ',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),

          // 5. PIE DE PÁGINA (Horario, Contacto y Políticas como en la web)
          Container(
            color: kMassYellow,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  '¡ÚNETE A LA FUERZA AMARILLA!',
                  style: TextStyle(
                    color: kMassBlue,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Horario de atención: Lunes a domingo de 7:00 AM a 10:00 PM\n'
                  'Contacto: servicioalcliente@tiendasmass.pe\n'
                  'Métodos de pago: Efectivo, Yape, Plin y Tarjetas Visa / Mastercard',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kMassDark, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => _mostrarPoliticas(context),
                  icon: const Icon(Icons.policy, color: kMassBlue),
                  label: const Text(
                    'Ver Políticas de cambios y devoluciones',
                    style: TextStyle(
                      color: kMassBlue,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const Text(
                  '© Tiendas Mass - Compañía Hard Discount S.A.C.',
                  style: TextStyle(color: kMassBlue, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _indicador(IconData icono, String numero, String texto) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: kMassBlue,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icono, color: kMassYellow, size: 28),
            const SizedBox(height: 4),
            Text(
              numero,
              style: const TextStyle(
                color: kMassYellow,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              texto,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaAprende({
    required IconData icono,
    required String categoria,
    required String titulo,
    required String detalle,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: kMassYellow,
          foregroundColor: kMassBlue,
          child: Icon(icono),
        ),
        title: Text(
          categoria,
          style: const TextStyle(
            color: kMassBlue,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          '$titulo\n$detalle',
          style: const TextStyle(color: kMassDark, fontSize: 13),
        ),
        isThreeLine: true,
      ),
    );
  }
}
