import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/cupon.dart';
import 'package:flutter_application_1/models/producto.dart';
import 'package:flutter_application_1/services/routing_service.dart';
import 'package:flutter_application_1/utils/utilidades.dart';
import 'package:flutter_application_1/widgets/producto_catalogo_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

Producto _crearProducto({
  String id = 'p_1',
  String nombre = 'Arroz Extra Bolsa 5Kg',
  String codigoBarras = '7750123456789',
  double precio = 20.0,
  List<String> presentaciones = const ['Bolsa 5Kg'],
}) {
  return Producto(
    id: id,
    codigoBarras: codigoBarras,
    nombre: nombre,
    descripcion: nombre,
    marca: 'COSTEÑO',
    precio: precio,
    stock: 25,
    categoria: 'abarrotes',
    disponible: true,
    fechaRegistro: DateTime(2026, 1, 1),
    presentaciones: presentaciones,
    valoracion: 5,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Producto serializa código de barras y calcula precio unitario', () {
    final producto = _crearProducto(precio: 20.0, presentaciones: ['Bolsa 5Kg']);
    expect(producto.precioUnitarioTexto, 'S/ 4.00 / kg');

    final recuperado = Producto.fromMap(producto.id, producto.toMap());
    expect(recuperado.codigoBarras, '7750123456789');
    expect(recuperado.precio, 20.0);
  });

  test('QR de descuento extrae código desde texto plano, prefijo o URL', () {
    expect(CuponDescuento.extraerCodigoDesdeQr('mass10'), 'MASS10');
    expect(CuponDescuento.extraerCodigoDesdeQr('MASS:AHORRO5'), 'AHORRO5');
    expect(
      CuponDescuento.extraerCodigoDesdeQr(
        'https://tiendasmass.pe/promo?code=bienvenido20',
      ),
      'BIENVENIDO20',
    );
  });

  test('RoutingService construye mensaje compartible y enlace Google Maps', () {
    const origen = LatLng(-12.065, -75.210);
    const destino = LatLng(-12.068, -75.205);
    const ruta = ResultadoRuta(
      distanciaMetros: 1500,
      duracionSegundos: 300,
      puntos: [origen, destino],
    );
    final msg = RoutingService.construirMensajeRuta(
      nombreDestino: 'Tienda Mass Centro',
      origen: origen,
      destino: destino,
      modo: ModoRuta.carro,
      ruta: ruta,
    );
    expect(msg, contains('Tienda Mass Centro'));
    expect(msg, contains('1.50 km'));
    expect(msg, contains('https://www.google.com/maps/dir/'));
    expect(msg.toLowerCase(), isNot(contains('académica')));
  });

  for (final width in [156.0, 300.0]) {
    testWidgets('Tarjeta legible con precio en una línea en ancho $width', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                height: 365,
                child: ProductoCatalogoCard(
                  producto: _crearProducto(precio: 1250.90),
                  onAgregar: () {},
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Sin imagen'), findsOneWidget);
      expect(find.text('S/ 1250.90'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('precioUnaLinea renderiza sin saltos de línea', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 110,
            child: precioUnaLinea(
              'Total S/ 12450.99',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
    final textWidget = tester.widget<Text>(find.text('Total S/ 12450.99'));
    expect(textWidget.maxLines, 1);
    expect(textWidget.softWrap, isFalse);
    expect(tester.takeException(), isNull);
  });
}
