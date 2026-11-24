import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/producto.dart';
import 'package:flutter_application_1/screens/inicio/inicio_screen.dart';
import 'package:flutter_application_1/screens/inicio/seleccion_inicio.dart';
import 'package:flutter_application_1/services/carrito_service.dart';
import 'package:flutter_application_1/services/catalogo_sesion.dart';
import 'package:flutter_application_1/services/filtro_catalogo.dart';
import 'package:flutter_application_1/tema/tema_mass.dart';
import 'package:flutter_test/flutter_test.dart';

Producto _producto({
  required String id,
  required String nombre,
  required String categoria,
  double precio = 5,
  int stock = 3,
  bool disponible = true,
}) {
  return Producto(
    id: id,
    nombre: nombre,
    descripcion: '',
    marca: 'Mass',
    precio: precio,
    stock: stock,
    categoria: categoria,
    disponible: disponible,
    fechaRegistro: DateTime(2026),
    presentaciones: const ['Bolsa 500g'],
    valoracion: 0,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    FiltroCatalogo.instancia.reiniciar();
    CatalogoSesion.instancia.reiniciar();
    CarritoService.instance.vaciar();
  });

  test('la selección prioriza disponibilidad y variedad', () {
    final lista = [
      _producto(id: 'z', nombre: 'Zumo', categoria: 'bebidas'),
      _producto(id: 'a', nombre: 'Arroz', categoria: 'abarrotes'),
      _producto(id: 'b', nombre: 'Avena', categoria: 'abarrotes'),
      _producto(
        id: 'agotado',
        nombre: 'Aceite',
        categoria: 'abarrotes',
        stock: 0,
      ),
      _producto(id: 'leche', nombre: 'Leche', categoria: 'lácteos', precio: 0),
    ];

    final seleccion = productosParaInicio(lista);

    expect(seleccion.map((p) => p.id), ['a', 'z', 'b']);
  });

  test('la búsqueda y la categoría se envían como una intención nueva', () {
    final filtro = FiltroCatalogo.instancia;
    filtro.buscar('aceite');
    expect(filtro.pendiente!.consulta, 'aceite');
    expect(filtro.pendiente!.categoria, 'todas');
    final primera = filtro.pendiente!.marca;

    filtro.abrirCategoria('bebidas');
    expect(filtro.pendiente!.consulta, isEmpty);
    expect(filtro.pendiente!.categoria, 'bebidas');
    expect(filtro.pendiente!.marca, greaterThan(primera));
  });

  testWidgets('Inicio busca, filtra y agrega un producto real', (tester) async {
    CatalogoSesion.instancia.publicar([
      _producto(id: 'arroz', nombre: 'Arroz extra', categoria: 'abarrotes'),
      _producto(id: 'agua', nombre: 'Agua mineral', categoria: 'bebidas'),
    ]);
    await tester.binding.setSurfaceSize(const Size(420, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    int? destino;
    await tester.pumpWidget(
      MaterialApp(
        theme: temaClienteMovil(),
        home: Scaffold(
          body: InicioScreen(
            onCambiarPestana: (i) => destino = i,
            mostrarAlquiler: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Arroz extra'), findsOneWidget);
    expect(find.text('+900'), findsNothing);
    expect(find.text('Accesos rápidos'), findsNothing);

    await tester.enterText(find.byType(TextField), 'aceite');
    await tester.tap(find.byTooltip('Buscar'));
    await tester.pump();
    expect(destino, 1);
    expect(FiltroCatalogo.instancia.pendiente!.consulta, 'aceite');

    destino = null;
    await tester.tap(find.text('Bebidas'));
    await tester.pump();
    expect(destino, 1);
    expect(FiltroCatalogo.instancia.pendiente!.categoria, 'bebidas');

    await tester.tap(find.text('Agregar').first);
    await tester.pump();
    expect(
      CarritoService.instance.cantidadDe(
        CatalogoSesion.instancia.productos.firstWhere((p) => p.id == 'arroz'),
      ),
      1,
    );
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(const Size(340, 760));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -2400));
    await tester.pumpAndSettle();
    expect(find.text('Aprende Mass'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
