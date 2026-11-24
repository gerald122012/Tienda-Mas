import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/cupon.dart';
import 'package:flutter_application_1/models/pedido.dart';
import 'package:flutter_application_1/models/producto.dart';
import 'package:flutter_application_1/models/tienda.dart';
import 'package:flutter_application_1/screens/admin/conteo_gestion.dart';
import 'package:flutter_application_1/screens/admin/piezas_gestion.dart';
import 'package:flutter_application_1/tema/tema_gestion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el resumen cuenta registros reales y no calcula ventas', () {
    final conteo = ConteoGestion.desde(
      productos: [
        _producto(stock: 4, disponible: true),
        _producto(stock: 0, disponible: true),
        _producto(stock: 3, disponible: false),
      ],
      pedidos: [
        _pedido('pendiente'),
        _pedido('preparando'),
        _pedido('entregado'),
        _pedido('cancelado'),
        _pedido('otro'),
      ],
      tiendas: [
        _tienda(latitud: -12.0, longitud: -77.0),
        _tienda(),
      ],
      cupones: const [
        CuponDescuento(
          codigo: 'MASS10',
          descripcion: 'Diez',
          tipo: 'porcentaje',
          valor: 10,
        ),
        CuponDescuento(
          codigo: 'PAUSA',
          descripcion: 'Pausa',
          tipo: 'monto',
          valor: 5,
          activo: false,
        ),
      ],
      locales: 2,
    );

    expect(conteo.productos, 3);
    expect(conteo.disponibles, 1);
    expect(conteo.agotados, 1);
    expect(conteo.noDisponiblesConStock, 1);
    expect(conteo.stockUnidades, 7);
    expect(conteo.pedidos, 5);
    expect(conteo.pendientes, 1);
    expect(conteo.preparando, 1);
    expect(conteo.entregados, 1);
    expect(conteo.cancelados, 1);
    expect(conteo.estadosNoReconocidos, 1);
    expect(conteo.tiendas, 2);
    expect(conteo.tiendasSinCoordenadas, 1);
    expect(conteo.cuponesActivos, 1);
    expect(conteo.hayPedidosParaGrafico, isTrue);
  });

  testWidgets('el gráfico solo aparece cuando hay pedidos registrados', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: temaGestionEmpresarial(),
        home: const Scaffold(
          body: BarrasPedidos(
            conteo: ConteoGestion(
              productos: 0,
              disponibles: 0,
              agotados: 0,
              noDisponiblesConStock: 0,
              stockUnidades: 0,
              pedidos: 0,
              pendientes: 0,
              preparando: 0,
              entregados: 0,
              cancelados: 0,
              estadosNoReconocidos: 0,
              tiendas: 0,
              tiendasSinCoordenadas: 0,
              cupones: 0,
              cuponesActivos: 0,
              locales: 0,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Todavía no hay pedidos registrados para graficar.'), findsOneWidget);
    expect(find.textContaining('Ventas'), findsNothing);
    expect(find.textContaining('%'), findsNothing);
  });
}

Producto _producto({required int stock, required bool disponible}) {
  return Producto(
    nombre: 'Producto',
    descripcion: 'Descripción',
    marca: 'Mass',
    precio: 2,
    stock: stock,
    categoria: 'abarrotes',
    disponible: disponible,
    fechaRegistro: DateTime(2026, 1, 1),
    presentaciones: const ['Bolsa'],
    valoracion: 0,
  );
}

Pedido _pedido(String estado) {
  return Pedido(
    id: estado,
    clienteNombre: 'Ana',
    clienteCorreo: 'ana@ejemplo.test',
    fecha: DateTime(2026, 1, 1),
    estado: estado,
    total: 10,
    items: const [
      ItemPedido(nombre: 'Arroz', marca: 'Mass', precio: 5, cantidad: 2),
    ],
  );
}

Tienda _tienda({double? latitud, double? longitud}) {
  return Tienda(
    nombre: 'Mass Centro',
    ciudad: 'Huancayo',
    distrito: 'El Tambo',
    direccion: 'Real 100',
    horario: '7:00 AM - 10:00 PM',
    cantidadProductos: 10,
    fechaApertura: DateTime(2020, 1, 1),
    abierta: true,
    servicios: const ['Yape'],
    latitud: latitud,
    longitud: longitud,
  );
}
