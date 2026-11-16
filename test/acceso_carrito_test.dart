import 'package:flutter_application_1/models/producto.dart';
import 'package:flutter_application_1/models/usuario.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/carrito_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    AuthService.instance.cerrarSesion();
    CarritoService.instance.vaciar();
  });

  test('login demo con rol correcto', () async {
    final auth = AuthService.instance;
    expect(
      await auth.iniciarSesion(' CLIENTE@tiendamass.pe ', 'Cliente123'),
      isNull,
    );
    expect(auth.usuario!.rol, Rol.cliente);
    expect(await auth.iniciarSesion('admin@tiendamass.pe', 'Admin123'), isNull);
    expect(auth.usuario!.esAdmin, isTrue);
  });

  test('carrito respeta stock, suma totales y se vacía al salir', () async {
    final carrito = CarritoService.instance;
    final p = Producto.ejemplos().first..stock = 2;
    expect(carrito.agregar(p), isTrue);
    expect(carrito.agregar(p), isTrue);
    expect(carrito.agregar(p), isFalse);
    expect(carrito.unidades, 2);
    expect(carrito.total, closeTo(p.precio * 2, 0.001));
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
    final p = Producto.ejemplos().first..stock = 0;
    expect(CarritoService.instance.agregar(p), isFalse);
  });
}
