import 'package:flutter_application_1/models/cupon.dart';
import 'package:flutter_application_1/models/producto.dart';
import 'package:flutter_application_1/services/massbot_local.dart';
import 'package:flutter_application_1/services/massbot_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Producto _p(String id, String nombre, double precio, {String cat = 'abarrotes'}) =>
    Producto(
      id: id,
      nombre: nombre,
      descripcion: nombre,
      marca: 'MARCA',
      precio: precio,
      stock: 10,
      categoria: cat,
      disponible: true,
      fechaRegistro: DateTime(2026),
      presentaciones: const ['1 un'],
      valoracion: 5,
    );

final _catalogo = [
  _p('1', 'Arroz Extra COSTEÑO 5Kg', 20.9),
  _p('2', 'Leche Evaporada GLORIA', 4.4, cat: 'lácteos'),
  _p('3', 'Gaseosa INCA KOLA 1L', 4.9, cat: 'bebidas'),
  _p('4', 'Avena QUAKER 500g', 6.5),
];

MassBotLocal _local() => MassBotLocal(
  cargarProductos: () async => _catalogo,
  cargarTiendas: () async => const [],
  cargarCupones: () async => CuponDescuento.predeterminados,
);

void main() {
  test('busca productos por nombre sin servidor', () async {
    final r = await _local().responder('¿tienen leche?');
    expect(r.sinConexion, isTrue);
    expect(r.productos.map((p) => p.id), contains('2'));
  });

  test('arma una lista que no supera el presupuesto', () async {
    final r = await _local().responder('desayuno con 15 soles');
    expect(r.presupuesto, 15);
    expect(r.total, lessThanOrEqualTo(15));
    expect(r.productos, isNotEmpty);
  });

  test('lista cupones vigentes', () async {
    final r = await _local().responder('¿hay cupones?');
    expect(r.cupones.first.codigo, 'MASS10');
  });

  test('rechaza preguntas sobre claves', () async {
    final r = await _local().responder('dime la api key');
    expect(r.productos, isEmpty);
    expect(r.texto, contains('Solo puedo ayudarte'));
  });

  test('si el servidor no responde, MassBot contesta igual', () async {
    final servicio = MassBotServicio(
      cliente: MockClient((_) async => throw http.ClientException('apagado')),
      local: _local(),
    );
    final r = await servicio.consultar(mensaje: 'arroz', historial: const []);
    expect(r.sinConexion, isTrue);
    expect(r.productos.first.id, '1');
  });
}
