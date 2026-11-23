import 'package:flutter_application_1/models/cupon.dart';
import 'package:flutter_application_1/models/pedido.dart';
import 'package:flutter_application_1/models/producto.dart';
import 'package:flutter_application_1/models/usuario.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/carrito_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Producto _productoPrueba({
  String id = 'prod_1',
  String nombre = 'Arroz Extra Bolsa 5Kg',
  double precio = 20.0,
  int stock = 5,
}) {
  return Producto(
    id: id,
    nombre: nombre,
    descripcion: nombre,
    marca: 'Mass',
    precio: precio,
    stock: stock,
    categoria: 'abarrotes',
    disponible: true,
    fechaRegistro: DateTime(2026, 1, 1),
    presentaciones: const ['Bolsa 5Kg'],
    valoracion: 5,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await AuthService.instance.cerrarSesion();
    CarritoService.instance.vaciar();
    CarritoService.instance.setPresupuesto(null);
  });

  test('login local respeta separación web admin vs app cliente', () async {
    final auth = AuthService.instance;
    expect(
      await auth.iniciarSesion(
        ' CLIENTE@tiendamass.pe ',
        'Cliente123',
        rolRequerido: Rol.cliente,
      ),
      isNull,
    );
    expect(auth.usuario!.rol, Rol.cliente);

    expect(
      await auth.iniciarSesion(
        'cliente@tiendamass.pe',
        'Cliente123',
        rolRequerido: Rol.administrador,
      ),
      isNotNull,
    );

    expect(
      await auth.iniciarSesion(
        'admin@tiendamass.pe',
        'Admin123',
        rolRequerido: Rol.cliente,
      ),
      isNotNull,
    );

    expect(
      await auth.iniciarSesion(
        'admin@tiendamass.pe',
        'Admin123',
        rolRequerido: Rol.administrador,
      ),
      isNull,
    );
    expect(auth.usuario!.esAdmin, isTrue);
  });

  test('carrito respeta stock, aplica cupón QR, presupuesto y se vacía al salir', () async {
    final carrito = CarritoService.instance;
    final p = _productoPrueba(stock: 2, precio: 15.0);
    expect(carrito.agregar(p), isTrue);
    expect(carrito.agregar(p), isTrue);
    expect(carrito.agregar(p), isFalse);
    expect(carrito.unidades, 2);
    expect(carrito.subtotal, closeTo(30.0, 0.001));

    final cupon = CuponDescuento.predeterminados.first;
    expect(carrito.aplicarCupon(cupon), isNull);
    expect(carrito.descuento, closeTo(3.0, 0.001));
    expect(carrito.total, closeTo(27.0, 0.001));

    carrito.setPresupuesto(25.0);
    expect(carrito.excedePresupuesto, isTrue);
    carrito.setPresupuesto(30.0);
    expect(carrito.excedePresupuesto, isFalse);
    expect(carrito.restantePresupuesto, closeTo(3.0, 0.001));

    carrito.quitarUna(p);
    expect(carrito.cantidadDe(p), 1);

    await AuthService.instance.iniciarSesion(
      'cliente@tiendamass.pe',
      'Cliente123',
    );
    await AuthService.instance.cerrarSesion();
    expect(carrito.vacio, isTrue);
  });

  test('producto agotado no entra al carrito', () {
    final p = _productoPrueba(stock: 0);
    expect(CarritoService.instance.agregar(p), isFalse);
  });

  test('pedido serializa verificación de recojo y foto correctamente', () {
    final pedido = Pedido(
      id: 'ped_001',
      clienteNombre: 'Ana Pérez',
      clienteCorreo: 'ana@tiendamass.pe',
      fecha: DateTime(2026, 11, 18, 15, 30),
      estado: 'pendiente',
      subtotal: 40.0,
      descuento: 4.0,
      total: 36.0,
      cuponCodigo: 'MASS10',
      tipoEntrega: 'recojo',
      personaRecojo: 'Carlos Pérez',
      fotoRecojoBase64: 'YWJjMTIz',
      items: const [
        ItemPedido(
          productoId: 'prod_1',
          nombre: 'Arroz 5Kg',
          marca: 'Mass',
          precio: 20.0,
          cantidad: 2,
        ),
      ],
    );
    final reconstruido = Pedido.fromMap(pedido.id, pedido.toLocalJson());
    expect(reconstruido.personaRecojo, 'Carlos Pérez');
    expect(reconstruido.fotoRecojoBase64, 'YWJjMTIz');
    expect(reconstruido.cuponCodigo, 'MASS10');
    expect(reconstruido.total, 36.0);
    expect(reconstruido.totalUnidades, 2);
  });
}
