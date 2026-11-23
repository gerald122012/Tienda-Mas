import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../main.dart';
import '../../utils/utilidades.dart';
import '../../widgets/aparecer.dart';
import '../delivery/delivery_mapa_screen.dart';
import '../escaner/escaner_herramientas_screen.dart';

class _TemaAprende {
  final String etiqueta;
  final String titulo;
  final String resumen;
  final String contenidoCompleto;
  final IconData icono;
  final Color colorFondo;
  final Color colorAcento;
  final String? imagenAsset;

  const _TemaAprende({
    required this.etiqueta,
    required this.titulo,
    required this.resumen,
    required this.contenidoCompleto,
    required this.icono,
    required this.colorFondo,
    required this.colorAcento,
    this.imagenAsset,
  });
}

class InicioScreen extends StatelessWidget {
  final ValueChanged<int> onCambiarPestana;
  final bool mostrarAlquiler;

  const InicioScreen({
    super.key,
    required this.onCambiarPestana,
    this.mostrarAlquiler = true,
  });

  static const _temasAprende = [
    _TemaAprende(
      etiqueta: 'RECETA · 15 MIN',
      titulo: 'Almuerzos con arroz',
      resumen: '2 ideas rendidoras',
      contenidoCompleto:
          '1. Arroz tapado exprés: saltea cebolla, ajo, carne molida y pasas, sirve con arroz graneado y huevo frito.\n\n'
          '2. Chaufa casero Mass: aprovecha arroz del día anterior con sillao, cebollita china, tortilla picada y hot dog en cubitos.',
      icono: Icons.restaurant_rounded,
      colorFondo: Color(0xFFFFF2C2),
      colorAcento: Color(0xFFB45309),
      imagenAsset: 'assets/productos/marcas/catalogo_001.jpg',
    ),
    _TemaAprende(
      etiqueta: 'SNACKS · 5 MIN',
      titulo: 'Bocaditos crocantitos',
      resumen: 'Para compartir hoy',
      contenidoCompleto:
          'Prepara una tabla económica combinando galletas saladas, queso edam en cubos y dips rápidos de palta o yogurt natural con limón.',
      icono: Icons.fastfood_rounded,
      colorFondo: Color(0xFFD6F8F4),
      colorAcento: Color(0xFF0F766E),
      imagenAsset: 'assets/productos/marcas/catalogo_011-limpia.png',
    ),
    _TemaAprende(
      etiqueta: 'AHORRO MASS',
      titulo: 'Compra inteligente',
      resumen: 'Cuida tu presupuesto',
      contenidoCompleto:
          '• Compara el precio por kg o litro que aparece en cada tarjeta del catálogo.\n'
          '• Activa el Modo Bolsillo en Productos para controlar tu gasto en tiempo real.\n'
          '• Escanea los códigos QR promocionales antes de pagar.',
      icono: Icons.savings_rounded,
      colorFondo: Color(0xFFE0E7FF),
      colorAcento: kMassBlue,
    ),
    _TemaAprende(
      etiqueta: 'HOGAR LIMPIO',
      titulo: 'Tips de limpieza',
      resumen: 'Rinde más tu compra',
      contenidoCompleto:
          'Dosifica el detergente líquido usando la tapa medidora y separa prendas claras de oscuras para duplicar el rendimiento de cada botella.',
      icono: Icons.cleaning_services_rounded,
      colorFondo: Color(0xFFFCE7F3),
      colorAcento: Color(0xFF9D174D),
      imagenAsset: 'assets/productos/marcas/catalogo_025-limpia.png',
    ),
  ];

