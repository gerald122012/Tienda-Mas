import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/cupon.dart';
import 'package:flutter_application_1/models/pedido.dart';
import 'package:flutter_application_1/models/producto.dart';
import 'package:flutter_application_1/screens/carrito/carrito_screen.dart';
import 'package:flutter_application_1/screens/massbot/widgets/boton_flotante_massbot.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/carrito_service.dart';
import 'package:flutter_application_1/services/pedidos_local_service.dart';
import 'package:flutter_application_1/services/registro_pedidos.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _png =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

Producto _producto({
  String id = 'arroz',
  String nombre = 'Arroz extra gran reserva de la costa norte',
  String marca = 'Mass',
  double precio = 12,
  int stock = 5,
  String imagen = '',
  bool disponible = true,
}) {
  return Producto(
    id: id,
    nombre: nombre,
    descripcion: nombre,
    marca: marca,
    precio: precio,
    stock: stock,
    categoria: 'abarrotes',
    disponible: disponible,
    fechaRegistro: DateTime(2026, 1, 1),
    presentaciones: const ['Bolsa 5 kg'],
    valoracion: 0,
    imagenBase64: imagen,
  );
}

Future<void> _abrir(
  WidgetTester tester,
  CarritoScreen pantalla, {
  Size tamano = const Size(400, 900),
  double teclado = 0,
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: teclado);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      home: const Scaffold(body: Text('origen')),
    ),
  );
  final contexto = tester.element(find.text('origen'));
  Navigator.of(contexto).push(
    MaterialPageRoute<void>(builder: (_) => pantalla),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CarritoService.instance.vaciar();
  });

  tearDown(() async {
    await AuthService.instance.cerrarSesion();
    CarritoService.instance.vaciar();
    CarritoService.instance.setPresupuesto(null);
    CarritoService.instance.setRutaSeleccionada(null);
    await IntentoRegistroPedido.limpiar();
  });

  testWidgets('el carrito vacío invita a ver productos', (tester) async {
    var abrioCatalogo = false;
    await _abrir(
      tester,
      CarritoScreen(alVerProductos: () => abrioCatalogo = true),
    );
    expect(find.text('Tu carrito está vacío'), findsOneWidget);
    expect(find.text('Mi carrito'), findsOneWidget);
    expect(find.text('Sin productos'), findsOneWidget);
    await tester.tap(find.text('Ver productos'));
    expect(abrioCatalogo, isTrue);
    expect(find.byType(BotonFlotanteMassBot), findsNothing);
  });

  testWidgets('muestra la foto real y el marcador si la imagen no sirve', (
    tester,
  ) async {
    final carrito = CarritoService.instance;
    carrito.agregar(_producto(id: 'ok', nombre: 'Leche', imagen: _png));
    carrito.agregar(_producto(id: 'mala', nombre: 'Fideos', imagen: '%%%'));
    carrito.agregar(_producto(id: 'nada', nombre: 'Agua', imagen: ''));
    await _abrir(tester, const CarritoScreen(buscarCupon: _sinCupon));
    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Icons.shopping_bag_outlined), findsNWidgets(2));
    expect(find.text('Leche'), findsOneWidget);
    expect(find.text('Fideos'), findsOneWidget);
  });

  testWidgets('cantidad, stock, subtotal y catálogo usan el mismo carrito', (
    tester,
  ) async {
    final carrito = CarritoService.instance;
    final arroz = _producto(stock: 2, precio: 10);
    carrito.agregar(arroz);
    await _abrir(tester, const CarritoScreen(buscarCupon: _sinCupon));
    expect(find.text('1 unidad'), findsWidgets);
    expect(find.text('S/ 10.00'), findsWidgets);

    await tester.tap(find.byTooltip('Agregar una unidad'));
    await tester.pump();
    expect(carrito.cantidadDe(arroz), 2);
    expect(carrito.subtotal, closeTo(20, 0.001));
    expect(carrito.total, closeTo(20, 0.001));
    expect(find.text('2 unidades'), findsWidgets);
    expect(find.text('S/ 20.00'), findsWidgets);

    final mas = tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip('Sin más stock registrado'),
        matching: find.byType(IconButton),
      ),
    );
    expect(mas.onPressed, isNull);

    await tester.tap(find.byTooltip('Quitar una unidad'));
    await tester.pump();
    expect(carrito.cantidadDe(arroz), 1);
    expect(find.text('1 unidad'), findsWidgets);
  });

  testWidgets('eliminar un producto pide confirmación y vacía la lista', (
    tester,
  ) async {
    final carrito = CarritoService.instance;
    final arroz = _producto();
    carrito.agregar(arroz);
    await _abrir(tester, const CarritoScreen(buscarCupon: _sinCupon));
    await tester.tap(find.byTooltip('Quitar ${arroz.nombre}'));
    await tester.pumpAndSettle();
    expect(carrito.unidades, 1);
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    expect(carrito.vacio, isTrue);
    expect(find.text('Tu carrito está vacío'), findsOneWidget);
  });

  testWidgets('un cupón válido descuenta y uno inválido no', (tester) async {
    final carrito = CarritoService.instance;
    carrito.agregar(_producto(precio: 20));
    await _abrir(tester, const CarritoScreen(buscarCupon: _sinCupon));
    expect(find.textContaining('Ahorras'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'NOEXISTE');
    await tester.tap(find.text('Aplicar'));
    await tester.pump();
    expect(find.textContaining('no corresponde a un cupón válido'), findsOneWidget);
    expect(carrito.cuponAplicado, isNull);
    expect(carrito.total, closeTo(20, 0.001));

    await tester.enterText(find.byType(TextField).first, 'mass10');
    await tester.tap(find.text('Aplicar'));
    await tester.pump();
    expect(find.text('Cupón MASS10 aplicado'), findsOneWidget);
    expect(carrito.descuento, closeTo(2, 0.001));
    expect(carrito.total, closeTo(18, 0.001));
    expect(find.text('S/ 18.00'), findsWidgets);
    expect(find.textContaining('Pagar ahora'), findsNothing);
  });

  testWidgets('si el carrito baja del mínimo el cupón deja de descontar', (
    tester,
  ) async {
    final carrito = CarritoService.instance;
    final caro = _producto(id: 'caro', precio: 12);
    final barato = _producto(id: 'barato', nombre: 'Agua', precio: 4);
    carrito.agregar(caro);
    expect(carrito.aplicarCupon(CuponDescuento.predeterminados.first), isNull);
    carrito.agregar(barato);
    await _abrir(tester, const CarritoScreen(buscarCupon: _sinCupon));
    expect(carrito.descuento, closeTo(1.6, 0.001));

    await tester.tap(find.byTooltip('Quitar ${caro.nombre}'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(carrito.cuponAplicado?.codigo, 'MASS10');
    expect(carrito.descuento, 0);
    expect(carrito.total, closeTo(4, 0.001));
    expect(find.textContaining('ya no cumple el monto mínimo'), findsOneWidget);
  });

  testWidgets('recojo y delivery se distinguen sin inventar un costo', (
    tester,
  ) async {
    CarritoService.instance.agregar(_producto());
    CarritoService.instance.setRutaSeleccionada('Tienda demo · 1.20 km');
    await _abrir(tester, const CarritoScreen(buscarCupon: _sinCupon));
    expect(find.text('¿Cómo recibirás tu compra?'), findsOneWidget);
    expect(find.text('Recojo en tienda'), findsOneWidget);
    expect(find.textContaining('La tienda se elige en Ubícame'), findsOneWidget);

    await tester.ensureVisible(find.text('Delivery'));
    await tester.tap(find.text('Delivery'));
    await tester.pump();
    expect(find.text('Tienda demo · 1.20 km'), findsOneWidget);
    expect(find.textContaining('No hay un costo de entrega calculado'), findsWidgets);
    expect(find.text('Ver ruta'), findsOneWidget);
    expect(find.text('Total de productos'), findsOneWidget);
    expect(find.textContaining('Total a pagar'), findsNothing);
  });

  testWidgets('un invitado continúa hacia el acceso y no paga', (tester) async {
    CarritoService.instance.agregar(_producto());
    await _abrir(tester, const CarritoScreen(buscarCupon: _sinCupon));
    expect(AuthService.instance.usuario, isNull);
    expect(find.text('Ingresar para continuar'), findsOneWidget);
    expect(find.text('Confirmar pedido'), findsNothing);
  });

  testWidgets('registrar el pedido bloquea un segundo toque', (tester) async {
    await AuthService.instance.iniciarSesion(
      'cliente@tiendamass.pe',
      'Cliente123',
    );
    CarritoService.instance.agregar(_producto());
    final espera = Completer<AcuseEscritura>();
    final escritor = _EscritorControlado(
      alEscribir: (_, _) => espera.future,
    );
    addTearDown(() {
      if (!espera.isCompleted) espera.complete(AcuseEscritura.confirmada);
    });
    await _abrir(
      tester,
      CarritoScreen(
        buscarCupon: _sinCupon,
        uidCliente: 'cliente-prueba',
        registro: RegistroPedidos(
          escritor: escritor,
          guardarLocal: PedidosLocalService.instance.guardarPedido,
        ),
      ),
    );
    await tester.tap(find.text('Confirmar pedido'));
    await tester.pump();
    expect(find.text('Registrando pedido'), findsOneWidget);
    await tester.tap(find.text('Registrando pedido'));
    await tester.pump();
    expect(escritor.escrituras, 1);
    expect(CarritoService.instance.vacio, isFalse);
    espera.complete(AcuseEscritura.confirmada);
    await tester.pumpAndSettle();
    expect(CarritoService.instance.vacio, isTrue);
    expect(find.textContaining('Pedido registrado'), findsOneWidget);
    expect(find.textContaining('Pagar'), findsNothing);
  });

  testWidgets('un error al registrar conserva el carrito y el cupón', (
    tester,
  ) async {
    await AuthService.instance.iniciarSesion(
      'cliente@tiendamass.pe',
      'Cliente123',
    );
    final carrito = CarritoService.instance;
    final arroz = _producto(precio: 20);
    carrito.agregar(arroz);
    expect(carrito.aplicarCupon(CuponDescuento.predeterminados.first), isNull);
    final total = carrito.total;
    await _abrir(
      tester,
      CarritoScreen(
        buscarCupon: _sinCupon,
        uidCliente: 'cliente-prueba',
        registro: RegistroPedidos(
          escritor: _EscritorControlado(
            alEscribir: (_, _) async => AcuseEscritura.rechazada,
          ),
          guardarLocal: PedidosLocalService.instance.guardarPedido,
        ),
      ),
    );
    await tester.tap(find.text('Confirmar pedido'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'No se pudo registrar tu pedido. Tus productos siguen en el carrito. Inténtalo nuevamente.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Pedido registrado'), findsNothing);
    expect(carrito.vacio, isFalse);
    expect(carrito.cantidadDe(arroz), 1);
    expect(carrito.cuponAplicado?.codigo, 'MASS10');
    expect(carrito.total, closeTo(total, 0.001));
    final intento = await IntentoRegistroPedido.leer(
      uid: 'cliente-prueba',
      correo: 'cliente@tiendamass.pe',
    );
    expect(intento, isNotNull);
    expect(
      PedidosLocalService.instance.pedidos.any((p) => p.id == intento!.id),
      isFalse,
    );
  });

  testWidgets('cabe en una pantalla estrecha y con el teclado abierto', (
    tester,
  ) async {
    CarritoService.instance.agregar(
      _producto(
        nombre: 'Detergente líquido para ropa de color con aroma prolongado',
      ),
    );
    await _abrir(
      tester,
      const CarritoScreen(buscarCupon: _sinCupon),
      tamano: const Size(320, 640),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Confirmar pedido'), findsNothing);
    expect(find.text('Ingresar para continuar'), findsOneWidget);

    await _abrir(
      tester,
      const CarritoScreen(buscarCupon: _sinCupon),
      tamano: const Size(360, 700),
      teclado: 280,
    );
    await tester.enterText(find.byType(TextField).first, 'MASS15');
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Aplicar'), findsOneWidget);
  });

  test('un cupón inactivo o bajo el mínimo no se aplica dos veces', () {
    final carrito = CarritoService.instance;
    carrito.agregar(_producto(precio: 5));
    final minimo = carrito.aplicarCupon(CuponDescuento.predeterminados.first);
    expect(minimo, contains('Compra mínima'));
    expect(carrito.cuponAplicado, isNull);

    final inactivo = const CuponDescuento(
      codigo: 'PAUSA',
      descripcion: 'Pausado',
      tipo: 'monto',
      valor: 5,
      activo: false,
    );
    expect(carrito.aplicarCupon(inactivo), contains('no está activo'));
    carrito.agregar(_producto(id: 'otro', precio: 40));
    expect(carrito.aplicarCupon(CuponDescuento.predeterminados.first), isNull);
    expect(carrito.descuento, closeTo(4.5, 0.001));
    expect(carrito.aplicarCupon(CuponDescuento.predeterminados[1]), isNull);
    expect(carrito.cuponAplicado?.codigo, 'MASS15');
    expect(carrito.descuento, closeTo(6.75, 0.001));
  });

  test('el pedido de prueba conserva el total de productos sin delivery', () {
    final pedido = Pedido(
      id: 'local',
      clienteNombre: 'Cliente de prueba',
      clienteCorreo: 'cliente@tiendamass.pe',
      fecha: DateTime(2026, 11, 24),
      estado: 'pendiente',
      subtotal: 20,
      descuento: 2,
      total: 18,
      cuponCodigo: 'MASS10',
      tipoEntrega: 'delivery',
      rutaResumen: 'Destino de prueba · 1 km',
      items: const [
        ItemPedido(
          productoId: 'arroz',
          nombre: 'Arroz',
          marca: 'Mass',
          precio: 20,
          cantidad: 1,
        ),
      ],
    );
    expect(pedido.total, pedido.subtotal - pedido.descuento);
    expect(pedido.toLocalJson().containsKey('costoDelivery'), isFalse);
  });
}

Future<CuponDescuento?> _sinCupon(String codigo) async {
  return CuponDescuento.predeterminados
      .where((c) => c.codigo == codigo)
      .firstOrNull;
}

class _EscritorControlado implements EscritorPedidos {
  final Future<AcuseEscritura> Function(String id, Map<String, dynamic> datos)?
  alEscribir;
  int escrituras = 0;

  _EscritorControlado({this.alEscribir});

  @override
  Future<AcuseEscritura> consultar(String id) async => AcuseEscritura.ausente;

  @override
  Future<AcuseEscritura> escribir(String id, Map<String, dynamic> datos) {
    escrituras++;
    return alEscribir?.call(id, datos) ??
        Future.value(AcuseEscritura.confirmada);
  }
}
