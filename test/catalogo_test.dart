import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/producto.dart';
import 'package:flutter_application_1/widgets/producto_catalogo_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('40 productos con IDs únicos y ocho por categoría', () {
    final productos = Producto.ejemplos();
    expect(productos.length, 40);
    expect(
      productos.every((p) => p.marca.isNotEmpty && p.marca != 'Genérica'),
      isTrue,
    );
    expect(productos.map((p) => p.id).toSet().length, 40);
    for (final categoria in Producto.categorias) {
      expect(productos.where((p) => p.categoria == categoria).length, 8);
    }
    expect(
      productos.every((p) => p.precio > 0 && p.stock > 0 && p.esEjemplo),
      isTrue,
    );
  });

  test('URL y marca de ejemplo sobreviven al guardado y edición', () {
    final producto = Producto.ejemplos().first
      ..imagenUrl = 'https://example.com/arroz.jpg';
    final recuperado = Producto.fromMap(producto.id, producto.toMap());
    expect(recuperado.imagenUrl, producto.imagenUrl);
    expect(recuperado.imagenAsset, producto.imagenAsset);
    expect(recuperado.imagenAutor, producto.imagenAutor);
    expect(recuperado.imagenLicencia, producto.imagenLicencia);
    expect(recuperado.imagenFuente, producto.imagenFuente);
    expect(recuperado.esEjemplo, isTrue);
    expect(recuperado.precio, producto.precio);
    final anterior = Map<String, dynamic>.from(producto.toMap())
      ..remove('imagenUrl')
      ..remove('esEjemplo');
    expect(Producto.fromMap('anterior', anterior).imagenUrl, '');
    expect(Producto.fromMap('anterior', anterior).esEjemplo, isFalse);
  });

  for (final width in [156.0, 300.0]) {
    testWidgets('Tarjeta sin foto legible con ancho $width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                height: 380,
                child: ProductoCatalogoCard(
                  producto: (Producto.ejemplos()[5]
                    ..imagenUrl = ''
                    ..imagenAsset = ''),
                  onEditar: () {},
                  onDuplicar: () {},
                  onEliminar: () {},
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Imagen pendiente'), findsOneWidget);
      expect(find.text('Avena QUAKER Tradicional Bolsa 500g'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  test('Los 40 productos incluyen fotos locales y créditos', () async {
    for (final producto in Producto.ejemplos()) {
      expect(
        producto.imagenUrl.isEmpty || producto.imagenUrl.startsWith('https://'),
        isTrue,
      );
      expect(producto.imagenAutor, isNotEmpty);
      expect(producto.imagenLicencia, isNotEmpty);
      expect(producto.imagenFuente, startsWith('https://www.'));
      final bytes = await rootBundle.load(producto.imagenAsset);
      expect(bytes.lengthInBytes, greaterThan(100));
    }
  });

  testWidgets('La foto local se muestra sin red y permite consultar créditos', (
    tester,
  ) async {
    final producto = Producto.ejemplos().first..imagenUrl = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 380,
            child: ProductoCatalogoCard(producto: producto, onEditar: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.image(AssetImage(producto.imagenAsset)), findsOneWidget);
    expect(find.text('Imagen pendiente'), findsNothing);
    await tester.tap(find.byTooltip('Créditos de la foto'));
    await tester.pumpAndSettle();
    expect(find.text('Foto del producto'), findsOneWidget);
    expect(find.textContaining(producto.imagenAutor), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test(
    'Coca-Cola y ChokoSoda conservan marca, presentación y empaque verificados',
    () {
      final productos = Producto.ejemplos();
      final coca = productos.singleWhere((p) => p.id == 'catalogo_011');
      expect(coca.marca, 'COCA COLA');
      expect(coca.nombre, contains('500ml'));
      expect(coca.presentaciones, ['Botella 500ml']);
      final choko = productos.singleWhere((p) => p.id == 'catalogo_035');
      expect(choko.marca, 'FIELD');
      expect(choko.nombre, contains('ChokoSoda'));
      expect(choko.presentaciones, ['Paquete 6un']);
      final lays = productos.singleWhere((p) => p.id == 'catalogo_033');
      expect(lays.presentaciones, ['Bolsa 140g']);
      expect(
        productos.every((p) => p.imagenAsset.contains('/marcas/')),
        isTrue,
      );
    },
  );
}