  void _mostrarPoliticas(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kMassCream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Políticas de cambios y devoluciones',
          style: TextStyle(color: kMassBlue, fontWeight: FontWeight.w900),
        ),
        content: const Text(
          '1. Acércate a la tienda donde realizaste la compra.\n'
          '2. Presenta tu comprobante y el producto con empaque cerrado.\n\n'
          '• Perecibles: dentro de las 24 horas.\n'
          '• No perecibles: hasta 7 días posteriores.',
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

  void _mostrarDetalleAprende(BuildContext context, _TemaAprende tema) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: tema.colorFondo,
                    foregroundColor: tema.colorAcento,
                    child: Icon(tema.icono),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tema.etiqueta,
                          style: TextStyle(
                            color: tema.colorAcento,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                        Text(
                          tema.titulo,
                          style: const TextStyle(
                            color: kMassBlue,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                tema.contenidoCompleto,
                style: const TextStyle(fontSize: 14.5, height: 1.45),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onCambiarPestana(1);
                  },
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('VER PRODUCTOS EN CATÁLOGO'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heroBanner(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _EncabezadoSeccion(
                  titulo: 'Accesos rápidos',
                  subtitulo: 'Elige a dónde quieres ir',
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth >= 640 ? 4 : 2;
                    return GridView.count(
                      crossAxisCount: cols,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: cols == 4 ? 1.05 : 1.12,
                      children: [
                        Aparecer(
                          indice: 0,
                          child: _PanelAcceso(
                            titulo: 'Productos',
                            subtitulo: 'Ingresar a productos',
                            etiqueta: 'CATÁLOGO',
                            colorFondo: const Color(0xFFEAF2FF),
                            colorAcento: kMassBlue,
                            icono: Icons.shopping_basket_rounded,
                            imagenAsset:
                                'assets/productos/marcas/catalogo_003-limpia.png',
                            onTap: () => onCambiarPestana(1),
                          ),
                        ),
                        Aparecer(
                          indice: 1,
                          child: _PanelAcceso(
                            titulo: 'Ubicación',
                            subtitulo: 'Tiendas y rutas',
                            etiqueta: 'UBÍCAME',
                            colorFondo: kMassMint,
                            colorAcento: const Color(0xFF0F766E),
                            icono: Icons.location_on_rounded,
                            onTap: () => onCambiarPestana(2),
                          ),
                        ),
                        Aparecer(
                          indice: 2,
                          child: _PanelAcceso(
                            titulo: 'Mis Compras',
                            subtitulo: 'Historial y recojo',
                            etiqueta: 'PEDIDOS',
                            colorFondo: const Color(0xFFFFF3CC),
                            colorAcento: const Color(0xFFB45309),
                            icono: Icons.receipt_long_rounded,
                            onTap: () => onCambiarPestana(3),
                          ),
                        ),
                        Aparecer(
                          indice: 3,
                          child: _PanelAcceso(
                            titulo: 'Sensores',
                            subtitulo: 'Tiempo real y QR',
                            etiqueta: 'EN VIVO',
                            colorFondo: const Color(0xFFEDE9FE),
                            colorAcento: const Color(0xFF5B21B6),
                            icono: Icons.sensors_rounded,
                            onTap: () => onCambiarPestana(4),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                Aparecer(
                  indice: 4,
                  child: _bannerDelivery(context),
                ),
                const SizedBox(height: 18),
                Aparecer(
                  indice: 5,
                  child: _franjaIndicadores(),
                ),
                const SizedBox(height: 22),
                const _EncabezadoSeccion(
                  titulo: 'Aprende Mass',
                  subtitulo: 'Toca un cuadro para ver el tip completo',
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth >= 640 ? 4 : 2;
                    return GridView.builder(
                      itemCount: _temasAprende.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 172,
                      ),
                      itemBuilder: (context, i) {
                        final tema = _temasAprende[i];
                        return Aparecer(
                          indice: i + 2,
                          child: _CuadroAprende(
                            tema: tema,
                            onTap: () => _mostrarDetalleAprende(context, tema),
                          ),
                        );
                      },
                    );
                  },
                ),
                if (mostrarAlquiler) ...[
                  const SizedBox(height: 18),
                  _tarjetaAlquiler(),
                ],
                const SizedBox(height: 20),
                _pieCompacto(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kMassBlue, Color(0xFF051D7A)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -12,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kMassYellow.withValues(alpha: 0.14),
              ),
            ),
          ),
          Positioned(
            right: 24,
            bottom: -24,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kMassTurquoise.withValues(alpha: 0.16),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: kMassYellow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, size: 15, color: kMassBlue),
                    SizedBox(width: 4),
                    Text(
                      'LLEVA MASS PAGANDO MENOS',
                      style: TextStyle(
                        color: kMassBlue,
                        fontWeight: FontWeight.w900,
                        fontSize: 11.5,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tu tienda Mass,\nsiempre cerca',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            height: 1.12,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Ahorra en cada compra diaria.',
                          style: TextStyle(
                            color: Color(0xFFDCE7FF),
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 78,
                    height: 78,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/productos/marcas/catalogo_012-limpia.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.storefront_rounded,
                        color: kMassBlue,
                        size: 40,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kMassYellow,
                        foregroundColor: kMassBlue,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        onCambiarPestana(1);
                      },
                      icon: const Icon(Icons.local_offer_rounded, size: 18),
                      label: const Text(
                        'VER PRODUCTOS',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EscanerHerramientasScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                    label: const Text(
                      'QR',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bannerDelivery(BuildContext context) {
    return _PanelPulsable(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DeliveryMapaScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kMassTurquoise, Color(0xFF1BB8A6)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: kMassTurquoise.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.delivery_dining_rounded,
                color: kMassBlue,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery y Rutas GPS',
                    style: TextStyle(
                      color: kMassBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Calcula tu ruta y compártela al instante',
                    style: TextStyle(
                      color: kMassDark,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const CircleAvatar(
              radius: 16,
              backgroundColor: kMassBlue,
              foregroundColor: kMassYellow,
              child: Icon(Icons.arrow_forward_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _franjaIndicadores() {
    return Row(
      children: [
        _indicador(Icons.storefront_rounded, '+900', 'Tiendas'),
        const SizedBox(width: 10),
        _indicador(Icons.shopping_basket_rounded, '+1000', 'Productos'),
        const SizedBox(width: 10),
        _indicador(Icons.map_rounded, '15', 'Regiones'),
      ],
    );
  }

  Widget _indicador(IconData icono, String numero, String texto) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kMassBlue.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icono, color: kMassBlue, size: 22),
            const SizedBox(height: 4),
            Text(
              numero,
              style: const TextStyle(
                color: kMassBlue,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              texto,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaAlquiler() {
    return _PanelPulsable(
      onTap: () => onCambiarPestana(0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kMassBlue,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Row(
          children: [
            CircleAvatar(
              backgroundColor: kMassYellow,
              foregroundColor: kMassBlue,
              child: Icon(Icons.real_estate_agent_rounded),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alquila tu local (+200 m²)',
                    style: TextStyle(
                      color: kMassYellow,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'Registra tu espacio comercial aquí',
                    style: TextStyle(color: Colors.white, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: kMassYellow),
          ],
        ),
      ),
    );
  }

  Widget _pieCompacto(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kMassYellow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.schedule_rounded, size: 16, color: kMassBlue),
              SizedBox(width: 6),
              Text(
                'Lun a Dom · 7:00 AM - 10:00 PM',
                style: TextStyle(
                  color: kMassBlue,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (final metodo in ['Yape', 'Plin', 'Visa / MC', 'Efectivo'])
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    metodo,
                    style: const TextStyle(
                      color: kMassBlue,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: kMassBlue,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => _mostrarPoliticas(context),
                icon: const Icon(Icons.policy_outlined, size: 16),
                label: const Text(
                  'Políticas',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const Text(
                'Tiendas Mass · v$kAppVersion',
                style: TextStyle(
                  color: kMassBlue,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EncabezadoSeccion extends StatelessWidget {
  final String titulo;
  final String subtitulo;

  const _EncabezadoSeccion({required this.titulo, required this.subtitulo});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: kMassBlue,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          subtitulo,
          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}

class _PanelPulsable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PanelPulsable({required this.child, required this.onTap});

  @override
  State<_PanelPulsable> createState() => _PanelPulsableState();
}

class _PanelPulsableState extends State<_PanelPulsable> {
  bool _presionado = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _presionado = true),
      onTapUp: (_) {
        setState(() => _presionado = false);
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _presionado = false),
      child: AnimatedScale(
        scale: _presionado ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class _PanelAcceso extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final String etiqueta;
  final Color colorFondo;
  final Color colorAcento;
  final IconData icono;
  final String? imagenAsset;
  final VoidCallback onTap;

  const _PanelAcceso({
    required this.titulo,
    required this.subtitulo,
    required this.etiqueta,
    required this.colorFondo,
    required this.colorAcento,
    required this.icono,
    required this.onTap,
    this.imagenAsset,
  });

  @override
  Widget build(BuildContext context) {
    return _PanelPulsable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colorAcento.withValues(alpha: 0.14)),
          boxShadow: [
            BoxShadow(
              color: kMassBlue.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: colorFondo,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: imagenAsset != null
                      ? Image.asset(
                          imagenAsset!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              Icon(icono, color: colorAcento, size: 28),
                        )
                      : Icon(icono, color: colorAcento, size: 28),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colorFondo,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    etiqueta,
                    style: TextStyle(
                      color: colorAcento,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: kMassBlue,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    subtitulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: colorAcento,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CuadroAprende extends StatelessWidget {
  final _TemaAprende tema;
  final VoidCallback onTap;

  const _CuadroAprende({required this.tema, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _PanelPulsable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: tema.colorAcento.withValues(alpha: 0.14)),
          boxShadow: [
            BoxShadow(
              color: kMassBlue.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 80,
              color: tema.colorFondo,
              padding: const EdgeInsets.all(10),
              child: Stack(
                children: [
                  Center(
                    child: tema.imagenAsset != null
                        ? Image.asset(
                            tema.imagenAsset!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => Icon(
                              tema.icono,
                              color: tema.colorAcento,
                              size: 38,
                            ),
                          )
                        : Icon(tema.icono, color: tema.colorAcento, size: 38),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tema.etiqueta,
                        style: TextStyle(
                          color: tema.colorAcento,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tema.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kMassBlue,
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                        height: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tema.resumen,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.add_circle_outline_rounded,
                          size: 16,
                          color: tema.colorAcento,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
