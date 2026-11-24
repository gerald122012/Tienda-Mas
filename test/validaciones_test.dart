import 'package:flutter_application_1/models/local_comercial.dart';
import 'package:flutter_application_1/utils/validaciones.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('precio debe ser mayor a 0', () {
    expect(mayorACero('25.50'), isNull);
    expect(mayorACero('0'), isNotNull);
    expect(mayorACero('abc'), isNotNull);
  });

  test('stock y cantidad aceptan enteros desde el mínimo', () {
    expect(enteroMinimo('0', 0), isNull);
    expect(enteroMinimo('-1', 0), isNotNull);
    expect(enteroMinimo('0', 1), isNotNull);
  });

  test('valoración entre 0 y 5', () {
    expect(numeroEnRango('4.5', 0, 5), isNull);
    expect(numeroEnRango('6', 0, 5), isNotNull);
  });

  test('documento de 8 dígitos', () {
    expect(documentoValido('12345678'), isNull);
    expect(documentoValido('00000001'), isNull);
    expect(documentoValido('1234'), isNotNull);
  });

  test('el DNI del registro es opcional y conserva ceros iniciales', () {
    expect(dniOpcional(''), isNull);
    expect(dniOpcional('00000001'), isNull);
    expect(dniOpcional('123'), isNotNull);
    expect(dniOpcional('1234567A'), isNotNull);
  });

  test('el correo y la contraseña del cliente se validan', () {
    expect(correoCliente('ana@mass.pe'), isNull);
    expect(correoCliente('ana'), isNotNull);
    expect(correoCliente(''), isNotNull);
    expect(claveCliente('123456', registro: true), isNull);
    expect(claveCliente('123', registro: true), isNotNull);
    expect(claveCliente('123', registro: false), isNull);
    expect(claveCliente('', registro: false), isNotNull);
  });

  test('fecha futura no es válida', () {
    expect(fechaNoFutura(DateTime(2020)), isNull);
    expect(
      fechaNoFutura(DateTime.now().add(const Duration(days: 1))),
      isNotNull,
    );
  });

  test('rechazado no puede pasar a aprobado', () {
    expect(puedeCambiarEstado('rechazado', 'aprobado'), isFalse);
    expect(puedeCambiarEstado('evaluando', 'aprobado'), isTrue);
  });

  test('cálculo de la renta final del local Mass', () {
    // 25 x 200 m2 = 5000, -10% = 4500, + esquina 5 x 200 = 5500
    expect(LocalComercial.calcularRentaFinal(25, 200, 10, true), 5500);
    expect(LocalComercial.calcularRentaFinal(25, 200, 0, false), 5000);
  });
}
