import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/producto.dart';
import 'package:flutter_application_1/screens/precios_mass/catalogo_cliente.dart';
import 'package:flutter_application_1/screens/precios_mass/consulta_catalogo.dart';
import 'package:flutter_application_1/services/carrito_service.dart';
import 'package:flutter_application_1/services/catalogo_visual.dart';
import 'package:flutter_application_1/tema/tema_mass.dart';
import 'package:flutter_application_1/widgets/foto_producto.dart';
import 'package:flutter_test/flutter_test.dart';

const _png =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

Producto _producto({
  required String id,
  required String nombre,
  String marca = 'Mass',
  String categoria = 'abarrotes',
  double precio = 5,
  int stock = 3,
  bool disponible = true,
  String presentacion = 'Bolsa 500g',
  String codigo = '',
  String imagen = '',
}) {
  return Producto(
    id: id,
    nombre: nombre,
    descripcion: '',
    marca: marca,
    precio: precio,
    stock: stock,
    categoria: categoria,
    disponible: disponible,
    codigoBarras: codigo,
    imagenBase64: imagen,
    fechaRegistro: DateTime(2026),
    presentaciones: [presentacion],
    valoracion: 0,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(CarritoService.instance.vaciar);

  test(
    'ordena, filtra y conserva el agotado fuera del filtro de disponibles',
    () {
      final lista = [
        _producto(
          id: 'z',
          nombre: 'Zumo',
          categoria: 'bebidas',
          precio: 4,
          marca: 'Cielo',
        ),
        _producto(
          id: 'a',
          nombre: 'Arroz',
          precio: 8,
          marca: 'Costeño',
          codigo: '775123',
        ),
        _producto(
          id: 'x',
          nombre: 'Aceite',
          precio: 2,
          stock: 0,
          disponible: false,
          marca: 'Primor',
        ),
      ];

      final az = productosConsultados(lista, const ConsultaCatalogo());
      expect(az.map((p) => p.id), ['x', 'a', 'z']);

      final za = productosConsultados(
        lista,
        const ConsultaCatalogo(orden: OrdenCatalogo.za),
      );
      expect(za.first.id, 'z');

      final barato = productosConsultados(
        lista,
        const ConsultaCatalogo(orden: OrdenCatalogo.menorPrecio),
      );
      expect(barato.map((p) => p.id), ['x', 'z', 'a']);

      final marca = productosConsultados(
        lista,
        const ConsultaCatalogo(texto: 'cielo'),
      );
      expect(marca.single.id, 'z');

      final codigo = productosConsultados(
        lista,
        const ConsultaCatalogo(texto: '775123'),
      );
      expect(codigo.single.id, 'a');

      final vivos = productosConsultados(
        lista,
        const ConsultaCatalogo(soloDisponibles: true),
      );
      expect(vivos.map((p) => p.id), ['a', 'z']);

      final rango = productosConsultados(
        lista,
        const ConsultaCatalogo(precioDesde: 3, precioHasta: 5),
      );
      expect(rango.single.id, 'z');

      expect(columnasCatalogo(360), 2);
      expect(columnasCatalogo(280), 1);
    },
  );

  test('la caché distingue una imagen nueva del mismo producto', () {
    final primero = _producto(id: 'foto', nombre: 'Foto', imagen: _png);
    final invalido = _producto(id: 'foto', nombre: 'Foto', imagen: '@@@');
    final nuevo = _producto(id: 'foto', nombre: 'Foto', imagen: '${_png}x');

    expect(bytesImagenProductoEnCache(primero), isNotNull);
    expect(bytesImagenProductoEnCache(invalido), isNull);
    expect(bytesImagenProductoEnCache(nuevo), isNull);
  });

  testWidgets('la foto válida se muestra y la inválida usa el marcador', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: temaClienteMovil(),
        home: Column(
          children: [
            FotoProducto(
              producto: _producto(id: 'ok', nombre: 'Ok', imagen: _png),
            ),
            FotoProducto(
              producto: _producto(
                id: 'mal',
                nombre: 'Mal',
                imagen: 'no-es-imagen',
              ),
            ),
          ],
        ),
      ),
    );
    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
  });

  testWidgets('agregar, limitar el stock y volver a Agregar', (tester) async {
    final arroz = _producto(
      id: 'arroz',
      nombre: 'Arroz extra largo de grano entero premium',
      precio: 8.5,
      stock: 2,
      presentacion: 'Bolsa 900ml',
    );
    final agotado = _producto(
      id: 'seco',
      nombre: 'Detergente',
      categoria: 'limpieza',
      stock: 0,
      disponible: false,
    );
    final busqueda = TextEditingController();
    addTearDown(busqueda.dispose);
    String categoria = 'todas';
    await tester.binding.setSurfaceSize(const Size(420, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: temaClienteMovil(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return CatalogoCliente(
                productos: [arroz, agotado],
                cargando: false,
                fallo: false,
                busqueda: busqueda,
                categoria: categoria,
                alCategoria: (valor) => setState(() => categoria = valor),
                alReintentar: () {},
                alBolsillo: () {},
                alCanasta: (_) {},
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Agotado'), findsWidgets);
    expect(find.text('S/ 8.50'), findsOneWidget);
    expect(find.textContaining('/ L'), findsOneWidget);

    await tester.ensureVisible(find.text('Agregar'));
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();
    expect(CarritoService.instance.cantidadDe(arroz), 1);
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byTooltip('Agregar una unidad'));
    await tester.pumpAndSettle();
    expect(CarritoService.instance.cantidadDe(arroz), 2);
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byTooltip('Sin más stock registrado'),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byTooltip('Quitar una unidad'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Quitar una unidad'));
    await tester.pumpAndSettle();
    expect(CarritoService.instance.cantidadDe(arroz), 0);
    expect(find.text('Agregar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la búsqueda, la categoría y la pantalla estrecha no desbordan', (
    tester,
  ) async {
    final busqueda = TextEditingController();
    addTearDown(busqueda.dispose);
    String categoria = 'todas';
    await tester.binding.setSurfaceSize(const Size(340, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: temaClienteMovil(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return CatalogoCliente(
                productos: [
                  _producto(
                    id: 'largo',
                    nombre:
                        'Aceite vegetal clásico de cocina familiar botella transparente',
                    marca: 'Primor',
                    categoria: 'abarrotes',
                  ),
                  _producto(
                    id: 'agua',
                    nombre: 'Agua mineral',
                    marca: 'San Mateo',
                    categoria: 'bebidas',
                    precio: 2,
                  ),
                ],
                cargando: false,
                fallo: false,
                busqueda: busqueda,
                categoria: categoria,
                alCategoria: (valor) => setState(() => categoria = valor),
                alReintentar: () {},
                alBolsillo: () {},
                alCanasta: (_) {},
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(const Size(280, 700));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(const Size(340, 760));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'san mateo');
    await tester.pumpAndSettle();
    expect(find.text('Agua mineral'), findsOneWidget);
    expect(find.textContaining('Aceite vegetal'), findsNothing);

    await tester.tap(find.byTooltip('Limpiar búsqueda'));
    await tester.pumpAndSettle();
    await tester.binding.setSurfaceSize(const Size(520, 800));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bebidas'));
    await tester.pumpAndSettle();
    expect(find.text('Agua mineral'), findsOneWidget);
    expect(find.textContaining('Aceite vegetal'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Todas'));
    await tester.enterText(find.byType(TextField), 'inexistente');
    await tester.pumpAndSettle();
    expect(find.text('No hay coincidencias'), findsOneWidget);
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
